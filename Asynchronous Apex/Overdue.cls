// Scheduler
global class BatchScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchInvoiceHandler(), 200);
    }
}

// Batch class — marks overdue invoices, accumulates totals
global class BatchInvoiceHandler implements Database.Batchable<SObject>, Database.Stateful {

    global Integer overdueCount = 0;
    global Decimal overdueAmount = 0;

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Status__c, Due_Date__c, Amount__c FROM Invoice__c ' +
                        'WHERE Status__c = \'Pending\' AND Due_Date__c < TODAY';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Invoice__c> scope) {
        List<Invoice__c> toUpdate = new List<Invoice__c>();

        for (Invoice__c inv : scope) {
            inv.Status__c = 'Overdue';
            toUpdate.add(inv);

            this.overdueCount += 1;
            this.overdueAmount += (inv.Amount__c != null ? inv.Amount__c : 0);
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    global void finish(Database.BatchableContext bc) {
        Map<String, Object> summary = new Map<String, Object>{
            'totalOverdueInvoices' => this.overdueCount,
            'totalOverdueAmount'   => this.overdueAmount
        };
        System.enqueueJob(new InvoiceSummaryCallout(JSON.serialize(summary)));
    }
}

// Queueable — sends the single summary callout
global class InvoiceSummaryCallout implements Queueable, Database.AllowsCallouts {

    global String payload;

    global InvoiceSummaryCallout(String payload) {
        this.payload = payload;
    }

    global void execute(QueueableContext qc) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Finance_API_Named_Cred/invoices/summary');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(payload);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            System.debug('Invoice summary sent successfully');
        } else {
            System.debug('Callout failed: ' + res.getStatusCode() + ' ' + res.getBody());
        }
    }
}