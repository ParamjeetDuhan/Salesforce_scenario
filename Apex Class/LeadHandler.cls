public class  LeadHandler{
    public static void reventDuplicateLead(List<Lead> leadlist){
        Set<String> leadEmail = new Set<String>();
        if(!leadlist.isEmpty()){
            for(Lead L : leadlist){
                leadEmail.add(L.Email);
            }
        }
        Set<String> ExistLeadEmail = new Set<String>();
        for(Lead L : [SELECT Id, Email FROM Lead
                       WHERE Email IN : leadEmail]){
                ExistLeadEmail.add(L.Email);
            }
         for(Lead L : leadlist){
                if(ExistLeadEmail.Contains(L.Email) ){
                    L.addError('Lead with this Email Exisit');
                }
            }
    }

    public static void validateUnqualifiedReason(List<Lead> newLeads, Map<Id, Lead> oldMap) {

        for (Lead l : newLeads) {
            Boolean becameUnqualified = false;

            if (oldMap == null) {
                // insert
                becameUnqualified = (l.Status == 'Unqualified');
            } else {
                // update
                becameUnqualified = (l.Status == 'Unqualified'
                                     && oldMap.get(l.Id).Status != l.Status);
            }

            if (becameUnqualified && String.isBlank(l.Unqualified_Reason__c)) {
                l.addError('Lead with status Unqualified requires a reason.');
            }
        }
    }

    // Rule 2: follow-up Task for hot Leads
    public static void leadFollowUpTask(List<Lead> newLeads, Map<Id, Lead> oldMap) {

        List<Task> taskList = new List<Task>();

        for (Lead l : newLeads) {
            Boolean becameHot = false;

            if (oldMap == null) {
                // insert
                becameHot = (l.Rating == 'Hot');
            } else {
                // update
                becameHot = (l.Rating == 'Hot' && oldMap.get(l.Id).Rating != 'Hot');
            }

            if (becameHot) {
                Task t = new Task();
                t.Subject = 'Call hot lead within 24 hours';
                t.WhoId = l.Id;
                t.OwnerId = l.OwnerId;
                t.ActivityDate = Date.today().addDays(1);
                taskList.add(t);
            }
        }

        if (!taskList.isEmpty()) {
            insert taskList;
        }
    }
}