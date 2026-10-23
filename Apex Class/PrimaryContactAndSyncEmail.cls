public class ContactEmailHandler {

    // Rule 1 (before): only one primary Contact per Account inside the same batch
    public static void IsPrimary(List<Contact> ContactList){
        Set<Id> AccId = new Set<Id>();
        for(Contact co : ContactList){
            if(co.AccountId != null && co.Is_Primary__c == true){
                if(AccId.contains(co.AccountId)){
                    co.addError('Only one primary Contact per Account is allowed in the same save');
                }
                else{
                    AccId.add(co.AccountId);
                }
            }
        }
    }

    // Rule 1 (after): set every other primary Contact of the same Accounts to false
    public static void UnmarkOtherPrimary(List<Contact> ContactList){
        Set<Id> AccId = new Set<Id>();
        Set<Id> ContactIds = new Set<Id>();
        for(Contact c : ContactList){
            if(c.AccountId != null && c.Is_Primary__c == true){
                AccId.add(c.AccountId);
                ContactIds.add(c.Id);
            }
        }
        if(AccId.isEmpty()){
            return;
        }
        List<Contact> otherPrimary = new List<Contact>();
        for(Contact con : [SELECT Id FROM Contact
                           WHERE AccountId IN : AccId
                           AND Is_Primary__c = true
                           AND Id NOT IN : ContactIds]){
            con.Is_Primary__c = false;
            otherPrimary.add(con);
        }
        if(!otherPrimary.isEmpty()){
            update otherPrimary;
        }
    }

    // Rule 2 (after): sync the primary Contact's Email to the Account
    public static void SyncPrimaryContactEmail(List<Contact> ContactList, Map<Id,Contact> oldContacts){
        Set<Id> AccId = new Set<Id>();
        Map<Id,String> AccountPerPrimaryEmail = new Map<Id,String>();
        if(!ContactList.isEmpty()){
            for(Contact c: ContactList){
                if(c.AccountId != null){
                    AccId.add(c.AccountId);
                }
                if(oldContacts != null && oldContacts.get(c.Id).AccountId != null){
                    AccId.add(oldContacts.get(c.Id).AccountId);
                }
            }
        }
        for(Contact con : [SELECT AccountId, Is_Primary__c, Email FROM Contact
                           WHERE AccountId IN : AccId
                           AND Is_Primary__c = true]){
            AccountPerPrimaryEmail.put(con.AccountId, con.Email);
        }
        List<Account> updatePrimaryEmail = new List<Account>();
        for(Id ids : AccId){
            Account a = new Account();
            a.Id = ids;
            if(AccountPerPrimaryEmail.containsKey(ids)){
                a.Primary_Contact_Email__c = AccountPerPrimaryEmail.get(ids);
            }
            else{
                a.Primary_Contact_Email__c = null;
            }
            updatePrimaryEmail.add(a);
        }
        if(!updatePrimaryEmail.isEmpty()){
            update updatePrimaryEmail;
        }
    }
}