// Trigger Scenario 
trigger OpportunityTrigger On Opportunity(before insert,before update, After update){

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

// Scenario: Opportunity Product Rollup and Discount Approval Guard
// Roll up product count to Opportunity. The Opportunity has a custom number field Total_Products__c.
// Block deep discounts without approval. On insert or update of an OpportunityLineItem, if Discount is greater than 30, the parent Opportunity’s custom checkbox Discount_Approved__c must be true. If it’s false, block the save with an error on the line item.

trigger OpportunityLineItemTrigger on OpportunityLineItem(after insert,after delete,after undelete , before insert , before update){
           if(Trigger.isAfter){
                  if(Trigger.isInsert || Trigger.isUndelete){
                          OpportunityLineItemHandler.rollupProduct(Trigger.new);
                  }
                  if(Trigger.isDelete){
                          OpportunityLineItemHandler.rollupProduct(Trigger.old);
                  }
           }
           if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
                      OpportunityLineItemHandler.blockDeepDiscounts(Trigger.new);
           }
}