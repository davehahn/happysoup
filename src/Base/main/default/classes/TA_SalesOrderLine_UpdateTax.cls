public inherited sharing class TA_SalesOrderLine_UpdateTax implements  TriggerAction.AfterUpdate
{
    
  public void afterUpdate( List<AcctSeedERP__Sales_Order_Line__c> newList,
                           List<AcctSeedERP__Sales_Order_Line__c> oldList
                          
                         )
  {
      set<Id> setIdBill = new set<Id>();
      Map<Id, AcctSeedERP__Sales_Order_Line__c> oldMap= new Map<Id, AcctSeedERP__Sales_Order_Line__c>( oldList);
       
      for(AcctSeedERP__Sales_Order_Line__c b : newList){
          setIdBill.add(b.AcctSeedERP__Sales_Order__c);
      }
      for(AcctSeedERP__Sales_Order_Line__c b : oldMap.values()){
          setIdBill.add(b.AcctSeedERP__Sales_Order__c);
      }
      
      SalesOrderLineService.updateSalesTax(setIdBill);
  }
 
}