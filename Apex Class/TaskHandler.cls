public with sharing class TaskHandler {

    @AuraEnabled(cacheable=true)
    public static List<Task> getTasks(Id contactId, String priority, String searchTerm) {
        if (contactId == null) {
            return new List<Task>();
        }
        Boolean allPriorities = String.isBlank(priority) || priority == 'All';
        String pattern = String.isBlank(searchTerm) ? '%' : '%' + searchTerm + '%';
        try {
            return [
                SELECT Id, Subject, Priority, ActivityDate, Status
                FROM Task
                WHERE WhoId = :contactId
                  AND IsClosed = false
                  AND (:allPriorities = true OR Priority = :priority)
                  AND Subject LIKE :pattern
                WITH USER_MODE
                ORDER BY ActivityDate ASC NULLS LAST
                LIMIT 200
            ];
        } catch (Exception e) {
            throw buildException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void markComplete(Id taskId) {
        try {
            update as user new Task(Id = taskId, Status = 'Completed');
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
}