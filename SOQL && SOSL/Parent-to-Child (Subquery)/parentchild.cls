//Find all Account records along with only those related Opportunities that have Amount > 50000
/*Find all Account records with their related Opportunities (Name, Amount), only Opportunities where Amount > 50000. 
  Limit to 10 Accounts. */
SELECT Id, Name,
    (SELECT Id, Name, Amount FROM Opportunities WHERE Amount > 50000)
FROM Account;
SELECT Id, Name,
    (SELECT  Name, Amount FROM Opportunities WHERE Amount > 50000)
FROM Account
LIMIT 10;

//Find all Order__c (custom object) records along with their related child Order_Item__c records (assume Child Relationship Name is Order_Items), 
//showing Order_Item__c's Product_Name__c and Quantity__c.
SELECT Id, 
    (SELECT Product_Name__c, Quantity__c FROM Order_Items__r)
FROM Order__c

//Find all Account records along with their related Contacts (Id, LastName), but only include Contacts where Email != null.
/*Find all Account records with their related Contacts (Id, LastName, Email), only Contacts where Email != null.
 Order the Accounts by Name ascending.*/
SELECT Id, Name , Rating , Industry,
     (SELECT Id, LastName , Email FROM Contacts WHERE Email != null)
FROM Account
ORDER BY NAME ASC;

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

/*Find all Invoice__c records (custom object) with their child Invoice_Line__c records, assuming the Child Relationship Name is Invoice_Lines. 
Show Name and Total__c for the children, only where Total__c > 1000. */
SELECT Id,CustomerName__c,Amount__c,
        (SELECT Name,Total__c FROM Invoice_Lines__r WHERE Total__c > 1000)
FROM Invoice__c;

/*Find all Account records with their related Contacts (Id, LastName) and Opportunities (Name, Amount) in a single query. 
Only include Opportunities where Amount > 25000, and limit to 20 Accounts. */

SELECT Id , Name , Industry,
             (SELECT Id , LastName FROM Contacts),
             (SELECT Name, Amount FROM Opportunities WHERE Amount>25000)
FROM Account
LIMIT 20;