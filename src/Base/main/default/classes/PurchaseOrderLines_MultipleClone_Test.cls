@isTest
private class PurchaseOrderLines_MultipleClone_Test {
  static Account vendor;
  static Account legend;
  Id pbId;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void init() {
    vendor = Factory_Account.insertSupplierAccounts(1)[0];
    legend = Factory_Account.insertDealerAccounts(1)[0];
  }

  @isTest
  static void cloneLines_Test() {
    init();
    AcctSeedERP__Purchase_Order__c po = Factory_PurchaseOrder.createMinimalPO(vendor.Id, legend.Id);
    Factory_PurchaseOrder.addPOLines(1, po.Id);
    AcctSeedERP__Purchase_Order_Line__c[] pols_1 = [
      SELECT Id
      FROM AcctSeedERP__Purchase_Order_Line__c
      WHERE AcctSeedERP__Purchase_Order__c = :po.Id
    ];
    System.assertEquals(1, pols_1.size());
    PurchaseOrderLines_MultipleClone.cloneLines(pols_1[0].Id, 5);
    AcctSeedERP__Purchase_Order_Line__c[] pols_6 = [
      SELECT Id
      FROM AcctSeedERP__Purchase_Order_Line__c
      WHERE AcctSeedERP__Purchase_Order__c = :po.Id
    ];
    System.assertEquals(6, pols_6.size());
  }
}
