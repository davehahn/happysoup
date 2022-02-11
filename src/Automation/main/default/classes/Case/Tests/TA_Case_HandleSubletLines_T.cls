/**
 * Created by dave on 2022-01-05.
 */

@IsTest
private class TA_Case_HandleSubletLines_T {
  static final Integer SUBLET_PRICE = 400;
  static final String SUBLET_COMPANY = 'AngrySlothBrewing';

  private static List<Case> cases;
  private static List<Case> oldList;
  private static AcctSeed__Project__c erp;
  private static AcctSeed__Project_Task__c task;
  private static AcctSeedERP__Material__c material;
  private static Account dealer;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void init() {
    dealer = AccountFactory.buildDealerAccount('Testy McDealer');
    insert dealer;
    cases = new List<Case>();
    buildERP();
  }

  private static void initForUpdate( String newCompany, Integer newPrice){
    createSubletMaterial();
    Case c = Factory_Case.buildWarrantyCase(dealer);
    c.Warranty_ERP__c = erp.Id;
    c.Sublet_Company__c = SUBLET_COMPANY;
    c.Sublet_Price__c = SUBLET_PRICE;
    c.Id = TestUtility.getFakeId(Case.SObjectType);

    Case oldC = c.clone(true,true,true,true);
    oldList = new List<Case>{oldC};

    c.Sublet_Company__c = newCompany;
    c.Sublet_Price__c = newPrice;
    cases.add(c);
  }

  private static void buildERP() {
    Id erpRtId = new Application_RecordType().getERPOrderRecordTypes().getWarrantyId();
    erp = new AcctSeed__Project__c(
      RecordTypeId = erpRtId,
      Name = dealer.Name.trim(),
      AcctSeed__Status__c = 'Active',
      AcctSeed__Account__c = dealer.Id
    );
    TriggerBase.bypass('AcctSeed__Project__c');
    insert erp;
    TriggerBase.clearBypass('AcctSeed__Project__c');
    String tn = '%' + ProjectTask_Service.warrantyPayableTaskName + '%';
    task = Factory_ERPOrderTask.buildProjectTask( erp.Id, tn );
    TriggerBase.bypass('AcctSeed__Project_Task__c');
    insert task;
    TriggerBase.clearBypass('AcctSeed__Project_Task__c');
  }

  private static void createSubletMaterial(){
    material = new AcctSeedERP__Material__c(
      AcctSeedERP__Product__c = Utility_Products__c.getOrgDefaults().Sublet__c,
      AcctSeedERP__Quantity_Per_Unit__c = 1,
      AcctSeedERP__Project__c = erp.Id,
      AcctSeedERP__Project_Task__c = task.Id,
      GMBLASERP__Unit_Price__c = SUBLET_PRICE,
      GMBLASERP__Price_Override__c = true,
      AcctSeedERP__Comment__c = SUBLET_COMPANY
    );
    TriggerBase.bypass('AcctSeedERP__Material__c');
    insert material;
    TriggerBase.clearBypass('AcctSeedERP__Material__c');
  }

  @IsTest
  static void TA_afterInsert() {
    init();
    Case c = Factory_Case.buildWarrantyCase(dealer);
    c.Warranty_ERP__c = erp.Id;
    c.Sublet_Company__c = SUBLET_COMPANY;
    c.Sublet_Price__c = SUBLET_PRICE;
    cases.add(c);

    Test.startTest();
    new TA_Case_HandleSubletLines().afterInsert(cases);
    Test.stopTest();

    AcctSeedERP__Material__c[] mats = [
      SELECT Id, AcctSeedERP__Comment__c, GMBLASERP__Unit_Price__c
      FROM AcctSeedERP__Material__c
      WHERE AcctSeedERP__Project__c = :c.Warranty_ERP__c
    ];
    System.assertEquals(1, mats.size());
    //will be negative do to a warrantyERP changing all values to negative
    System.assertEquals(-400, mats[0].GMBLASERP__Unit_Price__c);
    System.assertEquals('AngrySlothBrewing', mats[0].AcctSeedERP__Comment__c);
  }

  @IsTest
  static void TA_afterUpdate_change(){
    init();
    initForUpdate( 'BadAssBrewing', 800 );

    Test.startTest();
    new TA_Case_HandleSubletLines().afterUpdate( cases, oldList );
    Test.stopTest();

    material = [
      SELECT Id, AcctSeedERP__Comment__c, GMBLASERP__Unit_Price__c
      FROM AcctSeedERP__Material__c
      WHERE Id = :material.Id
    ];

    System.assertEquals(-800, material.GMBLASERP__Unit_Price__c);
    System.assertEquals('BadAssBrewing', material.AcctSeedERP__Comment__c);
  }

  @IsTest
  static void TA_afterUpdate_remove()
  {
    init();
    initForUpdate(null, null);

    Test.startTest();
    new TA_Case_HandleSubletLines().afterUpdate(cases, oldList);
    Test.stopTest();

    List<AcctSeedERP__Material__c> mats = [SELECT Id FROM AcctSeedERP__Material__c WHERE AcctSeedERP__Project__c = :erp.Id];
    System.assertEquals( 0, mats.size() );
  }

  }
