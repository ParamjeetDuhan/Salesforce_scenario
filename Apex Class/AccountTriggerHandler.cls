public class AccountTriggerHandler {

    public static void preventDelete(List<Account> oldAccounts) {

        Set<Id> accIds = new Set<Id>();
        for (Account a : oldAccounts) {
            accIds.add(a.Id);
        }

        Set<Id> blockedAccIds = new Set<Id>();
        for (Opportunity opp : [SELECT AccountId FROM Opportunity
                                WHERE StageName = 'Closed Won'
                                AND AccountId IN :accIds]) {
            blockedAccIds.add(opp.AccountId);
        }

        for (Account a : oldAccounts) {
            if (blockedAccIds.contains(a.Id)) {
                a.addError('Accounts with Closed Won Opportunities cannot be deleted.');
            }
        }
    }
    public static void syncIndustry(List<Account> newAccounts, Map<Id, Account> oldMap) {

        Map<Id, String> industryMap = new Map<Id, String>();

        for (Account a : newAccounts) {
            if (a.Industry != oldMap.get(a.Id).Industry) {
                industryMap.put(a.Id, a.Industry);
            }
        }

        if (industryMap.isEmpty()) {
            return;
        }

        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for (Opportunity opp : [SELECT Id, AccountId FROM Opportunity
                                WHERE IsClosed = false
                                AND AccountId IN :industryMap.keySet()]) {
            opp.Account_Industry__c = industryMap.get(opp.AccountId);
            oppsToUpdate.add(opp);
        }

        if (!oppsToUpdate.isEmpty()) {
            update oppsToUpdate;
        }
    }
}