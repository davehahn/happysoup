@isTest
private class CPQ_Lib_dh_Test {
  static Product2 boat;
  static Product2 upgradeProduct;
  static Product2 optionProduct;
  static Product2 subOptionProduct;
  static Product_Upgrade__c pu;
  static Opportunity opp;
  static Quote q;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    //old setupBoatData
    Product2 boat = dataSetup_insertBoat();
    dataSetup_insertFeeForMotorUpgrade(boat.Standard_Motor__c);
    dataSetup_insertOpportunityAndQuote();
  }

  private static Product2 dataSetup_insertBoat() {
    Pricebook2[] pbs = [SELECT Id FROM Pricebook2 WHERE Id IN :CPQ_Lib_dh.defaultPricebooks.values()];
    BoatTestFactory factory = new BoatTestFactory();
    return factory.insertFullTestBoats(1, pbs, 'Pontoon')[0];
  }

  private static void dataSetup_insertFeeForMotorUpgrade(Id productId) {
    Product_Upgrade__c pu = [
      SELECT Id, From_Product__c, To_Product__c
      FROM Product_Upgrade__c
      WHERE From_Product__c = :productId
      LIMIT 1
    ];
    // build a fees
    Product2 fee_prod = Factory_Product.buildNonSerializedProduct('Fees', 'Freight');
    insert fee_prod;
    insertpricebookEntries(fee_prod.Id);
    Product_Fee_Amount__c[] pfas = new List<Product_Fee_Amount__c>();
    for (Id pbId : CPQ_Lib_dh.defaultPricebooks.values()) {
      pfas.add(
        new Product_Fee_Amount__c(
          Price_Book__c = pbId,
          Fee_Product__c = fee_prod.Id,
          Province__c = 'Ontario',
          Amount__c = 100
        )
      );
    }
    insert pfas;
    Product_Fee_Map__c pfm = new Product_Fee_Map__c(Parent_Product__c = pu.To_Product__c, Fee_Product__c = fee_prod.Id);
    insert pfm;
  }

  private static void dataSetup_insertOpportunityAndQuote() {
    Account person = Factory_Account.insertFullPersonAccount('fName', 'lName');
    Id pbId = CPQ_Lib_dh.defaultPricebooks.get('retail');
    Opportunity opp = Factory_Opportunity.insertOpportunity(person, pbId);
    Factory_Quote.insertQuote(opp);
  }

  private static void setupBoatData() {
    boat = [
      SELECT
        Id,
        Name,
        RecordType.Name,
        Family,
        Make__c,
        Standard_Motor__c,
        Standard_Trailer__c,
        Standard_Trolling_Motor__c,
        Default_Image_Thumb__c,
        Taxable__c,
        (
          SELECT Id, UnitPrice, Pricebook2Id, IsActive
          FROM PricebookEntries
          WHERE Pricebook2Id IN :CPQ_Lib_dh.defaultPricebooks.values()
        )
      FROM Product2
      WHERE RecordType.Name = 'Boat' AND Family = 'Pontoon'
      LIMIT 1
    ];
  }

  private static Product2 findProduct(Id pId) {
    return [
      SELECT
        Id,
        Name,
        Make__c,
        RecordType.Name,
        Family,
        Default_Image_Thumb__c,
        Taxable__c,
        (SELECT Id, UnitPrice, Pricebook2Id, IsActive FROM PricebookEntries)
      FROM Product2
      WHERE Id = :pId
    ];
  }

  private static void setupOpportunity(Boolean includeQuote) {
    opp = [SELECT Id, Name, AccountId, Pricebook2Id, StageName, CloseDate FROM Opportunity LIMIT 1];
    if (includeQuote) {
      q = [SELECT Id, OpportunityId, Pricebook2Id, Name FROM Quote WHERE OpportunityId = :opp.Id LIMIT 1];
    }
  }

  private static void insertpricebookEntries(Id pId) {
    Factory_PricebookEntry.createAllDefaultEntriesEntries(pId, 100);
  }

  private static void setUpgradeAttrs(Boolean withFee) {
    if (withFee) {
      pu = [
        SELECT Id, From_Product__c, To_Product__c
        FROM Product_Upgrade__c
        WHERE From_Product__c = :boat.Standard_Motor__c
        LIMIT 1
      ];
      upgradeProduct = findProduct(pu.To_Product__c);
    } else {
      pu = [
        SELECT Id, From_Product__c, To_Product__c
        FROM Product_Upgrade__c
        WHERE From_Product__c = :boat.Standard_Trailer__c
        LIMIT 1
      ];
      upgradeProduct = findProduct(pu.To_Product__c);
    }
  }

  private static void setOptionAttrs(String family, Boolean includeSubOption) {
    optionProduct = Factory_Product.buildNonSerializedProduct('Part', family);
    insert optionProduct;
    Factory_PricebookEntry.createStandardEntry(optionProduct.Id, 100);
    if (includeSubOption) {
      subOptionProduct = Factory_Product.buildNonSerializedProduct('Part', family);
      insert subOptionProduct;
      Factory_PricebookEntry.createStandardEntry(subOptionProduct.Id, 100);
    }
    PricebookEntry[] pbes = new List<PriceBookEntry>();
    for (Id pbId : CPQ_Lib_dh.defaultPricebooks.values()) {
      pbes.add(Factory_PricebookEntry.buildEntry(optionProduct.Id, pbId, 100));
      if (includeSubOption) {
        pbes.add(Factory_PricebookEntry.buildEntry(subOptionProduct.Id, pbId, 100));
      }
    }
    insert pbes;
    optionProduct = findProduct(optionProduct.Id);
    if (includeSubOption) {
      subOptionProduct = findProduct(subOptionProduct.Id);
    }
    if (family == 'Premium Package') {
      Factory_ProductFeature.createAllFeatures(optionProduct.Id, 2);
    }
  }

  @isTest
  static void defaultPricebooks_Test() {
    Map<String, Id> defaultPBs = CPQ_Lib_dh.defaultPricebooks;
    System.assertEquals(3, defaultPBs.size());
  }

  @isTest
  static void taxZone_Test() {
    AcctSeed__Accounting_Variable__c aVar = [
      SELECT Id, Name, Tax_is_Harmonized__c, Tax_Rate_Provincial_Statutory__c, Tax_Rate_Retail__c
      FROM AcctSeed__Accounting_Variable__c
      WHERE AcctSeed__Type__c = 'GL Account Variable 3'
      LIMIT 1
    ];
    CPQ_Lib_dh.TaxZone tz = new CPQ_Lib_dh.TaxZone(aVar);
    System.assertEquals(aVar.Name, tz.name);
    System.assertEquals(aVar.Tax_Rate_Provincial_Statutory__c, tz.provincialRate);
    System.assertEquals(5.0, tz.federalRate);
    System.assertEquals(aVar.Tax_is_Harmonized__c, tz.isHarmonized);
  }

  @isTest
  static void CPQ_Product_fromId_Test() {
    setupBoatData();
    Map<Id, PricebookEntry> pb_pbe_map = new Map<Id, PricebookEntry>();
    CPQ_Lib_dh.CPQ_Product cpqP = new CPQ_Lib_dh.CPQ_Product(boat.Id);
    for (PricebookEntry pbe : [
      SELECT Id, Pricebook2Id, Pricebook2.Name
      FROM PricebookEntry
      WHERE Product2Id = :boat.Id
    ]) {
      pb_pbe_map.put(pbe.Pricebook2Id, pbe);
    }
    System.assertEquals(boat.Id, cpqP.id);
    System.assertEquals(boat.Name, cpqP.name);
    System.assertEquals(boat.Family, cpqP.family);
    System.assertEquals(pb_pbe_map.get(CPQ_Lib_dh.defaultPricebooks.get('retail')).Id, cpqP.retailPricebookEntryId);
    System.assertEquals(pb_pbe_map.get(CPQ_Lib_dh.defaultPricebooks.get('partner')).Id, cpqP.partnerPricebookEntryId);
    System.assertEquals(pb_pbe_map.get(CPQ_Lib_dh.defaultPricebooks.get('factory')).Id, cpqP.factoryPricebookEntryId);
    System.assertEquals(100, cpqP.retailPrice); //set in BoatTestFactory
    System.assertEquals(100, cpqP.partnerPrice); //set in BoatTestFactory
    System.assertEquals(100, cpqP.factoryPrice); //set in BoatTestFactory
  }

  @isTest
  static void CPQ_Product_fromObject_Test() {
    setupBoatData();
    Product2 p = findProduct(boat.Id);
    CPQ_Lib_dh.CPQ_Product cpqP = new CPQ_Lib_dh.CPQ_Product(p);
    System.assertEquals(boat.Id, cpqP.id);
    System.assertEquals(boat.Name, cpqP.name);
    System.assertEquals(boat.Family, cpqP.family);
    System.assertEquals(100, cpqP.retailPrice); //set in BoatTestFactory
    System.assertEquals(100, cpqP.partnerPrice); //set in BoatTestFactory
    System.assertEquals(100, cpqP.factoryPrice); //set in BoatTestFactory
  }

  @isTest
  static void CPQ_Product_fromObject_fail_Test() {
    setupBoatData();
    try {
      CPQ_Lib_dh.CPQ_Product cpqP = new CPQ_Lib_dh.CPQ_Product(boat);
    } catch (CPQ.CPQ_Exception ex) {
      System.assertEquals(
        boat.Name + ' does not have an entry in the current Retail, Partner or Factory Pricebooks',
        ex.getMessage()
      );
    }
  }

  @isTest
  static void CPQ_Boat_Test() {
    setupBoatData();
    CPQ_Lib_dh.Boat cpqBoat = new CPQ_Lib_dh.Boat(boat.Id, 'Ontario');
    System.assertEquals(boat.Id, cpqBoat.id);
    System.assertEquals(boat.Name, cpqBoat.name);
    System.assertEquals(boat.Family, cpqBoat.family);
    System.assertEquals(100, cpqBoat.retailPrice); //set in BoatTestFactory
    System.assertEquals(100, cpqBoat.partnerPrice); //set in BoatTestFactory
    System.assertEquals(100, cpqBoat.factoryPrice); //set in BoatTestFactory
    System.assertEquals(boat.Standard_Motor__c, cpqBoat.standardMotorId);
    System.assertEquals(boat.Standard_Trailer__c, cpqBoat.standardTrailerId);
    System.assertEquals(boat.Standard_Trolling_Motor__c, cpqBoat.standardTrollingMotorId);
    System.assertEquals(12, cpqBoat.fees.size()); //created in BoatTestFactory
  }

  @isTest
  static void CPQ_Boat_ToOppLineItem_Test() {
    setupBoatData();
    CPQ_Lib_dh.Boat cpqBoat = new CPQ_Lib_dh.Boat(boat.Id, 'Ontario');
    SObject[] lineItems = cpqBoat.createLineItems('OpportunityLineItem');

    System.assertEquals(13, lineItems.size()); // 12 from the fees and 1 for the boat
  }

  @isTest
  static void CPQ_Upgrade_Constructor_StandardTest() {
    setupBoatData();
    Id pbId = CPQ_Lib_dh.defaultPricebooks.get('retail');
    CPQ_Lib_dh.UpgradeProduct cpqUp = new CPQ_Lib_dh.UpgradeProduct(
      boat.Standard_Motor__c,
      boat.Standard_Motor__c,
      pbId,
      'Ontario'
    );
    System.assertEquals(0, cpqUp.retailUpgradeCost);
    System.assertEquals(0, cpqUp.partnerUpgradeCost);
  }

  @isTest
  static void CPQ_Upgrade_Constructor_FullPriceTest() {
    setupBoatData();
    Id r_pbId = CPQ_Lib_dh.defaultPricebooks.get('retail');
    Id p_pbId = CPQ_Lib_dh.defaultPricebooks.get('partner');
    Id prodId = boat.Standard_Motor__c;
    PricebookEntry r_pbe = [SELECT UnitPrice FROM PricebookEntry WHERE Pricebook2Id = :r_pbId AND Product2Id = :prodId];
    PricebookEntry p_pbe = [SELECT UnitPrice FROM PricebookEntry WHERE Pricebook2Id = :p_pbId AND Product2Id = :prodId];
    Test.startTest();
    CPQ_Lib_dh.UpgradeProduct cpqUp = new CPQ_Lib_dh.UpgradeProduct(null, prodId, r_pbId, 'Ontario');
    Test.stopTest();
    System.assertEquals(r_pbe.UnitPrice, cpqUp.retailUpgradeCost);
    System.assertEquals(p_pbe.UnitPrice, cpqUp.partnerUpgradeCost);
  }

  @isTest
  static void CPQ_Upgrade_Constructor1_Test() {
    setupBoatData();
    setUpgradeAttrs(false);
    Id pbId = CPQ_Lib_dh.defaultPricebooks.get('retail');
    CPQ_Lib_dh.UpgradeProduct cpqUp = new CPQ_Lib_dh.UpgradeProduct(
      pu.From_Product__c,
      pu.To_Product__c,
      pbId,
      'Ontario'
    );
    System.assertEquals(upgradeProduct.Id, cpqUp.id);
    System.assertEquals(upgradeProduct.Name, cpqUp.name);
    System.assertEquals(upgradeProduct.Family, cpqUp.family);
    System.assertEquals(100, cpqUp.retailPrice); //set in BoatTestFactory
    System.assertEquals(100, cpqUp.partnerPrice); //set in BoatTestFactory
    System.assertEquals(100, cpqUp.factoryPrice); //set in BoatTestFactory
    System.assertEquals(10, cpqUp.retailUpgradeCost); //set in BoatTestFactory
    System.assertEquals(10, cpqUp.PartnerUpgradeCost); //set in BoatTestFactory
  }

  @isTest
  static void CPQ_Upgrade_Constructor2_Test() {
    setupBoatData();
    setUpgradeAttrs(false);
    Product_Upgrade_Cost__c[] pucs = [
      SELECT Id, Cost__c, Price_book__c
      FROM Product_Upgrade_Cost__c
      WHERE
        Product_Upgrade__r.From_Product__c = :pu.From_Product__c
        AND Product_Upgrade__r.To_Product__c = :pu.To_Product__c
    ];
    Id pbId = CPQ_Lib_dh.defaultPricebooks.get('retail');
    CPQ_Lib_dh.UpgradeProduct cpqUp = new CPQ_Lib_dh.UpgradeProduct(
      pu.From_Product__c,
      upgradeProduct,
      pucs,
      'Ontario'
    );
    System.assertEquals(upgradeProduct.Id, cpqUp.id);
    System.assertEquals(upgradeProduct.Name, cpqUp.name);
    System.assertEquals(upgradeProduct.Family, cpqUp.family);
    System.assertEquals(100, cpqUp.retailPrice); //set in BoatTestFactory
    System.assertEquals(100, cpqUp.partnerPrice); //set in BoatTestFactory
    System.assertEquals(100, cpqUp.factoryPrice); //set in BoatTestFactory
    System.assertEquals(10, cpqUp.retailUpgradeCost); //set in BoatTestFactory
    System.assertEquals(10, cpqUp.PartnerUpgradeCost); //set in BoatTestFactory
  }

  @isTest
  static void CPQ_UpgradeProduct_noFees_toOppLineItem_Test() {
    setupBoatData();
    setUpgradeAttrs(false);
    setupOpportunity(false);
    Id pbId = CPQ_Lib_dh.defaultPricebooks.get('retail');
    CPQ_Lib_dh.UpgradeProduct cpqUp = new CPQ_Lib_dh.UpgradeProduct(
      pu.From_Product__c,
      pu.To_Product__c,
      pbId,
      'Ontario'
    );
    SObject[] olis = cpqUp.createLineItems('OpportunityLineItem', 'Test Description');
    PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pbId AND Product2Id = :pu.To_Product__c];

    System.assertEquals(1, olis.size());
    System.assertEquals(olis[0].get('PricebookEntryId'), pbe.Id);
  }

  @isTest
  static void CPQ_UpgradeProduct_withFees_toOppLineItem_Test() {
    setupBoatData();
    setUpgradeAttrs(true);
    setupOpportunity(false);
    Id pbId = CPQ_Lib_dh.defaultPricebooks.get('retail');
    CPQ_Lib_dh.UpgradeProduct cpqUp = new CPQ_Lib_dh.UpgradeProduct(
      pu.From_Product__c,
      pu.To_Product__c,
      pbId,
      'Ontario'
    );
    SObject[] olis = cpqUp.createLineItems('OpportunityLineItem', 'Test Description');
    System.assertEquals(1, cpqUp.fees.size());
    System.assertEquals(2, olis.size());
  }

  @isTest
  static void CPQ_OptionProduct_Test() {
    setOptionAttrs('Premium Package', false);
    Integer featureCount = Feature__c.Category__c.getDescribe().getPicklistValues().size() * 2;
    Test.startTest();
    CPQ_Lib_dh.OptionProduct op = new CPQ_Lib_dh.OptionProduct(optionProduct, null, 0, 1);
    Test.stopTest();
    System.assertEquals(optionProduct.Id, op.id);
    System.assertEquals(optionProduct.Name, op.name);
    System.assertEquals(optionProduct.Family, op.family);
    System.assertEquals(0, op.standard);
    System.assertEquals(1, op.maximum);
    System.assert(op.isCheckbox == true);
    System.assert(op.isSelected == false);
    System.assertEquals(featureCount, op.premiumPackage.size());
  }

  @isTest
  static void CPQ_SaleLineItem_FromOptionProduct() {
    setOptionAttrs('Hardware', false);
    //setupOpportunity();
    CPQ_Lib_dh.OptionProduct op = new CPQ_Lib_dh.OptionProduct(optionProduct, null, 1, 2);
    op.quantitySelected = 2;
    Test.startTest();
    CPQ_Lib_dh.SaleLineItem sli = new CPQ_Lib_dh.SaleLineItem(op);
    Test.stopTest();
    System.assertEquals(op.quantitySelected, sli.quantity);
    System.assertEquals(op.retailPrice, sli.salePrice);
  }

  @isTest
  static void CPQ_SaleLineItem_FromOppLine_Test() {
    setupOpportunity(false);
    Product2 part = Factory_Product.createNonSerializedProduct('Part', 'Hardware');
    Factory_PricebookEntry.createAllDefaultEntriesEntries(part.Id, 100);
    PricebookEntry pbe = [
      SELECT Id, UnitPrice
      FROM PricebookEntry
      WHERE Product2Id = :part.Id AND Pricebook2Id = :opp.Pricebook2Id
      LIMIT 1
    ];
    OpportunityLineItem oli = Factory_OpportunityLineItem.buildLineItem(pbe, opp.Id, 1, null);
    insert oli;
    oli = [
      SELECT
        PricebookEntry.Product2Id,
        PricebookEntry.Product2.Name,
        PricebookEntry.Product2.Family,
        Description,
        Quantity,
        UnitPrice,
        ParentProductId__c,
        Taxable_Provincial__c
      FROM OpportunityLineItem
      WHERE Id = :oli.Id
    ];
    Test.startTest();
    CPQ_Lib_dh.SaleLineItem cp = new CPQ_Lib_dh.SaleLineItem(oli);
    Test.stopTest();
    System.assertEquals(oli.Id, cp.lineItemId);
    System.assertEquals(part.Id, cp.productId);
    System.assertEquals(oli.Quantity, cp.quantity);
    System.assertEquals(pbe.UnitPrice, cp.salePrice);
  }

  @isTest
  static void CPQ_SaleLineItem_FromQuoteLine_Test() {
    setupOpportunity(true);
    Product2 part = Factory_Product.createNonSerializedProduct('Part', 'Hardware');
    Factory_PricebookEntry.createAllDefaultEntriesEntries(part.Id, 100);
    PricebookEntry pbe = [
      SELECT Id, UnitPrice
      FROM PricebookEntry
      WHERE Product2Id = :part.Id AND Pricebook2Id = :opp.Pricebook2Id
      LIMIT 1
    ];
    QuoteLineItem qli = Factory_QuoteLineItem.buildLineItem(pbe, q.Id, 1, null);
    insert qli;
    qli = [
      SELECT
        PricebookEntry.Product2Id,
        PricebookEntry.Product2.Name,
        PricebookEntry.Product2.Family,
        Description,
        Quantity,
        UnitPrice,
        ParentProductId__c,
        Taxable_Provincial__c
      FROM QuoteLineItem
      WHERE Id = :qli.Id
    ];
    Test.startTest();
    CPQ_Lib_dh.SaleLineItem cp = new CPQ_Lib_dh.SaleLineItem(qli);
    Test.stopTest();
    System.assertEquals(qli.Id, cp.lineItemId);
    System.assertEquals(part.Id, cp.productId);
    System.assertEquals(qli.Quantity, cp.quantity);
    System.assertEquals(pbe.UnitPrice, cp.salePrice);
  }

  @isTest
  static void CPQ_SalesLineItem_CreateSobject_Test() {
    CPQ_Lib_dh.SaleLineItem sli = new CPQ_Lib_dh.SaleLineItem();
    sli.ParentProductId = null;
    sli.quantity = 10;
    sli.salePrice = 100.00;
    SObject soj = sli.createLineItem('QuoteLineItem');

    System.assertEquals(Schema.QuoteLineItem.getSObjectType(), soj.getSObjectType());
  }

  @isTest
  static void CPQ_SubOption_Test() {
    setOptionAttrs('Hardware', true);
    Test.startTest();
    CPQ_Lib_dh.SubOptionProduct sop = new CPQ_Lib_dh.SubOptionProduct(subOptionProduct, optionProduct.Id, 0, 4);
    Test.stopTest();
    System.assertEquals(optionProduct.Id, sop.parentProductId);
  }

  @isTest
  static void CPQ_Fee_Test() {
    Product2 fee_product = Factory_Product.buildNonSerializedProduct('Fees', 'Freight');
    insert fee_product;
    insertpricebookEntries(fee_product.Id);
    setupOpportunity(false);
    Test.startTest();
    CPQ_Lib_dh.Fee fee = new CPQ_Lib_dh.Fee();
    fee.retailAmount = 500;
    fee.feeProductId = fee_product.Id;
    SObject oli = fee.createLineItem('OpportunityLineItem');
    Test.stopTest();
    System.assertEquals(fee.retailAmount, oli.get('UnitPrice'));
  }

  @isTest
  static void CPQ_CustomProduct_Test() {
    setupOpportunity(false);
    Id custProdId = Utility_Products__c.getOrgDefaults().Partner_Custom_Product__c;
    insertpricebookEntries(custProdId);
    Test.startTest();
    CPQ_Lib_dh.CustomProduct cp = new CPQ_Lib_dh.CustomProduct();
    cp.amount = 100;
    cp.quantity = 5;
    SObject oli = cp.createLineItem('OpportunityLineItem');
    SObject qli = cp.createLineItem('QuoteLineItem');
    Test.stopTest();
    System.assertEquals(custProdId, cp.productId);
    System.assertEquals(18, cp.id.length());
    System.assertEquals(cp.quantity, oli.get('Quantity'));
    System.assertEquals('OpportunityLineItem', oli.getSObjectType().getDescribe().getName());
    System.assertEquals(cp.quantity, qli.get('Quantity'));
    System.assertEquals('QuoteLineItem', qli.getSObjectType().getDescribe().getName());
  }

  @isTest
  static void CPQ_CustomProduct_From_OppLine_Test() {
    setupOpportunity(false);
    Id custProdId = Utility_Products__c.getOrgDefaults().Partner_Custom_Product__c;
    Factory_PricebookEntry.createAllDefaultEntriesEntries(custProdId, 100);
    PricebookEntry pbe = [
      SELECT Id, UnitPrice
      FROM PricebookEntry
      WHERE Product2Id = :custProdId AND Pricebook2Id = :opp.Pricebook2Id
      LIMIT 1
    ];
    OpportunityLineItem oli = Factory_OpportunityLineItem.buildLineItem(pbe, opp.Id, 1, null);
    insert oli;
    oli = [
      SELECT Id, PricebookEntry.Product2Id, Description, Quantity, UnitPrice
      FROM OpportunityLineItem
      WHERE Id = :oli.Id
    ];
    Test.startTest();
    CPQ_Lib_dh.CustomProduct cp = new CPQ_Lib_dh.CustomProduct(oli);
    System.assertEquals(oli.Id, cp.id);
    System.assertEquals(custProdId, cp.productId);
    System.assertEquals(oli.Quantity, cp.quantity);
    System.assertEquals(pbe.UnitPrice, cp.amount);
    Test.stopTest();
  }

  @isTest
  static void CPQ_CustomProduct_From_QuoteLine_Test() {
    setupOpportunity(true);
    Id custProdId = Utility_Products__c.getOrgDefaults().Partner_Custom_Product__c;
    Factory_PricebookEntry.createAllDefaultEntriesEntries(custProdId, 100);
    PricebookEntry pbe = [
      SELECT Id, UnitPrice
      FROM PricebookEntry
      WHERE Product2Id = :custProdId AND Pricebook2Id = :opp.Pricebook2Id
      LIMIT 1
    ];
    QuoteLineItem qli = Factory_QuoteLineItem.buildLineItem(pbe, q.Id, 1, null);
    insert qli;
    qli = [
      SELECT Id, PricebookEntry.Product2Id, Description, Quantity, UnitPrice
      FROM QuoteLineItem
      WHERE Id = :qli.Id
    ];
    Test.startTest();
    CPQ_Lib_dh.CustomProduct cp = new CPQ_Lib_dh.CustomProduct(qli);
    System.assertEquals(qli.Id, cp.id);
    System.assertEquals(custProdId, cp.productId);
    System.assertEquals(qli.Quantity, cp.quantity);
    System.assertEquals(pbe.UnitPrice, cp.amount);
    Test.stopTest();
  }

  @isTest
  static void CPQ_SavingsLine_Test() {
    setupOpportunity(false);
    Id savingsId = Utility_Products__c.getOrgDefaults().Savings__c;
    insertpricebookEntries(savingsId);
    Test.startTest();
    CPQ_Lib_dh.SavingsLine cp = new CPQ_Lib_dh.SavingsLine();
    cp.amount = 100;
    SObject oli = cp.createLineItem('OpportunityLineItem');
    Test.stopTest();
    System.assertEquals(savingsId, cp.productId);
    System.assertEquals(18, cp.id.length());
    System.assertEquals(cp.amount, oli.get('UnitPrice'));
  }

  @isTest
  static void CPQ_SavingsProduct_From_OppLine_Test() {
    setupOpportunity(false);
    Id prodId = Utility_Products__c.getOrgDefaults().Savings__c;
    Factory_PricebookEntry.createAllDefaultEntriesEntries(prodId, 100);
    PricebookEntry pbe = [
      SELECT Id, UnitPrice
      FROM PricebookEntry
      WHERE Product2Id = :prodId AND Pricebook2Id = :opp.Pricebook2Id
      LIMIT 1
    ];
    OpportunityLineItem oli = Factory_OpportunityLineItem.buildLineItem(pbe, opp.Id, 1, null);
    insert oli;
    oli = [
      SELECT Id, PricebookEntry.Product2Id, Description, Quantity, UnitPrice
      FROM OpportunityLineItem
      WHERE Id = :oli.Id
    ];
    Test.startTest();
    CPQ_Lib_dh.SavingsLine cp = new CPQ_Lib_dh.SavingsLine(oli);
    System.assertEquals(oli.Id, cp.id);
    System.assertEquals(prodId, cp.productId);
    System.assertEquals(pbe.UnitPrice, cp.amount);
    Test.stopTest();
  }

  @isTest
  static void CPQ_SavingsProduct_From_QuoteLine_Test() {
    setupOpportunity(true);
    Id prodId = Utility_Products__c.getOrgDefaults().Savings__c;
    Factory_PricebookEntry.createAllDefaultEntriesEntries(prodId, 100);
    PricebookEntry pbe = [
      SELECT Id, UnitPrice
      FROM PricebookEntry
      WHERE Product2Id = :prodId AND Pricebook2Id = :opp.Pricebook2Id
      LIMIT 1
    ];
    QuoteLineItem qli = Factory_QuoteLineItem.buildLineItem(pbe, q.Id, 1, null);
    insert qli;
    qli = [
      SELECT Id, PricebookEntry.Product2Id, Description, Quantity, UnitPrice
      FROM QuoteLineItem
      WHERE Id = :qli.Id
    ];
    Test.startTest();
    CPQ_Lib_dh.SavingsLine cp = new CPQ_Lib_dh.SavingsLine(qli);
    System.assertEquals(qli.Id, cp.id);
    System.assertEquals(prodId, cp.productId);
    System.assertEquals(pbe.UnitPrice, cp.amount);
    Test.stopTest();
  }

  @isTest
  static void CPQ_OptionsWrapper() {
    List<CPQ_Lib_dh.OptionsWrapper> wrappers = new List<CPQ_Lib_dh.OptionsWrapper>();
    for (Integer i = 0; i < 10; i++) {
      CPQ_Lib_dh.OptionsWrapper w = new CPQ_Lib_dh.OptionsWrapper();
      w.family = 'test family ' + String.valueOf(i);
      wrappers.add(w);
    }
    wrappers.sort();
  }

  @isTest
  static void CPQ_TradeIn_SaveToOpp_Test() {
    setupOpportunity(false);
    Test.startTest();
    List<CPQ_Lib_dh.TradeInItem> tiItems = new List<CPQ_Lib_dh.TradeInItem>();
    for (Integer i = 0; i < 5; i++) {
      CPQ_Lib_dh.TradeInItem ti = new CPQ_Lib_dh.TradeInItem();
      ti.modelYear = 2019;
      ti.manufacturer = 'Test Boats';
      ti.model = 'Test Model';
      ti.serialNumber = 'TEST000SERIAL-' + String.valueOf(i);
      tiItems.add(ti);
    }
    CPQ_Lib_dh.TradeIn trade = new CPQ_Lib_dh.TradeIn();
    trade.value = 1000;
    trade.lien = 500;
    // should not save anything
    trade.save(opp.Id);
    Trade_In_Record__c[] tir_fail = [SELECT Id FROM Trade_In_Record__c WHERE Opportunity__c = :opp.Id];
    trade.items = tiItems;
    trade.save(opp.Id);
    Test.stopTest();
    Trade_In_Record__c[] tir_success = [
      SELECT Id, (SELECT Id, Model_Year__c, Model__c, Make__c, Serial_Number__c FROM Trade_In_Items__r)
      FROM Trade_In_Record__c
      WHERE Opportunity__c = :opp.Id
    ];
    CPQ_Lib_dh.TradeInItem tti = new CPQ_Lib_dh.TradeInItem(tir_success[0].Trade_In_Items__r[0]);
    System.assertEquals(0, tir_fail.size());
    System.assertEquals(1, tir_success.size());
    System.assertEquals(5, tir_success[0].Trade_In_Items__r.size());
    System.assertEquals(Integer.valueOf(tir_success[0].Trade_In_Items__r[0].Model_Year__c), tti.modelYear);
    System.assertEquals(tir_success[0].Trade_In_Items__r[0].Model__c, tti.model);
    System.assertEquals(tir_success[0].Trade_In_Items__r[0].Make__c, tti.manufacturer);
    System.assertEquals(tir_success[0].Trade_In_Items__r[0].Serial_Number__c, tti.serialNumber);
  }

  @isTest
  static void CPQ_TradeIn_SaveToQuote_Test() {
    setupOpportunity(true);
    Test.startTest();
    List<CPQ_Lib_dh.TradeInItem> tiItems = new List<CPQ_Lib_dh.TradeInItem>();
    for (Integer i = 0; i < 5; i++) {
      CPQ_Lib_dh.TradeInItem ti = new CPQ_Lib_dh.TradeInItem();
      ti.modelYear = 2019;
      ti.manufacturer = 'Test Boats';
      ti.model = 'Test Model';
      ti.serialNumber = 'TEST000SERIAL-' + String.valueOf(i);
      tiItems.add(ti);
    }
    CPQ_Lib_dh.TradeIn trade = new CPQ_Lib_dh.TradeIn();
    trade.value = 1000;
    trade.lien = 500;
    // should not save anything
    trade.save(q.Id);
    Trade_In_Record__c[] tir_fail = [SELECT Id FROM Trade_In_Record__c WHERE Opportunity__c = :opp.Id];
    trade.items = tiItems;
    trade.save(q.Id);
    Test.stopTest();
    Trade_In_Record__c[] tir_success = [
      SELECT Id, (SELECT Id, Model_Year__c, Model__c, Make__c, Serial_Number__c FROM Trade_In_Items__r)
      FROM Trade_In_Record__c
      WHERE Quote__c = :q.Id
    ];
    CPQ_Lib_dh.TradeInItem tti = new CPQ_Lib_dh.TradeInItem(tir_success[0].Trade_In_Items__r[0]);
    System.assertEquals(0, tir_fail.size());
    System.assertEquals(1, tir_success.size());
    System.assertEquals(5, tir_success[0].Trade_In_Items__r.size());
    System.assertEquals(Integer.valueOf(tir_success[0].Trade_In_Items__r[0].Model_Year__c), tti.modelYear);
    System.assertEquals(tir_success[0].Trade_In_Items__r[0].Model__c, tti.model);
    System.assertEquals(tir_success[0].Trade_In_Items__r[0].Make__c, tti.manufacturer);
    System.assertEquals(tir_success[0].Trade_In_Items__r[0].Serial_Number__c, tti.serialNumber);
  }

  @isTest
  static void CPQ_TradeIn_FromRecord_Test() {
    setupOpportunity(false);
    Trade_In_Record__c tr = new Trade_In_Record__c(
      Lien_Amount__c = 10000,
      Total_Value__c = 15000,
      Opportunity__c = opp.Id
    );
    insert tr;
    Trade_In_Item__c[] tis = new List<Trade_In_Item__c>();
    for (Integer i = 0; i < 3; i++) {
      tis.add(
        new Trade_in_item__c(
          Trade_in_Record__c = tr.Id,
          Model__c = 'Model' + String.valueOf(i),
          Make__c = 'Make' + String.valueOf(i),
          Model_Year__c = '2001'
        )
      );
    }
    insert tis;
    tr = [
      SELECT
        Id,
        Lien_Amount__c,
        Total_Value__c,
        (SELECT Id, Trade_In_Record__c, Make__c, Model__c, Model_Year__c, Serial_Number__c FROM Trade_In_Items__r)
      FROM Trade_In_Record__c
      WHERE Id = :tr.Id
    ];
    Test.startTest();
    CPQ_Lib_dh.TradeIn tradeIn = new CPQ_Lib_dh.TradeIn(tr);
    System.assertEquals(tr.Lien_Amount__c, tradeIn.lien);
    System.assertEquals(tr.Total_Value__c, tradeIn.value);
    System.assertEquals(3, tradeIn.items.size());
  }

  //Legacy found in Business office tools
  @isTest
  static void OptionWrapper_Test() {
    Product2 p = Factory_Product.createNonSerializedProduct('Part', 'Hardware');
    PricebookEntry pbe = Factory_PricebookEntry.createStandardEntry(p.Id, 10);
    pbe = [
      SELECT Id, Product2.Name, Product2Id, UnitPrice, Product2.isPrepayable__c
      FROM PricebookEntry
      WHERE Id = :pbe.Id
    ];
    CPQ_Lib_dh.OptionWrapper result = new CPQ_Lib_dh.OptionWrapper(pbe, 0, 6);

    System.assertEquals(p.Name, result.productName);
    System.assertEquals(p.Id, result.productId);
    System.assertEquals(pbe.UnitPrice, result.unitCost);
    System.assertEquals(pbe.Id, result.pricebookEntryId);
    System.assertEquals(false, result.isSelected);
    System.assertEquals(false, result.isCheckbox);
    System.assertEquals(0, result.standard);
    System.assertEquals(6, result.maximum);
    System.assertEquals(0, result.subOptions.size());
  }
}
