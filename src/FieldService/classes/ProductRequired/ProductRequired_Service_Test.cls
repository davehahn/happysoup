/**
 * Created by dave on 2019-08-07.
 */

@IsTest
private class ProductRequired_Service_Test {
  static Account acct;
  static Opportunity opp;
  static WorkOrder wo;
  static WorkOrderLineItem woli;
  static AcctSeed__Project__c erp;
  static List<ProductRequired> requiredProducts;

  @TestSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void init() {
    Id pbId = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
    acct = Factory_Account.insertFullPersonAccount('Testy', 'McTesterson');
    opp = Factory_Opportunity.insertOpportunityForBoatSale(pbId, acct);
    TriggerBase.bypass('WorkOrder');
    wo = Factory_WorkOrder.createNew(acct.Id, pbId);
    TriggerBase.clearBypass('WorkOrder');
    woli = new WorkOrderLineItem(WorkOrderId = wo.Id, Description = 'Retail Sale From Opportunity');
    TriggerBase.bypass('WorkOrderLineItem');
    insert woli;
    TriggerBase.clearBypass('WorkOrderLineItem');
  }

  private static void initERP() {
    GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertFullSerial('Boat', 'Full Windshield', '123TEST987');
    String boatSaleRtId = String.valueOf(
      LGND_Utilities.recordTypeIdFromName('AcctSeed__Project__c', 'Retail Boat Sale')
    );
    erp = Factory_ERPOrder.buildERP(acct, serial.Id, boatSaleRtId);
    erp.Work_Order__c = wo.Id;
    Boolean orig = gcProject.disableTrigger;
    gcProject.disableTrigger = true;
    insert erp;
    gcProject.disableTrigger = orig;
    TriggerBase.bypass('WorkOrder');
    wo.ERP_Order__c = erp.Id;
    update wo;
    TriggerBase.clearBypass('WorkOrder');
    AcctSeed__Project_Task__c task = Factory_ERPOrder.buildProjectTask(erp.Id, 'Test Task');
    task.Work_Order_Line_Item__c = woli.Id;
    orig = gcProjectTask.disableTrigger;
    gcProjectTask.disableTrigger = true;
    insert task;
    gcProjectTask.disableTrigger = orig;
    TriggerBase.bypass('WorkOrderLineItem');
    woli.ERP_Order_Task__c = task.Id;
    update woli;
    TriggerBase.clearBypass('WorkOrderLineItem');
  }

  private static void initProductRequired() {
    Product2[] parts = Factory_Product.buildNonSerializedProducts('Part', 'Electronics', 10);
    insert parts;
    requiredProducts = new List<ProductRequired>();
    for (Product2 p : parts) {
      requiredProducts.add(new ProductRequired(ParentRecordId = woli.Id, Product2Id = p.Id, QuantityRequired = 1));
    }
    insert requiredProducts;
  }

  @IsTest
  static void createERP_Materials_Test() {
    init();
    initERP();
    Test.startTest();
    initProductRequired();
    Test.stopTest();
    AcctSeedERP__Material__c[] mats = [SELECT Id FROM AcctSeedERP__Material__c WHERE AcctSeedERP__Project__c = :erp.Id];
    System.assertEquals(requiredProducts.size(), mats.size());
  }
}
