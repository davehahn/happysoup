@isTest (seeAllData=false)

public  class gcAccountPayable_Override_T {

    final static String RECORDTYPE = 'Motor';
    final static String FAMILY = 'Remote';
    final static String SERIALNUMBER = '123450';
    final static String FNAME = 'TestFirstName';
    final static String LNAME = 'TestLastName';
    final static String TASKNAME = 'Test ERP Task';

    @TestSetup
    static void testData(){

        new Factory_TestData();
        new Factory_AccountingVariables();
        Factory_AccountPayable.insertAccountPayable(5);

        List<Product2> serializedProducts = Factory_Product.createSerializedProducts(RECORDTYPE, FAMILY, 10);
        GMBLASERP__Serial_Number__c serialNumber = Factory_SerialNumber.insertSerialNumber(serializedProducts[0], SERIALNUMBER);
        Account acct = Factory_Account.insertFullPersonAccount(FNAME, LNAME);
        Id erpRecordTypeId = Schema.SObjectType.AcctSeed__Project__c.getRecordTypeInfosByName().get('Project').getRecordTypeId();
        AcctSeed__Project__c erp = Factory_ERPOrder.buildERP(acct, serialNumber.Id, erpRecordTypeId);
        AcctSeed__Project_Task__c erpTask = Factory_ERPOrder.buildProjectTask(erp.Id, TASKNAME);
    }

    
    @isTest
    static void testRetriveItems() {
        List<AcctSeed__Account_Payable__c> lstAccountPayable = [
                                                                SELECT
                                                                    Id,
                                                                    Name,
                                                                    GL_Account_Variable_3__c,
                                                                    Tax_Override__c,
                                                                    Tax_Rate_Retail__c,
                                                                    Payee_New__c,
                                                                    Tax_Amount_Fixed__c,
                                                                    AcctSeed__Fixed_Asset__c,
                                                                    AcctSeed__Proprietary_Payable_Number__c,
                                                                    GL_Account_Variable_1__c,
                                                                    GL_Account_Variable_2__c,
                                                                    Approval_Date__c,
                                                                    Approved__c, Submitted_Date__c,
                                                                    AcctSeed__VAT_Line_Count__c,
                                                                    AcctSeed__Vendor__c
                                                                FROM
                                                                    AcctSeed__Account_Payable__c
            													LIMIT 1
                                                                ];

        Test.startTest();
		List<AcctSeed__Account_Payable_Line__c> apListBefore = [select id from AcctSeed__Account_Payable_Line__c where AcctSeed__Account_Payable__c =:lstAccountPayable[0].id  ];
        List<Map<String,String>> listJSON = gcAccountPayable_Override.retrieveAPLines(lstAccountPayable[0].id);
        System.assert(apListBefore.size()==listJSON.size());
 		Test.stopTest();
    }
    @IsTest
    static void testAccountPayableLine(){
       
        List<AcctSeed__Account_Payable__c> lstAccountPayable = [
                                                                SELECT
                                                                    Id,
                                                                    Name,
                                                                    GL_Account_Variable_3__c,
                                                                    Tax_Override__c,
                                                                    Tax_Rate_Retail__c,
                                                                    Payee_New__c,
                                                                    Tax_Amount_Fixed__c,
                                                                    AcctSeed__Fixed_Asset__c,
                                                                    AcctSeed__Proprietary_Payable_Number__c,
                                                                    GL_Account_Variable_1__c,
                                                                    GL_Account_Variable_2__c,
                                                                    Approval_Date__c,
                                                                    Approved__c, Submitted_Date__c,
                                                                    AcctSeed__VAT_Line_Count__c,
                                                                    AcctSeed__Vendor__c
                                                                FROM
                                                                    AcctSeed__Account_Payable__c
            													LIMIT 1
                                                                ];

		List<AcctSeed__Account_Payable_Line__c> apListBefore = [select id from AcctSeed__Account_Payable_Line__c where AcctSeed__Account_Payable__c =:lstAccountPayable[0].id  ];
        List<Map<String,String>> listJSON = gcAccountPayable_Override.retrieveAPLines(lstAccountPayable[0].id);
        System.assert(apListBefore.size()==listJSON.size());
        Test.startTest();
        List<Map<String,String>> APLine = new List<Map<String,String>>();
        gcAccountPayable_Override.saveAPLines(lstAccountPayable[0].id,listJSON, APLine);
        List<AcctSeed__Account_Payable_Line__c> apList = [select id from AcctSeed__Account_Payable_Line__c where AcctSeed__Account_Payable__c =:lstAccountPayable[0].id];
        System.assert(apList.size()==(listJSON.size()+APLine.size()));
        Test.stopTest();
     
    }

     @IsTest
    static void testAccountPayableLineDelete(){
       
        List<AcctSeed__Account_Payable__c> lstAccountPayable = [
                                                                SELECT
                                                                    Id,
                                                                    Name,
                                                                    GL_Account_Variable_3__c,
                                                                    Tax_Override__c,
                                                                    Tax_Rate_Retail__c,
                                                                    Payee_New__c,
                                                                    Tax_Amount_Fixed__c,
                                                                    AcctSeed__Fixed_Asset__c,
                                                                    AcctSeed__Proprietary_Payable_Number__c,
                                                                    GL_Account_Variable_1__c,
                                                                    GL_Account_Variable_2__c,
                                                                    Approval_Date__c,
                                                                    Approved__c, Submitted_Date__c,
                                                                    AcctSeed__VAT_Line_Count__c,
                                                                    AcctSeed__Vendor__c
                                                                FROM
                                                                    AcctSeed__Account_Payable__c
                                                                ];

        
        List<Map<String,String>> listJSON = gcAccountPayable_Override.retrieveAPLines(lstAccountPayable[0].id);
        Test.startTest();
        gcAccountPayable_Override.deleteAPLine(lstAccountPayable[0].id);
        id accountPayableId = lstAccountPayable[0].id;
        List<AcctSeed__Account_Payable_Line__c> lstAP = [SELECT Id FROM AcctSeed__Account_Payable_Line__c WHERE Id =:accountPayableId];
        
        Test.stopTest();
        

    }

    @isTest
    static void testSearchItems() {

        AcctSeed__Account_Payable__c accountPayable = [
                SELECT
                        id
                FROM
                        AcctSeed__Account_Payable__c
                LIMIT 1
        ];

        ApexPages.StandardController sc = new ApexPages.StandardController(accountPayable);
        gcAccountPayable_Override accountPayableOverride = new gcAccountPayable_Override(sc);
        new Factory_AccountingVariables();

        Test.startTest();
        String json = accountPayableOverride.getAllGlAccounts();
        String jsonGLVariables = accountPayableOverride.getAllGlVariables();
        List<AcctSeed__GL_Account__c> listGLA = gcAccountPayable_Override.searchGLA('Test');
        List<Product2> listProduct = gcAccountPayable_Override.searchProduct('InventoryTestMotor' + Crypto.getRandomLong());
        List<AcctSeed__Project__c> listProject = gcAccountPayable_Override.searchProject('Test');
        List<AcctSeed__Project_Task__c> listProjectForTask = gcAccountPayable_Override.searchProjectTask('test','Test');
        Test.stopTest();
    }

}