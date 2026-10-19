//Find all Opportunity records belonging to Accounts that do not have Industry 'Technology'.
SELECT Id, Name FROM Opportunity
WHERE Account.Industry != 'Technology';

//Find all Contact records that do not have any related Case with Status = 'Open'.
SELECT Id, LastName
FROM Contact
WHERE Id NOT IN (SELECT ContactId FROM Case WHERE Status = 'Open' );

//Find all Account records that have no Contacts at all (use an anti-join subquery).
SELECT Id , Name , Rating FROM Account
WHERE Id NOT IN(SELECT AccountId FROM Contact);
