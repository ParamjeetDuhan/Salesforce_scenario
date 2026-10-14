public with sharing class ContactPickerController {
    @AuraEnabled(cacheable=true)
    public static List<Contact> searchContacts(Id accountId, String searchTerm, Id excludeId) {
        String pattern = '%' + searchTerm + '%';
        return [
            SELECT Id, Name
            FROM Contact
            WHERE AccountId = :accountId
              AND Name LIKE :pattern
              AND Id != :excludeId
            WITH USER_MODE
            ORDER BY Name
            LIMIT 10
        ];
    }
}