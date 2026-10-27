/*Query all Opportunity records with Amount > 100000, collect their AccountId values into a Set<Id> (skip nulls), 
then query those Account records (Id, Name) into a Map<Id, Account>.*/
              
                                               //JOIN
    SELECT Id , Name 
    FROM Account
    WHERE Id IN(SELECT AccountId FROM Opportunity WHERE Amount>100000);
                  
                                                //APEX WITH Query
     Set<Id> accountIds = new Set<Id>();
    for(Opportunity o : [SELECT AccountId FROM Opportunity
                         WHERE Amount>100000]){
                            if(o.AccountId != null){
                                  accountIds.add(o.AccountId);
                            }
                         }
    Map<Id, Account> mapidToAccount = new Map<Id, Account>();
    for(Account a : [ SELECT Id ,Name FROM Account WHERE Id IN accountIds]){
              mapidToAccount.put(a.Id,a);
    }

/*Query all Contact records where Email = null, collect their AccountId values into a Set<Id>, then query
 the matching Account records (Id, Name, Industry) into a List<Account> */

                                       //JOIN
        SELECT Id,Name,Industry FROM Account
        WHERE Id IN(SELECT AccountId FROM Contact WHERE Email = null);

                                       //Apex With Query
        Set<Id> accountIds = new Set<Id>();
        for(Contact c :[SELECT AccountId FROM Contact
                        WHERE Email = null]){
                            accountIds.add(c.AccountId);
                        }

    List<Account> acc = [SELECT Id,Name,Industry FROM Account WHERE Id IN : accountIds];

/*Query all Case records where IsClosed = false, collect the OwnerId values into a Set<Id>, 
then query User records (Id, Name, Email) for those Ids into a Map<Id, User>. */

                           //JOIN 
    SELECT Id ,Name ,Email FROM User 
     WHERE Id IN (SELECT OwnerId FROM Case WHERE IsClosed = false);
      
                        //Apex With Query
         Set<Id> ownerIds = new Set<Id>();
    for(Case c : [SELECT OwnerId FROM Case
                         WHERE IsClosed = false]){
                            if(c.OwnerId != null){
                                  ownerIds.add(c.OwnerId);
                            }
                         }
    Map<Id, User> mapidTouser = new Map<Id, User>();
    for(User u : [ SELECT Id ,Name ,Email FROM User WHERE Id IN : ownerIds]){
              mapidTouser.put(u.Id,u);
    }

/*Query Opportunity records where StageName = 'Closed Won' and collect their AccountId values into a Set<Id>. 
Then query all Account records that are not in that set (use the bind variable), and store them in a List<Account>. */

                             //JOIN
        SELECT Id , Name 
    FROM Account
    WHERE Id NOT IN(SELECT AccountId FROM Opportunity WHERE StageName = 'Closed Won');
                  
                                                //APEX WITH Query
     Set<Id> accountIds = new Set<Id>();
    for(Opportunity o : [SELECT AccountId FROM Opportunity
                         WHERE StageName = 'Closed Won']){
                            if(o.AccountId != null){
                                  accountIds.add(o.AccountId);
                            }
                         }
    List<Account> acc =  [ SELECT Id ,Name FROM Account WHERE Id NOT IN : accountIds];

/*In Apex, use an aggregate query to get the count of Contacts per AccountId,
 and store it in a Map<Id, Integer>. Skip Contacts with a null AccountId. */

                    // Aggregate Query
SELECT AccountId,COUNT(Id) FROM Contact
WHERE AccountId != null
GROUP BY AccountId;
   
                   //Apex With Query
 Map<Id, Integer> ContactsPerAccount = new  Map<Id, Integer>();
   for(AggregateResult ar : [SELECT AccountId,COUNT(Id) TotalContact FROM Contact
                             WHERE AccountId != null
                             GROUP BY AccountId]){
                                ContactsPerAccount.put((Id)ar.get('AccountId'),(Integer)ar.get('TotalContact'));
                             }


/*In Apex, use an aggregate query to get the average Amount per OwnerId from
 Opportunity where StageName = 'Closed Won', and store it in a Map<Id, Decimal>. */
  
                    //Aggregate Query

 SELECT OwnerId , AVG(Amount) FROM Opportunity
 WHERE StageName = 'Closed Won'
 GROUP BY OwnerId;
              //Apex With Query
 Map<Id, Decimal> AveragePerId = new  Map<Id, Decimal>();
   for(AggregateResult ar : [SELECT OwnerId,AVG(Amount) AverageAmount FROM Opportunity
                             WHERE StageName = 'Closed Won'
                             GROUP BY OwnerId]){
                                AveragePerId.put((Id)ar.get('OwnerId'),(Decimal)ar.get('AverageAmount'));
                             }
/*Given a Set<Id> ownerIds already populated, write an Apex query that returns a Map<Id, User> of Users 
(Id, Name, Email) with those Ids, only where IsActive = true. */

Set<Id> ownerIds ; // Already Populated

                    //Normal Query
SELECT Id,Name,Email FROM User
  WHERE Id IN : ownerIds AND IsActive = true

 Map<Id, User> UserMapToId = new  Map<Id, User>();
 for(User u : [SELECT Id,Name,Email FROM User
                WHERE Id IN : ownerIds AND IsActive = true]){
                    UserMapToId.put(u.Id,u);
                }