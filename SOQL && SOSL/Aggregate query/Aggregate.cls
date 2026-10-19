//Find the count of Opportunities grouped by both StageName and LeadSource.
SELECT StageName, LeadSource, COUNT(Id) Total
FROM Opportunity
GROUP BY StageName, LeadSource

//Find OwnerId values (Users) who own more than 10 Accounts, sorted by the count descending.
SELECT OwnerId , COUNT(Id)
FROM Account
GROUP BY OwnerId
HAVING  COUNT(Id)>10 
ORDER BY  COUNT(Id) DESC;

//Find the average Amount of Opportunity records grouped by OwnerId, but only show owners whose average is greater than 20,000.
SELECT  AVG(Amount) average, OwnerId
FROM Opportunity
GROUP BY OwnerId
HAVING AVG(Amount)>20000;

//Find the number of Contacts per Account (AccountId), but only show Accounts having more than 2 Contacts, sorted by the count descending.
SELECT Count(Id) Totalcontact , AccountId FROM Contact
GROUP BY AccountId
HAVING COUNT(Id)>2
ORDER By COUNT(Id) DESC;


