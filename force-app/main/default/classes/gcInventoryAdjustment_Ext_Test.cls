@isTest
private class gcInventoryAdjustment_Ext_Test{

    @testSetup static void dataSetup()
    {
        new Factory_TestData();
        Factory_CustomSettings.setupInventorySettings();
    }

    @IsTest
    static void testAdjustmentValue()
    {
        AcctSeed__Ledger__c ledger = [SELECT Id FROM AcctSeed__Ledger__c Where AcctSeed__Type__c = 'Transactional'];
        AcctSeedERP__Warehouse__c wh;
        AcctSeedERP__Warehouse__c whAd;
        AcctSeedERP__Warehouse__c whIn;
        for(AcctSeedERP__Warehouse__c w : [SELECT Id, Name FROM AcctSeedERP__Warehouse__c WHERE Name IN ('Adjustments','Wholesale','In Transit')]){
            if(w.Name == 'Adjustments')
                whAd = w;
            if(w.Name == 'Wholesale')
                wh = w;
            if(w.Name == 'In Transit')
                whIn = w;
        }
        AcctSeedERP__Location__c loc = new AcctSeedERP__Location__c(
            Name = 'Test Loc',
            AcctSeedERP__Warehouse__c = wh.Id
        );
        insert loc;
        Product2 part = Factory_Product.createNonSerializedProduct('Part', 'Electronics');
        AcctSeedERP__Inventory_Balance__c balance = new AcctSeedERP__Inventory_Balance__c(
            AcctSeedERP__Location__c = loc.Id,
            AcctSeedERP__Warehouse__c = wh.Id,
            AcctSeedERP__Product__c = part.Id
        );
        // Required for Hibiscus;
        //balance.AcctSeedERP__Ledger__c = ledger.Id;
        insert balance;
        Account[] accts = Factory_Account.insertSupplierAccounts(2);
        Account vendor = accts[0];
        Account shipTo = accts[1];
        AcctSeedERP__Purchase_Order__c po = Factory_PurchaseOrder.createMinimalPO( vendor.Id, shipTo.Id );
        System.debug([SELECT Id, AcctSeedERP__Vendor_Country__c FROM AcctSeedERP__Purchase_Order__c WHERE Id = :po.Id]);
        AcctSeedERP__Purchase_Order_Line__c pol = new AcctSeedERP__Purchase_Order_Line__c(
            AcctSeedERP__Purchase_Order__c = po.Id,
            AcctSeedERP__Product__c = part.Id,
            AcctSeedERP__Quantity__c = 10,
            AcctSeedERP__Unit_Price__c = 10.00
        );
        insert pol;

        AcctSeedERP__Purchase_Order_Inventory_Movement__c movement = new AcctSeedERP__Purchase_Order_Inventory_Movement__c(
            AcctSeedERP__Unit_Cost__c = 10,
            GMBLASERP__Cost_Override__c = true,
            AcctSeedERP__Quantity__c = 10,
            AcctSeedERP__Inventory_Balance__c = balance.Id,
            AcctSeedERP__Ledger__c = ledger.Id,
            GMBLASERP__Warehouse__c = wh.Id,
            AcctSeedERP__Movement_Date__c = Date.today(),
            GMBLASERP__Product__c = part.Id,
            AcctSeedERP__Purchase_Order_Line__c = pol.Id,
            GMBLASERP__Purchase_Order__c = po.Id
        );
        GMBLASERP.gcPurchaseOrderInventoryMovement.disableTrigger = true;
        insert movement;

        GMBLASERP__Inventory_Adjustment__c adj = new GMBLASERP__Inventory_Adjustment__c();
        adj.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
        adj.Department_GLV_2__c = gcConstants.idGlv2Sales;
        adj.GMBLASERP__GL_Account__c = gcConstants.idGlCostVariance;
        adj.GMBLASERP__Product__c = part.Id;
        adj.GMBLASERP__Adjustment_Type__c = 'Value';
        insert adj;
        String adjId = whAd.Id;
        String intId = whIn.Id;
        GMBLASERP__Inventory_Settings__c setting = new GMBLASERP__Inventory_Settings__c();
        setting.GMBLASERP__Adjustment_Warehouse_Id__c = adjId.left(15);
        setting.GMBLASERP__Transit_Warehouse_Id__c = intId.left(15);
        insert setting;

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(adj);
        gcInventoryAdjustment_Ext obj = new gcInventoryAdjustment_Ext(sc);
        List<SelectOption> listPT = obj.getListProductType();
        map<string,string> mapString = gcInventoryAdjustment_Ext.createAdjustment(adj.Id,part.Id);
        Id idMove = mapString.get('idMove');
        gcInventoryAdjustment_Ext.adjustValue(idMove, -5);
        gcInventoryAdjustment_Ext.adjustValueIn(idMove, -5);
        Test.stopTest();
    }

    @IsTest
    static void testAdjustmentQuantity()
    {
        AcctSeed__Ledger__c ledger = [SELECT Id FROM AcctSeed__Ledger__c Where AcctSeed__Type__c = 'Transactional'];
        AcctSeedERP__Warehouse__c wh;
        AcctSeedERP__Warehouse__c whAd;
        AcctSeedERP__Warehouse__c whIn;
        for(AcctSeedERP__Warehouse__c w : [SELECT Id, Name FROM AcctSeedERP__Warehouse__c WHERE Name IN ('Adjustments','Wholesale','In Transit')]){
            if(w.Name == 'Adjustments')
                whAd = w;
            if(w.Name == 'Wholesale')
                wh = w;
            if(w.Name == 'In Transit')
                whIn = w;
        }
        AcctSeedERP__Location__c loc = new AcctSeedERP__Location__c(
            Name = 'Test Loc',
            AcctSeedERP__Warehouse__c = wh.Id
        );
        insert loc;
        Product2 part = Factory_Product.createNonSerializedProduct('Part', 'Electronics');
        AcctSeedERP__Inventory_Balance__c balance = new AcctSeedERP__Inventory_Balance__c(
            AcctSeedERP__Location__c = loc.Id,
            AcctSeedERP__Warehouse__c = wh.Id,
            AcctSeedERP__Product__c = part.Id
        );
        // Required for Hibiscus;
        //balance.AcctSeedERP__Ledger__c = ledger.Id;
        insert balance;
        Account[] accts = Factory_Account.insertSupplierAccounts(2);
        Account vendor = accts[0];
        Account shipTo = accts[1];
        AcctSeedERP__Purchase_Order__c po = Factory_PurchaseOrder.createMinimalPO( vendor.Id, shipTo.Id );
        System.debug([SELECT Id, AcctSeedERP__Vendor_Country__c FROM AcctSeedERP__Purchase_Order__c WHERE Id = :po.Id]);
        AcctSeedERP__Purchase_Order_Line__c pol = new AcctSeedERP__Purchase_Order_Line__c(
            AcctSeedERP__Purchase_Order__c = po.Id,
            AcctSeedERP__Product__c = part.Id,
            AcctSeedERP__Quantity__c = 10,
            AcctSeedERP__Unit_Price__c = 10.00
        );
        insert pol;

        AcctSeedERP__Purchase_Order_Inventory_Movement__c movement = new AcctSeedERP__Purchase_Order_Inventory_Movement__c(
            AcctSeedERP__Unit_Cost__c = 10,
            GMBLASERP__Cost_Override__c = true,
            AcctSeedERP__Quantity__c = 10,
            AcctSeedERP__Inventory_Balance__c = balance.Id,
            AcctSeedERP__Ledger__c = ledger.Id,
            GMBLASERP__Warehouse__c = wh.Id,
            AcctSeedERP__Movement_Date__c = Date.today(),
            GMBLASERP__Product__c = part.Id,
            AcctSeedERP__Purchase_Order_Line__c = pol.Id,
            GMBLASERP__Purchase_Order__c = po.Id
        );
        GMBLASERP.gcPurchaseOrderInventoryMovement.disableTrigger = true;
        insert movement;

        GMBLASERP__Inventory_Adjustment__c adj = new GMBLASERP__Inventory_Adjustment__c();
        adj.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
        adj.Department_GLV_2__c = gcConstants.idGlv2Sales;
        adj.GMBLASERP__GL_Account__c = gcConstants.idGlCostVariance;
        adj.GMBLASERP__Warehouse__c = wh.Id;
        adj.GMBLASERP__Product__c = part.Id;
        adj.GMBLASERP__Adjustment_Type__c = 'Quantity';
        insert adj;
        String adjId = whAd.Id;
        String intId = whIn.Id;
        GMBLASERP__Inventory_Settings__c setting = new GMBLASERP__Inventory_Settings__c();
        setting.GMBLASERP__Adjustment_Warehouse_Id__c = adjId.left(15);
        setting.GMBLASERP__Transit_Warehouse_Id__c = intId.left(15);
        insert setting;

        Test.startTest();
        map<string,string> mapString = gcInventoryAdjustment_Ext.createAdjustment(adj.Id,part.Id);
        Id idMove = mapString.get('idMove');
        gcInventoryAdjustment_Ext.adjustQuantity(idMove, 1);
        Test.stopTest();
    }

    @IsTest
    static void testAdjustmentDelete()
    {
        AcctSeed__Ledger__c ledger = [SELECT Id FROM AcctSeed__Ledger__c Where AcctSeed__Type__c = 'Transactional'];
        AcctSeedERP__Warehouse__c wh;
        AcctSeedERP__Warehouse__c whAd;
        AcctSeedERP__Warehouse__c whIn;
        for(AcctSeedERP__Warehouse__c w : [SELECT Id, Name FROM AcctSeedERP__Warehouse__c WHERE Name IN ('Adjustments','Wholesale','In Transit')]){
            if(w.Name == 'Adjustments')
                whAd = w;
            if(w.Name == 'Wholesale')
                wh = w;
            if(w.Name == 'In Transit')
                whIn = w;
        }
        AcctSeedERP__Location__c loc = new AcctSeedERP__Location__c(
            Name = 'Test Loc',
            AcctSeedERP__Warehouse__c = wh.Id
        );
        insert loc;
        Product2 part = Factory_Product.createNonSerializedProduct('Part', 'Electronics');
        AcctSeedERP__Inventory_Balance__c balance = new AcctSeedERP__Inventory_Balance__c(
            AcctSeedERP__Location__c = loc.Id,
            AcctSeedERP__Warehouse__c = wh.Id,
            AcctSeedERP__Product__c = part.Id
        );
        // Required for Hibiscus;
        //balance.AcctSeedERP__Ledger__c = ledger.Id;
        insert balance;
        Account[] accts = Factory_Account.insertSupplierAccounts(2);
        Account vendor = accts[0];
        Account shipTo = accts[1];
        AcctSeedERP__Purchase_Order__c po = Factory_PurchaseOrder.createMinimalPO( vendor.Id, shipTo.Id );
        System.debug([SELECT Id, AcctSeedERP__Vendor_Country__c FROM AcctSeedERP__Purchase_Order__c WHERE Id = :po.Id]);
        AcctSeedERP__Purchase_Order_Line__c pol = new AcctSeedERP__Purchase_Order_Line__c(
            AcctSeedERP__Purchase_Order__c = po.Id,
            AcctSeedERP__Product__c = part.Id,
            AcctSeedERP__Quantity__c = 10,
            AcctSeedERP__Unit_Price__c = 10.00
        );
        insert pol;

        AcctSeedERP__Purchase_Order_Inventory_Movement__c movement = new AcctSeedERP__Purchase_Order_Inventory_Movement__c(
            AcctSeedERP__Unit_Cost__c = 10,
            GMBLASERP__Cost_Override__c = true,
            AcctSeedERP__Quantity__c = 10,
            AcctSeedERP__Inventory_Balance__c = balance.Id,
            AcctSeedERP__Ledger__c = ledger.Id,
            GMBLASERP__Warehouse__c = wh.Id,
            AcctSeedERP__Movement_Date__c = Date.today(),
            GMBLASERP__Product__c = part.Id,
            AcctSeedERP__Purchase_Order_Line__c = pol.Id,
            GMBLASERP__Purchase_Order__c = po.Id
        );
        GMBLASERP.gcPurchaseOrderInventoryMovement.disableTrigger = true;
        insert movement;

        GMBLASERP__Inventory_Adjustment__c adj = new GMBLASERP__Inventory_Adjustment__c();
        adj.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
        adj.Department_GLV_2__c = gcConstants.idGlv2Sales;
        adj.GMBLASERP__GL_Account__c = gcConstants.idGlCostVariance;
        adj.GMBLASERP__Warehouse__c = wh.Id;
        adj.GMBLASERP__Product__c = part.Id;
        adj.GMBLASERP__Adjustment_Type__c = 'Quantity';
        insert adj;
        String adjId = whAd.Id;
        String intId = whIn.Id;
        GMBLASERP__Inventory_Settings__c setting = new GMBLASERP__Inventory_Settings__c();
        setting.GMBLASERP__Adjustment_Warehouse_Id__c = adjId.left(15);
        setting.GMBLASERP__Transit_Warehouse_Id__c = intId.left(15);
        insert setting;

        Test.startTest();
        map<string,string> mapString = gcInventoryAdjustment_Ext.createAdjustment(adj.Id,part.Id);
        Id idMove = mapString.get('idMove');
        gcInventoryAdjustment_Ext.adjustQuantity(idMove, 1);
        gcInventoryAdjustment_Ext.deleteMove(idMove);
        Test.stopTest();
    }

    @IsTest
    static void testAdjustmentValueSerialized()
    {
        AcctSeed__Ledger__c ledger = [SELECT Id FROM AcctSeed__Ledger__c Where AcctSeed__Type__c = 'Transactional'];
        AcctSeedERP__Warehouse__c wh;
        AcctSeedERP__Warehouse__c whAd;
        AcctSeedERP__Warehouse__c whIn;
        AcctSeedERP__Location__c loc;
        AcctSeedERP__Location__c locIn;
        AcctSeedERP__Location__c locAd;
        for(AcctSeedERP__Warehouse__c w : [SELECT Id, Name, (SELECT Id FROM AcctSeedERP__Locations__r LIMIT 1) FROM AcctSeedERP__Warehouse__c WHERE Name IN ('Adjustments','Wholesale','In Transit')]){
            if(w.Name == 'Adjustments') {
                whAd = w;
                locAd = w.AcctSeedERP__Locations__r[0];
            }
            if(w.Name == 'Wholesale') {
                wh = w;
                loc = w.AcctSeedERP__Locations__r[0];
            }
            if(w.Name == 'In Transit') {
                whIn = w;
                locIn = w.AcctSeedERP__Locations__r[0];
            }
        }

        String adjId = whAd.Id;
        String intId = whIn.Id;
        GMBLASERP__Inventory_Settings__c setting = new GMBLASERP__Inventory_Settings__c();
        setting.GMBLASERP__Adjustment_Warehouse_Id__c = adjId.left(15);
        setting.GMBLASERP__Transit_Warehouse_Id__c = intId.left(15);
        setting.GMBLASERP__disable_lotNameConstraints__c = true;
        insert setting;

        Product2 boat = Factory_Product.buildSerializedProduct('Boat', 'Full Windshield');
        insert boat;
        GMBLASERP__Serial_Number__c boatSerial = Factory_SerialNumber.insertSerialNumber( boat, 'Test666' );
        boatSerial = [SELECT Id, Name, GMBLASERP__Lot__c, GMBLASERP__Product__c FROM GMBLASERP__Serial_Number__c WHERE Id =: boatSerial.Id];
        System.debug('boatSerial');
        System.debug(boatSerial);
        List<AcctSeedERP__Inventory_Balance__c> balances = new List<AcctSeedERP__Inventory_Balance__c>();
        AcctSeedERP__Inventory_Balance__c balance = new AcctSeedERP__Inventory_Balance__c(
            AcctSeedERP__Location__c = loc.Id,
            AcctSeedERP__Warehouse__c = wh.Id,
            AcctSeedERP__Product__c = boatSerial.GMBLASERP__Product__c
        );
        balances.add(balance);
        AcctSeedERP__Inventory_Balance__c balance1 = new AcctSeedERP__Inventory_Balance__c(
            AcctSeedERP__Location__c = locIn.Id,
            AcctSeedERP__Warehouse__c = whIn.Id,
            AcctSeedERP__Product__c = boatSerial.GMBLASERP__Product__c
        );
        balances.add(balance1);
        AcctSeedERP__Inventory_Balance__c balance2 = new AcctSeedERP__Inventory_Balance__c(
            AcctSeedERP__Location__c = locAd.Id,
            AcctSeedERP__Warehouse__c = whAd.Id,
            AcctSeedERP__Product__c = boatSerial.GMBLASERP__Product__c
        );
        balances.add(balance2);
        // Required for Hibiscus;
        //balance.AcctSeedERP__Ledger__c = ledger.Id;
        insert balances;
        System.debug('balances');
        System.debug(balances);
        Account[] accts = Factory_Account.insertSupplierAccounts(2);
        Account vendor = accts[0];
        Account shipTo = accts[1];
        AcctSeedERP__Purchase_Order__c po = Factory_PurchaseOrder.createMinimalPO( vendor.Id, shipTo.Id );
        AcctSeedERP__Purchase_Order_Line__c pol = new AcctSeedERP__Purchase_Order_Line__c(
            AcctSeedERP__Purchase_Order__c = po.Id,
            AcctSeedERP__Product__c = boatSerial.GMBLASERP__Product__c,
            //GMBLASERP__Serial_Number__c = boatSerial.Id,
            //GMBLASERP__Lot__c = boatSerial.GMBLASERP__Lot__c,
            AcctSeedERP__Quantity__c = 1,
            AcctSeedERP__Unit_Price__c = 1000.00
        );
        insert pol;

        AcctSeedERP__Purchase_Order_Inventory_Movement__c movement = new AcctSeedERP__Purchase_Order_Inventory_Movement__c(
            AcctSeedERP__Unit_Cost__c = 1000,
            GMBLASERP__Cost_Override__c = true,
            AcctSeedERP__Quantity__c = 1,
            AcctSeedERP__Inventory_Balance__c = balance.Id,
            AcctSeedERP__Ledger__c = ledger.Id,
            GMBLASERP__Warehouse__c = wh.Id,
            AcctSeedERP__Movement_Date__c = Date.today(),
            GMBLASERP__Product__c = boatSerial.GMBLASERP__Product__c,
            GMBLASERP__Serial_Number__c = boatSerial.Id,
            GMBLASERP__Lot__c = boatSerial.GMBLASERP__Lot__c,
            AcctSeedERP__Purchase_Order_Line__c = pol.Id,
            GMBLASERP__Purchase_Order__c = po.Id
        );
        GMBLASERP.gcPurchaseOrderInventoryMovement.disableTrigger = true;
        insert movement;

        GMBLASERP__Inventory_Adjustment__c adj = new GMBLASERP__Inventory_Adjustment__c();
        adj.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
        adj.Department_GLV_2__c = gcConstants.idGlv2Sales;
        adj.GMBLASERP__GL_Account__c = gcConstants.idGlCostVariance;
        adj.GMBLASERP__Product__c = boatSerial.GMBLASERP__Product__c;
        adj.GMBLASERP__Adjustment_Type__c = 'Value';
        adj.GMBLASERP__Adjustment_Date__c = Date.today();
        insert adj;

        Test.startTest();
        map<string,string> mapString = gcInventoryAdjustment_Ext.createAdjustment(adj.Id,boatSerial.Id);
        Id idMove = mapString.get('idMove');
        gcInventoryAdjustment_Ext.adjustValue(idMove, 100);
        gcInventoryAdjustment_Ext.adjustValueIn(idMove, 100);
        Test.stopTest();
    }
}