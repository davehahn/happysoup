/**
 * Created by dave on 2020-03-26.
 */

@IsTest
private class CommissionLineItem2_Selector_T {
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
    Set<Id> lineIds = new Set<Id>();
    for (CommissionLineItem2__c line : [
      SELECT Id
      FROM CommissionLineItem2__c
      WHERE CommissionRecord2__c = :commissionRecord.Id
    ]) {
      lineIds.add(line.Id);
    }

    Test.startTest();
    List<CommissionLineItem2__c> result = CommissionLineItem2_Selector.allById(lineIds);
    Test.stopTest();

    System.assertEquals(lineIds.size(), result.size());
  }

  @IsTest
  static void allByCommissionRecordId_Test() {
    init();
    List<CommissionLineItem2__c> known = [
      SELECT Id
      FROM CommissionLineItem2__c
      WHERE CommissionRecord2__c = :commissionRecord.Id
    ];
    Test.startTest();
    List<CommissionLineItem2__c> result = CommissionLineItem2_Selector.allByCommissionRecordId(commissionRecord.Id);
    Test.stopTest();

    System.assertEquals(known.size(), result.size());
  }

  @IsTest
  static void allByMaterialIds_Test() {
    init();
    Set<Id> matIds = new Set<Id>();
    for (AcctSeedERP__Material__c mat : [
      SELECT Id
      FROM AcctSeedERP__Material__c
      WHERE AcctSeedERP__Project__c = :project.Id
    ]) {
      matIds.add(mat.Id);
    }

    Test.startTest();
    List<CommissionLineItem2__c> result = CommissionLineItem2_Selector.allByMaterialIds(matIds);
    Test.stopTest();

    System.assertEquals(matIds.size(), result.size());
  }
}
