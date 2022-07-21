/**
 * Created by dave on 2022-01-04.
 */

@IsTest
private class TA_Case_ValidateStatusChange_T {
  private static Case c;
  private static Account dealer;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void init() {
    dealer = AccountFactory.buildDealerAccount('Testy McDealer');
    insert dealer;
    c = Factory_Case.buildWarrantyCase(dealer);
  }

  @IsTest
  static void validateOnPartsOrderExists() {
    init();
    TriggerBase.bypass('AcctSeed__Project__c');
    AcctSeed__Project__c partsOrderERP = Factory_ERPOrder.insertPartnerPartsOrder(dealer, null);
    TriggerBase.clearBypass('AcctSeed__Project__c');
    c.Status = 'Approved';
    c.Parts_Order_ERP__c = partsOrderERP.Id;
    TriggerBase.bypass('Case');
    insert c;
    TriggerBase.clearBypass('Case');

    c.Status = 'New';

    String error;
    Test.startTest();
    try {
      update c;
    } catch (Exception e) {
      error = e.getMessage();
    }

    System.assert(error != null);
    System.assert(
      error.contains('This case has a related parts order. Please remove the parts order first to change status.')
    );
  }

  @IsTest
  static void validateWarrantyChangeHasAnActualOwner_error() {
    init();
    //Id cUser = UserInfo.getUserId();
    Id que = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Warranty_Cases' LIMIT 1].Id;
    c.OwnerId = que;

    TriggerBase.bypass('Case');
    insert c;
    TriggerBase.clearBypass('Case');

    c.Status = 'Approved';

    String error;
    Test.startTest();
    try {
      update c;
    } catch (Exception e) {
      error = e.getMessage();
    }
    Test.stopTest();

    System.assert(error != null);
    System.assert(error.contains('Status change is not allowed until the Case is Owned by a Person'));
  }

  @IsTest
  static void validateWarrantyChangeHasAnActualOwner_noError() {
    init();
    Id cUser = UserInfo.getUserId();
    Id que = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Warranty_Cases' LIMIT 1].Id;
    c.OwnerId = que;

    TriggerBase.bypass('Case');
    insert c;
    TriggerBase.clearBypass('Case');

    c.OwnerId = cUser;
    c.Status = 'Approved';

    String error;
    Test.startTest();
    try {
      update c;
    } catch (Exception e) {
      error = e.getMessage();
    }
    Test.stopTest();

    System.assert(error == null);
  }
}
