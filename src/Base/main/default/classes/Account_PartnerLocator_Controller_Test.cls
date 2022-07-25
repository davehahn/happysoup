@isTest
private class Account_PartnerLocator_Controller_Test {
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  @isTest
  static void fetchPartners() {
    Factory_Account.insertDealerAccounts(20);
    Test.startTest();
    String resultJSON = Account_PartnerLocator_Controller.fetchPartners();
    List<Account_PartnerLocator_Controller.Partner> result = (List<Account_PartnerLocator_Controller.Partner>) JSON.deserialize(
      resultJSON,
      List<Account_PartnerLocator_Controller.Partner>.class
    );
    Test.stopTest();
    //20 we created + 3 internal accounts created in Factory_CustomSetting
    System.assertEquals(23, result.size());
  }
}
