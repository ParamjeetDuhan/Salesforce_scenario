// Scenario
//On the Contact object, whenever a Contact is inserted or updated, update a custom field Total_Contacts__c 
//   on the related Account to reflect the count of Contacts linked to that Account

Trigger ContactTrigger On Contact(before insert, before update,After insert,After update,After delete,After undelete){
//Prevent Duplicate Contacts and Keep Account Contact Count Updated
   //1.No duplicate emails within the same Account. If a user inserts or updates a Contact with an Email that already exists
     // on another Contact under the same Account, block the save with an error message on the record.
            if (Trigger.isBefore) {
                   if (Trigger.isInsert || Trigger.isUpdate) {
            ContactTriggerHandler.preventDuplicateContacts(Trigger.new);
         }
    }
   //2.Contact count on Account. The Account has a custom number field Total_Contacts__c. It should always reflect the number of 
     //Contacts under that Account, updating on insert, delete, and undelete, and also when a Contact is moved from one Account to another.
          if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUndelete) {
            ContactTriggerHandler.countContactPerAccount(Trigger.new, null);
        }
        if (Trigger.isUpdate) {
            ContactTriggerHandler.countContactPerAccount(Trigger.new, Trigger.oldMap);
        }
        if (Trigger.isDelete) {
            ContactTriggerHandler.countContactPerAccount(Trigger.old, null);
        }
    }
}