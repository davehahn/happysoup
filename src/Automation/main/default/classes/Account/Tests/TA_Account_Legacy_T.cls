/**
 * Created by dave on 2021-12-22.
 */

@IsTest
private class TA_Account_Legacy_T {
  static String newName = 'Changed By Test Corp.';
  static List<Account> newList;
  static List<Account> oldList;

  private static void buildTriggerVariables() {
    newList = new List<Account>();
    oldList = new List<Account>();
    Account dealer = Factory_Account.buildDealerAccounts(1)[0];
    Id dealerAcctId = TestUtility.getFakeId(Account.SObjectType);
    dealer.Id = dealerAcctId;

    Account dealerClone = dealer.clone(true, true, true, true);
    oldList.add(dealerClone);

    dealer.Name = newName;
    newList.add(dealer);
  }

  @IsTest
  static void beforeInsertTest() {
    buildTriggerVariables();
    Test.startTest();
    new TA_Account_Legacy().beforeInsert(newList);
    Test.stopTest();
  }

  @IsTest
  static void afterInsertTest() {
    buildTriggerVariables();
    Test.startTest();
    new TA_Account_Legacy().afterInsert(newList);
    Test.stopTest();
  }

  @IsTest
  static void beforeUpdateTest() {
    buildTriggerVariables();
    Test.startTest();
    new TA_Account_Legacy().beforeUpdate(newList, oldList);
    Test.stopTest();
  }

  @IsTest
  static void afterUpdateTest() {
    buildTriggerVariables();
    Test.startTest();
    new TA_Account_Legacy().afterUpdate(newList, oldList);
    Test.stopTest();
  }

  @IsTest
  static void beforeDeleteTest() {
    buildTriggerVariables();
    Test.startTest();
    new TA_Account_Legacy().beforeDelete(oldList);
    Test.stopTest();
  }

  @IsTest
  static void afterDeleteTest() {
    buildTriggerVariables();
    Test.startTest();
    new TA_Account_Legacy().afterDelete(oldList);
    Test.stopTest();
  }
}
