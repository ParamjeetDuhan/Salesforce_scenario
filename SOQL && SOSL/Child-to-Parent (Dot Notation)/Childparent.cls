//Find all Contact records showing the Name of their Account's Owner
SELECT Id, Name , Account.Owner.Name FROM Contact;

//Find all Invoice__c records showing the parent Account__r.Name and Account__r.Phone, where Invoice__c.Status__c = 'Overdue'.

SELECT Id, Name , Account__r.Name ,Account__r.Phone FROM Invoice__c
WHERE Invoice__c.Status__c = 'Overdue';

//Find all Case records showing Id, Subject, and the Contact.Account.Name (two levels up), where Status = 'Closed'.
SELECT Id, Subject , Contact.Account.Name FROM Case
WHERE Status = 'Closed';

/* Find all Contact records showing Name and the parent Account__r.Name from a custom lookup field Account__c on Contact.
       Only include contacts whose Account__r.Industry = 'Healthcare'. */
SELECT Id , LastName , Account__r.Name FROM Contact
 WHERE Account__r.Industry = 'Healthcare';