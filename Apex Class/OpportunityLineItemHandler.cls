public class OpportunityLineItemHandler{

    public static void rollupProduct(List<OpportunityLineItem> Productlist){
        Set<Id> OpportunityIds = new Set<Id>();
                 if(!Productlist.isEmpty()){
                      for(OpportunityLineItem p : Productlist){
                            OpportunityIds.add(p.OpportunityId);
                      }
                 }
                 Map<Id,Integer> Rollupcount = new Map<Id,Integer>();
                 for(AggregateResult ar :[SELECT OpportunityId , Count(Id) TotalProduct FROM OpportunityLineItem
                                          WHERE OpportunityId IN :(OpportunityIds)
                                          GROUP BY OpportunityId]){
                                            Rollupcount.put((Id)ar.get('OpportunityId'),(Integer)ar.get('TotalProduct'));
                                          }
            List<Opportunity> countUpdate = new List<Opportunity>();
            for(Id i : OpportunityIds){

                    Opportunity o = new Opportunity();
                     o.Id = i;
                     o.Total_Products__c = Rollupcount.containsKey(i)? Rollupcount.get(i):0;
                     countUpdate.add(o);
                  }
                if(!countUpdate.isEmpty()){
                    update countUpdate;
                }
            }

    public static void blockDeepDiscounts(List<OpportunityLineItem> Lineitem){
        Set<Id> OpportunityIds = new Set<Id>();
                 if(!Lineitem.isEmpty()){
                      for(OpportunityLineItem p : Lineitem){
                        if(p.Discount > 30){
                              OpportunityIds.add(p.OpportunityId);
                        }
                      }
                 }
        Map<Id,Boolean> OppToDiscountApproved = new Map<Id,Boolean>();
                 for(Opportunity opp :[SELECT Id , Discount_Approved__c  FROM Opportunity
                                          WHERE Id IN :(OpportunityIds)
                                          ]){
                                             OppToDiscountApproved.put(opp.Id,opp.Discount_Approved__c);
                                          } 
       for(OpportunityLineItem p : Lineitem){
                   if(p.Discount > 30 && OppToDiscountApproved.containsKey(p.OpportunityId)){
                         if(!OppToDiscountApproved.get(p.OpportunityId)){
                            p.addError('Product with discount more than 30 cannot be save without Approval');
                         }
                   }
                }
    }

}