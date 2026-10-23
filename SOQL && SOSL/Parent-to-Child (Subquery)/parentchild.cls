//Find all Account records along with only those related Opportunities that have Amount > 50000
SELECT Id, Name,
    (SELECT Id, Name, Amount FROM Opportunities WHERE Amount > 50000)
FROM Account;

//Find all Order__c (custom object) records along with their related child Order_Item__c records (assume Child Relationship Name is Order_Items), 
//showing Order_Item__c's Product_Name__c and Quantity__c.
SELECT Id, 
    (SELECT Product_Name__c, Quantity__c FROM Order_Items__r)
FROM Order__c

//Find all Account records along with their related Contacts (Id, LastName), but only include Contacts where Email != null.
SELECT Id, Name , Rating , Industry,
     (SELECT Id, LastName , Email FROM Contacts WHERE Email != null)
FROM Account;

//Find all Account records with their related Opportunities (Id, Name, StageName), but only Opportunities where StageName = 'Closed Won'.
SELECT Id, Name, Rating,
    (SELECT Id, Name, StageName FROM Opportunities WHERE StageName = 'Closed Won')
FROM Account

/*Find all Order__c records (custom object) with their child Order_Item__c records, assuming the Child Relationship Name is Order_Items. 
   Show Name and Quantity__c for the children, and only include Order Items where Quantity__c > 10.*/
SELECT Id, Order_Number__c,
    (SELECT Name, Quantity__c FROM Order_Items__r WHERE Quantity__c > 10)
FROM Order__c

/* Find all Account records with their related Cases (Id, Subject), ordered by Account Name ascending. Limit to the first 5 Accounts. */

SELECT Id, Name , Rating,
        (SELECT Id,Subject FROM Cases)
FROM Account
ORDER BY Name ASC
LIMIT 5; 