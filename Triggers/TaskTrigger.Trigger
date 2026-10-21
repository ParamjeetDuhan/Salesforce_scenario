// Task Completion Tracking and Account Owner Notification

/* 1. Count open Tasks on Account. The Account has a custom number field Open_Tasks__c. 
     It should equal the number of Tasks related to that Account (WhatId = Account Id) where Status is not 'Completed'. */
/*2. Require a comment when closing a high priority Task. When a Task’s Status is changed to 'Completed' and its Priority is 'High', 
     the Description field must not be blank. If it is, block the save with an error on the Task.*/

trigger TaskTrigger on Task(after insert,after Update,after delete,after undelete , before insert , before update){
         if(Trigger.iSAfter){
                if(Trigger.isInsert ||Trigger.isUndelete){
                      TaskHandler.CountOpenTask(Trigger.new,null);
                }
                if(Trigger.isUpdate){
                    TaskHandler.CountOpenTask(Trigger.new,Trigger.oldMap);
                }
                  if(Trigger.isDelete){
                      TaskHandler.CountOpenTask(Trigger.old,null);
                }
         }
         if(Trigger.iSbefore){
                if(Trigger.isInsert){
                      TaskHandler.closingHighPriorityTaskRequireComment(Trigger.new,null);
                }
                if(Trigger.isUpdate){
                    TaskHandler.closingHighPriorityTaskRequireComment(Trigger.new,Trigger.oldMap);
                }
         }
}