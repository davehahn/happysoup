@IsTest(SeeAllData=false)
private class gcProduct_UpdateMRPQty_T {
    final static String RECORDTYPE = 'Insurance';
    final static String FAMILY = 'Insurance';
    @TestSetup
    static void testData(){
        new Factory_TestData();
        Factory_CustomSettings.setupInventorySettings();
        Factory_AccountPayable.insertAccountPayable(5);
        new Factory_AccountingVariables();
        List<Product2> serializedProducts = Factory_Product.createSerializedProducts(RECORDTYPE, FAMILY, 10);
    }

    @IsTest
    static void testMethod1StandardController() {
        List<Product2> lstProd = [SELECT Id FROM Product2];
        String idFilter = lstProd[0].Id;
        Test.setCurrentPage(Page.gpProduct_UpdateMRPQty);
        ApexPages.currentPage().getParameters().put('retUrl', 'www.salesforce.com');
        ApexPages.currentPage().getParameters().put('idFilter', idFilter);

        ApexPages.StandardController sc = new ApexPages.StandardController(lstProd[0]);
        gcProduct_UpdateMRPQty objTest = new gcProduct_UpdateMRPQty(sc);

        Test.startTest();
        objTest.init();
        PageReference P = objTest.back();
        System.assertEquals('/' + idFilter.left(15), P.getUrl());
        Test.stopTest();
    }

    @IsTest
    static void testMethod2StandardSetController(){
        List<Product2> lstProd = [SELECT Id FROM Product2];
        String idFilter = lstProd[0].Id;

        Test.setCurrentPage(Page.gpProduct_UpdateMRPQty);
        ApexPages.currentPage().getParameters().put('retUrl', 'www.salesforce.com');
        ApexPages.currentPage().getParameters().put('idFilter', idFilter);

        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(lstProd);
        ssc.setSelected(lstProd);
        gcProduct_UpdateMRPQty objTest = new gcProduct_UpdateMRPQty(ssc);

        Test.startTest();
        objTest.init();
        PageReference P = objTest.back();
        System.assertEquals('www.salesforce.com', P.getUrl());
        Test.stopTest();
    }

    @IsTest
    static void testMethod3DefaultConstructor(){
        List<Product2> lstProd = [SELECT Id FROM Product2];
        String idFilter = lstProd[0].Id;
        ApexPages.currentPage().getParameters().put('idFilter', idFilter);
        gcProduct_UpdateMRPQty objTest = new gcProduct_UpdateMRPQty();
    }


    @IsTest
    static void testMethod4StandardControllerNoRetURL() {
        List<Product2> lstProd = [SELECT Id FROM Product2];
        String idFilter = lstProd[0].Id;

        Test.setCurrentPage(Page.gpProduct_UpdateMRPQty);
        ApexPages.currentPage().getParameters().put('idFilter', idFilter);

        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(lstProd);
        ssc.setSelected(lstProd);
        gcProduct_UpdateMRPQty objTest = new gcProduct_UpdateMRPQty(ssc);

        Test.startTest();
        objTest.init();
        Test.stopTest();
    }

    @IsTest
    static void testMethod5StandardControllerNoSelectedNoRetURL() {
        List<Product2> lstProd = [SELECT Id FROM Product2];
        String idFilter = lstProd[0].Id;

        Test.setCurrentPage(Page.gpProduct_UpdateMRPQty);

        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(lstProd);
        gcProduct_UpdateMRPQty objTest = new gcProduct_UpdateMRPQty(ssc);

        Test.startTest();
        objTest.init();
        Test.stopTest();
    }

    @IsTest
    static void testMethod5StandardControllerNoIdFilterNoRetURL() {
        List<Product2> lstProd = [SELECT Id FROM Product2];
        String idFilter = lstProd[0].Id;

        Test.setCurrentPage(Page.gpProduct_UpdateMRPQty);

        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(lstProd);
        ssc.setSelected(lstProd);
        gcProduct_UpdateMRPQty objTest = new gcProduct_UpdateMRPQty(ssc);

        Test.startTest();
        objTest.init();
        Test.stopTest();
    }
}