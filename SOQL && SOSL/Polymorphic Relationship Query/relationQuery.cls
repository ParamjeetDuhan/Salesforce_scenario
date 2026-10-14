// Find all Task records showing the Subject, and conditionally show Email if the related Who is a Contact, 
// or Company if the related Who is a Lead.
SELECT Id, Subject,
    TYPEOF Who
        WHEN Contact THEN  Email
        WHEN Lead THEN Company
    END
FROM Task
WHERE WhoId != null
