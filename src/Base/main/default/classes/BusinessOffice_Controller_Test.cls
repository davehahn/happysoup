@isTest
private class BusinessOffice_Controller_Test {
  static Opportunity opp;
  static AcctSeed__Project__c erp;
  static AcctSeed__Project_task__c orderTask;
  static Account personAccount;
  static Pricebook2 customPb;
  static Account[] finAccounts;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void init() {
    Application_RecordType art = new Application_RecordType();
    Id salesRtId = art.getPricebookRecordTypes().getSalesId();
    customPb = new Pricebook2(
      Name = 'CustomPb',
      isActive = true,
      RecordTypeId = salesRtId,
      Sales_Year__c = String.valueOf(Date.today().year()),
      Version__c = 2
    );
    insert customPb;
    personAccount = AccountFactory.insertPersonAccount();
  }

  private static void oppInit() {
    if( customPb == null ) {
      init();
    }
    finAccounts = Factory_Account.insertFinancialInstitutions(7);
    OpportunityTriggerHandler.disableAutoPricebookSet = true;
    opp = OpportunityFactory.buildBasicRetail(personAccount.Id);
    OpportunityTriggerHandler.disableAutoPricebookSet = true;
    opp.Financing_Account__c = finAccounts[0].Id;
    insert opp;
    opp.Pricebook2Id = customPb.Id;
    update opp;
  }

  private static void erpInit() {
    if( customPb == null ) {
      init();
    }
    GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertFullSerial(
      'Boat',
      'Pontoon',
      '1234567890'
    );
    erp = Factory_ERPOrder.buildERP(
      personAccount,
      serial.Id,
      gcConstants.idRtProjectBoatSale
    );
    erp.GMBLASERP__Pricebook__c = customPb.Id;
    gcProject.disableTrigger = true;
    insert erp;
  }

  /* ++++++++++++++++++ PPSA TESTS ************************* */

  static Product2 ppsaProduct;
  static Id ppsaPricebookEntryId;
  static OpportunityLineItem ppsa_oli;
  static AcctSeedERP__Material__c ppsa_mat;
  static Decimal ppsaCost = 200;

  private static void init4opp(Boolean createPPSA_line) {
    oppInit();
    if (createPPSA_line) {
      ppsa_oli = new OpportunityLineItem(
        OpportunityId = opp.Id,
        PricebookEntryId = ppsaPricebookEntryId,
        UnitPrice = ppsaCost,
        Quantity = 1
      );
      insert ppsa_oli;
    }
  }

  private static void init4erp(Boolean createPPSA) {
    erpInit();
    if (createPPSA) {
      orderTask = Factory_ERPOrder.buildProjectTask(erp.Id, 'Business Office');
      orderTask.AcctSeed__GL_Account_Variable_2__c = LGND_Constants.GLV2Id_BusinessOffice;
      insert orderTask;
      ppsa_mat = new AcctSeedERP__Material__c(
        AcctSeedERP__Project__c = erp.Id,
        AcctSeedERP__Project_Task__c = orderTask.Id,
        AcctSeedERP__Product__c = ppsaProduct.Id,
        GMBLASERP__Unit_Price__c = ppsaCost,
        GMBLASERP__Price_Override__c = true,
        AcctSeedERP__Quantity_Per_Unit__c = 1
      );
      insert ppsa_mat;
    }
  }

  private static void ppsaTestInit() {
    if( customPb == null ) {
      init();
    }
    ppsaProduct = Factory_Product.createPPSA(customPb.Id);
    ppsaPricebookEntryId = [
      SELECT Id
      FROM PricebookEntry
      WHERE Product2Id = :ppsaProduct.Id AND Pricebook2Id = :customPb.Id
      LIMIT 1
    ]
    .Id;
  }

  @isTest
  static void toolInitialize_opp_Test() {
    init4opp(false);
    String resultJSON = BusinessOffice_Controller.toolInitialize(opp.Id);
    Map<String, String> result = (Map<String, String>) JSON.deserialize(
      resultJSON,
      Map<String, String>.class
    );
    System.assertEquals(customPb.Id, result.get('Id'));
    System.assertEquals('Opportunity', result.get('sObjectType'));
  }

  @isTest
  static void toolInitialize_erp_Test() {
    init4erp(false);
    String resultJSON = BusinessOffice_Controller.toolInitialize(erp.Id);
    Map<String, String> result = (Map<String, String>) JSON.deserialize(
      resultJSON,
      Map<String, String>.class
    );
    System.assertEquals(customPb.Id, result.get('Id'));
    System.assertEquals('AcctSeed__Project__c', result.get('sObjectType'));
  }

  @isTest
  static void ppsa_int_opp_without_PPSA_Line_Test() {
    init4opp(false);
    ppsaTestInit();
    String jsonResult = BusinessOffice_Controller.ppsa_init(
      opp.Id,
      customPb.Id
    );
    Map<String, String> result = (Map<String, String>) JSON.deserialize(
      jsonResult,
      Map<String, String>.class
    );
    System.assertEquals(ppsaPricebookEntryId, result.get('pricebookEntryId'));
    System.assertEquals(null, result.get('ppsa_id'));
    System.assertEquals(null, result.get('ppsa_value'));
  }

  @isTest
  static void ppsa_int_erp_without_PPSA_Line_Test() {
    init4erp(false);
    ppsaTestInit();
    String jsonResult = BusinessOffice_Controller.ppsa_init(
      erp.Id,
      customPb.Id
    );
    Map<String, String> result = (Map<String, String>) JSON.deserialize(
      jsonResult,
      Map<String, String>.class
    );
    System.assertEquals(ppsaPricebookEntryId, result.get('pricebookEntryId'));
    System.assertEquals(null, result.get('ppsa_id'));
    System.assertEquals(null, result.get('ppsa_value'));
  }

  @isTest
  static void ppsa_int_opp_with_PPSA_Line_Test() {
    Test.startTest();
    ppsaTestInit();
    init4opp(true);
    Test.stopTest();
    String jsonResult = BusinessOffice_Controller.ppsa_init(
      opp.Id,
      customPb.Id
    );
    Map<String, String> result = (Map<String, String>) JSON.deserialize(
      jsonResult,
      Map<String, String>.class
    );
    System.assertEquals(ppsaPricebookEntryId, result.get('pricebookEntryId'));
    System.assertEquals(ppsa_oli.Id, result.get('ppsa_id'));
    System.assertEquals(ppsaCost, Decimal.valueOf(result.get('ppsa_value')));
  }

  @isTest
  static void ppsa_int_erp_with_PPSA_Line_Test() {
    Test.startTest();
    ppsaTestInit();
    init4erp(true);
    Test.stopTest();
    String jsonResult = BusinessOffice_Controller.ppsa_init(
      erp.Id,
      customPb.Id
    );
    Map<String, String> result = (Map<String, String>) JSON.deserialize(
      jsonResult,
      Map<String, String>.class
    );
    System.assertEquals(ppsaPricebookEntryId, result.get('pricebookEntryId'));
    System.assertEquals(ppsa_mat.Id, result.get('ppsa_id'));
    System.assertEquals(ppsaCost, Decimal.valueOf(result.get('ppsa_value')));
  }

  @isTest
  static void savePPSALine_new_opp_Test() {
    Test.startTest();
    ppsaTestInit();
    init4opp(false);
    String jsonResult = BusinessOffice_Controller.savePPSALine(
      null,
      String.valueOf(ppsaCost),
      String.valueOf(opp.Id),
      String.valueOf(ppsaPricebookEntryId)
    );
    Map<String, String> result = (Map<String, String>) JSON.deserialize(
      jsonResult,
      Map<String, String>.class
    );
    OpportunityLineItem[] olis = [
      SELECT Id
      FROM OpportunityLineItem
      WHERE OpportunityId = :opp.Id AND PricebookEntryId = :ppsaPricebookEntryId
    ];
    Test.stopTest();

    System.assertEquals(1, olis.size());
    System.assertEquals(olis[0].Id, result.get('ppsa_id'));
    System.assertEquals(ppsaCost, Decimal.valueOf(result.get('ppsa_value')));
  }

  @isTest
  static void savePPSALine_new_erp_Test() {
    Test.startTest();
    ppsaTestInit();
    init4erp(false);
    String jsonResult = BusinessOffice_Controller.savePPSALine(
      null,
      String.valueOf(ppsaCost),
      String.valueOf(erp.Id),
      String.valueOf(ppsaPricebookEntryId)
    );
    Map<String, String> result = (Map<String, String>) JSON.deserialize(
      jsonResult,
      Map<String, String>.class
    );
    AcctSeedERP__Material__c[] mats = [
      SELECT Id
      FROM AcctSeedERP__Material__c
      WHERE
        AcctSeedERP__Project__c = :erp.Id
        AND AcctSeedERP__Product__c = :ppsaProduct.Id
    ];
    Test.stopTest();

    System.assertEquals(1, mats.size());
    System.assertEquals(mats[0].Id, result.get('ppsa_id'));
    System.assertEquals(ppsaCost, Decimal.valueOf(result.get('ppsa_value')));
  }

  @isTest
  static void savePPSALine_update_opp_Test() {
    Test.startTest();
    ppsaTestInit();
    init4opp(true);

    String jsonResult = BusinessOffice_Controller.savePPSALine(
      String.valueOf(ppsa_oli.Id),
      String.valueOf(500),
      String.valueOf(opp.Id),
      String.valueOf(ppsaPricebookEntryId)
    );
    Map<String, String> result = (Map<String, String>) JSON.deserialize(
      jsonResult,
      Map<String, String>.class
    );
    OpportunityLineItem[] olis = [
      SELECT Id
      FROM OpportunityLineItem
      WHERE OpportunityId = :opp.Id AND PricebookEntryId = :ppsaPricebookEntryId
    ];
    Test.stopTest();

    System.assertEquals(1, olis.size());
    System.assertEquals(olis[0].Id, result.get('ppsa_id'));
    System.assertEquals(500, Decimal.valueOf(result.get('ppsa_value')));
  }

  @isTest
  static void savePPSALine_update_erp_Test() {
    Test.startTest();
    ppsaTestInit();
    init4erp(true);
    String jsonResult = BusinessOffice_Controller.savePPSALine(
      String.valueOf(ppsa_mat.Id),
      String.valueOf(500),
      String.valueOf(erp.Id),
      String.valueOf(ppsaPricebookEntryId)
    );
    Map<String, String> result = (Map<String, String>) JSON.deserialize(
      jsonResult,
      Map<String, String>.class
    );
    AcctSeedERP__Material__c[] mats = [
      SELECT Id
      FROM AcctSeedERP__Material__c
      WHERE
        AcctSeedERP__Project__c = :erp.Id
        AND AcctSeedERP__Product__c = :ppsaProduct.Id
    ];
    Test.stopTest();

    System.assertEquals(1, mats.size());
    System.assertEquals(mats[0].Id, result.get('ppsa_id'));
    System.assertEquals(500, Decimal.valueOf(result.get('ppsa_value')));
  }

  @isTest
  static void savePPSALine_delete_opp_Test() {
    Test.startTest();
    ppsaTestInit();
    init4opp(true);
    String jsonResult = BusinessOffice_Controller.savePPSALine(
      String.valueOf(ppsa_oli.Id),
      String.valueOf(0),
      String.valueOf(opp.Id),
      String.valueOf(ppsaPricebookEntryId)
    );
    Map<String, String> result = (Map<String, String>) JSON.deserialize(
      jsonResult,
      Map<String, String>.class
    );
    OpportunityLineItem[] olis = [
      SELECT Id
      FROM OpportunityLineItem
      WHERE OpportunityId = :opp.Id AND PricebookEntryId = :ppsaPricebookEntryId
    ];
    Test.stopTest();

    System.assertEquals(0, olis.size());
    System.assertEquals(null, result.get('ppsa_id'));
    System.assertEquals(null, result.get('ppsa_value'));
  }

  @isTest
  static void savePPSALine_delete_erp_Test() {
    Test.startTest();
    ppsaTestInit();
    init4erp(true);
    String jsonResult = BusinessOffice_Controller.savePPSALine(
      String.valueOf(ppsa_mat.Id),
      String.valueOf(0),
      String.valueOf(erp.Id),
      String.valueOf(ppsaPricebookEntryId)
    );
    Map<String, String> result = (Map<String, String>) JSON.deserialize(
      jsonResult,
      Map<String, String>.class
    );
    AcctSeedERP__Material__c[] mats = [
      SELECT Id
      FROM AcctSeedERP__Material__c
      WHERE
        AcctSeedERP__Project__c = :erp.Id
        AND AcctSeedERP__Product__c = :ppsaProduct.Id
    ];
    Test.stopTest();

    System.assertEquals(0, mats.size());
    System.assertEquals(null, result.get('ppsa_id'));
    System.assertEquals(null, result.get('ppsa_value'));
  }

  /* =========================== PPSA TESTS ========================= */

  /* +++++++++++++++++++++++++ FINANCING INSTITUTION TESTS ++++++++++ */

  @isTest
  static void fetchFinancialInstitutionOptions_Test() {
    oppInit();

    String jsonResult = BusinessOffice_Controller.fetchFinancialInstitutionOptions(
      opp.Id
    );
    BusinessOffice_Controller.FinancingInstitutionDetails result = (BusinessOffice_Controller.FinancingInstitutionDetails) JSON.deserialize(
      jsonResult,
      BusinessOffice_Controller.FinancingInstitutionDetails.class
    );
    //List<String> fi_opts = LGND_Utilities.getPicklistValues('Opportunity', 'Financing_Institution__c');
    System.assertEquals(finAccounts.size(), result.options.size());
    System.assertEquals(finAccounts[0].Id, result.value);
  }

  @isTest
  static void updateFinancialInstitution_Test() {
    oppInit();
    //List<String> fi_opts = LGND_Utilities.getPicklistValues('Opportunity', 'Financing_Institution__c');
    BusinessOffice_Controller.updateFinancialInstitution(
      opp.Id,
      finAccounts[1].Id
    );
    opp = [SELECT Id, Financing_Account__c FROM Opportunity WHERE Id = :opp.Id];
    System.assertEquals(finAccounts[1].Id, opp.Financing_Account__c);
  }

  /* ========================= FINANCING INSTITUTION TESTS ========== */

  /* +++++++++++++++++++++++++++ INSURANCE TESTS ++++++++++++++++++++ */

  static InsurancePlan__c[] insurancePlans;
  static Map<Id, List<Product2>> insuranceProductsByPlanId;

  private static void insuranceInit4opp(List<Product2> insuranceProducts) {
    oppInit();
    if (insuranceProducts != null && insuranceProducts.size() > 0) {
      Set<Id> pIds = LGND_Utilities.getIdSetFromList(
        (List<sObject>) insuranceProducts
      );
      PricebookEntry[] pbes = [
        SELECT Id
        FROM PricebookEntry
        WHERE Product2Id IN :pIds AND Pricebook2Id = :customPb.Id
      ];
      OpportunityLineItem[] olis = new List<OpportunityLineItem>();
      for (PricebookEntry pbe : pbes) {
        olis.add(
          new OpportunityLineItem(
            OpportunityId = opp.Id,
            Insurance_Rate__c = 6,
            InsuranceCoverage__c = 'Single',
            PricebookEntryId = pbe.Id,
            UnitPrice = 100,
            Quantity = 1
          )
        );
      }
      insert olis;
    }
  }

  private static void insuranceInit4erp(List<Product2> insuranceProducts) {
    erpInit();
    if (insuranceProducts != null && insuranceProducts.size() > 0) {
      orderTask = Factory_ERPOrder.buildProjectTask(erp.Id, 'Business Office');
      orderTask.AcctSeed__GL_Account_Variable_2__c = LGND_Constants.GLV2Id_BusinessOffice;
      orderTask.isInsurance__c = true;
      insert orderTask;
      AcctSeedERP__Material__c[] mats = new List<AcctSeedERP__Material__c>();
      for (Product2 p : insuranceProducts) {
        mats.add(
          new AcctSeedERP__Material__c(
            AcctSeedERP__Project__c = erp.Id,
            AcctSeedERP__Project_Task__c = orderTask.Id,
            AcctSeedERP__Product__c = p.Id,
            GMBLASERP__Unit_Price__c = 100,
            GMBLASERP__Price_Override__c = true,
            Insurance_Rate__c = 6,
            Insurance_Coverage__c = 'Single',
            AcctSeedERP__Quantity_Per_Unit__c = 1
          )
        );
      }
      insert mats;
    }
  }

  private static void insuranceTestInit() {
    if( customPb == null ) {
      init();
    }
    insuranceProductsByPlanId = new Map<Id, List<Product2>>();
    insurancePlans = new List<InsurancePlan__c>();
    insurancePlans.add(
      new InsurancePlan__c(Name = 'Insurance Plan One', Profit_Percent__c = 50)
    );
    insurancePlans.add(
      new InsurancePlan__c(Name = 'Insurance Plan Two', Profit_Percent__c = 50)
    );
    insert insurancePlans;
    insuranceProductsByPlanId.put(insurancePlans[0].Id, new List<Product2>());
    insuranceProductsByPlanId.put(insurancePlans[1].Id, new List<Product2>());
    insuranceProductsByPlanId.get(insurancePlans[0].Id)
      .add(
        Factory_Product.createInsuranceProduct(
          'Life Insurance Coverage',
          'Life (One)',
          insurancePlans[0].Id,
          false,
          customPb.Id
        )
      );
    insuranceProductsByPlanId.get(insurancePlans[0].Id)
      .add(
        Factory_Product.createInsuranceProduct(
          'Life Insurance Coverage',
          'Life Residual (One)',
          insurancePlans[0].Id,
          true,
          customPb.Id
        )
      );
    insuranceProductsByPlanId.get(insurancePlans[1].Id)
      .add(
        Factory_Product.createInsuranceProduct(
          'Life Insurance Coverage',
          'Life (Two)',
          insurancePlans[1].Id,
          false,
          customPb.Id
        )
      );
    insuranceProductsByPlanId.get(insurancePlans[1].Id)
      .add(
        Factory_Product.createInsuranceProduct(
          'Life Insurance Coverage',
          'Life Residual (Two)',
          insurancePlans[1].Id,
          true,
          customPb.Id
        )
      );
  }

  @isTest
  static void insurance_init_opp_Test() {
    insuranceTestInit();
    insuranceInit4opp(insuranceProductsByPlanId.get(insurancePlans[0].Id));
    String jsonResult = BusinessOffice_Controller.insurance_init(opp.Id);
    BusinessOffice_Controller.InsuranceInitWrapper result = (BusinessOffice_Controller.InsuranceInitWrapper) JSON.deserialize(
      jsonResult,
      BusinessOffice_Controller.InsuranceInitWrapper.class
    );
    System.assertEquals(insurancePlans.size(), result.plans.size());
    System.assertEquals(insurancePlans[0].Id, result.planId);
    System.assertEquals(
      insuranceProductsByPlanId.get(insurancePlans[0].Id).size(),
      result.selectedItems.size()
    );
  }

  @isTest
  static void insurance_init_erp_Test() {
    insuranceTestInit();
    insuranceInit4erp(insuranceProductsByPlanId.get(insurancePlans[0].Id));
    String jsonResult = BusinessOffice_Controller.insurance_init(erp.Id);
    BusinessOffice_Controller.InsuranceInitWrapper result = (BusinessOffice_Controller.InsuranceInitWrapper) JSON.deserialize(
      jsonResult,
      BusinessOffice_Controller.InsuranceInitWrapper.class
    );
    System.assert(result.plans.size() >= 2);
    System.assertEquals(insurancePlans[0].Id, result.planId);
    System.assertEquals(
      insuranceProductsByPlanId.get(insurancePlans[0].Id).size(),
      result.selectedItems.size()
    );
  }

  @isTest
  static void fetchInsurancePlanOptions_null_Test() {
    init();
    String result = BusinessOffice_Controller.fetchInsurancePlanOptions(
      null,
      customPb.Id
    );
    System.assertEquals(null, result);
  }

  @isTest
  static void fetchInsurancePlanOptions_Test() {
    insuranceTestInit();
    String jsonResult = BusinessOffice_Controller.fetchInsurancePlanOptions(
      insurancePlans[0].Id,
      customPb.Id
    );
    List<BusinessOffice_Controller.insurancePlanWrapper> planOptions = (List<BusinessOffice_Controller.insurancePlanWrapper>) JSON.deserialize(
      jsonResult,
      List<BusinessOffice_Controller.insurancePlanWrapper>.class
    );
    System.assertEquals(1, planOptions.size());
    System.assertEquals('Life Insurance Coverage', planOptions[0].groupName);
    System.assertEquals(2, planOptions[0].planItems.size());
  }

  @isTest
  static void saveInsuranceItems_new_opp_Test() {
    Test.startTest();
    insuranceTestInit();
    insuranceInit4opp(null);
    List<BusinessOffice_Controller.SelectedInsuranceItem> items = new List<BusinessOffice_Controller.SelectedInsuranceItem>();
    Set<Id> pIds = LGND_Utilities.getIdSetFromList(
      (List<sObject>) insuranceProductsByPlanId.get(insurancePlans[0].Id)
    );
    PricebookEntry[] pbes = [
      SELECT Id, Product2Id, Product2.Is_Residual_Insurance__c
      FROM PricebookEntry
      WHERE Product2Id IN :pIds AND Pricebook2Id = :customPb.Id
    ];
    for (PricebookEntry pbe : pbes) {
      BusinessOffice_Controller.SelectedInsuranceItem item = new BusinessOffice_Controller.SelectedInsuranceItem();
      item.recordId = null;
      item.pricebookEntryId = pbe.Id;
      item.productId = pbe.Product2Id;
      item.coverage = 'Single';
      item.insuranceRate = 6;
      item.isResidual = pbe.Product2.Is_Residual_Insurance__c;
      item.unitPrice = 100;
      items.add(item);
    }
    BusinessOffice_Controller.saveInsuranceItems(
      opp.Id,
      JSON.serialize(items),
      new List<String>()
    );
    OpportunityLineItem[] olis = [
      SELECT Id
      FROM OpportunityLineItem
      WHERE OpportunityId = :opp.Id
    ];
    Test.stopTest();
    System.assertEquals(items.size(), olis.size());
  }

  @isTest
  static void saveInsuranceItems_delete_opp_Test() {
    Test.startTest();
    insuranceTestInit();
    insuranceInit4opp(insuranceProductsByPlanId.get(insurancePlans[0].Id));
    OpportunityLineItem[] olis = [
      SELECT
        Id,
        PricebookEntryId,
        PricebookEntry.Product2Id,
        PricebookEntry.Product2.Is_Residual_Insurance__c,
        Insurance_Rate__c,
        InsuranceCoverage__c,
        UnitPrice,
        Quantity
      FROM OpportunityLineItem
      WHERE OpportunityId = :opp.Id
    ];
    List<BusinessOffice_Controller.SelectedInsuranceItem> items = new List<BusinessOffice_Controller.SelectedInsuranceItem>();
    BusinessOffice_Controller.SelectedInsuranceItem item = new BusinessOffice_Controller.SelectedInsuranceItem();
    item.recordId = olis[0].Id;
    item.pricebookEntryId = olis[0].PricebookEntryId;
    item.productId = olis[0].PricebookEntry.Product2Id;
    item.coverage = olis[0].InsuranceCoverage__c;
    item.insuranceRate = olis[0].Insurance_Rate__c;
    item.isResidual = olis[0].PricebookEntry.Product2.Is_Residual_Insurance__c;
    item.unitPrice = 10000;
    items.add(item);
    List<String> toDelete = new List<String>();
    toDelete.add(String.valueOf(olis[1].Id));
    BusinessOffice_Controller.saveInsuranceItems(
      opp.Id,
      JSON.serialize(items),
      toDelete
    );
    olis = [
      SELECT Id, unitPrice
      FROM OpportunityLineItem
      WHERE OpportunityId = :opp.Id
    ];
    Test.stopTest();
    System.assertEquals(items.size(), olis.size());
    System.assertEquals(10000, olis[0].unitPrice);
  }

  @isTest
  static void saveInsuranceItems_new_erp_Test() {
    Test.startTest();
    insuranceTestInit();
    insuranceInit4erp(null);
    List<BusinessOffice_Controller.SelectedInsuranceItem> items = new List<BusinessOffice_Controller.SelectedInsuranceItem>();
    for (Product2 p : insuranceProductsByPlanId.get(insurancePlans[0].Id)) {
      BusinessOffice_Controller.SelectedInsuranceItem item = new BusinessOffice_Controller.SelectedInsuranceItem();
      item.recordId = null;
      item.productId = p.Id;
      item.coverage = 'Single';
      item.insuranceRate = 6;
      item.isResidual = p.Is_Residual_Insurance__c;
      item.unitPrice = 100;
      items.add(item);
    }
    BusinessOffice_Controller.saveInsuranceItems(
      erp.Id,
      JSON.serialize(items),
      new List<String>()
    );
    AcctSeedERP__Material__c[] mats = [
      SELECT Id
      FROM AcctSeedERP__Material__c
      WHERE AcctSeedERP__Project__c = :erp.Id
    ];
    Test.stopTest();
    System.assertEquals(items.size(), mats.size());
  }

  @isTest
  static void saveInsuranceItems_delete_erp_Test() {
    Test.startTest();
    insuranceTestInit();
    insuranceInit4erp(insuranceProductsByPlanId.get(insurancePlans[0].Id));
    List<BusinessOffice_Controller.SelectedInsuranceItem> items = new List<BusinessOffice_Controller.SelectedInsuranceItem>();
    AcctSeedERP__Material__c[] mats = [
      SELECT
        Id,
        AcctSeedERP__Product__c,
        AcctSeedERP__Product__r.Is_Residual_Insurance__c,
        Insurance_Rate__c,
        Insurance_Coverage__c,
        GMBLASERP__Unit_Price__c,
        GMBLASERP__Price_Override__c,
        AcctSeedERP__Quantity_per_Unit__c
      FROM AcctSeedERP__Material__c
      WHERE AcctSeedERP__Project__c = :erp.Id
    ];

    BusinessOffice_Controller.SelectedInsuranceItem item = new BusinessOffice_Controller.SelectedInsuranceItem();
    item.recordId = mats[0].Id;
    item.productId = mats[0].AcctSeedERP__Product__c;
    item.coverage = mats[0].Insurance_Coverage__c;
    item.insuranceRate = mats[0].Insurance_Rate__c;
    item.isResidual = mats[0].AcctSeedERP__Product__r.Is_Residual_Insurance__c;
    item.unitPrice = 10000;
    items.add(item);
    List<String> toDelete = new List<String>();
    toDelete.add(String.valueOf(mats[1].Id));
    BusinessOffice_Controller.saveInsuranceItems(
      erp.Id,
      JSON.serialize(items),
      toDelete
    );
    mats = [
      SELECT Id, GMBLASERP__Unit_Price__c
      FROM AcctSeedERP__Material__c
      WHERE AcctSeedERP__Project__c = :erp.Id
    ];
    Test.stopTest();
    System.assertEquals(items.size(), mats.size());
    System.assertEquals(10000, mats[0].GMBLASERP__Unit_Price__c);
  }

  /* ========================== INSURANCE TESTS ===================== */

  /* ++++++++++++++++++++++++++ SERVICE AND WARRANTY TESTS ++++++++++ */

  static Product2 boat;
  static Product2 part;
  static Product2[] serviceProducts;
  static Product2[] warrantyProducts;

  private static void serviceAndWarrantyInit() {
    if( customPb == null ) {
      init();
    }
    insertProducts();
    insertPricebookEntries(Test.getStandardPricebookId());
    insertPricebookEntries(customPb.Id);
    insertProductOptions();
  }

  private static BusinessOffice_Controller.WarrantyAndServiceInitWrapper serviceAndWarrantyInit_opp(
    Boolean addLine
  ) {
    oppInit();
    PricebookEntry boatPbe = [
      SELECT Id, UnitPrice
      FROM PricebookEntry
      WHERE Product2Id = :boat.Id AND Pricebook2Id = :customPb.Id
    ];

    OpportunityLineItem[] olis = new List<OpportunityLineItem>();
    olis.add(
      new OpportunityLineItem(
        OpportunityId = opp.Id,
        PricebookEntryId = boatPbe.Id,
        UnitPrice = boatPbe.UnitPrice,
        Quantity = 1
      )
    );
    if (addLine) {
      PricebookEntry pbe = [
        SELECT Id, UnitPrice
        FROM PricebookEntry
        WHERE
          Product2Id = :serviceProducts[0].Id
          AND Pricebook2Id = :customPb.Id
      ];
      olis.add(
        new OpportunityLineItem(
          OpportunityId = opp.Id,
          PricebookEntryId = pbe.Id,
          UnitPrice = pbe.UnitPrice,
          Quantity = 1
        )
      );
    }
    insert olis;
    String jsonResult = BusinessOffice_Controller.initServiceAndWarranty(
      opp.Id,
      customPb.Id
    );
    return (BusinessOffice_Controller.WarrantyAndServiceInitWrapper) JSON.deserialize(
      jsonResult,
      BusinessOffice_Controller.WarrantyAndServiceInitWrapper.class
    );
  }

  private static BusinessOffice_Controller.WarrantyAndServiceInitWrapper serviceAndWarrantyInit_erp() {
    erpInit();
    orderTask = Factory_ERPOrder.buildProjectTask(erp.Id, 'Oppy Line Items');
    insert orderTask;
    PricebookEntry boatPbe = [
      SELECT Id, UnitPrice
      FROM PricebookEntry
      WHERE Product2Id = :boat.Id AND Pricebook2Id = :customPb.Id
    ];
    AcctSeedERP__Material__c mat = new AcctSeedERP__Material__c(
      AcctSeedERP__Project__c = erp.Id,
      AcctSeedERP__Project_Task__c = orderTask.Id,
      AcctSeedERP__Product__c = boat.Id,
      GMBLASERP__Unit_Price__c = boatPbe.UnitPrice,
      GMBLASERP__Price_Override__c = true,
      AcctSeedERP__Quantity_Per_Unit__c = 1
    );
    insert mat;
    String jsonResult = BusinessOffice_Controller.initServiceAndWarranty(
      erp.Id,
      customPb.Id
    );
    return (BusinessOffice_Controller.WarrantyAndServiceInitWrapper) JSON.deserialize(
      jsonResult,
      BusinessOffice_Controller.WarrantyAndServiceInitWrapper.class
    );
  }

  private static void insertProducts() {
    boat = Factory_Product.buildSerializedProduct('Boat', 'Pontoon');
    part = Factory_Product.buildNonSerializedProduct('Part', 'Electronics');
    serviceProducts = Factory_Product.buildNonSerializedProducts(
      'Protection and Services',
      'Maintenance Package',
      5
    );
    warrantyProducts = Factory_Product.buildNonSerializedProducts(
      'Protection and Services',
      'Extended Warranty',
      5
    );
    Product2[] allprods = new List<Product2>();
    allProds.add(boat);
    allProds.add(part);
    allProds.addAll(serviceProducts);
    allProds.addAll(warrantyProducts);
    Boolean orig = gcProduct.disableTrigger;
    gcProduct.disableTrigger = true;
    insert allProds;
    gcProduct.disableTrigger = orig;
  }

  private static void insertPricebookEntries(Id pricebookId) {
    PricebookEntry[] pbes = new List<PricebookEntry>();
    pbes.add(Factory_PricebookEntry.buildEntry(boat.Id, pricebookId, 10000));
    for (Product2 p : serviceProducts) {
      pbes.add(Factory_PricebookEntry.buildEntry(p.Id, pricebookId, 100));
    }
    for (Product2 p : warrantyProducts) {
      pbes.add(Factory_PricebookEntry.buildEntry(p.Id, pricebookId, 100));
    }
    insert pbes;
  }

  private static void insertProductOptions() {
    Product_Option__c[] opts = new List<Product_Option__c>();
    opts.addAll(
      Factory_ProductOption.buildProductOptions(boat.Id, serviceProducts, 0, 1)
    );
    opts.addAll(
      Factory_ProductOption.buildProductOptions(boat.Id, warrantyProducts, 0, 1)
    );
    opts.add(
      Factory_ProductOption.buildProductOption(
        warrantyProducts[0].Id,
        part.Id,
        0,
        1
      )
    );
    insert opts;
  }

  @isTest
  static void initServiceAndWarranty_opp_Test() {
    serviceAndWarrantyInit();
    BusinessOffice_Controller.WarrantyAndServiceInitWrapper result = serviceAndWarrantyInit_opp(
      false
    );

    System.assertEquals(serviceProducts.size(), result.service.size());
    System.assertEquals(warrantyProducts.size(), result.warranty.size());
    System.assertEquals(0, result.selectedLineIds.size());
  }

  @isTest
  static void initServiceAndWarrantyWithLineItem_opp_Test() {
    serviceAndWarrantyInit();
    BusinessOffice_Controller.WarrantyAndServiceInitWrapper result = serviceAndWarrantyInit_opp(
      true
    );

    System.assertEquals(serviceProducts.size(), result.service.size());
    System.assertEquals(warrantyProducts.size(), result.warranty.size());
    System.assertEquals(1, result.selectedLineIds.size());
  }

  @isTest
  static void saveWarrantyAndServiceLines_opp_Test() {
    serviceAndWarrantyInit();
    BusinessOffice_Controller.WarrantyAndServiceInitWrapper result = serviceAndWarrantyInit_opp(
      false
    );
    result.service[0].quantitySelected = 1;
    result.warranty[0].quantitySelected = 1;
    List<CPQ_Lib_dh.OptionWrapper> items = new List<CPQ_Lib_dh.OptionWrapper>();
    items.add(result.service[0]);
    items.add(result.warranty[0]);
    BusinessOffice_Controller.saveWarrantyAndServiceLines(
      opp.Id,
      JSON.serialize(items),
      new List<String>()
    );
    OpportunityLineItem[] olis = [
      SELECT Id
      FROM OpportunityLineItem
      WHERE OpportunityId = :opp.Id
    ];
    System.assertEquals(3, olis.size());
  }

  @isTest
  static void initServiceAndWarranty_erp_Test() {
    serviceAndWarrantyInit();
    BusinessOffice_Controller.WarrantyAndServiceInitWrapper result = serviceAndWarrantyInit_erp();

    System.assertEquals(serviceProducts.size(), result.service.size());
    System.assertEquals(warrantyProducts.size(), result.warranty.size());
  }

  @isTest
  static void saveWarrantyAndServiceLines_erp_Test() {
    serviceAndWarrantyInit();
    BusinessOffice_Controller.WarrantyAndServiceInitWrapper result = serviceAndWarrantyInit_erp();
    List<CPQ_Lib_dh.OptionWrapper> items = new List<CPQ_Lib_dh.OptionWrapper>();
    items.add(result.service[0]);
    items.add(result.warranty[0]);
    BusinessOffice_Controller.saveWarrantyAndServiceLines(
      erp.Id,
      JSON.serialize(items),
      new List<String>()
    );
    AcctSeedERP__Material__c[] mats = [
      SELECT Id
      FROM AcctSeedERP__Material__c
      WHERE AcctSeedERP__Project__c = :erp.Id
    ];
    System.assertEquals(3, mats.size());
  }

  /* ========================= SERVICE AND WARRANTY TESTS ========== */

  @isTest
  static void calculateInsurancePremiums_Recursive_Test() {
    Decimal expetedResult = 329.52; //calculated using spreadsheet provided by insurance co
    List<Map<String, String>> lineData = new List<Map<String, String>>();
    Map<String, String> line = new Map<String, String>();
    line.put('recordId', 'testId');
    line.put('isResidual', 'false');
    line.put('insuranceRate', '5');
    lineData.add(line);

    Map<String, Decimal> result = BusinessOffice_Controller.calculateInsurancePremiums(
      lineData,
      10000,
      0,
      60,
      120,
      5,
      8
    );
    System.assertEquals(expetedResult, result.get('testId'));
  }

  @isTest
  static void calculateInsurancePremiums_Recursive_ZeroInterest_Test() {
    Decimal testIdResult = 220.15; //calculated using spreadsheet provided by insurance co
    Decimal residualIdResult = 226.94; //calculated using spreadsheet provided by insurance co
    //non-residual line
    List<Map<String, String>> lineData = new List<Map<String, String>>();
    Map<String, String> line = new Map<String, String>();
    line.put('recordId', 'testId');
    line.put('isResidual', 'false');
    line.put('insuranceRate', '4.2');
    lineData.add(line);
    //residual line
    line = new Map<String, String>();
    line.put('recordId', 'residualId');
    line.put('isResidual', 'true');
    line.put('insuranceRate', '4.33');
    lineData.add(line);

    Map<String, Decimal> result = BusinessOffice_Controller.calculateInsurancePremiums(
      lineData,
      10000,
      0,
      60,
      120,
      0,
      8
    );
    System.assertEquals(testIdResult, result.get('testId'));
    System.assertEquals(residualIdResult, result.get('residualId'));
  }

  /* ========================= INSURANCE TESTS ========== */

  @isTest
  static void fetchInsurancePlanItem_Test() {
    AcctSeed__Accounting_Variable__c taxZone = [
      SELECT Id
      FROM AcctSeed__Accounting_Variable__c
      WHERE Name = 'Quebec'
    ];
    //Id rt = LGND_Utilities.recordTypeIdFromName('Product2', 'Insurance' );
    insert Factory_Product.buildNonSerializedProduct(
      'Insurance',
      'Life Insurance Coverage'
    );
    Product2 insProd = [
      SELECT Id
      FROM Product2
      WHERE Family = 'Life Insurance Coverage'
      LIMIT 1
    ];
    String resultString = BusinessOffice_Controller.fetchInsurancePlanItem(
      insProd.Id,
      taxZone.Id
    );
    Product2 item = (Product2) JSON.deserialize(resultString, Product2.class);
    System.assert(item != null);
  }
}
