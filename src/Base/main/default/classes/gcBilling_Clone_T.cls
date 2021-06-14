@IsTest(SeeAllData=false)
private class gcBilling_Clone_T {
    final static String RECORDTYPE = 'Motor';
    final static String FAMILY = 'Motor Accessories';
    final static String SERIALNUMBER = '123450';
    final static String FNAME = 'TestFirstName';
    final static String LNAME = 'TestLastName';
    final static String TASKNAME = 'Test ERP Task';
    @TestSetup
    static void testData(){

        new Factory_TestData();
        Factory_CustomSettings.setupInventorySettings();
        List<AcctSeed__Project__c> erps;
        Map<Id,AcctSeed__Project_Task__c> erp_task_map;
        Contact dealerContact;


        Date startDate = Date.today().toStartOfMonth().addMonths(-4);
        AcctSeed__Accounting_Period__c previousPeriod = new AcctSeed__Accounting_Period__c(
                AcctSeed__End_Date__c = Date.today().addMonths(-1).toStartOfMonth().addDays(-1),
                AcctSeed__Start_Date__c = startDate,
                AcctSeed__Status__c = 'Open',
                Name = Datetime.newInstance( startDate.year(),
                        startDate.month(),
                        startDate.day() ).format('YYYY-MM')
        );
        insert previousPeriod;
        // Account
        Account dealer = AccountFactory.buildDealerAccount('Test Dealer UnitTester');
        insert dealer;
        String email = LGND_Utilities.generateRandomString(5) + '@' + LGND_Utilities.generateRandomString(5) +'.org';
        dealerContact = Factory_Contact.buildContact(dealer.Id, 'My Amazing', 'Tester', email );
        dealerContact.Receives_Monthly_Statements__c = true;
        update dealerContact;

        // Serial
        GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertFullSerial(
                'Boat',
                'Pontoon',
                '1234567890-UNIT-TESTER'
        );

        // Projects
        //createPartnerPartSales( dealer, serial, 3 );
        integer count=3;

        erps = new List<AcctSeed__Project__c>();
        for( Integer i=0; i<count; i++ )
        {
            erps.add(Factory_ERPOrder.buildERP(dealer, serial.Id, gcConstants.idRtPartnerPartsOrder));
        }
        Boolean origTrig = gcProject.disableTrigger;
        gcProject.disableTrigger = true;
        insert erps;
        gcProject.disableTrigger = origTrig;
        erp_task_map = new Map<Id, AcctSeed__Project_Task__c>();
        for( AcctSeed__Project__c erp : erps )
        {
            erp_task_map.put( erp.Id, Factory_ERPOrder.buildProjectTask( erp.Id, 'Dealer Order' ) );
        }
        insert erp_task_map.values();
        Product2[] parts = Factory_Product.buildNonSerializedProducts('Part', 'Electronics', 5);
        insert parts;
        List<AcctSeedERP__Material__c> mats = new List<AcctSeedERP__Material__c>();
        for( AcctSeed__Project_Task__c task : erp_task_map.values() )
        {
            for( Product2 part : parts )
            {
                mats.add( Factory_ERPOrder.buildMaterial( task.AcctSeed__Project__c, task.Id, part.Id) );
            }
        }
        insert mats;

        List<Product2> serializedProducts = Factory_Product.createSerializedProducts(RECORDTYPE, FAMILY, 10);

        // Billing
        AcctSeed__Billing_Format__c format = [SELECT Id FROM AcctSeed__Billing_Format__c WHERE Name = 'Billing PDF Format' LIMIT 1];
        AcctSeed__Ledger__c ledger = [SELECT Id FROM AcctSeed__Ledger__c LIMIT 1];
        List<AcctSeed__Billing__c> billings = new List<AcctSeed__Billing__c>();
        List<AcctSeed__Cash_Receipt__c> lstCashReceipt = new List<AcctSeed__Cash_Receipt__c>();
        for( AcctSeed__Project__c erp : erps )
        {
            billings.add( new AcctSeed__Billing__c(
                    AcctSeed__Customer__c = dealer.Id,
                    AcctSeed__Billing_Format__c = format.Id,
                    GMBLASERP__Project__c = erp.Id,
                    AcctSeed__Ledger__c = ledger.Id
            )
            );

            lstCashReceipt.add(new AcctSeed__Cash_Receipt__c(
                    AcctSeed__Account__c = dealer.Id,
                    AcctSeed__Amount__c = 5.0,
                    AcctSeed__Receipt_Date__c = Date.today(),
                    AcctSeed__Payment_Reference__c = 'Cash',
                    AcctSeed__Ledger__c = ledger.Id,
                    AcctSeed__Project__c = erp.Id,
                    AcctSeed__Project_Task__c = erp_task_map.get(erp.Id).Id,
                    AcctSeed__Product__c = serializedProducts[0].Id
            ));
        }
        Date thisMonth = Date.today();
        Date lastMonth = Date.today().toStartOfMonth().addMonths(-1);
        Date nextMonth = Date.today().toStartOfMonth().addMonths(1);
        //current
        billings[0].Lgnd_Due_Date__c = Date.newInstance(thisMonth.year(), thisMonth.month(), 15);
        //overdue
        billings[1].Lgnd_Due_Date__c = Date.newInstance(lastMonth.year(), lastMonth.month(), 15);
        //future
        billings[2].Lgnd_Due_Date__c = Date.newInstance(nextMonth.year(), nextMonth.month(), 16);
        insert billings;
        insert lstCashReceipt;
        List<AcctSeed__Billing_Line__c> billingLines = new List<AcctSeed__Billing_Line__c>();

        for( AcctSeed__Billing__c billing : billings )
        {
            billingLines.add( new AcctSeed__Billing_Line__c(
                    AcctSeed__Billing__c = billing.Id,
                    AcctSeed__Revenue_GL_Account__c = gcConstants.idGlCustomerRefund,
                    AcctSeed__Hours_Units__c = 1,
                    AcctSeed__Rate__c = 5.0,
                    AcctSeed__GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale,
                    AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2Sales,
                    AcctSeed__Project__c = billing.GMBLASERP__Project__c,
                    AcctSeed__Project_Task__c = erp_task_map.get( billing.GMBLASERP__Project__c ).Id,
                    AcctSeed__List_Price__c=50,
                    AcctSeed__Product_Unit_Cost__c=50,
                    AcctSeed__Tax_Amount2__c=1.2
            ) );

        }
        insert billingLines;

    }
    @IsTest
    static void test3NoBilling(){
        gcBilling_Clone clone = new gcBilling_Clone();
        clone.init();
        clone.createClone();
    }
    @IsTest
    static void test1StandardController() {
        //PAGENAME: gpBilling_Clone
        //reverse,
        List<AcctSeed__Billing__c> billings = [
                SELECT Id FROM AcctSeed__Billing__c
        ];

        Test.setCurrentPage(Page.gpBilling_Clone);
        ApexPages.currentPage().getParameters().put('retUrl', 'www.google.com');
        ApexPages.currentPage().getParameters().put('cloneType', 'reverse');
        ApexPages.currentPage().getParameters().put('idFilter', billings[0].Id);
        ApexPages.StandardController std = new ApexPages.StandardController(billings[0]);

        Test.StartTest();
        gcBilling_Clone ext = new gcBilling_Clone(std);
        ext.init();
        PageReference pr = ext.back();
        //system.assertEquals('www.google.com', pr.getUrl());
        Test.stopTest();
    }
    @IsTest
    static void test1StandardSetController() {
        //PAGENAME: gpBilling_Clone
        //reverse,
        List<AcctSeed__Billing__c> billings = [
                SELECT Id FROM AcctSeed__Billing__c
        ];

        Test.setCurrentPage(Page.gpBilling_Clone);
        ApexPages.currentPage().getParameters().put('retUrl', 'www.google.com');
        ApexPages.currentPage().getParameters().put('cloneType', 'reverse');
        ApexPages.currentPage().getParameters().put('idFilter', billings[0].Id);
        ApexPages.StandardSetController std = new ApexPages.StandardSetController(billings);
        std.setSelected(billings);
        Test.StartTest();
        gcBilling_Clone ext = new gcBilling_Clone(std);
        ext.init();
        Test.stopTest();
    }


    @IsTest
    static void test1StandardControllerNoRetURL() {
        //PAGENAME: gpBilling_Clone
        //reverse,
        List<AcctSeed__Billing__c> billings = [
                SELECT Id FROM AcctSeed__Billing__c
        ];

        Test.setCurrentPage(Page.gpBilling_Clone);
        ApexPages.currentPage().getParameters().put('cloneType', 'reverse');
        ApexPages.currentPage().getParameters().put('idFilter', billings[0].Id);
        ApexPages.StandardSetController std = new ApexPages.StandardSetController(billings);
        std.setSelected(billings);
        Test.StartTest();
        gcBilling_Clone ext = new gcBilling_Clone(std);
        ext.init();
        Test.stopTest();
    }
}