@isTest
private class SurveyManagerController_Test {
  @isTest
  static void positive_Test() {
    User u = Factory_User.buildUser('Fname', 'Lname', 'System Administrator');
    System.runAs(u) {
      ApexPages.StandardController stdCtrl = new ApexPages.StandardController(new Survey__c());
      SurveyManagerController ctr = new SurveyManagerController(stdCtrl);
      System.assertEquals(true, ctr.getEditCSS());
    }
  }

  @isTest
  static void negative_Test() {
    User u = Factory_User.buildUser('Fname', 'Lname', 'Standard User');
    System.runAs(u) {
      ApexPages.StandardController stdCtrl = new ApexPages.StandardController(new Survey__c());
      SurveyManagerController ctr = new SurveyManagerController(stdCtrl);
      System.assertEquals(false, ctr.getEditCSS());
    }
  }
}
