//Find all Opportunities that are closing THIS_QUARTER and have StageName != 'Closed Lost'
SELECT Id, Name, StageName
FROM Opportunity
WHERE CloseDate = THIS_QUARTER AND StageName != 'Closed Lost'

//Find all Account records created in the last 30 days (use a SOQL date function, not a hardcoded date), showing Id, Name, and CreatedDate.
SELECT Id, Name, CreatedDate
FROM Account
WHERE CreatedDate = LAST_N_DAYS:30
