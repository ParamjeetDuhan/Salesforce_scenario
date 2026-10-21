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

    public static void CountOpenTask(List<Task> tasklist , Map<Id,Task> oldTaskList){
         Set<Id> AccountId = new Set<Id>();
         if(!tasklist.isEmpty()){
              for(Task t: tasklist){
                 if(t.WhatId != null && String.valueOf(t.WhatId).startsWith('001')){
                     if(oldTaskList == null){
                          AccountId.add(t.WhatId);
                     }
                     else if(t.Status != oldTaskList.get(t.Id).Status){
                          AccountId.add(t.WhatId);
                     }
                 }
              }
         }
         Map<Id,Integer> taskperAccount = new Map<Id,Integer>();

         for(AggregateResult ar : [
                                    SELECT WhatId , Count(Id) TotalCount FROM Task
                                     WHERE WhatId IN : AccountId
                                     AND Status != 'Completed'
                                     GROUP BY WhatId
         ]){
            taskperAccount.put((Id)ar.get('WhatId'),(Integer)ar.get('TotalCount'));
         }
        List<Account> updatetaskCount = new List<Account>();
          for(Id i : AccountId){
                   Account a = new Account();
                   a.Id = i;
                   a.Open_Tasks__c = taskperAccount.containsKey(i) ? taskperAccount.get(i):0;
                   updatetaskCount.add(a);
          }
          if(!updatetaskCount.isEmpty()){
              update updatetaskCount;
          }
    }

    public static void closingHighPriorityTaskRequireComment(List<Task> tasklist , Map<Id,Task> oldTaskList){
            if(!tasklist.isEmpty()){
                  for(Task t : tasklist){
                         if(oldTaskList == null){
                               if(t.Status == 'Completed' && t.Priority == 'High' && String.isBlank(t.Description)){
                                    t.addError('High priority task with completed status must require Description');
                               }
                         }
                         else if(t.Status == 'Completed' && oldTaskList.get(t.Id).Status != 'Completed' && t.Priority == 'High' && String.isBlank(t.Description)){
                                    t.addError('High priority task with completed status must require Description');
                         }
                  }
            }
    }
    }
