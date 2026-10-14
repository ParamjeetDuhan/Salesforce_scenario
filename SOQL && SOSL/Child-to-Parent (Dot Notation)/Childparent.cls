//Find all Contact records showing the Name of their Account's Owner
SELECT Id, Name , Account.Owner.Name FROM Contact;

//Find all Invoice__c records showing the parent Account__r.Name and Account__r.Phone, where Invoice__c.Status__c = 'Overdue'.

SELECT Id, Name , Account__r.Name ,Account__r.Phone FROM Invoice__c
WHERE Invoice__c.Status__c = 'Overdue';

