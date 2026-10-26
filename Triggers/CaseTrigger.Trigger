trigger CaseTrigger on Case (before update) {

    if (Trigger.isBefore && Trigger.isUpdate) {
        CaseTriggerHandler.autoEscalate(Trigger.new, Trigger.oldMap);
        CaseTriggerHandler.preventPriorityDowngrade(Trigger.new, Trigger.oldMap);
    }
}

/* 1.Inherit priority from the parent. When a Case is inserted with a ParentId and its Priority is blank, 
copy the parent Case’s Priority onto it. If the Case already has a Priority, leave it alone.*/
/* 2. Block closing a parent with open children. When a Case’s Status is changed to 'Closed', check its child Cases
 (Cases whose ParentId is this Case). If any child is not closed, block the save with an error on the parent Case. */
/* 3. Block deleting a parent with open children. When a Case is deleted, block the delete with an error on that Case if any of its 
    child Cases is still open. Cases with no open children can be deleted normally, even in a mass delete.*/
    
trigger CaseTrigger on Case(before insert , before update , before delete){
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            CaseTriggerHandler.setPriority(Trigger.new,null);
        }
        if(Trigger.isUpdate){
            CaseTriggerHandler.setPriority(Trigger.new,Trigger.oldMap);
            CaseTriggerHandler.PreventStatusChange(Trigger.new,Trigger.oldMap);
        }
        if(Trigger.isDelete){
            CaseTriggerHandler.PreventCaseDelete(Trigger.old);
        }
    }
}