public class CaseTriggerHandler {

    public static void autoEscalate(List<Case> newCases, Map<Id, Case> oldMap) {

        for (Case c : newCases) {
            Case old = oldMap.get(c.Id);

            Boolean movedToHigh = (c.Priority == 'High' && old.Priority != 'High');
            Boolean olderThan3Days = (c.CreatedDate <= System.now().addDays(-3));

            if (movedToHigh && olderThan3Days && !c.IsClosed) {
                c.IsEscalated = true;
                c.Description = (c.Description != null ? c.Description + '\n' : '')
                                 + 'Auto-escalated on ' + String.valueOf(System.today());
            }
        }
    }

    public static void preventPriorityDowngrade(List<Case> newCases, Map<Id, Case> oldMap) {

        for (Case c : newCases) {
            Case old = oldMap.get(c.Id);

            if (c.IsEscalated == true && c.Priority == 'Low' && old.Priority != 'Low') {
                c.addError('Escalated Case Priority cannot be set to Low.');
            }
        }
    }

    public static void setPriority(List<Case> caselist,Map<Id,Case> oldcaselist){
        Set<Id> Parentids = new Set<Id>();
        List<Case> casetobesetPriority = new List<Case>();
        if(!caselist.isEmpty()){
            for(Case c: caselist){
                if(oldcaselist == null && c.ParentId != null && String.isBlank(c.Priority)){
                    Parentids.add(c.ParentId);
                    casetobesetPriority.add(c);
                }
                else if(oldcaselist != null && c.ParentId != null && oldcaselist.get(c.Id).ParentId == null && String.isBlank(c.Priority)){
                    Parentids.add(c.ParentId);
                    casetobesetPriority.add(c);
                }
            }
        }
        Map<Id,String> MapCasePriority = new Map<Id,String>();
        for(Case ca : [SELECT Id,Priority FROM Case
                       WHERE Id IN : Parentids]) {
            MapCasePriority.put(ca.Id,ca.Priority);
        }
        for(Case c : casetobesetPriority){
            c.Priority = MapCasePriority.containsKey(c.ParentId) ? MapCasePriority.get(c.ParentId) : null;
        }
    }

    public static void PreventStatusChange(List<Case> caselist,Map<Id,Case> oldcaselist){
        Set<Id> CaseId = new Set<Id>();
        List<Case> checkStatus = new List<Case>();
        if(!caselist.isEmpty()){
            for(Case c : caselist){
                if(c.Status == 'Closed' && oldcaselist.get(c.Id).Status != 'Closed'){
                    CaseId.add(c.Id);
                    checkStatus.add(c);
                }
            }
        }
        Set<Id> isChildOpen = new Set<Id>();
        for(Case ca : [SELECT ParentId FROM Case
                       WHERE ParentId IN : CaseId
                       AND IsClosed = false]) {
            isChildOpen.add(ca.ParentId);
        }
        for(Case c : checkStatus){
            if(isChildOpen.contains(c.Id)){
                c.addError('Case cannot be closed while it has open child Cases');
            }
        }
    }

    // Rule 3: block deleting a parent that has open children
    public static void PreventCaseDelete(List<Case> oldCase){
        Set<Id> CaseId = new Set<Id>();
        if(!oldCase.isEmpty()){
            for(Case c : oldCase){
                CaseId.add(c.Id);
            }
        }
        Set<Id> isChildOpen = new Set<Id>();
        for(Case ca : [SELECT ParentId FROM Case
                       WHERE ParentId IN : CaseId
                       AND IsClosed = false]) {
            isChildOpen.add(ca.ParentId);
        }
        for(Case c : oldCase){
            if(isChildOpen.contains(c.Id)){
                c.addError('Case cannot be deleted while it has open child Cases');
            }
        }
    }
}