/**
 * Created by dhavalmacbook on 18/05/22.
 */
@IsTest
public with sharing class SalesOrder_Service_T {
    @testSetup
    static void dataSetup() {
        new Factory_TestData();
        Factory_CustomSettings.setupInventorySettings();
    }
    @isTest
    static public void generateSO(){
        Account customer = Factory_Account.insertCustomerAccounts(1)[0];
        Id idWarehouseWholesale = gcConstants.idWarehouseWholesale;
        InventoryTestFactory itf = new InventoryTestFactory();
        Product2[] prods = itf.buildTestProducts( 1, 'Part' );
        Test.startTest();
        gcProduct.disableTrigger = true;
        insert prods;
        gcProduct.disableTrigger = false;
        AcctSeedERP__Sales_Order__c so = Factory_SalesOrder.createSalesOrder(customer, idWarehouseWholesale, prods[0].Id);
        AcctSeedERP__Sales_Order_Line__c sol = [SELECT Id FROM AcctSeedERP__Sales_Order_Line__c WHERE AcctSeedERP__Sales_Order__c =: so.Id limit 1];
        Test.stopTest();
        List<AcctSeedERP__Sales_Order_Line__c> solList = [Select id from AcctSeedERP__Sales_Order_Line__c where AcctSeedERP__Sales_Order__c =:so.Id];
        System.assert(!solList.isEmpty());
    }
    @isTest
    static public void generateCashReceipt(){
        Account customer = Factory_Account.insertCustomerAccounts(1)[0];
        Id idWarehouseWholesale = gcConstants.idWarehouseWholesale;
        InventoryTestFactory itf = new InventoryTestFactory();
        Product2[] prods = itf.buildTestProducts( 1, 'Part' );
        AcctSeed__Accounting_Settings__c accSetting = [SELECT AcctSeed__Default_Ledger__c FROM AcctSeed__Accounting_Settings__c ORDER BY CreatedDate][0];

        gcProduct.disableTrigger = true;
        insert prods;
        gcProduct.disableTrigger = false;
        AcctSeedERP__Sales_Order__c so = Factory_SalesOrder.createSalesOrder(customer, idWarehouseWholesale, prods[0].Id);
        Ecwid_Sales_Order__e evt = new Ecwid_Sales_Order__e(Status__c = true, Sales_Order_Id__c = so.Id);
        Database.SaveResult sr = EventBus.publish(evt);
        Test.startTest();
        AcctSeedERP__Sales_Order_Line__c sol = [SELECT Id FROM AcctSeedERP__Sales_Order_Line__c WHERE AcctSeedERP__Sales_Order__c =: so.Id limit 1];
        AcctSeedERP__Location__c loc = [SELECT ID FROM AcctSeedERP__Location__c WHERE AcctSeedERP__Warehouse__c =:idWarehouseWholesale limit 1];

        // Create Balance
        AcctSeedERP__Inventory_Balance__c balance = new AcctSeedERP__Inventory_Balance__c(
                AcctSeedERP__Location__c = loc.Id,
                AcctSeedERP__Warehouse__c = idWarehouseWholesale,
                AcctSeedERP__Product__c = prods[0].Id
        );
        insert balance;
        AcctSeedERP__Sales_Order_Inventory_Movement__c inmove = new AcctSeedERP__Sales_Order_Inventory_Movement__c(
                AcctSeedERP__Unit_Cost__c = 12,
                AcctSeedERP__Quantity__c = 1,
                AcctSeedERP__Inventory_Balance__c = balance.Id,
                AcctSeedERP__Ledger__c = accSetting.AcctSeed__Default_Ledger__c,
                GMBLASERP__Warehouse__c = idWarehouseWholesale,
                AcctSeedERP__Movement_Date__c = Date.today(),
                AcctSeedERP__Sales_Order_Line__c = sol.Id
        );
        insert inmove;
        Test.stopTest();


    }
}