/**
 * Created by dave on 2021-06-09.
 */

@IsTest
private class ServiceAppointment_Automation_T {
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Id pbId = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
    Account acct = Factory_Account.insertFullPersonAccount('Testy', 'McTesterson');
    TriggerBase.bypass('WorkOrder');
    Factory_WorkOrder.createNew(acct.Id, pbId);
    TriggerBase.clearBypass('WorkOrder');
  }

  private static WorkOrder fetchWorkOrder() {
    return [SELECT Id, WorkOrderNumber FROM WorkOrder LIMIT 1];
  }

  @IsTest
  static void afterInsert() {
    WorkOrder wo = fetchWorkOrder();
    ServiceAppointment sa = Factory_ServiceAppointment.buildForWorkOrder(wo);

    Test.startTest();
    insert sa;
    Test.stopTest();

    sa = [SELECT Id, FSL__GanttLabel__c FROM ServiceAppointment WHERE Id = :sa.Id];

    System.assertEquals(wo.WorkOrderNumber, sa.FSL__GanttLabel__c);
  }

  @IsTest
  static void afterInsert_Bypassed() {
    WorkOrder wo = fetchWorkOrder();
    ServiceAppointment sa = Factory_ServiceAppointment.buildForWorkOrder(wo);

    Test.startTest();
    TriggerBase.bypass('ServiceAppointment');
    insert sa;
    TriggerBase.clearBypass('ServiceAppointment');
    Test.stopTest();

    sa = [SELECT Id, FSL__GanttLabel__c FROM ServiceAppointment WHERE Id = :sa.Id];

    System.assertEquals(null, sa.FSL__GanttLabel__c);
  }
}
