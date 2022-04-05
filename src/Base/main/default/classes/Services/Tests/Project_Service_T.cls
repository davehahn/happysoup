/**
 * Created by dave on 2020-01-21.
 */

@IsTest
private class Project_Service_T {
  private static final Integer recordCount = 3;
  private static final Date deliveryDate = Date.today().addDays(10);
  private static Product2 boat;
  private static List<AcctSeed__Project__c> retailERPs;
  private static List<AcctSeed__Project__c> partnerERPs;
  private static Map<Id, AcctSeedERP__Purchase_Order_Line__c> pol_by_linkedPartnerERPid;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    buildOpp();
    initPartnerRetailPOLStuff();
  }

  private static void buildOpp() {
    Account customer = Factory_Account.buildFullPersonAccount('TestF', 'TestL');
    insert customer;
    Factory_Opportunity.insertOpportunityForBoatSale(LGND_Constants.retailPricebookId, customer);
  }

  private static void addBusinessOfficeItems(Opportunity opp) {
    InsurancePlan__c plan = new InsurancePlan__c(Name = 'Insurance Plan One', Profit_Percent__c = 50);
    insert plan;
    Set<Id> prodIds = new Set<Id>();
    prodIds.add(
      Factory_Product.createInsuranceProduct(
          'Life Insurance Coverage',
          'Life (One)',
          plan.Id,
          false,
          LGND_Constants.retailPricebookId
        )
        .Id
    );
    prodIds.add(
      Factory_Product.createInsuranceProduct(
          'Life Insurance Coverage',
          'Life (Two)',
          plan.Id,
          false,
          LGND_Constants.retailPricebookId
        )
        .Id
    );
    Product2 warranty = Factory_Product.buildNonSerializedProduct('Part', 'Extended Warranty');
    insert warranty;
    prodIds.add(warranty.Id);
    Factory_PricebookEntry.createStandardEntry(warranty.Id, 100);
    Factory_PricebookEntry.createStandardEntryInPricebook(warranty.Id, opp.Pricebook2Id, 100);

    List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
    for (PricebookEntry pbe : [
      SELECT Id, Product2Id
      FROM PricebookEntry
      WHERE Pricebook2Id = :opp.Pricebook2Id AND Product2Id IN :prodIds
    ]) {
      OpportunityLineItem oli = Factory_OpportunityLineItem.buildLineItem(pbe.Id, opp.Id, 1000, 1, null);
      if (pbe.Product2Id != warranty.Id) {
        oli.Insurance_Rate__c = 6;
        oli.InsuranceCoverage__c = 'Single';
      }
      olis.add(oli);
    }
    insert olis;
  }

  private static void initPartnerRetailPOLStuff() {
    createERPs();
    createPO_and_POLs();
  }

  private static void fetchPartnerRetailPOLStuff() {
    Application_RecordType.ERPOrderRTs rts = new Application_RecordType().getERPOrderRecordTypes();
    List<AcctSeed__Project__c> erps = [
      SELECT Id, RecordTypeId, Arrival_Date__c, Retail_ERP__c
      FROM AcctSeed__Project__c
    ];
    partnerERPs = new List<AcctSeed__Project__c>();
    Set<Id> partnerIds = new Set<Id>();
    retailERPs = new List<AcctSeed__Project__c>();
    for (AcctSeed__Project__c erp : erps) {
      if (erp.RecordTypeId == rts.getRetailBoatSaleId()) {
        retailERPs.add(erp);
      }
      if (erp.RecordTypeId == rts.getPartnerBoatSaleId()) {
        partnerERPs.add(erp);
        partnerIds.add(erp.Id);
      }
    }

    pol_by_linkedPartnerERPid = new Map<Id, AcctSeedERP__Purchase_Order_Line__c>();
    List<AcctSeedERP__Purchase_Order_Line__c> pols = [
      SELECT Id, deliverDate__c, AcctSeedERP__Project__c
      FROM AcctSeedERP__Purchase_Order_Line__c
      WHERE AcctSeedERP__Project__C IN :partnerIds
    ];
    for (AcctSeedERP__Purchase_Order_Line__c pol : pols) {
      pol_by_linkedPartnerERPid.put(pol.AcctSeedERP__Project__c, pol);
    }
  }

  private static void createERPs() {
    Account dealer = Factory_Account.insertDealerAccounts(1)[0];
    List<Account> customers = Factory_Account.insertCustomerAccounts(recordCount);
    boat = Factory_Product.createSerializedProduct('Boat', 'Pontoon');
    partnerERPs = Factory_ERPOrder.createPartnerBoatSales(dealer, new List<Product2>{ boat }, recordCount);
    Id retailRtId = new Application_RecordType().getERPOrderRecordTypes().getRetailBoatSaleId();
    retailERPs = new List<AcctSeed__Project__c>();
    for (Account acct : customers) {
      retailERPs.add(Factory_ERPOrder.buildERP(acct, null, retailRtId));
    }
    retailERPs[0].Arrival_Date__c = deliveryDate;
    insert retailERPs;
    for (Integer i = 0; i < recordCount; i++) {
      partnerERPs[i].Retail_ERP__c = retailERPs[i].Id;
    }
    update partnerERPs;
  }

  private static void createPO_and_POLs() {
    Account vendor = Factory_Account.insertSupplierAccounts(1)[0];
    Set<Id> partnerERPids = new Set<Id>();
    for (AcctSeed__Project__c erp : partnerERPs) {
      partnerERPids.add(erp.Id);
    }
    partnerERPs = [
      SELECT Id, (SELECT Id FROM AcctSeed__Project_Tasks__r)
      FROM AcctSeed__Project__c
      WHERE Id IN :partnerERPids
    ];
    AcctSeedERP__Purchase_Order__c po = Factory_PurchaseOrder.createMinimalPO(vendor.Id, null);
    pol_by_linkedPartnerERPid = new Map<Id, AcctSeedERP__Purchase_Order_Line__c>();
    for (AcctSeed__Project__c erp : partnerERPs) {
      AcctSeedERP__Purchase_Order_Line__c pol = Factory_PurchaseOrder.buildLineItem(po.Id, boat.Id, 1);
      pol.AcctSeedERP__Project__c = erp.Id;
      pol.AcctSeedERP__Project_Task__c = erp.AcctSeed__Project_Tasks__r[0].Id;
      pol.deliverDate__c = deliveryDate;
      pol_by_linkedPartnerERPid.put(erp.Id, pol);
    }
    gcPurchaseOrderLine.disableTrigger = true;
    insert pol_by_linkedPartnerERPid.values();
  }

  @IsTest
  static void newFromOpportunityId_SimpleTest() {
    Opportunity opp = [SELECT Id, Pricebook2Id FROM Opportunity LIMIT 1];
    Test.startTest();
    AcctSeed__Project__c project = Project_Service.newFromOpportunityId(opp.Id);
    Test.stopTest();
    checkResults(project.Id, 3, 9, 0);
  }

  @IsTest
  static void newFromOpportunityId_wTradeInTest() {
    Opportunity opp = [SELECT Id, Pricebook2Id FROM Opportunity LIMIT 1];
    Factory_TradeIn.insertTradeInRecordWithItems(opp.Id, 3);
    Test.startTest();
    AcctSeed__Project__c project = Project_Service.newFromOpportunityId(opp.Id);
    Test.stopTest();
    checkResults(project.Id, 3, 11, 0);
  }

  @IsTest
  static void newFromOpportunityId_wInsuranceTest() {
    Opportunity opp = [SELECT Id, Pricebook2Id FROM Opportunity LIMIT 1];
    addBusinessOfficeItems(opp);
    Test.startTest();
    AcctSeed__Project__c project = Project_Service.newFromOpportunityId(opp.Id);
    Test.stopTest();
    checkResults(project.Id, 3, 9, 3);
  }

  @IsTest
  static void handlePartnerToRetailBoatSaleLinkChanges_linkCreateSimulate_Test() {
    fetchPartnerRetailPOLStuff();
    List<AcctSeed__Project__c> listNew = new List<AcctSeed__Project__c>();
    Map<Id, AcctSeed__Project__c> oldMap = new Map<Id, AcctSeed__Project__c>();

    AcctSeed__Project__c partnerERP = [
      SELECT Id, Retail_ERP__c, RecordTypeId
      FROM AcctSeed__Project__c
      WHERE Id = :partnerERPs[1].Id
    ];

    partnerERP.Retail_ERP__c = retailERPs[1].Id;
    listNew.add(partnerERP);

    Test.startTest();
    Project_Service.handlePartnerToRetailBoatSaleLinkChanges(listNew, oldMap);
    Test.stopTest();

    AcctSeed__Project__c retailERP = [
      SELECT Id, Arrival_Date__c
      FROM AcctSeed__Project__c
      WHERE Id = :retailERPs[1].Id
    ];

    System.assertEquals(deliveryDate, retailERP.Arrival_Date__c, 'Arrival Date should now be set on Retail ERP');
  }

  @IsTest
  static void handlePartnerToRetailBoatSaleLinkChanges_unlinkSimulate_Test() {
    fetchPartnerRetailPOLStuff();
    List<AcctSeed__Project__c> listNew = new List<AcctSeed__Project__c>();
    Map<Id, AcctSeed__Project__c> oldMap = new Map<Id, AcctSeed__Project__c>();

    oldMap.put(partnerERPs[0].Id, partnerERPs[0]);

    AcctSeed__Project__c partnerERP = [
      SELECT Id, Retail_ERP__c, RecordTypeId
      FROM AcctSeed__Project__c
      WHERE Id = :partnerERPs[0].Id
    ];
    partnerERP.Retail_ERP__c = null;
    listNew.add(partnerERP);

    Test.startTest();
    Project_Service.handlePartnerToRetailBoatSaleLinkChanges(listNew, oldMap);
    Test.stopTest();

    AcctSeed__Project__c retailERP = [
      SELECT Id, Arrival_Date__c
      FROM AcctSeed__Project__c
      WHERE Id = :retailERPs[0].Id
    ];

    System.assertEquals(null, retailERP.Arrival_Date__c, 'Arrival Date should now be null on Retail ERP');
  }

  @IsTest
  static void handlePartnerToRetailBoatSaleLinkChanges_linkChangeSimulate_Test() {
    fetchPartnerRetailPOLStuff();
    List<AcctSeed__Project__c> listNew = new List<AcctSeed__Project__c>();
    Map<Id, AcctSeed__Project__c> oldMap = new Map<Id, AcctSeed__Project__c>();

    AcctSeed__Project__c partnerERP = [
      SELECT Id, Retail_ERP__c, RecordTypeId
      FROM AcctSeed__Project__c
      WHERE Id = :partnerERPs[1].Id
    ];

    partnerERP.Retail_ERP__c = retailERPs[1].Id;
    retailERPs[1].Arrival_Date__c = deliveryDate;
    gcProject.disableTrigger = true;
    update new List<AcctSeed__Project__c>{ partnerERP, retailERPs[1] };

    oldMap.put(partnerERP.Id, partnerERP);

    AcctSeed__Project__c partnerERPnew = [
      SELECT Id, Retail_ERP__c, RecordTypeId
      FROM AcctSeed__Project__c
      WHERE Id = :partnerERP.Id
    ];

    partnerERPnew.Retail_ERP__c = retailERPs[2].Id;
    listNew.add(partnerERPnew);

    Test.startTest();
    Project_Service.handlePartnerToRetailBoatSaleLinkChanges(listNew, oldMap);
    Test.stopTest();

    AcctSeed__Project__c retailERP1 = [
      SELECT Id, Arrival_Date__c
      FROM AcctSeed__Project__c
      WHERE Id = :retailERPs[1].Id
    ];

    AcctSeed__Project__c retailERP2 = [
      SELECT Id, Arrival_Date__c
      FROM AcctSeed__Project__c
      WHERE Id = :retailERPs[2].Id
    ];

    System.assertEquals(null, retailERP1.Arrival_Date__c, 'Arrival Date should now be null on Retail ERP 1');

    System.assertEquals(deliveryDate, retailERP2.Arrival_Date__c, 'Arrival Date should now be set on Retail ERP 2');
  }

  @IsTest
  static void createFlexibleAccessoryCreditProjects_Test() {
    Id retailBoatSaleId = RetailBoatSaleFunded_TestHelper.testDataCreate();
    AcctSeed__Project__c boatSale = [
      SELECT Id, Name, AcctSeed__Account__c, Serial_Number__c, Boat_Specialist__c, AcctSeedERP__Work_Order_Number__c
      FROM AcctSeed__Project__c
      WHERE Id = :retailBoatSaleId
    ];

    Test.startTest();
    TriggerBase.bypass('AcctSeed__Project__c');
    TriggerBase.bypass('AcctSeed__Project_Task__c');
    TriggerBase.bypass('AcctSeedERP__Material__c');
    Project_Service.createFlexibleAccessoryCreditProjects(new Set<Id>{ retailBoatSaleId });
    TriggerBase.clearAllBypasses();
    Test.stopTest();

    AcctSeed__Project__c[] result = [
      SELECT
        Id,
        Salesperson__c,
        OwnerId,
        AcctSeed__Account__c,
        Serial_Number__c,
        (SELECT Id, Correction_dh__c FROM AcctSeed__Project_Tasks__r),
        (SELECT Id, AcctSeedERP__Product__c, GMBLASERP__Unit_Price__c, AcctSeedERP__Quantity_Per_Unit__c FROM AcctSeedERP__Project_Materials__r)
      FROM AcctSeed__Project__c
      WHERE Id != :retailBoatSaleId AND AcctSeed__Account__c = :boatSale.AcctSeed__Account__c
    ];

    System.assertEquals(1, result.size());
    System.assertEquals(boatSale.AcctSeed__Account__c, result[0].AcctSeed__Account__c);
    System.assertEquals(boatSale.Boat_Specialist__c, result[0].Salesperson__c);
    System.assertEquals(boatSale.Boat_Specialist__c, result[0].OwnerId);
    System.assertEquals(boatSale.Serial_Number__c, result[0].Serial_Number__c);
    System.assertEquals(1, result[0].AcctSeed__Project_Tasks__r.size());
    System.assert(result[0].AcctSeed__Project_Tasks__r[0].Correction_dh__c.contains(boatSale.AcctSeedERP__Work_Order_Number__c));
    System.assertEquals(1, result[0].AcctSeedERP__Project_Materials__r.size());
    System.assertEquals(
      Application_Constants.getInstance().utilityProducts.getFlexibleAccessoriesCredit(),
      result[0].AcctSeedERP__Project_Materials__r[0].AcctSeedERP__Product__c
    );
    System.assertEquals(1, result[0].AcctSeedERP__Project_Materials__r[0].AcctSeedERP__Quantity_Per_Unit__c);
    System.assertEquals(
      RetailBoatSaleFunded_TestHelper.ACCESSORY_CREDIT_AMOUNT,
      result[0].AcctSeedERP__Project_Materials__r[0].GMBLASERP__Unit_Price__c
    );
  }

  private static void checkResults(
    Id projectId,
    Integer taskSize,
    Integer retailSaleMatSize,
    Integer businessOfficeMatSize
  ) {
    List<AcctSeed__Project_Task__c> tasks = [
      SELECT Id, Name
      FROM AcctSeed__Project_Task__c
      WHERE AcctSeed__Project__c = :projectId
    ];
    AcctSeed__Project_Task__c retailSale;
    AcctSeed__Project_Task__c businessOffice;
    for (AcctSeed__Project_Task__c pt : tasks) {
      if (pt.Name.contains('Retail Sale'))
        retailSale = pt;
      if (pt.Name.contains('Business Office'))
        businessOffice = pt;
    }
    System.debug(businessOffice);
    for (AcctSeedERP__Material__c m : [
      SELECT Id, AcctSeedERP__Project_Task__r.Name
      FROM AcctSeedERP__Material__c
      WHERE AcctSeedERP__Project__c = :projectId
    ]) {
      System.debug(m.AcctSeedERP__Project_Task__r.Name);
    }
    List<AcctSeedERP__Material__c> retailMaterials = [
      SELECT Id
      FROM AcctSeedERP__Material__c
      WHERE AcctSeedERP__Project_Task__c = :retailSale.Id
    ];
    List<AcctSeedERP__Material__c> boMaterials = [
      SELECT Id
      FROM AcctSeedERP__Material__c
      WHERE AcctSeedERP__Project_Task__c = :businessOffice.Id
    ];

    System.assertEquals(taskSize, tasks.size(), 'There should be 3 Project Tasks');
    System.assertEquals(retailSaleMatSize, retailMaterials.size(), 'There should be 9 Retail Sales materials');
    System.assertEquals(businessOfficeMatSize, boMaterials.size(), 'There should be 2 Business Office materials');
  }
}
