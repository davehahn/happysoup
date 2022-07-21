/**
 * Created by Legend on 16/5/22.
 */

@IsTest
private class TA_EcwidSalesOrder_AI_T {
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  @IsTest
  static void afterInsert_Trigger() {
    Account customer = Factory_Account.insertCustomerAccounts(1)[0];
    AcctSeedERP__Sales_Order__c so = Factory_SalesOrder.createSalesOrder(customer, null);
    Ecwid_Sales_Order__e evt = new Ecwid_Sales_Order__e(Status__c = true, Sales_Order_Id__c = so.Id);
    Test.startTest();
    Database.SaveResult sr = EventBus.publish(evt);
    Test.stopTest();
    List<AcctSeed__Cash_Receipt__c> receipts = [SELECT Id FROM AcctSeed__Cash_Receipt__c WHERE Sales_Order__c = :so.Id];
    System.assertEquals(true, sr.isSuccess());
    System.assertEquals(1, receipts.size());
  }
}
