/**
 * Created by Legend on 27/8/21.
 */

@IsTest
private class GCR_InventoryTransfer_Test {
    static Account cust;
    static GMBLASERP__Serial_Number__c ser;
    static AcctSeedERP__Location__c loc;

    @testSetup static void dataSetup()
    {
        new Factory_TestData();
        Factory_CustomSettings.setupInventorySettings();
        Factory_SerialNumber.insertFullSerial('Boat','Pontoon','0987654321');
    }

    static void init()
    {
        ser = [SELECT Id, Name, GMBLASERP__Product__c, GMBLASERP__Product__r.AcctSeed__Inventory_GL_Account__c, GMBLASERP__Lot__c FROM GMBLASERP__Serial_Number__c WHERE Name = '0987654321' LIMIT 1];
    }

    @IsTest
    static void createTransfer(){
        init();
        Id idWarehouseWholesale = gcConstants.idWarehouseWholesale;
        Id idWarehouseMontreal = gcConstants.idWarehouseMontreal;
        loc = [SELECT Id FROM AcctSeedERP__Location__c WHERE AcctSeedERP__Warehouse__c =:idWarehouseWholesale LIMIT 1];
        Account vendor = Factory_Account.insertSupplierAccounts(1)[0];
        AcctSeed__Accounting_Settings__c accSetting = [SELECT AcctSeed__Default_Ledger__c FROM AcctSeed__Accounting_Settings__c ORDER BY CreatedDate][0];
        System.debug('accSetting');
        System.debug(accSetting);
        AcctSeedERP__Purchase_Order__c po = Factory_PurchaseOrder.createMinimalPO(
                vendor.Id, null
        );

        AcctSeedERP__Purchase_Order_Line__c pol = Factory_PurchaseOrder.buildLineItem(
                po.Id,
                ser.GMBLASERP__Product__c,
                1
        );
        pol.AcctSeedERP__Unit_Price__c = 20000;
        pol.GMBLASERP__Serial_Number__c = ser.Id;
        pol.GMBLASERP__Lot__c = ser.GMBLASERP__Lot__c;
        pol.deliverDate__c = Date.today();
        insert pol;
        /// Inbound the inventory for the serial
        Id idBalance = GCR_InventoryBalance.findOrCreateBalance(ser.GMBLASERP__Product__c,idWarehouseWholesale,loc.Id);
        /// Bring the inventory in
        AcctSeedERP__Purchase_Order_Inventory_Movement__c movement = new AcctSeedERP__Purchase_Order_Inventory_Movement__c(
                AcctSeedERP__Unit_Cost__c = 10000,
                AcctSeedERP__Quantity__c = 1,
                AcctSeedERP__Inventory_Balance__c = idBalance,
                AcctSeedERP__Ledger__c = accSetting.AcctSeed__Default_Ledger__c,
                GMBLASERP__Warehouse__c = idWarehouseWholesale,
                AcctSeedERP__Movement_Date__c = Date.today(),
                GMBLASERP__Product__c = ser.GMBLASERP__Product__c,
                GMBLASERP__Serial_Number__c = ser.Id,
                GMBLASERP__Lot__c = ser.GMBLASERP__Lot__c,
                AcctSeedERP__Purchase_Order_Line__c = pol.Id,
                GMBLASERP__Purchase_Order__c = po.Id
        );
        insert movement;
        Test.startTest();
        GMBLASERP__Inventory_Transfer__c xfr = new GMBLASERP__Inventory_Transfer__c();// Ware= imc.Warehouse__c, Warehouse_To__c = idWarehouse2, Outbound_Date__c = date.today());
        xfr.GMBLASERP__Warehouse_From__c = idWarehouseWholesale;
        xfr.GMBLASERP__Warehouse_To__c = idWarehouseMontreal;
        xfr.GMBLASERP__Outbound_Date__c = Date.today();
        xfr.Comments__c = 'Test Comment';
        insert xfr;

        Id idProduct = ser.GMBLASERP__Product__c;
        Id idLot = ser.GMBLASERP__Lot__c;
        Id idSerial = ser.Id;
        Id idGLDebit = ser.GMBLASERP__Product__r.AcctSeed__Inventory_GL_Account__c;

        AcctSeedERP__Outbound_Inventory_Movement__c outmove = new AcctSeedERP__Outbound_Inventory_Movement__c
                (
                        AcctSeedERP__Debit_GL_Account__c = idGLDebit,
                        AcctSeedERP__Inventory_Balance__c = idBalance,
                        AcctSeedERP__Movement_Date__c = xfr.GMBLASERP__Outbound_Date__c,
                        AcctSeedERP__Quantity__c = 1,
                        AcctSeedERP__Type__c = 'Non-Accounting',
                        AcctSeedERP__Unit_Cost__c = 0,
                        GMBLASERP__Cost_Override__c = true,
                        GMBLASERP__Inventory_Transfer__c = xfr.Id,
                        GMBLASERP__Lot__c = idLot,
                        GMBLASERP__Serial_Number__c = idSerial
                );

        insert outmove;

        //xfr.GMBLASERP__Inbound_Date__c = Date.today();
        //update xfr;
        /// Now delete the outbound
        delete outmove;
        Test.stopTest();
    }

    @IsTest
    static void deleteTransfer(){
        init();
        Id idWarehouseWholesale = gcConstants.idWarehouseWholesale;
        Id idWarehouseMontreal = gcConstants.idWarehouseMontreal;
        loc = [SELECT Id FROM AcctSeedERP__Location__c WHERE AcctSeedERP__Warehouse__c =:idWarehouseWholesale LIMIT 1];
        Account vendor = Factory_Account.insertSupplierAccounts(1)[0];
        AcctSeed__Accounting_Settings__c accSetting = [SELECT AcctSeed__Default_Ledger__c FROM AcctSeed__Accounting_Settings__c ORDER BY CreatedDate][0];
        System.debug('accSetting');
        System.debug(accSetting);
        AcctSeedERP__Purchase_Order__c po = Factory_PurchaseOrder.createMinimalPO(
                vendor.Id, null
        );

        AcctSeedERP__Purchase_Order_Line__c pol = Factory_PurchaseOrder.buildLineItem(
                po.Id,
                ser.GMBLASERP__Product__c,
                1
        );
        pol.AcctSeedERP__Unit_Price__c = 20000;
        pol.GMBLASERP__Serial_Number__c = ser.Id;
        pol.GMBLASERP__Lot__c = ser.GMBLASERP__Lot__c;
        pol.deliverDate__c = Date.today();
        insert pol;
        /// Inbound the inventory for the serial
        Id idBalance = GCR_InventoryBalance.findOrCreateBalance(ser.GMBLASERP__Product__c,idWarehouseWholesale,loc.Id);
        /// Bring the inventory in
        AcctSeedERP__Purchase_Order_Inventory_Movement__c movement = new AcctSeedERP__Purchase_Order_Inventory_Movement__c(
                AcctSeedERP__Unit_Cost__c = 10000,
                AcctSeedERP__Quantity__c = 1,
                AcctSeedERP__Inventory_Balance__c = idBalance,
                AcctSeedERP__Ledger__c = accSetting.AcctSeed__Default_Ledger__c,
                GMBLASERP__Warehouse__c = idWarehouseWholesale,
                AcctSeedERP__Movement_Date__c = Date.today().addDays(-5),
                GMBLASERP__Product__c = ser.GMBLASERP__Product__c,
                GMBLASERP__Serial_Number__c = ser.Id,
                GMBLASERP__Lot__c = ser.GMBLASERP__Lot__c,
                AcctSeedERP__Purchase_Order_Line__c = pol.Id,
                GMBLASERP__Purchase_Order__c = po.Id
        );
        insert movement;
        GMBLASERP__Inventory_Transfer__c xfr = new GMBLASERP__Inventory_Transfer__c();// Ware= imc.Warehouse__c, Warehouse_To__c = idWarehouse2, Outbound_Date__c = date.today());
        xfr.GMBLASERP__Warehouse_From__c = idWarehouseWholesale;
        xfr.GMBLASERP__Warehouse_To__c = idWarehouseMontreal;
        xfr.GMBLASERP__Outbound_Date__c = Date.today().addDays(-2);
        xfr.GMBLASERP__Inbound_Date__c = Date.today();
        xfr.Comments__c = 'Test Comment';
        insert xfr;

        Id idProduct = ser.GMBLASERP__Product__c;
        Id idLot = ser.GMBLASERP__Lot__c;
        Id idSerial = ser.Id;
        Id idGLDebit = ser.GMBLASERP__Product__r.AcctSeed__Inventory_GL_Account__c;

        AcctSeedERP__Outbound_Inventory_Movement__c outmove = new AcctSeedERP__Outbound_Inventory_Movement__c
                (
                        AcctSeedERP__Debit_GL_Account__c = idGLDebit,
                        AcctSeedERP__Inventory_Balance__c = idBalance,
                        AcctSeedERP__Movement_Date__c = xfr.GMBLASERP__Outbound_Date__c,
                        AcctSeedERP__Quantity__c = 1,
                        AcctSeedERP__Type__c = 'Non-Accounting',
                        AcctSeedERP__Unit_Cost__c = 0,
                        GMBLASERP__Cost_Override__c = true,
                        GMBLASERP__Inventory_Transfer__c = xfr.Id,
                        GMBLASERP__Lot__c = idLot,
                        GMBLASERP__Serial_Number__c = idSerial
                );

        insert outmove;

        //xfr.GMBLASERP__Inbound_Date__c = Date.today();
        //update xfr;
        /// Now delete the outbound
        List<AcctSeedERP__Inbound_Inventory_Movement__c> listInMove = new List<AcctSeedERP__Inbound_Inventory_Movement__c>();
        for(AcctSeedERP__Inbound_Inventory_Movement__c inmove : [SELECT Id FROM AcctSeedERP__Inbound_Inventory_Movement__c WHERE AcctSeedERP__Outbound_Inventory_Movement__c = :outmove.Id]){
            listInMove.add(inmove);
        }
        if(!listInMove.isEmpty())
            delete listInMove;
        Test.stopTest();
    }
}