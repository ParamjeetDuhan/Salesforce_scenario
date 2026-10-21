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
     (SELECT Id, LastName , Email FROM Contact WHERE Email != null)
FROM Account;
