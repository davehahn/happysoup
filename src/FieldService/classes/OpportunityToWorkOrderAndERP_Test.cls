/**
 * Created by dave on 2019-08-22.
 */

@IsTest
private class OpportunityToWorkOrderAndERP_Test {
  static Opportunity opp;
  static Id pbId;
  static Account acct;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void init() {
    pbId = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
    acct = Factory_Account.insertFullPersonAccount('Testy', 'McTesterson');
    opp = Factory_Opportunity.insertOpportunityForBoatSale(pbId, acct);
  }

  private static void initInsuranceProds() {
    InsurancePlan__c plan = new InsurancePlan__c(Name = 'Test Plan', Profit_Percent__c = 75);
    insert plan;
    Product2 insuranceProd = Factory_Product.createInsuranceProduct(
      'Life Insurance Coverage',
      'Life',
      plan.Id,
      false,
      pbId
    );
    PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pbId AND Product2Id = :insuranceProd.Id];
    OpportunityLineItem oli = Factory_OpportunityLineItem.buildLineItem(pbe.Id, opp.Id, 100, 1, null);
    oli.Insurance_Rate__c = 5;
    insert oli;
  }

  private static void initProtectionAndServiceProds() {
    Product2 prod = Factory_Product.createNonSerializedProduct('Protection and Services', 'Extended Warranty');
    Factory_PricebookEntry.createStandardEntry(prod.Id, 100);
    PricebookEntry pbe = Factory_PricebookEntry.buildEntry(prod.Id, pbId, 100);
    insert pbe;
    insert Factory_OpportunityLineItem.buildLineItem(pbe.Id, opp.Id, 100, 1, null);
  }

  @IsTest
  static void stepOne_Test() {
    init();
    Test.startTest();
    new OpportunityToWorkOrderAndERP_Promise().executeStepOne(opp.Id);
    Test.stopTest();
    List<WorkOrder> workOrders = [SELECT Id, LocationId FROM WorkOrder WHERE Opportunity__c = :opp.Id];
    List<AcctSeed__Project__c> erps = [SELECT Id FROM AcctSeed__Project__c WHERE AcctSeed__Opportunity__c = :opp.Id];
    System.assertEquals(1, workOrders.size(), 'One Work Order should have been created');
    System.assert(workOrder.LocationId != null, 'WorkOrder Location should be populated');
    System.assertEquals(1, erps.size(), 'One ERP should have been created');
  }

  @IsTest
  static void stepTwo_Test() {
    init();
    Id woId = OpportunityToWorkOrderAndERP_Promise.stepOne(opp.Id);
    Test.startTest();
    new OpportunityToWorkOrderAndERP_Promise().executeStepTwo(woId);
    Test.stopTest();
    List<WorkOrderLineItem> wolis = [SELECT Id FROM WorkOrderLineItem WHERE WorkOrderId = :woId];
    List<AcctSeed__Project_Task__c> tasks = [
      SELECT Id
      FROM AcctSeed__Project_Task__c
      WHERE Work_Order_Line_Item__c = :wolis[0].Id
    ];
    System.assertEquals(1, wolis.size(), 'One Work Order Line Item should have been created');
    System.assertEquals(1, tasks.size(), 'One Erp Order Task should have been created');
  }

  @IsTest
  static void stepThree_Test() {
    init();
    Id woId = OpportunityToWorkOrderAndERP_Promise.stepOne(opp.Id);
    Id woliId = OpportunityToWorkOrderAndERP_Promise.stepTwo(woId);
    Test.startTest();
    new OpportunityToWorkOrderAndERP_Promise().executeStepThree(woliId);
    Test.stopTest();
    OpportunityLineItem[] olis = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
    ProductRequired[] prs = [SELECT Id FROM ProductRequired WHERE ParentRecordId = :woliId];
    AcctSeedERP__Material__c[] mats = [
      SELECT Id
      FROM AcctSeedERP__Material__c
      WHERE AcctSeedERP__Project__r.Work_Order__c = :woId
    ];
    System.assertEquals(olis.size(), prs.size());
    System.assertEquals(olis.size(), mats.size());
  }

  @IsTest
  static void stepThree_withInsuranceTest() {
    init();
    initInsuranceProds();
    Id woId = OpportunityToWorkOrderAndERP_Promise.stepOne(opp.Id);
    Id woliId = OpportunityToWorkOrderAndERP_Promise.stepTwo(woId);
    Test.startTest();
    new OpportunityToWorkOrderAndERP_Promise().executeStepThree(woliId);
    Test.stopTest();
    WorkOrder wo = [SELECT Id, ERP_Order__c FROM WorkOrder WHERE Id = :woId];
    OpportunityLineItem[] olis = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
    ProductRequired[] prs = [SELECT Id FROM ProductRequired WHERE ParentRecordId = :woliId];
    AcctSeedERP__Material__c[] mats = [
      SELECT Id
      FROM AcctSeedERP__Material__c
      WHERE AcctSeedERP__Project__r.Work_Order__c = :woId
    ];
    AcctSeed__Project_Task__c[] tasks = [
      SELECT Id
      FROM AcctSeed__Project_Task__c
      WHERE AcctSeed__Project__c = :wo.ERP_Order__c
    ];
    System.assertEquals((olis.size() - 1), prs.size());
    System.assertEquals(olis.size(), mats.size());
    System.assertEquals(2, tasks.size());
  }

  @IsTest
  static void stepThree_withProtectionAndServicesTest() {
    init();
    initProtectionAndServiceProds();
    Id woId = OpportunityToWorkOrderAndERP_Promise.stepOne(opp.Id);
    Id woliId = OpportunityToWorkOrderAndERP_Promise.stepTwo(woId);
    Test.startTest();
    new OpportunityToWorkOrderAndERP_Promise().executeStepThree(woliId);
    Test.stopTest();
    WorkOrder wo = [SELECT Id, ERP_Order__c FROM WorkOrder WHERE Id = :woId];
    OpportunityLineItem[] olis = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
    ProductRequired[] prs = [SELECT Id FROM ProductRequired WHERE ParentRecordId = :woliId];
    AcctSeedERP__Material__c[] mats = [
      SELECT Id
      FROM AcctSeedERP__Material__c
      WHERE AcctSeedERP__Project__r.Work_Order__c = :woId
    ];
    AcctSeed__Project_Task__c[] tasks = [
      SELECT Id
      FROM AcctSeed__Project_Task__c
      WHERE AcctSeed__Project__c = :wo.ERP_Order__c
    ];
    System.assertEquals((olis.size() - 1), prs.size());
    System.assertEquals(olis.size(), mats.size());
    System.assertEquals(2, tasks.size());
  }

  @IsTest
  static void stepThree_withEverythingTest() {
    init();
    initInsuranceProds();
    initProtectionAndServiceProds();
    Id woId = OpportunityToWorkOrderAndERP_Promise.stepOne(opp.Id);
    Id woliId = OpportunityToWorkOrderAndERP_Promise.stepTwo(woId);
    Test.startTest();
    new OpportunityToWorkOrderAndERP_Promise().executeStepThree(woliId);
    Test.stopTest();
    WorkOrder wo = [SELECT Id, ERP_Order__c FROM WorkOrder WHERE Id = :woId];
    OpportunityLineItem[] olis = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
    ProductRequired[] prs = [SELECT Id FROM ProductRequired WHERE ParentRecordId = :woliId];
    AcctSeedERP__Material__c[] mats = [
      SELECT Id
      FROM AcctSeedERP__Material__c
      WHERE AcctSeedERP__Project__r.Work_Order__c = :woId
    ];
    AcctSeed__Project_Task__c[] tasks = [
      SELECT Id
      FROM AcctSeed__Project_Task__c
      WHERE AcctSeed__Project__c = :wo.ERP_Order__c
    ];
    System.assertEquals((olis.size() - 2), prs.size());
    System.assertEquals(olis.size(), mats.size());
    System.assertEquals(3, tasks.size());
  }
}
