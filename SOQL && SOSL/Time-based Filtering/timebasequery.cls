//Find all Opportunities that are closing THIS_QUARTER and have StageName != 'Closed Lost'
SELECT Id, Name, StageName
FROM Opportunity
WHERE CloseDate = THIS_QUARTER AND StageName != 'Closed Lost'

//Find all Account records created in the last 30 days (use a SOQL date function, not a hardcoded date), showing Id, Name, and CreatedDate.
SELECT Id, Name, CreatedDate
FROM Account
WHERE CreatedDate = LAST_N_DAYS:30

//Find all Opportunity records closing in the next 15 days (use a date literal), showing Id, Name, and CloseDate.
SELECT Id, Name , CloseDate FROM Opportunity 
WHERE CloseDate = NEXT_N_DAYS:15

/*Find all Account records created in the last 6 months (use a date literal) that have at least one Opportunity with Amount > 100000. 
 Return only Account Id and Name. */
SELECT Id, Name FROM Account
WHERE CreatedDate = LAST_N_DAYS:180
AND Id IN (SELECT AccountId FROM Opportunity WHERE Amount > 100000)

/*Find all Case records created in the last 7 days (use a date literal) showing Id, Subject, and 
Contact.Account.Name, where Status != 'Closed'. */
SELECT Id,Priority,Subject,Contact.Account.Name FROM Case
WHERE CreatedDate = LAST_N_DAYS:7 AND IsClosed = false;

/*Find all Contact records showing Id, LastName, and Account.Owner.Name, where the Account’s Industry = 'Finance' 
and the Contact’s CreatedDate is in the last 3 months (use a date literal). Order by LastName ascending. */

SELECT Id , LastName , Account.Owner.Name FROM Contact
WHERE Account.Industry = 'Finance'
AND CreatedDate = LAST_N_MONTHS:3
ORDER BY LastName ASC;