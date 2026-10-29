// ============================================================
// Schedulable
// ============================================================
global class SchedulePendingCustomer implements Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new SyncPendingCustomer(), 200);
    }
}

// ============================================================
// Shape of one item in the ERP's response array
// ============================================================
public class ErpResult {
    public String id;
    public Boolean success;
    public String message;
}

// ============================================================
// Batch: one bulk callout per chunk
// ============================================================
global class SyncPendingCustomer implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {

    public Integer synced = 0;
    public Integer failed = 0;

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, Email__c, Phone__c
            FROM Customer_Sync__c
            WHERE Sync_Status__c = 'Pending'
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Customer_Sync__c> scope) {

        // 1) ONE payload for the whole chunk, with the Id so the ERP can echo it back
        List<Map<String, Object>> payload = new List<Map<String, Object>>();
        for (Customer_Sync__c c : scope) {
            payload.add(new Map<String, Object>{
                'id'    => c.Id,
                'name'  => c.Name,
                'email' => c.Email__c,
                'phone' => c.Phone__c
            });
        }

        Map<String, ErpResult> resultById = new Map<String, ErpResult>();
        String errorMsg;

        // 2) Callout FIRST, before any DML
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:ERP_API_Named_Cred/customers');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(payload));

            HttpResponse res = new Http().send(req);

            if (res.getStatusCode() == 200) {
                List<ErpResult> parsed =
                    (List<ErpResult>) JSON.deserialize(res.getBody(), List<ErpResult>.class);
                for (ErpResult r : parsed) {
                    resultById.put(r.id, r);
                }
            } else {
                errorMsg = 'HTTP ' + res.getStatusCode() + ': ' + res.getBody();
            }
        } catch (Exception e) {
            errorMsg = e.getMessage();
        }

        // 3) DML AFTER the callout: decide each record's status exactly once
        List<Customer_Sync__c> toUpdate = new List<Customer_Sync__c>();
        for (Customer_Sync__c c : scope) {
            Customer_Sync__c upd = new Customer_Sync__c(Id = c.Id);
            ErpResult r = resultById.get(String.valueOf(c.Id));

            if (errorMsg != null) {
                upd.Sync_Status__c = 'Failed';
                upd.Last_Error__c = errorMsg;
                failed++;
            } else if (r == null) {
                upd.Sync_Status__c = 'Failed';
                upd.Last_Error__c = 'No result returned by ERP';
                failed++;
            } else if (r.success == true) {
                upd.Sync_Status__c = 'Synced';
                upd.Last_Error__c = null;
                synced++;
            } else {
                upd.Sync_Status__c = 'Failed';
                upd.Last_Error__c = r.message;
                failed++;
            }
            toUpdate.add(upd);
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    global void finish(Database.BatchableContext bc) {
        insert new Sync_Summary__c(
            Synced_Count__c = synced,
            Failed_Count__c = failed,
            Run_Date__c = Date.today()
        );
    }
}