//@isTest(seeAllData = true)
@isTest
private class DealerPartsOrderController_Test {
  static Product2 pdt;
  static Account acc;
  static String saleType = 'Partner';

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  static {
    //gcProduct.disableTrigger = true;
    acc = AccountFactory.buildDealerAccount('test bobs burgers');
    insert acc;
    InventoryTestFactory itf = new InventoryTestFactory();
    pdt = itf.insertTestProducts(1, 'Part')[0];
  }

  static testMethod void saveMaterialsTest() {
    String errorMessage = 'Error in saving materials';
    String jsonValue = '[{"pdtId": "' + pdt.Id + '","pdtName": "' + pdt.Name + '","matQuantity": 10}]';
    AcctSeed__Project__c erpOrder = new AcctSeed__Project__c(
      Name = 'Test',
      AcctSeed__Status__c = 'Active',
      AcctSeed__Account__c = acc.Id,
      RecordTypeId = gcConstants.idRtPartnerPartsOrder
    );
    insert erpOrder;
    AcctSeed__Project_Task__c projectTask = new AcctSeed__Project_Task__c(
      AcctSeed__Project__c = erpOrder.Id,
      Name = 'Default Task Name'
    );
    insert projectTask;
    DealerPartsOrderController.saveMaterials(jsonValue, 'test1111', erpOrder.Id, '', false);
    //NewERPOrderController.insertMaterials(jsonValue, erpOrder);
  }

  static testMethod void getProductFamilyTest() {
    String errorMessage = 'Error in getting Product family';
    Id pbId = DealerPartsOrderController.findPriceBook(saleType);
    Account acc = [SELECT Id, Name FROM Account LIMIT 1];
    Product2 pdt = [SELECT Id, Name FROM Product2 WHERE IsActive = TRUE LIMIT 1];
    AcctSeed__Project__c erpOrder = new AcctSeed__Project__c(
      Name = 'Test',
      AcctSeed__Status__c = 'Active',
      AcctSeed__Account__c = acc.Id
    );
    String jsonValue = '[{"isSelected": true,"prodFamilyName": "Accessories"}]';
    DealerPartsOrderController.getProductFamily(erpOrder.Id, saleType);
    insert erpOrder;
    AcctSeed__Project_Task__c projectTask = new AcctSeed__Project_Task__c(
      AcctSeed__Project__c = erpOrder.Id,
      Name = 'Default Task Name'
    );
    insert projectTask;
    AcctSeedERP__Material__c newMaterial = new AcctSeedERP__Material__c();
    newMaterial.AcctSeedERP__Product__c = pdt.Id;
    newMaterial.AcctSeedERP__Quantity_Per_Unit__c = 2;
    newMaterial.GMBLASERP__Unit_Price__c = 200;
    newMaterial.AcctSeedERP__Project__c = erpOrder.Id;
    newMaterial.AcctSeedERP__Project_Task__c = projectTask.Id;
    insert newMaterial;
    DealerPartsOrderController.getProductFamily(erpOrder.Id, saleType);
    DealerPartsOrderController.getProductswithFamily('a', jsonValue, '', pdt.Id, pbId, false);
    DealerPartsOrderController.getProductswithFamily('ab', jsonValue, '', 'All Models', pbId, false);
    DealerPartsOrderController.getProductswithFamily('', jsonValue, '', pdt.Id, pbId, false);
  }

  @isTest
  static void coverageTest() {
    DealerPartsOrderController.coverage();
  }
}
