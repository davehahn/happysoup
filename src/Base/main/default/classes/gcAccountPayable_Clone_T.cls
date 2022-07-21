@isTest
public class gcAccountPayable_Clone_T {
  @TestSetup
  static void testData() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Factory_AccountPayable.insertAccountPayable(5);
    new Factory_AccountingVariables();
  }

  @isTest
  static void testScenario1() {
    AcctSeed__Account_Payable__c accountPayable = [SELECT id FROM AcctSeed__Account_Payable__c LIMIT 1];
    ApexPages.StandardController sc = new ApexPages.StandardController(accountPayable);
    gcAccountPayable_Clone accountPayableClone = new gcAccountPayable_Clone(sc);
    Test.startTest();
    pageReference pr = accountPayableClone.init();
    System.assertEquals(pr != null, true);
    Test.stopTest();
  }

  @isTest
  static void testScenario2() {
    List<AcctSeed__Account_Payable__c> lstAccountPayable = [SELECT id FROM AcctSeed__Account_Payable__c];
    ApexPages.currentPage().getParameters().put('retUrl', '/apex/0');
    ApexPages.currentPage().getParameters().put('idFilter', 'abcd');
    ApexPages.StandardSetController sc = new ApexPages.StandardSetController(lstAccountPayable);
    gcAccountPayable_Clone accountPayableClone = new gcAccountPayable_Clone(sc);
    sc.setSelected(lstAccountPayable);
    Test.startTest();
    pageReference pr = accountPayableClone.back();
    System.assertNotEquals(null, pr);
    Test.stopTest();
  }

  @isTest
  static void testScenario3() {
    AcctSeed__Account_Payable__c accountPayable = [SELECT id FROM AcctSeed__Account_Payable__c LIMIT 1];

    ApexPages.StandardController sc = new ApexPages.StandardController(accountPayable);
    gcAccountPayable_Clone accountPayableClone = new gcAccountPayable_Clone(sc);
    accountPayableClone.idFilter = null;
    Test.startTest();
    pageReference prInit = accountPayableClone.init();
    pageReference pr = accountPayableClone.createClone();

    System.assertEquals(null, prInit);
    System.assertEquals(null, pr);
    Test.stopTest();
  }
  @isTest
  static void testScenario4() {
    AcctSeed__Account_Payable__c accountPayable = [SELECT id FROM AcctSeed__Account_Payable__c LIMIT 1];

    ApexPages.currentPage().getParameters().put('retUrl', '/apex/0');
    ApexPages.currentPage().getParameters().put('idFilter', 'abcd');
    ApexPages.currentPage().getParameters().put('cloneType', 'reverse');
    ApexPages.StandardController sc = new ApexPages.StandardController(accountPayable);
    gcAccountPayable_Clone accountPayableClone = new gcAccountPayable_Clone(sc);
    accountPayableClone.retUrl = null;
    Test.startTest();
    pageReference pr = accountPayableClone.init();
    gcAccountPayable_Clone objTest = new gcAccountPayable_Clone();

    System.assertNotEquals(null, pr);
    System.assertNotEquals(null, objTest);
    Test.stopTest();
  }
}
