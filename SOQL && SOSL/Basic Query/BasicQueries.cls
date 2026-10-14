//Find all Contact records where MailingCity = 'Noida' and Title contains the word 'Manager'.
SELECT Id, LastName , MailingCity , Title
FROM Contact
WHERE MailingCity = 'Noida' AND Title Like '%Manager%';

//Find the 11th to 20th Account (alphabetically by Name) — i.e., skip the first 10, return the next 10.
SELECT Id, Name FROM Account
ORDER BY Name
LIMIT 10
OFFSET 10

