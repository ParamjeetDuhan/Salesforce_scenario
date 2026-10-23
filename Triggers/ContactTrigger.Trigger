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

//Your org has a Contact object. When a Contact’s Email field changes, you must:

//Immediately update a custom field Email_Verified__c = false on that Contact (this is a plain DML in the trigger context).
//Call an external email-verification API with the new email address. The API returns {"valid": true} or {"valid": false}
//Write the API result back to Email_Verified__c on the same Contact.

trigger ContactEmailTrigger on Contact (before insert, before update, after insert, after update) {
    if (Trigger.isBefore) {
        ContactEmailHandler.markUnverified(Trigger.new, Trigger.oldMap);
    } else if (Trigger.isAfter) {
        ContactEmailHandler.enqueueVerification(Trigger.new, Trigger.oldMap);
    }
}

/* 1. Only one primary Contact per Account. When a Contact is inserted or updated with Is_Primary__c = true, 
every other Contact under the same Account must have Is_Primary__c set to false. 
If several Contacts in the same batch are marked primary for the same Account, 
throw an error on the extra ones. */
/*2. Sync the primary email to the Account. The Account’s Primary_Contact_Email__c must always show the Email of its primary Contact.
 If the primary Contact is deleted or unmarked, the field should be cleared (set to null). */
trigger PrimaryContactTrigger on Contact (before insert, before update, after insert, after update, after delete, after undelete) {
    if (Trigger.isBefore) {
        ContactEmailHandler.IsPrimary(Trigger.new);
    }
    else if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUndelete) {
            ContactEmailHandler.UnmarkOtherPrimary(Trigger.new);
            ContactEmailHandler.SyncPrimaryContactEmail(Trigger.new, null);
        }
        if (Trigger.isUpdate) {
            ContactEmailHandler.UnmarkOtherPrimary(Trigger.new);
            ContactEmailHandler.SyncPrimaryContactEmail(Trigger.new, Trigger.oldMap);
        }
        if (Trigger.isDelete) {
            ContactEmailHandler.SyncPrimaryContactEmail(Trigger.old, null);
        }
    }
}