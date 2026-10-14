public with sharing class CaseTableController {
    @AuraEnabled(cacheable=true)
    public static List<Case> getRelatedCases(Id accountId, String statusFilter) {
        // If "All" or empty, fetch all records, otherwise filter by status
        if (String.isBlank(statusFilter) || statusFilter == 'All') {
            return [
                SELECT Id, CaseNumber, Subject, Status, Priority, CreatedDate 
                FROM Case 
                WHERE AccountId = :accountId 
                WITH SECURITY_ENFORCED
                ORDER BY CreatedDate DESC
            ];
        } else {
            return [
                SELECT Id, CaseNumber, Subject, Status, Priority, CreatedDate 
                FROM Case 
                WHERE AccountId = :accountId AND Status = :statusFilter
                WITH SECURITY_ENFORCED
                ORDER BY CreatedDate DESC
            ];
        }
    }
}
