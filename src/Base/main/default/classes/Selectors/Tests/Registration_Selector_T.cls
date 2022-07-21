/**
 * Created by dave on 2019-10-18.
 */
@isTest
private class Registration_Selector_T {
  static AcctSeed__Project__c erp;
  static GMBLASERP__Serial_Number__c serial;
  static GMBLASERP__Serial_Number__c serial_motor;
  static Account customer;
  static Account dealer;
  static Registration__c registration;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void init() {
    customer = Factory_Account.insertFullPersonAccount('fName', 'lName');
    dealer = Factory_Account.insertDealerAccounts(1)[0];
    serial = Factory_SerialNumber.insertFullSerial('Boat', 'Pontoon', '1234567890-UNIT-TESTER');
    serial_motor = Factory_SerialNumber.insertFullSerial('Motor', 'Remote', '666TESTMOTOR666');
    AcctSeedERP__Warehouse__c wh = determineWarehouse();
    erp = Factory_ERPOrder.insertRetailBoatSale(customer, wh, null, serial, serial_motor);
    registration = new Registration__c(
      Account__c = customer.Id,
      RegisteredByAccount__c = dealer.Id,
      SerialNumber__c = serial.Id,
      Delivery_Date__c = DateTime.now(),
      Payment_Method__c = 'cash',
      ErpOrder__c = erp.Id
    );
    insert registration;
  }

  private static AcctSeedERP__Warehouse__c determineWarehouse() {
    User u = [SELECT GL_Account_Variable_1__c FROM User WHERE Id = :UserInfo.getUserId()];
    try {
      return [
        SELECT Id, Name, GL_Account_Variable_3__c
        FROM AcctSeedERP__Warehouse__c
        WHERE Name = :u.GL_Account_Variable_1__c
        LIMIT 1
      ];
    } catch (Exception e) {
      return [
        SELECT Id, Name, GL_Account_Variable_3__c
        FROM AcctSeedERP__Warehouse__c
        WHERE Name LIKE '%Whitefish%'
        LIMIT 1
      ];
    }
  }

  @IsTest
  static void allById_Test() {
    init();
    Test.startTest();
    List<Registration__c> results = Registration_Selector.allById(new Set<Id>{ registration.Id });
    Test.stopTest();
    System.assertEquals(1, results.size());
  }

  @IsTest
  static void allCustomerBoatRegisteredByAccountId_Test() {
    init();
    Test.startTest();
    List<Registration__c> results = Registration_Selector.allCustomerBoatRegisteredByAccountId(dealer.Id);
    Test.stopTest();
    System.assertEquals(1, results.size());
  }
}
