/**
 * Created by dave on 2019-11-26.
 */

@IsTest
private class RiggerJob_TriggerHandler_T {
  static AcctSeed__Project__c boatSale;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void init() {
    AcctSeedERP__Warehouse__c warehouse = [
      SELECT Id, Name
      FROM AcctSeedERP__Warehouse__c
      WHERE Name LIKE '%Whitefish%'
    ];
    Account customer = Factory_Account.insertCustomerAccounts(1)[0];
    GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertFullSerial('Boat', 'Pontoon', 'TEST6666');
    boatSale = Factory_ERPOrder.insertRetailBoatSale(customer, warehouse, DateTime.now().addMonths(1), serial);
  }

  @IsTest
  static void setNameToErpName_Test() {
    init();
    Rigger_Job__c job = new Rigger_Job__c(ERP_Order__c = boatSale.Id);
    Test.startTest();
    insert job;
    Test.stopTest();
    job = [SELECT Id, Name FROM Rigger_Job__c WHERE Id = :job.Id];
    boatSale = [SELECT Id, Name FROM AcctSeed__Project__c WHERE Id = :boatSale.Id];

    System.assertEquals(job.Name, boatSale.Name);
  }
}
