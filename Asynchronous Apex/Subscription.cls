
global class SubscriptionSchedular implements Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new expiredSubscription(), 200);
    }
}


global class expiredSubscription implements Database.Batchable<SObject>, Database.Stateful {

    global Integer expiredSuccessful = 0;
    global Integer expiredFail = 0;
    global Decimal totalMonthlyFee = 0;

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Status__c, End_Date__c, Account__c, Monthly_Fee__c
            FROM Subscription__c
            WHERE Status__c = 'Active' AND End_Date__c < TODAY
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Subscription__c> scope) {
        List<Subscription__c> toUpdate = new List<Subscription__c>();
        for (Subscription__c s : scope) {
            toUpdate.add(new Subscription__c(Id = s.Id, Status__c = 'Expired'));
        }

        // allOrNone = false: one bad record doesn't stop the others
        Database.SaveResult[] results = Database.update(toUpdate, false);

        List<Integration_Error__c> errors = new List<Integration_Error__c>();

        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                expiredSuccessful++;
                if (scope[i].Monthly_Fee__c != null) {
                    totalMonthlyFee += scope[i].Monthly_Fee__c;
                }
            } else {
                expiredFail++; 
                errors.add(new Integration_Error__c(
                    Subscription__c = scope[i].Id,
                    Error_Message__c = results[i].getErrors()[0].getMessage()
                ));
            }
        }
        if (!errors.isEmpty()) {
            insert errors;
        }
    }

    global void finish(Database.BatchableContext bc) {
        Map<String, Object> summary = new Map<String, Object>{
            'expiredSuccessful' => expiredSuccessful,
            'expiredFailed'     => expiredFail,
            'totalMonthlyFee'   => totalMonthlyFee
        };
        System.enqueueJob(new SummaryCallout(JSON.serialize(summary)));
    }
}

// ============================================================
// Queueable: one summary callout, failure logged
// ============================================================
global class SummaryCallout implements Queueable, Database.AllowsCallouts {

    global String payload;

    global SummaryCallout(String payload) {
        this.payload = payload;
    }

    global void execute(QueueableContext qc) {
        String errorMsg;

        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Finance_API_Named_Cred/summary');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(payload);

            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() != 200) {
                errorMsg = 'HTTP ' + res.getStatusCode() + ': ' + res.getBody();
            }
        } catch (Exception e) {
            errorMsg = e.getMessage();
        }

        if (errorMsg != null) {
            insert new Integration_Error__c(
                Error_Message__c = 'Summary callout failed: ' + errorMsg
            );
        }
    }
}