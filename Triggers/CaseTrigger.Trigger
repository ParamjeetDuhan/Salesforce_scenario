trigger CaseTrigger on Case (before update) {

    if (Trigger.isBefore && Trigger.isUpdate) {
        CaseTriggerHandler.autoEscalate(Trigger.new, Trigger.oldMap);
        CaseTriggerHandler.preventPriorityDowngrade(Trigger.new, Trigger.oldMap);
    }
}