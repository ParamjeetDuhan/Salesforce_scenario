public class ContactEmailVerifyQueueable implements Queueable, Database.AllowsCallouts {

    private List<Id> contactIds;

    public ContactEmailVerifyQueueable(List<Id> contactIds) {
        this.contactIds = contactIds;
    }

    public void execute(QueueableContext qc) {
        List<Contact> contacts = [
            SELECT Id, Email FROM Contact WHERE Id IN :contactIds
        ];

        // Build ONE payload for all contacts
        List<Map<String, String>> items = new List<Map<String, String>>();
        for (Contact c : contacts) {
            items.add(new Map<String, String>{ 'id' => c.Id, 'email' => c.Email });
        }

        Map<String, Boolean> results = new Map<String, Boolean>();
        String errorMsg;

        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Email_Verify_API_Named_Cred/verify');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(items));

            HttpResponse res = new Http().send(req);

            if (res.getStatusCode() == 200) {
                List<Object> parsed = (List<Object>) JSON.deserializeUntyped(res.getBody());
                for (Object o : parsed) {
                    Map<String, Object> m = (Map<String, Object>) o;
                    results.put((String) m.get('id'), (Boolean) m.get('valid'));
                }
            } else {
                errorMsg = 'HTTP ' + res.getStatusCode() + ': ' + res.getBody();
            }
        } catch (Exception e) {
            errorMsg = e.getMessage();
        }

        List<Contact> toUpdate = new List<Contact>();
        List<Integration_Error__c> errors = new List<Integration_Error__c>();

        for (Contact c : contacts) {
            if (errorMsg != null) {
                errors.add(new Integration_Error__c(
                    Contact__c = c.Id,
                    Error_Message__c = errorMsg
                ));
            } else {
                Boolean valid = results.get(String.valueOf(c.Id));
                toUpdate.add(new Contact(Id = c.Id, Email_Verified__c = (valid == true)));
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
        if (!errors.isEmpty()) {
            insert errors;
        }
    }
}