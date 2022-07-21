/**
 * Created by Legend on 21/4/22.
 */

public inherited sharing class TA_SalesOrderLine_BU implements TriggerAction.BeforeUpdate {
  public Boolean allowPartUpdate = false;
  public void beforeUpdate(
    List<AcctSeedERP__Sales_Order_Line__c> newList,
    List<AcctSeedERP__Sales_Order_Line__c> oldList
  ) {
    Map<Id, AcctSeedERP__Sales_Order_Line__c> oldMap = new Map<Id, AcctSeedERP__Sales_Order_Line__c>(oldList);

    for (AcctSeedERP__Sales_Order_Line__c sol : newList) {
      if (!allowPartUpdate && sol.Sales_Order_Line__c != null) {
        sol.AcctSeedERP__Quantity_Ordered__c = oldMap.get(sol.Id).AcctSeedERP__Quantity_Ordered__c;
        sol.Part_Quantity_Specified_Multiplier__c = oldMap.get(sol.Id).Part_Quantity_Specified_Multiplier__c;
        sol.AcctSeedERP__Unit_Price__c = oldMap.get(sol.Id).AcctSeedERP__Unit_Price__c;
      }
    }
  }
}
