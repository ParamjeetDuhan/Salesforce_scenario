@isTest
private class MyFeatureTest {

    // Only needed if the code under test makes a callout
    private class MyMock implements HttpCalloutMock {
        private Integer statusCode;
        MyMock(Integer statusCode) { this.statusCode = statusCode; }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody('{}');
            return res;
        }
    }

    @testSetup
    static void setup() {
       
    }

    @isTest
    static void testSomething() {
        Test.setMock(HttpCalloutMock.class, new MyMock(200)); // only if there is a callout

        Test.startTest();
        // run the trigger / class / batch / queueable here
        Test.stopTest();  

        // assert the results with SOQL + System.assertEquals
         System.assertEquals(5,
            [SELECT COUNT() FROM SOBJECT WHERE Condition = '']);
    }
}