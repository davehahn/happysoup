/**
 * Created by Legend on 17/12/21.
 */

@IsTest
private class gcProjectLaborJobCost_test {

    static Account cust;
    static GMBLASERP__Serial_Number__c ser;
    static AcctSeedERP__Warehouse__c wh;
    static AcctSeedERP__Location__c loc;
    Static AcctSeed__Project__c erp;

    @testSetup static void dataSetup()
    {
        new Factory_TestData();
        Factory_CustomSettings.setupInventorySettings();
        AcctSeedERP__Warehouse__c whMon = [SELECT Id, Name, GL_Account_Variable_3__c FROM AcctSeedERP__Warehouse__c WHERE Name = 'Montreal'];
        Account dealer = AccountFactory.buildDealerAccount('Test Dealer UnitTester');
        dealer.Warehouse__c = whMon.Id;
        insert dealer;
        Factory_SerialNumber.insertFullSerial('Boat','Pontoon','0987654321');
    }

    static void initMFG()
    {
        cust = [SELECT Id, Name  FROM Account Where Name = 'Test Dealer UnitTester'];
        ser = [SELECT Id, Name, GMBLASERP__Product__c, GMBLASERP__Product__r.AcctSeed__Inventory_GL_Account__c, GMBLASERP__Lot__c FROM GMBLASERP__Serial_Number__c WHERE Name = '0987654321' LIMIT 1];
        wh = [SELECT Id, Name, GL_Account_Variable_3__c FROM AcctSeedERP__Warehouse__c WHERE Name = 'Wholesale'];
        loc = [SELECT Id FROM AcctSeedERP__Location__c WHERE AcctSeedERP__Warehouse__c =:wh.Id LIMIT 1];
        erp = Factory_ERPOrder.buildERP( cust, ser.Id, gcConstants.idRtProjectManufacturing );
        erp.AcctSeedERP__Manufactured_Product__c = ser.GMBLASERP__Product__c;
        erp.GMBLASERP__Warehouse__c = wh.Id;
        GMBLASERP.gcProject.disableTrigger = true;
        gcProject.disableTrigger = true;
        insert erp;
        gcProject.disableTrigger = false;
        GMBLASERP.gcProject.disableTrigger = false;
        AcctSeed__Project_Task__c task = Factory_ERPOrder.buildProjectTask( erp.Id, 'Pre-Rig' );
        task.Product__c = ser.GMBLASERP__Product__c;
        insert task;
        AcctSeedERP__Material__c mat = Factory_ERPOrder.buildMaterial( erp.Id, task.Id, ser.GMBLASERP__Product__c);
        mat.GMBLASERP__Serial_Number__c = ser.Id;
        mat.GMBLASERP__Lot__c = ser.GMBLASERP__Lot__c;
        insert mat;
    }

    @IsTest
    static void testProjectLabourValue()
    {
        initMFG();
        AcctSeed__Accounting_Settings__c accSetting = [SELECT AcctSeed__Default_Ledger__c FROM AcctSeed__Accounting_Settings__c ORDER BY CreatedDate][0];
        System.debug('accSetting');
        System.debug(accSetting);
        AcctSeedERP__Warehouse__c wh = [SELECT Id, Name, GL_Account_Variable_3__c FROM AcctSeedERP__Warehouse__c WHERE Name = 'Wholesale'];
        AcctSeedERP__Location__c loc = [SELECT Id FROM AcctSeedERP__Location__c WHERE AcctSeedERP__Warehouse__c =:wh.Id LIMIT 1];
        /// Inbound the inventory for the serial
        Id idBalance = GCR_InventoryBalance.findOrCreateBalance(ser.GMBLASERP__Product__c,wh.Id,loc.Id);
        /// Bring the inventory in
        AcctSeedERP__Inbound_Inventory_Movement__c inmove = new AcctSeedERP__Inbound_Inventory_Movement__c(
                AcctSeedERP__Unit_Cost__c = 9000,
                AcctSeedERP__Type__c = 'Accounting',
                AcctSeedERP__Quantity__c = 1,
                AcctSeedERP__Credit_GL_Account__c = ser.GMBLASERP__Product__r.AcctSeed__Inventory_GL_Account__c,
                AcctSeedERP__Inventory_Balance__c = idBalance,
                AcctSeedERP__Ledger__c = accSetting.AcctSeed__Default_Ledger__c,
                GMBLASERP__Warehouse__c = wh.Id,
                AcctSeedERP__Movement_Date__c = Date.today(),
                GMBLASERP__Lot__c = ser.GMBLASERP__Lot__c,
                GMBLASERP__Serial_Number__c = ser.Id
        );
        gcInboundInventoryMovement.disableTrigger = true;
        insert inmove;

        GMBLASERP.gcInventoryMovementCube.allowDML = true;
        GMBLASERP__Inventory_Movement_Cube__c cube = new GMBLASERP__Inventory_Movement_Cube__c();
        cube.GMBLASERP__Inventory_Balance__c = idBalance;
        cube.GMBLASERP__Location__c = loc.Id;
        cube.GMBLASERP__Product__c = ser.GMBLASERP__Product__c;
        cube.GMBLASERP__Movement_Date__c = Date.today();
        cube.GMBLASERP__Warehouse__c = wh.Id;
        cube.GMBLASERP__Movement_Type__c = 'AcctSeedERP__Inbound_Inventory_Movement__c';
        cube.GMBLASERP__Quantity__c = 10;
        cube.GMBLASERP__Inventory_GL_Amount__c = 9000;
        cube.GMBLASERP__Serial_Number__c = ser.Id;
        cube.GMBLASERP__Lot__c = ser.GMBLASERP__Lot__c;
        /// Inv to WIP to COGS
        String currentDate = Datetime.now().format('dd/MM/yyyy');
        gcProject_AccountingActions.createWipRA(erp.Id,wh.Id,currentDate);
    }
}