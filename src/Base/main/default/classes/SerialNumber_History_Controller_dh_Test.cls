@isTest
private class SerialNumber_History_Controller_dh_Test {
  static Account legend;
  static Account dealer;
  static Account customer;
  static GMBLASERP__Serial_Number__c serial;
  static Registration__c[] registrations;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void setup() {
    Date today = Date.today();
    Account[] dealers = Factory_Account.insertDealerAccounts(2);
    legend = dealers[0];
    dealer = dealers[1];
    customer = Factory_Account.insertFullPersonAccount('fName', 'lName');
    serial = Factory_SerialNumber.insertFullSerials(1, 'Boat', 'Pontoon')[0];
    TriggerHandler.bypass('Registration_TriggerHandler');
    insert createReg(serial, legend, dealer, today, false);
    insert createReg(serial, dealer, customer, today, true);
    TriggerHandler.clearBypass('Registration_TriggerHandler');
  }

  private static Registration__c createReg(
    GMBLASERP__Serial_Number__c serial,
    Account fromAcct,
    Account toAcct,
    Date delDate,
    Boolean current
  ) {
    return new Registration__c(
      Account__c = toAcct.Id,
      RegisteredByAccount__c = fromAcct.Id,
      Delivery_Date__c = delDate,
      SerialNumber__c = serial.Id,
      isCurrent__c = current
    );
  }

  @isTest
  static void fetchData_Test() {
    Test.startTest();
    setup();
    Test.stopTest();
    String jsonResult = SerialNumber_History_Controller_dh.fetchData(serial.Id);
    SerialNumber_History_Controller_dh.HistoryWrapper result = (SerialNumber_History_Controller_dh.HistoryWrapper) JSON.deserialize(
      jsonResult,
      SerialNumber_History_Controller_dh.HistoryWrapper.class
    );
    System.assertEquals(serial.Id, result.recordId);
    System.assert(result.currentRegistration != null);
    System.assertEquals(1, result.registrations.size());
  }
}
