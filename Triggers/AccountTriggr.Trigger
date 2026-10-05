/Account Deletion Guard and Industry Sync to Opportunities
     trigger AccountTrigger on Account (before delete, after update) {
//1.Block deletion of important Accounts. If an Account has at least one Opportunity with StageName = 'Closed Won', it must not be deleted.
     // Show an error on that Account record. Accounts without Closed Won Opportunities can be deleted normally, even in a mass delete of 200 
      //Accounts where some are blocked and some are not.
    if (Trigger.isBefore && Trigger.isDelete) {
        AccountTriggerHandler.preventDelete(Trigger.old);
    }
   //2.Sync Industry to open Opportunities. When an Account's Industry changes, update the custom text field Account_Industry__c on all
     // of its open Opportunities (not Closed Won or Closed Lost) to the new Industry value. If Industry didn't change, do nothing.
    if (Trigger.isAfter && Trigger.isUpdate) {
        AccountTriggerHandler.syncIndustry(Trigger.new, Trigger.oldMap);
    }
}