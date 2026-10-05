//Scenario
//On the Lead object, prevent insertion of a new Lead if a Lead with the same Email already exists in the system.

Trigger LeadTrigger On Lead (Before insert){
        if(Trigger.isBefore && Trigger.isInsert){
            LeadHandler.preventDuplicateLead(Trigger.new);
        }
}