/**
 * Created by dave on 2021-12-22.
 */

@IsTest
private class TA_account_PreventPartnerEdit_T {
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
  static void standardUser_DealerAccountUpdate_Test() {
    User stduser = Factory_User.newUser(
      'Standard',
      'TestUser',
      'System Administrator',
      null
    );
    buildTriggerVariables();
    System.runAs(stduser) {
      new TA_Account_PreventPartnerEdit().beforeUpdate(newList, oldList);
      System.assertEquals(newName, newList[0].Name);
    }
  }

  @IsTest
  static void partnerUserUpdateOwnAccount_Test() {
    buildTriggerVariables();
    oldList[0].Id = null;
    TriggerBase.bypass('Account');
    insert oldList;
    TriggerBase.clearBypass('Account');
    newList[0].Id = oldList[0].Id;
    User partnerUser = Factory_User.createPartnerUser(newList[0].Id);
    System.runAs(partnerUser) {
      new TA_Account_PreventPartnerEdit().beforeUpdate(newList, oldList);
      System.assertEquals(newName, newList[0].Name);
    }
  }

  @IsTest
  static void partnerUserUpdateOtherAccount_Test() {
    Account dealerAcct = Factory_Account.buildDealerAccounts(1)[0];
    insert dealerAcct;
    User partnerUser = Factory_User.createPartnerUser(dealerAcct.Id);
    buildTriggerVariables();
    System.runAs(partnerUser) {
      try {
        new TA_Account_PreventPartnerEdit().beforeUpdate(newList, oldList);
      } catch (Exception e) {
        System.assert(
          e.getMessage()
            .contains(
              'You are not allowed to edit another Partners information'
            )
        );
      }
    }
  }
}
