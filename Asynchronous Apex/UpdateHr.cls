public class NotifyHrQueueable implements Queueable, Database.AllowsCallouts {

    private Map<Id, Integer> countPerUser;

    public NotifyHrQueueable(Map<Id, Integer> countPerUser) {
        this.countPerUser = countPerUser;
    }

    public void execute(QueueableContext qc) {
        List<Map<String, Object>> items = new List<Map<String, Object>>();
        for (Id uid : countPerUser.keySet()) {
            items.add(new Map<String, Object>{
                'userId'          => uid,
                'casesReassigned' => countPerUser.get(uid)
            });
        }

        String errorMsg;
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Reassign_Case_API_Named_Cred/Hr');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(items));

            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() != 200) {
                errorMsg = 'HTTP ' + res.getStatusCode() + ': ' + res.getBody();
            }
        } catch (Exception e) {
            errorMsg = e.getMessage();
        }

        if (errorMsg != null) {
            List<Audit_Log__c> logs = new List<Audit_Log__c>();
            for (Id uid : countPerUser.keySet()) {
                logs.add(new Audit_Log__c(
                    User__c = uid,
                    Error_Message__c = errorMsg
                ));
            }
            insert logs;
        }
    }
}