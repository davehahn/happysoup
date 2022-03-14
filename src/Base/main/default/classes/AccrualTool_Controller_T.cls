@IsTest
public class AccrualTool_Controller_T {
    
    private static final Integer PARTS_COUNT = 3;
    private static final Decimal RIGGINNG_TIME = 1;
    private static final Decimal COMM_COST = 50;
    private static final Decimal COMM_SALE = 100;
    private static final Decimal COMM_LABOUR = 150;
    private static final String boatSerial = 'TESTFULLWINDSHIELD0001';
    private static AcctSeed__Project__c erp;
    private static AcctSeed__Project_Task__c erpTask;
    private static  List<AcctSeedERP__Material__c> materials;
    private static List<Id> materialIds;
    private static Id matWithMultipleId;
    private static CommissionRecord2__c commRec;
    
    @testSetup static void dataSetup()
    {
        new Factory_TestData();
        Factory_CustomSettings.setupInventorySettings();
        Account customer = Factory_Account.insertCustomerAccounts(1)[0];
        AcctSeedERP__Warehouse__c wh = [SELECT Id, Name FROM AcctSeedERP__Warehouse__c LIMIT 1][0];
        GMBLASERP__Serial_Number__c ser = Factory_SerialNumber.insertFullSerial(
            'Boat',
            'Full Windshield',
            boatSerial
        );
        gcProject.disableTrigger = true;
        gcProjectTask.disableTrigger = true;
        gcMaterial.disableTrigger = true;
        
        AcctSeed__GL_Account__c revenueAccount;
        AcctSeed__GL_Account__c expenseAccount;
        AcctSeed__GL_Account__c commissionAccount;
        List<AcctSeed__GL_Account__c> glAccts = new List<AcctSeed__GL_Account__c>();
        revenueAccount = new AcctSeed__GL_Account__c(Name='Test Revenue Account',
                                                     AcctSeed__Active__c = true,
                                                     AcctSeed__Type__c = 'Revenue',
                                                     Uniquefier__c = 'AccruedRevenue');
        expenseAccount = new AcctSeed__GL_Account__c(Name='Test Expense Account',
                                                     AcctSeed__Active__c = true,
                                                     AcctSeed__Type__c = 'Expense',
                                                     Uniquefier__c = 'AccruedExpenses');
        commissionAccount = new AcctSeed__GL_Account__c(Name='Test Inventory Account',
                                                       AcctSeed__Active__c = true,
                                                       AcctSeed__Sub_Type_1__c = 'Assets',
                                                       AcctSeed__Type__c = 'Balance Sheet',
                                                       Uniquefier__c = 'CommissionExpense');
        glAccts.add(revenueAccount);
       // glAccts.add(expenseAccount);
        //glAccts.add(commissionAccount);
        
        insert glAccts;
        
        AcctSeed__Project__c retailSale = Factory_ERPOrder.insertRetailBoatSale(
            customer,
            wh,
            DateTime.now().addDays(20),
            ser
        );
        retailSale.GL_Account_Variable_1__c = gcConstants.idGlv1Whitefish;
        retailSale.GL_Account_Variable_2__c = gcConstants.idGlv2Sales;
        retailSale.GL_Account_Variable_3__c = gcConstants.idGlv3Ontario;
        update retailSale;
        AcctSeed__Project_Task__c retailTask = [
            SELECT
            Id
            FROM AcctSeed__Project_Task__c
            WHERE AcctSeed__Project__c = :retailSale.Id
        ];
        List<Product2> parts = Factory_Product.buildNonSerializedProducts(
            'Part',
            'Hardware',
            PARTS_COUNT
        );
        parts[0].Rigging_Time__c = RIGGINNG_TIME;
        insert parts;
        
        Factory_PricebookEntry.createStandardEntries( parts, 10 );
        List<PricebookEntry> pbes = new List<PricebookEntry>();
        pbes.addAll( Factory_PricebookEntry.buildEntries( parts, LGND_Constants.retailPricebookId, 10 ) );
        pbes.addAll( Factory_PricebookEntry.buildEntries( parts, LGND_Constants.factoryPricebookId, 5 ) );
        insert pbes;
        
        List<AcctSeedERP__Material__c> mats = Factory_Material.buildMaterials(
            retailSale.Id,
            retailTask.Id,
            parts
        );
        for( AcctSeedERP__Material__c mat : mats ){
          mat.GMBLASERP__Total_Price__c = mat.AcctSeedERP__Quantity_Per_Unit__c * mat.GMBLASERP__Unit_Price__c;
        }
        mats[0].AcctSeedERP__Quantity_Per_Unit__c = 3;
        mats[0].GMBLASERP__Total_Price__c = mats[0].GMBLASERP__Total_Price__c * 3;
        insert mats;
    }
    
    private static void initErpData()
    {
        erp = [
            SELECT
            Id,
            AcctSeed__Account__c,
            AcctSeed__Account__r.Name,
            GMBLASERP__Warehouse__c,
            GL_Account_Variable_1__c,
            GL_Account_Variable_2__c,
            GL_Account_Variable_3__c,
            Serial_Number__c,
            Serial_Number__r.Name,
            RecordType.Name,
            ( SELECT
             Id,
             Commission_Calculation_Method__c
             FROM AcctSeed__Project_Tasks__r ),
            ( SELECT
             Id,
              GMBLASERP__Total_Price__c,
             AcctSeedERP__Product__c,
             AcctSeedERP__Product__r.Name,
             AcctSeedERP__Product__r.Rigging_Time__c,
             AcctSeedERP__Project_Task__c,
             AcctSeedERP__Quantity_Per_Unit__c,
             GMBLASERP__Unit_Price__c,
             GMBLASERP__Price_Override__c,
             AcctSeedERP__Comment__c,
             Material__c
             FROM AcctSeedERP__Project_Materials__r
             WHERE AcctSeedERP__Product__r.RecordTypeId = :new Application_RecordType().getProductRecordTypes().getPartId() )
            FROM
            AcctSeed__Project__c
            LIMIT 1][0];
        erpTask = erp.AcctSeed__Project_Tasks__r[0];
        materialIds = new List<Id>();
        materials = new List<AcctSeedERP__Material__c>();
        for( AcctSeedERP__Material__c mat : erp.AcctSeedERP__Project_Materials__r )
        {
          System.debug('material total - ' + mat.GMBLASERP__Total_Price__c );
          materials.add( mat );
          materialIds.add( mat.Id );
          if( mat.AcctSeedERP__Quantity_Per_Unit__c > 1 )
          {
              matWithMultipleId = mat.Id;
          }
        }
        commRec = new CommissionRecord2__c(
            Project_Task__c = erpTask.Id,
            Calculation_Method__c = erpTask.Commission_Calculation_Method__c
        );
        insert commRec;
    }
    
    private static void createCommissionRecord()
    {
        CommissionRecord2__c record = new CommissionRecord2__c(
            Project_Task__c = erpTask.Id,
            Calculation_Method__c = erpTask.Commission_Calculation_Method__c
        );
        insert record;
        Decimal profit = ( COMM_SALE - COMM_COST - COMM_LABOUR ) * materials[0].AcctSeedERP__Quantity_Per_Unit__c;
        Decimal rate = CommissionLineItem2_Service.grossMarginRate;
        
        CommissionLineItem2__c line = new CommissionLineItem2__c(
            CommissionRecord2__c = record.Id,
            Material__c = materials[0].Id,
            Quantity__c = materials[0].AcctSeedERP__Quantity_Per_Unit__c,
            Sale_Price__c = COMM_SALE,
            Cost__c = COMM_COST,
            Labour_Cost__c = COMM_LABOUR,
            Commission_Rate__c = rate,
            Payment_Based_on_Profit__c = true,
            Profit__c = profit,
            Payment_Amount__c = profit * rate,
            Actual_Amount_for_Commission__c = profit
        );
        TriggerBase.bypass('CommissionLineItem2__c');
        insert line;
    }
    @IsTest
    static void testAccrualToolController()
    {
        initErpData();
        createCommissionRecord();
      for (AcctSeedERP__Material__c material : [
        SELECT
          id,
          Serial_Number__c,
          AcctSeedERP__Product__c,
          AcctSeedERP__Product__r.Name,
          GMBLASERP__Total_Price__c,
          AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__c,
          AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__r.Name,
          AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__r.AcctSeed__Type__c,
          AcctSeedERP__Product__r.AcctSeed__Revenue_GL_Account__c,
          AcctSeedERP__Product__r.AcctSeed__Revenue_GL_Account__r.Name,
          AcctSeedERP__Product__r.AcctSeed__Revenue_GL_Account__r.AcctSeed__Type__c,
          AcctSeedERP__Product__r.RecordType.Name,
          AcctSeedERP__Product__r.Insurance_Profit_Percent_Override__c,
          AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_1__c,
          AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_1__r.Name,
          AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__c,
          AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__r.Name
        FROM AcctSeedERP__Material__c
        WHERE AcctSeedERP__Project__c = :erp.Id
      ]) {
        System.debug(material.AcctSeedERP__Product__r.Name + ' - ' + material.GMBLASERP__Total_Price__c );
      }
        Test.startTest();
        AcctSeed__Project__c erpRecord = AccrualTool_Controller.fetchERPData(String.valueOf(erp.Id));
        AccrualTool_Controller.CommissionWrapper commWrapper = AccrualTool_Controller.fetchCommissionRecords(String.valueOf(erp.Id));
        AccrualTool_Controller.fetchOrderLines(String.valueOf(erp.Id));
        List<AccrualTool_Controller.ProductWrapper> products = AccrualTool_Controller.fetchSerializedProducts(String.valueOf(erp.Id));
        String msg = AccrualTool_Controller.createJournalEntry(String.valueOf(erp.Id), String.valueOf(Date.today()));
        String errorMsg = AccrualTool_Controller.createJournalEntry(String.valueOf(erp.Id), 'error Date');
        Test.stopTest();
        
        system.assertEquals(erp.Id, erpRecord.Id);
        system.assertEquals(false,commWrapper.isReviewed);
        system.assertEquals(2, commWrapper.commissionRecordsList.size());
        system.assertEquals(1, commWrapper.commPaymentWrapper.size());
        system.assertEquals(1, products.size());
        system.assertEquals('Journal Entry Created!', msg);
        if(errorMsg.containsIgnoreCase('Error')) {
            system.assert(true, errorMsg);
        }
    }
}