/**
 * Created by dave on 2020-03-26.
 */

@IsTest
private class CommissionRecord2_Selector_T {
  static AcctSeed__Project__c project;
  static CommissionRecord2__c commissionRecord;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Account customer = Factory_Account.insertCustomerAccounts(1)[0];
    AcctSeedERP__Warehouse__c warehouse = [
      SELECT Id, Name, GL_Account_Variable_3__c
      FROM AcctSeedERP__Warehouse__c
      WHERE Name = 'Whitefish'
    ];
    GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertFullSerial('Boat', 'Pontoon', 'test12345');
    Factory_ERPOrder.insertRetailBoatSale(customer, warehouse, DateTime.now().addMonths(1), serial);
  }

  private static void init() {
    project = [SELECT Id FROM AcctSeed__Project__c LIMIT 1];
    commissionRecord = [SELECT Id, Project_task__c FROM CommissionRecord2__c WHERE Project__c = :project.Id LIMIT 1];
  }

  @IsTest
  static void allById_Test() {
    init();
    Test.startTest();
    List<CommissionRecord2__c> records = CommissionRecord2_Selector.allById(new Set<Id>{ commissionRecord.Id });
    Test.stopTest();

    System.assertEquals(1, records.size());
  }

  @IsTest
  static void allByIdIncludingPayments_Test() {
    init();
    Test.startTest();
    List<CommissionRecord2__c> records = CommissionRecord2_Selector.allByIdIncludingPayments(
      new Set<Id>{ commissionRecord.Id }
    );
    Test.stopTest();

    System.assertEquals(1, records.size());
  }

  @IsTest
  static void allByERPId_Test() {
    init();
    List<CommissionRecord2__c> known = [SELECT Id FROM CommissionRecord2__c WHERE Project__c = :project.Id];
    Test.startTest();
    List<CommissionRecord2__c> result = CommissionRecord2_Selector.allByErpId(project.Id);
    Test.stopTest();

    System.assertEquals(known.size(), result.size());
  }

  @IsTest
  static void allByProjectTaskId_Test() {
    init();
    List<CommissionRecord2__c> known = [
      SELECT Id
      FROM CommissionRecord2__c
      WHERE Project_Task__c = :commissionRecord.Project_Task__c
    ];
    Test.startTest();
    List<CommissionRecord2__c> result = CommissionRecord2_Selector.allByProjectTaskId(commissionRecord.Project_Task__c);
    Test.stopTest();

    System.assertEquals(known.size(), result.size());
  }

  @IsTest
  static void mapOfAllById_IncludingProjectTask_Test() {
    init();
    Test.startTest();
    Map<Id, CommissionRecord2__c> records = CommissionRecord2_Selector.mapOfAllById_IncludingProjectTask(
      new Set<Id>{ commissionRecord.Id }
    );
    Test.stopTest();

    System.assertEquals(1, records.size());
  }
}
