/**
 * Created by dave on 2021-02-03.
 */

@IsTest
private class Account_Selector_T {
  static final Application_RecordType.AccountRTs recordTypes = Application_RecordType.getInstance()
    .getAccountRecordTypes();

  @testSetup
  static void dataSetup() {
    Factory_Account.insertDealerAccounts(5);
    Factory_Account.insertCustomerAccounts(5);
    Factory_Account.insertBusinessAccountWithContacts('business1', 3);
  }

  // Not sure why this is set up to use the Person Account Selector but.....
  @IsTest
  static void allById_Test() {
    Map<Id, Account> pAccounts = new Map<Id, Account>(
      [SELECT Id FROM Account WHERE RecordTypeId = :recordTypes.getPersonAccountId()]
    );

    Test.startTest();
    Account[] results = Account_Selector.allByIds(pAccounts.keySet());
    Test.stopTest();

    System.assertEquals(pAccounts.size(), results.size());
  }

  @IsTest
  static void personAccount_Test() {
    Map<Id, Account> pAccounts = new Map<Id, Account>(
      [SELECT Id FROM Account WHERE RecordTypeId = :recordTypes.getPersonAccountId()]
    );

    Test.startTest();
    Account[] results = Account_Selector.allPersonAccountsByIds(pAccounts.keySet());
    Account result = Account_Selector.personAccountById(pAccounts.values()[0].Id);
    Test.stopTest();

    System.assertEquals(pAccounts.size(), results.size());
    System.assertEquals(pAccounts.values()[0].Id, result.Id);
  }

  @IsTest
  static void personAccountByIds_FAIL_Test() {
    try {
      Account_Selector.personAccountById('fails');
    } catch (Exception e) {
      System.debug(e.getMessage());
      System.assert(e.getMessage() != null);
    }
  }

  @IsTest
  static void dealerAccount_Test() {
    Test.startTest();
    Account[] dealers = Account_Selector.allActiveDealers();
    Test.stopTest();

    System.assertEquals(5, dealers.size(), 'There should be 5 dealers');
  }

  @IsTest
  static void dealerAccountWithGeolocation_Test() {
    Test.startTest();
    Account[] dealers = Account_Selector.allActiveDealersWithGeolocation();
    Test.stopTest();

    System.assertEquals(0, dealers.size(), 'No Dealers have address information set');
  }

  @IsTest
  static void businessAccount_Test() {
    Account businessAccount = [SELECT Id FROM Account WHERE RecordTypeId = :recordTypes.getBusinessAccountId() LIMIT 1];

    Test.startTest();
    Account result = Account_Selector.businessAccountWithContactsById(businessAccount.Id);
    Test.stopTest();

    System.assertEquals(businessAccount.Id, result.Id);
    System.assertEquals(3, result.Contacts.size());
  }
}
