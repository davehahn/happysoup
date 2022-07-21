@isTest
private class lgnd_newClaimController_Test {
  static Account acct;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    insert new PricebookEntry(
      Product2Id = LGND_Constants.partnerWarrantyLabourProductId,
      Pricebook2Id = Test.getStandardPricebookId(),
      UnitPrice = 100,
      IsActive = true
    );
    insert new PricebookEntry(
      Product2Id = LGND_Constants.partnerWarrantyLabourProductId,
      Pricebook2Id = LGND_Constants.partnerPricebookId,
      UnitPrice = 100,
      IsActive = true
    );
  }

  @isTest
  static void getPricebookId() {
    Id pId = lgnd_newClaimController.getPricebookId();
    System.assert(pId != null);
  }

  @isTest
  static void initForm_Test() {
    Map<String, Object> initData = lgnd_newClaimController.initForm();
  }

  @isTest
  static void saveWithParts() {
    acct = AccountFactory.insertSupplierAccountWithContacts('TestSupplier', 1);
    Case c = Factory_Case.createWarrantyCase(acct);
    lgnd_newClaimController.saveWithParts(null, null);
    lgnd_newClaimController.saveWithParts(JSON.serialize(c), new List<Case_Part__c>());
  }

  @isTest
  static void saveWithoutParts() {
    acct = AccountFactory.insertSupplierAccountWithContacts('TestSupplier', 1);
    Case c = Factory_Case.createWarrantyCase(acct);
    lgnd_newClaimController.saveWithoutParts(c);
  }

  @isTest
  static void getDocs() {
    acct = AccountFactory.insertSupplierAccountWithContacts('TestSupplier', 1);
    Case c = Factory_Case.createWarrantyCase(acct);
    lgnd_newClaimController.getDocs(c.Id);
  }

  @isTest
  static void getRegistration() {
    GMBLASERP__Serial_Number__c serno = Factory_SerialNumber.insertFullSerial('Boat', 'Good boat', '1234567890');
    lgnd_newClaimController.getRegistration(serno.Id);
  }

  @isTest
  static void getProduct() {
    Product2 product = Factory_Product.createSerializedProduct('Boat', 'Pontoon');
    lgnd_newClaimController.getProduct(product.Id);
  }

  @isTest
  static void deleteClaims() {
    acct = AccountFactory.insertSupplierAccountWithContacts('TestSupplier', 1);
    Case c = Factory_Case.createWarrantyCase(acct);
    List<Id> cases = new List<Id>();
    cases.add(c.Id);
    lgnd_newClaimController.deleteClaims(cases);
  }

  @isTest
  static void getUnitPrice() {
    Product2 p = Factory_Product.createSerializedProduct('Boat', 'Pontoon');
    System.debug(p);
    Id pricebookId = Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c;
    System.debug(pricebookId);

    insert createPricebookEntry(p.Id, 'standard', 33);
    PricebookEntry[] pbes = new List<PricebookEntry>();
    pbes.add(createPricebookEntry(p.Id, 'retail', 33));
    pbes.add(createPricebookEntry(p.Id, 'partner', 23));
    insert pbes;

    lgnd_newClaimController.getUnitPrice(p.Id);
  }

  @isTest
  static void getUnitPrice_Oops() {
    try {
      Product2 p = Factory_Product.createSerializedProduct('Boat', 'Pontoon');
      lgnd_newClaimController.getUnitPrice(p.Id);
    } catch (Exception e) {
      return;
    }
  }

  @isTest
  static void getProductIdByName() {
    Product2 product = Factory_Product.createSerializedProduct('Boat', 'Pontoon');
    lgnd_newClaimController.getProductIdByName(product.Name);
  }

  private static PricebookEntry createPricebookEntry(Id partId, String pbType, Decimal price) {
    Id pbId;
    System.debug([SELECT count(Id) FROM Pricebook2]);
    if (pbType == 'standard')
      pbId = Test.getStandardPricebookId();
    if (pbType == 'retail')
      pbId = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
    if (pbType == 'partner')
      pbId = Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c;

    return new PricebookEntry(
      Pricebook2Id = pbId,
      Product2Id = partId,
      isActive = true,
      UnitPrice = price,
      UseStandardPrice = false
    );
  }
}
