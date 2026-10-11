trigger OrderTrigger on Order__c (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        List<Map<String, Object>> payloadList = new List<Map<String, Object>>();
        List<Id> orderIds = new List<Id>();

        for (Order__c o : Trigger.new) {
            Order__c oldOrder = Trigger.oldMap.get(o.Id);
            if (o.Status__c == 'Ready to ship' && o.Status__c != oldOrder.Status__c) {
                Map<String, Object> orderMap = new Map<String, Object>();
                orderMap.put('Id', o.Id);
                orderMap.put('Status', o.Status__c);
                orderMap.put('Amount', o.Amount__c);
                payloadList.add(orderMap);

                orderIds.add(o.Id);
            }
        }

        if (!payloadList.isEmpty()) {
            System.enqueueJob(
                new QueueableHandler(JSON.serialize(payloadList), orderIds, 3)
            );
        }
    }
}







global class QueueableHandler implements Queueable, Database.AllowsCallouts {
    global String orderPayload;
    global List<Id> orderIds;
    global Integer retryCount;

    global QueueableHandler(String orderPayload, List<Id> orderIds, Integer retryCount) {
        this.orderPayload = orderPayload;
        this.orderIds = orderIds;
        this.retryCount = retryCount;
    }

    global void execute(QueueableContext qc) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Shipping_API_Named_Cred/orders');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(orderPayload);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            return; // success — nothing further to do
        }

        if (retryCount > 0) {
            System.enqueueJob(new QueueableHandler(orderPayload, orderIds, retryCount - 1));
        } else {
            List<Manual_Review__c> reviews = new List<Manual_Review__c>();
            for (Id orderId : orderIds) {
                Manual_Review__c r = new Manual_Review__c();
                r.Order__c = orderId;
                r.Status__c = 'Failed';
                reviews.add(r);
            }
            insert reviews;
        }
    }
}