@isTest
private class ExpiredSubscriptionTest {

    // Reusable mock: returns whatever status code you give it
    private class BillingMock implements HttpCalloutMock {
        private Integer statusCode;
        BillingMock(Integer statusCode) {
            this.statusCode = statusCode;
        }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody('{"ok":true}');
            return res;
        }
    }

    @testSetup
    static void setup() {
        List<Subscription__c> subs = new List<Subscription__c>();
        for (Integer i = 0; i < 5; i++) {
            subs.add(new Subscription__c(
                Status__c = 'Active',
                End_Date__c = Date.today().addDays(-1),
                Monthly_Fee__c = 100
            ));
        }
        // Not expired yet: must stay Active
        subs.add(new Subscription__c(
            Status__c = 'Active',
            End_Date__c = Date.today().addDays(10),
            Monthly_Fee__c = 100
        ));
        insert subs;
    }

    @isTest
    static void batchExpiresOnlyPastDueSubscriptions() {
        Test.setMock(HttpCalloutMock.class, new BillingMock(200));

        Test.startTest();
        Database.executeBatch(new expiredSubscription(), 200);
        Test.stopTest();   // batch (and finish) have completed by here

        System.assertEquals(5,
            [SELECT COUNT() FROM Subscription__c WHERE Status__c = 'Expired']);
        System.assertEquals(1,
            [SELECT COUNT() FROM Subscription__c WHERE Status__c = 'Active']);
        System.assertEquals(0,
            [SELECT COUNT() FROM Integration_Error__c]);
    }

    @isTest
    static void summaryCalloutLogsErrorOnNon200() {
        Test.setMock(HttpCalloutMock.class, new BillingMock(500));

        Test.startTest();
        System.enqueueJob(new SummaryCallout('{"expiredSuccessful":5}'));
        Test.stopTest();

        System.assertEquals(1,
            [SELECT COUNT() FROM Integration_Error__c]);
    }

    @isTest
    static void schedulerRunsWithoutError() {
        Test.startTest();
        String jobId = System.schedule('Test Expire Job', '0 0 1 * * ?',
                                       new SubscriptionSchedular());
        Test.stopTest();

        System.assertNotEquals(null, jobId);
    }
}