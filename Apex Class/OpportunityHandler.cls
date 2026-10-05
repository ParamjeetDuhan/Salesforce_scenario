public class  OpportunityHandler{
    
    public static void PreventSave(List<Opportunity> opp){
        if(!opp.isEmpty()){
            for(Opportunity o : opp){
                if(o.Amount > 10000 && o.StageName == 'Closed Won'){
                    o.addError('Opportunity Cannot be saved if Amount is greater than 100000');
                }
            }
        }
    }

     public static void afterUpdate(List<Opportunity> newOpp, Map<Id, Opportunity> oldOp) {

        Set<Id> taskOppIds = new Set<Id>();
        Set<Id> customLogId = new Set<Id>();
        Map<Id, Opportunity> newOppMap = new Map<Id, Opportunity>();

        if (!newOpp.isEmpty()) {

            for (Opportunity o : newOpp) {
                Opportunity old = oldOp.get(o.Id);

                newOppMap.put(o.Id, o);

                if (o.StageName == 'Closed Won' && old.StageName != 'Closed Won') {
                    taskOppIds.add(o.Id);
                }

                if (o.StageName == 'Closed Won' && old.StageName == 'Closed Won'
                    && o.Amount < old.Amount) {
                    customLogId.add(o.Id);
                }
            }

            List<Task> newTaskList = new List<Task>();
            for (Id id : taskOppIds) {
                Opportunity opp = newOppMap.get(id);
                Task t = new Task();
                t.Description = 'Opportunity Closed Won. Please send Thank You email.';
                t.WhatId = id;
                t.OwnerId = opp.OwnerId;
                newTaskList.add(t);
            }

            List<Custom_Log__c> log = new List<Custom_Log__c>();
            for (Id id : customLogId) {
                Opportunity opp = newOppMap.get(id);
                Custom_Log__c l = new Custom_Log__c();
                l.Description = 'Amount reduced on a Closed Won Opportunity';
                l.Amount_Reduced__c = opp.Amount - oldOp.get(id).Amount;
                log.add(l);
            }

            if (!newTaskList.isEmpty()) {
                insert newTaskList;
            }
            if (!log.isEmpty()) {
                insert log;
            }
        }
    }
}