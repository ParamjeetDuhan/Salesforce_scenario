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