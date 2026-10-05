// Trigger Scenario 

Trigger OpportunityTrigger On Opportunity(before insert,before update, After update){

//On the Opportunity object, prevent a record from being saved if the Amount field is greater than 100,000 and the StageName is "Closed Won"
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
        OpportunityHandler.PreventSave(Trigger.new);
    }
//When an Opportunity's StageName changes to "Closed Won", automatically create a Task assigned to the Opportunity Owner reminding them 
//to send a thank-you email to the customer. Also, if a Closed Won Opportunity's Amount is later edited to be lower than what it was,
// add an entry to a custom Description field (or a related object like Opportunity_Change_Log__c) noting the amount reduction, with old 
//and new values.
    if(Trigger.isAfter && Trigger.isUpdate){
        OpportunityHandler.afterUpdate(Trigger.new,Trigger.oldMap);
    }
}