/**
 * Created by dave on 2021-06-08.
 */

@IsTest
private class WorkOrderLineItem_Automation_T {
  private static WorkOrder wo;
  private static AcctSeed__Project__c erp;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Id pbId = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
    Account acct = Factory_Account.insertFullPersonAccount('Testy', 'McTesterson');
    TriggerBase.bypass('WorkOrder');
    WorkOrder wo = Factory_WorkOrder.createNew(acct.Id, pbId);
    AcctSeed__Project__c erp = new AcctSeed__Project__c(
      Name = (wo.Account.Name + ' - ' + String.valueOf(wo.WorkOrderNumber)).LEFT(80),
      AcctSeed__Account__c = wo.AccountId,
      Work_Order__c = wo.Id
    );
    gcProject.disableTrigger = true;
    insert erp;
    wo.ERP_Order__c = erp.Id;
    update wo;
    TriggerBase.clearBypass('WorkOrder');
  }

  private static void createWoliAndTask() {
    TriggerBase.bypass('WorkOrderLineItem');
    AcctSeed__Project_Task__c orderTask = Factory_ERPOrderTask.buildProjectTask(erp.Id, 'WOLI Unit Test');
    WorkOrderLineItem woli = Factory_WorkOrder.createLineItems(wo.Id, 1)[0];
    orderTask.Work_Order_Line_Item__c = woli.Id;
    insert orderTask;
    woli.ERP_Order_Task__c = orderTask.Id;
    update woli;
    TriggerBase.clearBypass('WorkOrderLineItem');
  }

  private static void fetchWorkOrder() {
    wo = [SELECT Id, ERP_Order__c, (SELECT Id FROM WorkOrderLineItems) FROM WorkOrder LIMIT 1];
  }

  private static void fetchErpOrder() {
    erp = [SELECT Id, (SELECT Id FROM AcctSeed__Project_Tasks__r) FROM AcctSeed__Project__c LIMIT 1];
  }

  @IsTest
  static void afterInsert_Test() {
    fetchWorkOrder();
    Test.startTest();
    WorkOrderLineItem woli = Factory_WorkOrder.createLineItems(wo.Id, 1)[0];
    Test.stopTest();

    List<AcctSeed__Project_Task__c> orderTasks = [
      SELECT Id
      FROM AcctSeed__Project_Task__c
      WHERE AcctSeed__Project__c = :wo.ERP_Order__c
    ];

    woli = [SELECT Id, ERP_Order_Task__c FROM WorkOrderLineItem WHERE Id = :woli.Id];

    System.assertEquals(1, orderTasks.size());
    System.assert(woli.ERP_Order_Task__c != null);
  }

  @IsTest
  static void beforeDelete_Test() {
    fetchWorkOrder();
    fetchErpOrder();
    createWoliAndTask();
    fetchWorkOrder();
    fetchErpOrder();

    System.assertEquals(1, wo.WorkOrderLineItems.size());
    System.assertEquals(1, erp.AcctSeed__Project_Tasks__r.size());

    Test.startTest();
    delete wo.WorkOrderLineItems[0];
    Test.stopTest();

    fetchWorkOrder();
    fetchErpOrder();

    System.assertEquals(0, wo.WorkOrderLineItems.size());
    System.assertEquals(0, erp.AcctSeed__Project_Tasks__r.size());
  }
}
