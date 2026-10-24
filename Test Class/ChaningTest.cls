@isTest
private class ReassignChainTest {

    private class HrMock implements HttpCalloutMock {
        private Integer statusCode;
        HrMock(Integer statusCode) { this.statusCode = statusCode; }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody('{}');
            return res;
        }
    }

    @testSetup
    static void setup() {
        // Queue is a setup object and Case is not, so they need separate contexts.
        // runAs avoids the MIXED_DML_OPERATION error.
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Group q = new Group(
                Name = 'My Queue Case Developer',
                DeveloperName = 'My_Queue_Case_Developer',
                Type = 'Queue'
            );
            insert q;
            insert new QueueSobject(QueueId = q.Id, SobjectType = 'Case');
        }

        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < 3; i++) {
            cases.add(new Case(Subject = 'Open ' + i, Status = 'New',
                               OwnerId = UserInfo.getUserId()));
        }
        // A closed Case that must NOT be reassigned
        cases.add(new Case(Subject = 'Closed', Status = 'Closed',
                           OwnerId = UserInfo.getUserId()));
        insert cases;
    }

    // Link 1: DML job
    @isTest
    static void firstJobReassignsOnlyOpenCases() {
        Test.setMock(HttpCalloutMock.class, new HrMock(200));
        Id queueId = [SELECT Id FROM Group
                      WHERE Type = 'Queue' AND DeveloperName = 'My_Queue_Case_Developer'].Id;

        Test.startTest();
        System.enqueueJob(new ReassignCasesQueueable(new List<Id>{ UserInfo.getUserId() }));
        Test.stopTest();

        System.assertEquals(3,
            [SELECT COUNT() FROM Case WHERE OwnerId = :queueId AND IsClosed = false]);
        System.assertEquals(1,
            [SELECT COUNT() FROM Case WHERE OwnerId = :UserInfo.getUserId() AND IsClosed = true]);
    }

    // Link 2: callout job
    @isTest
    static void secondJobLogsErrorWhenHrReturns500() {
        Test.setMock(HttpCalloutMock.class, new HrMock(500));
        Map<Id, Integer> counts = new Map<Id, Integer>{ UserInfo.getUserId() => 3 };

        Test.startTest();
        System.enqueueJob(new NotifyHrQueueable(counts));
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Audit_Log__c]);
    }
}