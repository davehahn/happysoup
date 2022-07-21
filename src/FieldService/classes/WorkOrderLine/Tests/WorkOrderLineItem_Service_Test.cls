/**
 * Created by dave on 2019-08-06.
 */

@IsTest
private class WorkOrderLineItem_Service_Test {
  static WorkOrder wo;
  static AcctSeed__Project__c erp;

  @TestSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void init() {
    Id pbId = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
    Account acct = Factory_Account.insertFullPersonAccount('Testy', 'McTesterson');
    TriggerBase.bypass('WorkOrder');
    wo = Factory_WorkOrder.createNew(acct.Id, pbId);
    TriggerBase.clearBypass('WorkOrder');
  }

  private static void createERP() {
    Boolean origTriggerState = gcProject.disableTrigger;
    gcProject.disableTrigger = true;
    erp = new AcctSeed__Project__c(Name = 'Test Project', Work_Order__c = wo.Id, AcctSeed__Account__c = wo.AccountId);
    insert erp;
    gcProject.disableTrigger = origTriggerState;
    wo.ERP_Order__c = erp.Id;
    update wo;
  }

  @IsTest
  static void createForRetailBoatSale_Test() {
    init();
    TriggerBase.bypass('WorkOrderLineItem');
    System.debug('WORKORDERID *********');
    System.debug(wo.Id);
    WorkOrderLineItem woli = WorkOrderLineItem_Service.createForRetailBoatSale(wo.Id);
    TriggerBase.clearBypass('WorkOrderLineItem');
    System.assertEquals(woli.WorkOrderId, wo.Id);
    System.assertEquals('Retail Sale', woli.Description);
  }

  @isTest
  static void createProjectTasks_Test() {
    init();
    createERP();
    Test.startTest();
    List<WorkOrderLineItem> wolis = Factory_WorkOrder.createLineItems(wo.Id, 3);
    Test.stopTest();
    List<AcctSeed__Project_Task__c> tasks = [
      SELECT Id
      FROM AcctSeed__Project_Task__c
      WHERE AcctSeed__Project__c = :erp.Id
    ];
    System.assertEquals(wolis.size(), tasks.size());
  }
}
