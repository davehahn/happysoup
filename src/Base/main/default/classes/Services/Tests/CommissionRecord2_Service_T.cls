/**
 * Created by dave on 2020-01-28.
 */

@IsTest
private class CommissionRecord2_Service_T {
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Account customer = Factory_Account.insertCustomerAccounts(1)[0];
    GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertFullSerial('Boat', 'Pontoon', 'test12345');
    AcctSeed__Project__c project = Factory_ERPOrder.buildERP(customer, serial.Id, gcConstants.idRtProjectBoatSale);
    insert project;
  }

  @IsTest
  static void createRecords_Test() {
    AcctSeed__Project__c project = [SELECT Id FROM AcctSeed__Project__c LIMIT 1];
    gcProjectTask.ignoreCommissions = true;
    List<AcctSeed__Project_Task__c> tasks = Factory_ERPOrderTask.insertDefaultRetailBoatSaleTasks(project.Id);
    Test.startTest();
    CommissionRecord2_Service service = new CommissionRecord2_Service();
    service.addTasks(tasks);
    service.saveRecords();
    Test.stopTest();

    List<CommissionRecord2__c> records = [SELECT Id FROM CommissionRecord2__c WHERE Project__c = :project.Id];
    System.assertEquals(2, service.tasks.size());
    System.assertEquals(2, service.commissionRecords.size());
    System.assertEquals(2, records.size());
  }

  @IsTest
  static void updateRecords_Test() {
    AcctSeed__Project__c project = [SELECT Id FROM AcctSeed__Project__c LIMIT 1];
    AcctSeed__Project_Task__c task = Factory_ERPOrderTask.buildRetailSaleTask(project.Id);
    gcProjectTask.ignoreCommissions = true;
    insert task;
    CommissionRecord2__c commissionRecord = new CommissionRecord2__c(
      Project_Task__c = task.Id,
      Calculation_Method__c = task.Commission_Calculation_Method__c
    );
    insert commissionRecord;
    task.Commission_Calculation_Method__c = 'Revenue';
    Test.startTest();
    CommissionRecord2_Service service = new CommissionRecord2_Service();
    service.addTasks(new List<AcctSeed__Project_Task__c>{ task });
    service.saveRecords();
    Test.StopTest();

    CommissionRecord2__c cr_after = [
      SELECT Calculation_Method__c
      FROM CommissionRecord2__c
      WHERE Id = :commissionRecord.Id
    ];
    System.assertEquals('Revenue', cr_after.Calculation_Method__c);
    System.assertNotEquals(commissionRecord.Calculation_Method__c, cr_after.Calculation_Method__c);
  }
}
