public class ContactTriggerHandler {
    
        public static void preventDuplicateContacts(List<Contact> newCons) {

         Set<Id> accIds = new Set<Id>();
         Set<String> emails = new Set<String>();
         Set<Id> contactIds = new Set<Id>();

         for (Contact c : newCons) {
            if (c.AccountId != null && c.Email != null) {
                accIds.add(c.AccountId);
                emails.add(c.Email.toLowerCase());
            }
            if (c.Id != null) {          // Id is null on insert
                contactIds.add(c.Id);
            }
         }

         Set<String> existingKeys = new Set<String>();
         for (Contact c : [SELECT Id, AccountId, Email FROM Contact
                          WHERE AccountId IN :accIds
                          AND Email IN :emails
                          AND Id NOT IN :contactIds]) {
            existingKeys.add(c.AccountId + '_' + c.Email.toLowerCase());
         }

         Set<String> batchKeys = new Set<String>();

         for (Contact c : newCons) {
            if (c.AccountId == null || c.Email == null) {
                continue;
            }
            String key = c.AccountId + '_' + c.Email.toLowerCase();

            if (existingKeys.contains(key) || batchKeys.contains(key)) {
                c.addError('A Contact with this Email already exists under this Account.');
            } else {
                batchKeys.add(key);
            }
         }
    }

    public static void countContactPerAccount(List<Contact> cons, Map<Id, Contact> oldMap) {

        Set<Id> accIds = new Set<Id>();

        for (Contact c : cons) {
            if (c.AccountId != null) {
                accIds.add(c.AccountId);

            if (oldMap != null) {
                Contact old = oldMap.get(c.Id);
                if (old.AccountId != null && old.AccountId != c.AccountId) {
                    accIds.add(old.AccountId);
                }
            }
        }

        if (accIds.isEmpty()) {
            return;
        }

        Map<Id, Integer> totalCount = new Map<Id, Integer>();
        for (AggregateResult ar : [SELECT AccountId accId, COUNT(Id) total
                                   FROM Contact
                                   WHERE AccountId IN :accIds
                                   GROUP BY AccountId]) {
            totalCount.put((Id) ar.get('accId'), (Integer) ar.get('total'));
        }

        List<Account> accList = new List<Account>();
        for (Id accId : accIds) {
            Account a = new Account();
            a.Id = accId;
            a.Total_Contacts__c = totalCount.containsKey(accId) ? totalCount.get(accId) : 0;
            accList.add(a);
        }

        update accList;
     }
}