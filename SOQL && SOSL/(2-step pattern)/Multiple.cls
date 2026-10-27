//Find all Account records that have at least one Contact who is associated with at least one closed Case
SELECT Id, Name FROM Account
WHERE Id IN (
    SELECT AccountId FROM Contact
    WHERE Id IN (SELECT ContactId FROM Case WHERE Status = 'Closed')
)

/*Find all Account records that have more than 3 Contacts. Return only Id and Name.
 (Write the full approach, including the aggregate step.)*/

 Set<Id> accountIds = new Set<Id>();
 for(AggregateResult ar :[SELECT COUNT(Id),AccountId FROM Contact
                          GROUP BY AccountId
                          HAVING COUNT(Id)>3]){
                            accountIds.add((Id)ar.get('AccountId'));
                          }
List<Account> accs = [SELECT Id, Name FROM Account WHERE Id IN :accountIds];

/*Use an aggregate query to get the total Amount per AccountId from Opportunity where StageName = 'Closed Won'. 
Store the results in a Map<Id, Decimal>. Then query the Account 
records for those Ids and, in a loop, put each Account’s Name and its total into a Map<String, Decimal>. */

Map<Id, Decimal> AmountPerId = new Map<Id, Decimal>();

for(AggregateResult ar :[ SELECT AccountId,SUM(Amount) totalsum FROM Opportunity
                          WHERE StageName = 'Closed Won'
                          GROUP BY AccountId]){
                            AmountPerId.put((Id)ar.get('AccountId'),(Decimal)ar.get('totalsum'));
                          }
    
Map<String, Decimal> AmountPerName = new Map<String, Decimal>();

for(Account a : [SELECT Id,Name FROM Account
                 WHERE Id IN : AmountPerId.keySet()]){
                    if(AmountPerId.containskey(a.Id))
                    AmountPerName.put(a.Name,AmountPerId.get(a.Id));
                 }
