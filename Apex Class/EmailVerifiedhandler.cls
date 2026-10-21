public class ContactEmailHandler {

    private static Boolean emailChanged(Contact c, Map<Id, Contact> oldMap) {
        if (String.isBlank(c.Email)) {
            return false;
        }
        if (oldMap == null) {          // insert
            return true;
        }
        return c.Email != oldMap.get(c.Id).Email;
    }

    // before context: no extra DML needed, just set the field
    public static void markUnverified(List<Contact> newList, Map<Id, Contact> oldMap) {
        for (Contact c : newList) {
            if (emailChanged(c, oldMap)) {
                c.Email_Verified__c = false;
            }
        }
    }

    // after context: Ids exist now
    public static void enqueueVerification(List<Contact> newList, Map<Id, Contact> oldMap) {
        List<Id> changedIds = new List<Id>();
        for (Contact c : newList) {
            if (emailChanged(c, oldMap)) {
                changedIds.add(c.Id);
            }
        }
        if (!changedIds.isEmpty()) {
            System.enqueueJob(new ContactEmailVerifyQueueable(changedIds));
        }
    }
}