//Scenario
//On the Lead object, prevent insertion of a new Lead if a Lead with the same Email already exists in the system.

Trigger LeadTrigger On Lead (Before insert){
        if(Trigger.isBefore && Trigger.isInsert){
            LeadHandler.preventDuplicateLead(Trigger.new);
        }
}

//Scenario: Lead Conversion Guard and Campaign Member Tracking

trigger LeadTrigger on Lead (before insert, before update, after insert, after update) {

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            LeadHandler.validateUnqualifiedReason(Trigger.new, null);
        }
        if (Trigger.isUpdate) {
            LeadHandler.validateUnqualifiedReason(Trigger.new, Trigger.oldMap);
        }
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            LeadHandler.leadFollowUpTask(Trigger.new, null);
        }
        if (Trigger.isUpdate) {
            LeadHandler.leadFollowUpTask(Trigger.new, Trigger.oldMap);
        }
    }
}