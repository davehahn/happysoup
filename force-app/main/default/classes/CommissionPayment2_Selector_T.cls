/**
 * Created by dave on 2020-03-25.
 */

@IsTest
private class CommissionPayment2_Selector_T
{

  static AcctSeed__Project__c project;
  static CommissionRecord2__c commissionRecord;

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Account customer = Factory_Account.insertCustomerAccounts(1)[0];
    AcctSeedERP__Warehouse__c warehouse = [ SELECT Id, Name, GL_Account_Variable_3__c FROM AcctSeedERP__Warehouse__c WHERE Name = 'Whitefish'];
    GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertFullSerial('Boat', 'Pontoon', 'test12345');
    Factory_ERPOrder.insertRetailBoatSale( customer, warehouse, DateTime.now().addMonths(1), serial );
  }

  private static void init()
  {
    project = [SELECT Id FROM AcctSeed__Project__c LIMIT 1];
    commissionRecord = [SELECT Id FROM CommissionRecord2__c WHERE Project__c = :project.Id LIMIT 1];
  }

  @IsTest
  static void allByIds_Test()
  {
    init();
    Map<Id, CommissionPayment2__c> paymentMap = new Map<Id, CommissionPayment2__c>([
      SELECT Id FROM CommissionPayment2__c WHERE Commission_Record2__c = :commissionRecord.Id
    ]);

    Test.startTest();
    List<CommissionPayment2__c> result = CommissionPayment2_Selector.allByIds( paymentMap.keySet() );
    Test.stopTest();

    System.assertEquals( paymentMap.size(), result.size() );
  }

  @IsTest
  static void allByCommissionRecordId_Test()
  {
    init();
    List<CommissionPayment2__c> payments =
    [
      SELECT Id
      FROM CommissionPayment2__c
      WHERE Commission_Record2__c = :commissionRecord.Id
    ];

    Test.startTest();
    List<CommissionPayment2__c> result = CommissionPayment2_Selector.allByCommissionRecordId( commissionRecord.Id );
    Test.stopTest();

    System.assertEquals( payments.size(), result.size() );
  }

  @IsTest
  static void allByCommissionRecordIds_Test()
  {
    init();
    List<CommissionPayment2__c> payments =
    [
      SELECT Id
      FROM CommissionPayment2__c
      WHERE Commission_Record2__c = :commissionRecord.Id
    ];

    Test.startTest();
    List<CommissionPayment2__c> result =
      CommissionPayment2_Selector.allByCommissionRecordIds(
        new Set<Id>{commissionRecord.Id}
      );
    Test.stopTest();

    System.assertEquals( payments.size(), result.size() );
  }

  @IsTest
  static void allNewByCommissionRecordIds_Test()
  {
    init();
    List<CommissionPayment2__c> payments =
    [
      SELECT Id
      FROM CommissionPayment2__c
      WHERE Commission_Record2__c = :commissionRecord.Id
    ];

    Test.startTest();
    List<CommissionPayment2__c> result =
      CommissionPayment2_Selector.allNewByCommissionRecordIds(
        new Set<Id>{commissionRecord.Id}
      );
    Test.stopTest();

    System.assertEquals( payments.size(), result.size() );
  }
}