//Find all Account records that have at least one Contact who is associated with at least one closed Case
SELECT Id, Name FROM Account
WHERE Id IN (
    SELECT AccountId FROM Contact
    WHERE Id IN (SELECT ContactId FROM Case WHERE Status = 'Closed')
)
