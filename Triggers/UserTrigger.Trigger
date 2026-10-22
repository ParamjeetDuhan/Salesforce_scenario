trigger UserTrigger on User (after update) {
    List<Id> deactivatedIds = new List<Id>();
    for (User u : Trigger.new) {
        if (!u.IsActive && Trigger.oldMap.get(u.Id).IsActive) {
            deactivatedIds.add(u.Id);
        }
    }
    if (!deactivatedIds.isEmpty()) {
        System.enqueueJob(new ReassignCasesQueueable(deactivatedIds));
    }
}