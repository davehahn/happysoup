/**
 * Created by dave on 2021-02-03.
 */

@IsTest
private class Account_Selector_T {
  static final Application_RecordType.AccountRTs recordTypes = Application_RecordType.getInstance()
    .getAccountRecordTypes();

  @testSetup
  static void dataSetup() {
    List<Account> dealers = Factory_Account.buildDealerAccounts(5);
    dealers[0].BillingLatitude = 44.29707;
    dealers[0].BillingLongitude = -79.68126;
    dealers[0].Boat_Types_Carried__c = 'Deck Boat;Pontoon';
    dealers[1].BillingLatitude = 46.38468;
    dealers[1].BillingLongitude = -81.29074;
    dealers[1].Boat_Types_Carried__c = 'Full Windshield;Side Console';
    insert dealers;
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

    System.assertEquals(2, dealers.size(), '2 Dealers should have Geolocation set');
  }

  @IsTest
  static void dealerAccountWithGeolocation_sellsPontoons_Test() {
    Test.startTest();
    Account[] dealers = Account_Selector.allActiveDealersWithGeolocationThatSellThisBoatType('Pontoon');
    Test.stopTest();

    System.assertEquals(1, dealers.size(), '1 Dealer should have Geolocation set and carry Pontoons');
  }

  @IsTest
  static void dealerAccountWithGeolocation_SellsFullWindshields_Test() {
    Test.startTest();
    Account[] dealers = Account_Selector.allActiveDealersWithGeolocationThatSellThisBoatType('Full Windshield');
    Test.stopTest();

    System.assertEquals(1, dealers.size(), '1 Dealer should have Geolocation set and carry Full Windshields');
  }

  @IsTest
  static void dealerAccountWithGeolocation_SellsUtilities_Test() {
    Test.startTest();
    Account[] dealers = Account_Selector.allActiveDealersWithGeolocationThatSellThisBoatType('Utility');
    Test.stopTest();

    System.assertEquals(0, dealers.size(), '0 Dealer should have Geolocation set and carry Utilities');
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
