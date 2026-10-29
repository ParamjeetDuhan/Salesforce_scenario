// ============================================================
// Trigger: real-change filter + context routing
// ============================================================
trigger AddressVerification on Account (after insert, after update) {
    Set<Id> accountIds = new Set<Id>();

    for (Account acc : Trigger.new) {
        // On insert the || short-circuits, so oldMap is never touched
        if (String.isNotBlank(acc.BillingPostalCode) &&
            (Trigger.isInsert ||
             acc.BillingPostalCode != Trigger.oldMap.get(acc.Id).BillingPostalCode)) {
            accountIds.add(acc.Id);
        }
    }

    if (!accountIds.isEmpty()) {
        if (System.isBatch() || System.isFuture()) {
            // @future is not allowed here, so use a Queueable
            System.enqueueJob(new AddressVerificationQueueable(accountIds));
        } else {
            AddressVerificationHandler.verifyFuture(accountIds);
        }
    }
}

// ============================================================
// One item in the API response
// ============================================================
public class AddressResult {
    public Id id;
    public Boolean valid;
    public String city;
    public String state;
}

// ============================================================
// Shared logic: written ONCE, called from both paths
// ============================================================
public class AddressVerificationService {

    public static void verify(Set<Id> accountIds) {
        List<Account> accounts = [
            SELECT Id, BillingPostalCode FROM Account WHERE Id IN :accountIds
        ];
        if (accounts.isEmpty()) {
            return;
        }

        List<Map<String, Object>> payload = new List<Map<String, Object>>();
        for (Account a : accounts) {
            payload.add(new Map<String, Object>{
                'id'         => a.Id,
                'postalCode' => a.BillingPostalCode
            });
        }

        List<AddressResult> results = new List<AddressResult>();
        String errorMsg;

        // 1) Callout FIRST, before any DML
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Address_API_Named_Cred/verify');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(payload));

            HttpResponse res = new Http().send(req);

            if (res.getStatusCode() == 200) {
                results = (List<AddressResult>) JSON.deserialize(
                    res.getBody(), List<AddressResult>.class);
            } else {
                errorMsg = 'HTTP ' + res.getStatusCode() + ': ' + res.getBody();
            }
        } catch (Exception e) {
            errorMsg = e.getMessage();
        }

        // 2) DML AFTER the callout. Check the error FIRST.
        if (errorMsg != null) {
            List<Integration_Error__c> errors = new List<Integration_Error__c>();
            for (Account a : accounts) {
                errors.add(new Integration_Error__c(
                    Account__c = a.Id,
                    Error_Message__c = errorMsg
                ));
            }
            insert errors;
        } else {
            List<Account> toUpdate = new List<Account>();
            for (AddressResult r : results) {
                Boolean ok = (r.valid == true);
                toUpdate.add(new Account(
                    Id = r.id,
                    Address_Verified__c = ok,
                    Verified_City__c    = ok ? r.city  : null,
                    Verified_State__c   = ok ? r.state : null
                ));
            }
            if (!toUpdate.isEmpty()) {
                update toUpdate;
            }
        }
    }
}

// ============================================================
// Path 1: @future (normal context)
// ============================================================
public class AddressVerificationHandler {
    @future(callout=true)
    public static void verifyFuture(Set<Id> accountIds) {
        AddressVerificationService.verify(accountIds);
    }
}

// ============================================================
// Path 2: Queueable (batch / future context)
// ============================================================
public class AddressVerificationQueueable implements Queueable, Database.AllowsCallouts {

    private Set<Id> accountIds;

    public AddressVerificationQueueable(Set<Id> accountIds) {
        this.accountIds = accountIds;
    }

    public void execute(QueueableContext qc) {
        AddressVerificationService.verify(accountIds);
    }
}