/**
 * Created by Legend on 16/5/22.
 */

public without sharing class TA_EcwidSalesOrder_AI implements TriggerAction.AfterInsert {
  public void afterInsert(List<Ecwid_Sales_Order__e> newList) {
    Set<Id> setIdSO = new Set<Id>();
    for (Ecwid_Sales_Order__e eso : newList) {
      if (eso.Sales_Order_Id__c != null) {
        setIdSO.add(eso.Sales_Order_Id__c);
      }
    }
    if (!setIdSO.isEmpty()) {
      List<AcctSeedERP__Sales_Order__c> lstSalesOrderForCashReceipt = [
        SELECT
          Id,
          AcctSeedERP__Customer__c,
          GL_Account_Variable_1__c,
          GL_Account_Variable_2__c,
          AcctSeedERP__Total__c,
          Name
        FROM AcctSeedERP__Sales_Order__c
        WHERE Id IN :setIdSO
      ];
      SalesOrder_Service.generateCashReceipt(lstSalesOrderForCashReceipt);
    }
  }
}
