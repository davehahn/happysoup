/**
 * Created by Legend on 21/4/22.
 */

public inherited sharing class TA_SalesOrderLine_KIT_AU implements TriggerAction.AfterUpdate {
  public void afterUpdate(
    List<AcctSeedERP__Sales_Order_Line__c> newList,
    List<AcctSeedERP__Sales_Order_Line__c> oldList
  ) {
    set<Id> setId = new Set<Id>();
    Map<Id, AcctSeedERP__Sales_Order_Line__c> oldMap = new Map<Id, AcctSeedERP__Sales_Order_Line__c>(oldList);

    for (AcctSeedERP__Sales_Order_Line__c sol : newList) {
      if (sol.AcctSeedERP__Quantity_Ordered__c != oldMap.get(sol.Id).AcctSeedERP__Quantity_Ordered__c)
        setId.add(sol.Id);
    }
    if (!setId.isEmpty())
      SalesOrderLine_Service.updateMaterialSpec(setId);
  }
}
