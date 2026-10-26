public with Sharing class  OpportunityHandler{
    
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

        @AuraEnabled(cacheable=true)
    public static List<Opportunity> getOpenOpportunities(Id accountId, String stage) {
        if (accountId == null) {
            return new List<Opportunity>();
        }
        Boolean allStages = String.isBlank(stage) || stage == 'All';
        return [
            SELECT Id, Name, StageName, Amount, CloseDate
            FROM Opportunity
            WHERE AccountId = :accountId
              AND IsClosed = false
              AND (:allStages = true OR StageName = :stage)
            WITH USER_MODE
            ORDER BY CloseDate
            LIMIT 200
        ];
    }

    @AuraEnabled
    public static void closeAsWon(Id opportunityId) {
        try {
            Opportunity opp = new Opportunity(Id = opportunityId, StageName = 'Closed Won');
            update as user opp;
        } catch (DmlException e) {
            throw buildException(e.getDmlMessage(0));
        } catch (Exception e) {
            throw buildException(e.getMessage());
        }
    }

    private static AuraHandledException buildException(String message) {
        AuraHandledException ex = new AuraHandledException(message);
        ex.setMessage(message);
        return ex;
    }

   public static void OwnerAssignment(List<Opportunity> opplist,Map<Id,Opportunity> oldopplist){
        Set<Id> accId = new Set<Id>();
        List<Opportunity> oppsToAssign = new List<Opportunity>();
        if(!opplist.isEmpty()){
            for(Opportunity o : opplist){
                if(oldopplist == null && o.AccountId != null){
                    accId.add(o.AccountId);
                    oppsToAssign.add(o);
                }
                else if(oldopplist != null && o.AccountId != null && oldopplist.get(o.Id).AccountId == null){
                    accId.add(o.AccountId);
                    oppsToAssign.add(o);
                }
            }
        }
        Map<Id,Id> AccountToOwner = new Map<Id,Id>();
        for(Account a : [SELECT Id,OwnerId FROM Account
                         WHERE Id IN : accId]){
            AccountToOwner.put(a.Id,a.OwnerId);
        }
        for(Opportunity opp : oppsToAssign){
            opp.Account_Owner__c = AccountToOwner.containsKey(opp.AccountId) ? AccountToOwner.get(opp.AccountId) : null;
        }
    }

    public static void BlockStageMoved(List<Opportunity> opplist,Map<Id,Opportunity> oldopplist){
        if(!opplist.isEmpty()){
            for(Opportunity o : opplist){
                if(oldopplist.get(o.Id).StageName == 'Closed Won' && o.StageName != 'Closed Won'){
                    o.addError('Closed Won Opportunity stage cannot be changed');
                }
            }
        }
    }

    public static void TrackHistory(List<Opportunity> opplist,Map<Id,Opportunity> oldopplist){
        List<Stage_History__c> History = new List<Stage_History__c>();
        if(!opplist.isEmpty()){
            for(Opportunity o : opplist){
                Stage_History__c h = new Stage_History__c();
                if(oldopplist == null && !String.isBlank(o.StageName)){
                    h.Opportunity__c = o.Id;
                    h.Old_Stage__c = null;
                    h.New_Stage__c  = o.StageName;
                    h.Changed_On__c = Date.today();
                    History.add(h);
                }
                else if(oldopplist != null && o.StageName != oldopplist.get(o.Id).StageName){
                    h.Opportunity__c = o.Id;
                    h.Old_Stage__c = oldopplist.get(o.Id).StageName;
                    h.New_Stage__c  = o.StageName;
                    h.Changed_On__c = Date.today();
                    History.add(h);
                }
            }
        }
        if(!History.isEmpty()){
            insert History;
        }
    }
}