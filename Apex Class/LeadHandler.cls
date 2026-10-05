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
}