
@isTest (seeAllData=false)
public  class gcAccountPayable_Clone_T {
    @TestSetup
    static void testData(){
        new Factory_TestData();
        Factory_CustomSettings.setupInventorySettings();
        Factory_AccountPayable.insertAccountPayable(5);
        new Factory_AccountingVariables();
    }

    @isTest
    static void testScenario1() {
        AcctSeed__Account_Payable__c accountPayable = [SELECT id FROM AcctSeed__Account_Payable__c limit 1];

        ApexPages.StandardController sc = new ApexPages.StandardController(accountPayable);
        gcAccountPayable_Clone accountPayableClone = new gcAccountPayable_Clone(sc);

        accountPayableClone.init();
        accountPayableClone.createClone();

    }

    @isTest
    static void testScenario2() {
        List<AcctSeed__Account_Payable__c> lstAccountPayable = [SELECT id FROM AcctSeed__Account_Payable__c ];
        Test.startTest();
        // Test.setCurrentPage(Page.YOUR_PAGE);
        ApexPages.currentPage().getParameters().put('retUrl','/apex/0');
        ApexPages.currentPage().getParameters().put('idFilter','abcd');
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(lstAccountPayable);
        gcAccountPayable_Clone accountPayableClone = new gcAccountPayable_Clone(sc);
        sc.setSelected(lstAccountPayable);
        //YOUR_Extension ext = new YOUR_Extension(stdSetController);
        accountPayableClone.back();
        Test.stopTest();
    }

    @isTest
    static void testScenario3() {
        AcctSeed__Account_Payable__c accountPayable = [SELECT id FROM AcctSeed__Account_Payable__c limit 1];

        ApexPages.StandardController sc = new ApexPages.StandardController(accountPayable);
        gcAccountPayable_Clone accountPayableClone = new gcAccountPayable_Clone(sc);
        accountPayableClone.idFilter = null;
        accountPayableClone.init();
        accountPayableClone.createClone();

    }
    @isTest
    static void testScenario4() {
        AcctSeed__Account_Payable__c accountPayable = [SELECT id FROM AcctSeed__Account_Payable__c limit 1];

        ApexPages.currentPage().getParameters().put('retUrl','/apex/0');
        ApexPages.currentPage().getParameters().put('idFilter','abcd');
        ApexPages.currentPage().getParameters().put('cloneType','reverse');
        ApexPages.StandardController sc = new ApexPages.StandardController(accountPayable);
        gcAccountPayable_Clone accountPayableClone = new gcAccountPayable_Clone(sc);
        accountPayableClone.retUrl = null;
        accountPayableClone.init();
        gcAccountPayable_Clone objTest = new gcAccountPayable_Clone();
    }


}