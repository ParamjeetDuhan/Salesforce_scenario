// Trigger Scenario 
//1. On the Opportunity object, prevent a record from being saved if the Amount field is greater than 100,000 and the StageName is "Closed Won"
/*2. When an Opportunity's StageName changes to "Closed Won", automatically create a Task assigned to the Opportunity Owner reminding them 
     to send a thank-you email to the customer. Also, if a Closed Won Opportunity's Amount is later edited to be lower than what it was,
     add an entry to a custom Description field (or a related object like Opportunity_Change_Log__c) noting the amount reduction, with old 
     and new values.*/
trigger OpportunityTrigger On Opportunity(before insert,before update, After update){

    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
        OpportunityHandler.PreventSave(Trigger.new);
    }
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
/* 1. Copy the Account’s owner to a custom field on insert. When an Opportunity is created with an AccountId, 
set the custom lookup field Account_Owner__c (lookup to User) on the Opportunity to the Owner of the parent Account. 
If the Opportunity has no Account, leave it blank.*/
/* 2. Track stage changes in a history record. Whenever an Opportunity’s StageName changes, 
create a record in the custom object Stage_History__c with these fields: Opportunity__c (lookup), Old_Stage__c (text), 
New_Stage__c (text), and Changed_On__c (Date, today). Also, an Opportunity cannot be moved from 'Closed Won' back to any other stage.
 Block that with an error on the Opportunity.*/

trigger OpportunityTrigger on Opportunity(before insert, before update , after insert , after update){
    if(Trigger.isBefore){
        if(Trigger.isInsert){
                  OpportunityHandler.OwnerAssignment(Trigger.new,null);
        }
        if(Trigger.isUpdate){
                  OpportunityHandler.OwnerAssignment(Trigger.new,Trigger.oldMap);
                  OpportunityHandler.BlockStageMoved(Trigger.new,Trigger.oldMap);
        }
    }
    if(Trigger.isAfter){
        if(Trigger.isInsert){
                  OpportunityHandler.TrackHistory(Trigger.new,null);
        }
        if(Trigger.isUpdate){
                  OpportunityHandler.TrackHistory(Trigger.new,Trigger.oldMap);
        }
    }
}
