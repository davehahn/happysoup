//TODO : Remove disableTrigger
@isTest
public class TA_ManufacturingInvMovement_Legacy_T {

    static List<AcctSeedERP__Manufacturing_Inventory_Movement__c> manufacturingInv;
    private static List<AcctSeedERP__Manufacturing_Inventory_Movement__c> getData(){
        return [Select
                id ,
                AcctSeedERP__Unit_Cost__c,
                AcctSeedERP__Material__c,
                AcctSeedERP__Quantity__c,
                AcctSeedERP__Inventory_Balance__c,
                AcctSeedERP__Ledger__c,
                AcctSeedERP__Movement_Date__c,
                GMBLASERP__Lot__c ,
                GMBLASERP__Serial_Number__c,
                AcctSeedERP__Status__c,
                GMBLASERP__Project__c,
                GMBLASERP__Cost_Override__c

        From
                AcctSeedERP__Manufacturing_Inventory_Movement__c
        ];
    }
    @testSetup
    static void dataSetup()
    {
        new Factory_TestData();
        Factory_CustomSettings.setupInventorySettings();
        AcctSeed__Accounting_Settings__c accSetting = [SELECT AcctSeed__Default_Ledger__c FROM AcctSeed__Accounting_Settings__c ORDER BY CreatedDate][0];
        AcctSeedERP__Warehouse__c wh = [SELECT Id, Name, GL_Account_Variable_3__c FROM AcctSeedERP__Warehouse__c LIMIT 1];
        AcctSeedERP__Location__c loc = [SELECT Id FROM AcctSeedERP__Location__c WHERE AcctSeedERP__Warehouse__c =:wh.Id LIMIT 1];
        Account cust = Factory_Account.insertFullPersonAccount('TestFname', 'TestLname');
        GMBLASERP__Serial_Number__c ser = Factory_SerialNumber.insertFullSerial('Boat','Pontoon','0987654321');
      //  Boolean orig = gcProject.disableTrigger;
      //  gcProject.disableTrigger = true;
        TriggerBase.bypass('AcctSeed__Project__c');
        AcctSeed__Project__c erp = Factory_ERPOrder.insertRetailBoatSale( cust, wh, DateTime.now(), ser);
        TriggerBase.clearBypass('AcctSeed__Project__c');

        //GMBLASERP__Serial_Number__c serial = [SELECT Id, GMBLASERP__Inventory_Balance__c FROM GMBLASERP__Serial_Number__c WHERE Id=:ser.Id][0];
        Product2 prod = [SELECT Id, AcctSeed__Inventory_GL_Account__c FROM Product2 WHERE Id=:ser.GMBLASERP__Product__c LIMIT 1];
        System.debug(LoggingLevel.ERROR,'ser:'+ser);
        AcctSeedERP__Material__c matl = [SELECT Id, AcctSeedERP__Product__c FROM AcctSeedERP__Material__c WHERE AcctSeedERP__Project__c =:erp.Id AND GMBLASERP__Serial_Number__c =:ser.Id][0];
        System.debug(LoggingLevel.ERROR,'matl:'+matl);
        ////
        AcctSeedERP__Inventory_Balance__c balance = new AcctSeedERP__Inventory_Balance__c(
                AcctSeedERP__Location__c = loc.Id,
                AcctSeedERP__Warehouse__c = wh.Id,
                AcctSeedERP__Product__c = ser.GMBLASERP__Product__c
        );
        insert balance;
        Test.startTest();
        AcctSeedERP__Inbound_Inventory_Movement__c inmove = new AcctSeedERP__Inbound_Inventory_Movement__c(
                AcctSeedERP__Unit_Cost__c = 100000,
                AcctSeedERP__Type__c = 'Accounting',
                AcctSeedERP__Quantity__c = 1,
                AcctSeedERP__Credit_GL_Account__c = prod.AcctSeed__Inventory_GL_Account__c,
                AcctSeedERP__Inventory_Balance__c = balance.Id,
                AcctSeedERP__Ledger__c = accSetting.AcctSeed__Default_Ledger__c,
                GMBLASERP__Warehouse__c = wh.Id,
                AcctSeedERP__Movement_Date__c = Date.today(),
                GMBLASERP__Lot__c = ser.GMBLASERP__Lot__c,
                GMBLASERP__Serial_Number__c = ser.Id
        );
        GMBLASERP.gcInboundInventoryMovement.disableTrigger = true;
        insert inmove;
        ////
        AcctSeedERP__Manufacturing_Inventory_Movement__c movement = new AcctSeedERP__Manufacturing_Inventory_Movement__c(
                AcctSeedERP__Material__c = matl.Id,
                AcctSeedERP__Quantity__c = 1,
                AcctSeedERP__Inventory_Balance__c = balance.Id,
                AcctSeedERP__Ledger__c = accSetting.AcctSeed__Default_Ledger__c,
                AcctSeedERP__Movement_Date__c = Date.today(),
                GMBLASERP__Lot__c = ser.GMBLASERP__Lot__c,
                GMBLASERP__Serial_Number__c = ser.Id,
                AcctSeedERP__Unit_Cost__c = 0
        );
        GMBLASERP.gcManufacturingInventoryMovement.disableTrigger = true;
        insert movement;
        Test.stopTest();
        /// To test call serial update
        //update movement;
    }


    @IsTest
    static void afterInsertTest() {
        Test.startTest();
        new TA_ManufacturingInventoryMovement_Legacy().afterInsert(getData());
        Test.stopTest();
    }
    @IsTest
    static void afterUpdateTest() {
        Test.startTest();
        manufacturingInv = getData();
        AcctSeedERP__Manufacturing_Inventory_Movement__c geClone =manufacturingInv[0].clone(true, true, true, true);
        new TA_ManufacturingInventoryMovement_Legacy().afterUpdate(new List<AcctSeedERP__Manufacturing_Inventory_Movement__c>{manufacturingInv[0]},new List<AcctSeedERP__Manufacturing_Inventory_Movement__c>{geClone});
        Test.stopTest();
    }
    @IsTest
    static void beforeUpdateTest() {
        Test.startTest();
        manufacturingInv = getData();
        AcctSeedERP__Manufacturing_Inventory_Movement__c geClone =manufacturingInv[0].clone(true, true, true, true);
        new TA_ManufacturingInventoryMovement_Legacy().afterUpdate(new List<AcctSeedERP__Manufacturing_Inventory_Movement__c>{manufacturingInv[0]},new List<AcctSeedERP__Manufacturing_Inventory_Movement__c>{geClone});
        Test.stopTest();
    }

    @IsTest
    static void afterDeleteTest() {
        Test.startTest();
        new TA_ManufacturingInventoryMovement_Legacy().afterDelete(getData());
        Test.stopTest();
    }



}