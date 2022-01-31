/**
 * Created by Legend on 20/12/21.
 */

@isTest
private class gcAccountPayable_Actions_Test {
    @TestSetup
    static void testData(){
        new Factory_TestData();
        Factory_CustomSettings.setupInventorySettings();
        new Factory_AccountingVariables();
    }

    static void init()
    {
        map<Id,map<Id,map<Id,Id>>> mapPWLB = new map<Id,map<Id,map<Id,Id>>>();
        Product2 part = Factory_Product.createNonSerializedProduct('Part', 'Hardware');
        Product2 part2 = Factory_Product.createNonSerializedProduct('Part', 'Vehicle and Equipment Parts');
        Id idWarehouse = gcConstants.idWarehouseMontreal;
        AcctSeedERP__Location__c loc = [SELECT Id FROM AcctSeedERP__Location__c WHERE AcctSeedERP__Warehouse__c =:idWarehouse LIMIT 1];

        mapPWLB.put(part.Id, new map<Id,map<Id,Id>>());
        mapPWLB.get(part.Id).put(idWarehouse, new map<Id,Id>());
        mapPWLB.get(part.Id).get(idWarehouse).put(loc.Id,null);

        GCR_InventoryBalance.findOrCreateBalances(mapPWLB);
        Account[] accts = Factory_Account.insertSupplierAccounts(2);
        Account vendor = accts[0];
        Account shipTo = accts[1];
        AcctSeedERP__Purchase_Order__c po = Factory_PurchaseOrder.createMinimalPO( vendor.Id, shipTo.Id );
        AcctSeedERP__Purchase_Order_Line__c pol = new AcctSeedERP__Purchase_Order_Line__c(
                AcctSeedERP__Purchase_Order__c = po.Id,
                AcctSeedERP__Product__c = part.Id,
                AcctSeedERP__Quantity__c = 10,
                AcctSeedERP__Unit_Price__c = 10.00
        );
        AcctSeedERP__Purchase_Order_Line__c pol2 = new AcctSeedERP__Purchase_Order_Line__c(
                AcctSeedERP__Purchase_Order__c = po.Id,
                AcctSeedERP__Product__c = part2.Id,
                AcctSeedERP__Quantity__c = 10,
                AcctSeedERP__Unit_Price__c = 10.00,
                GMBLASERP__Quantity_Received_Non_Inventory__c = 10
        );
        insert new List<AcctSeedERP__Purchase_Order_Line__c>{pol,pol2};
        AcctSeedERP__Purchase_Order_Inventory_Movement__c movement = new AcctSeedERP__Purchase_Order_Inventory_Movement__c(
                AcctSeedERP__Unit_Cost__c = 10,
                GMBLASERP__Cost_Override__c = true,
                AcctSeedERP__Quantity__c = 5,
                AcctSeedERP__Inventory_Balance__c = mapPWLB.get(part.Id).get(idWarehouse).get(loc.Id),
                AcctSeedERP__Ledger__c = gcConstants.idActualLedger,
                GMBLASERP__Warehouse__c = idWarehouse,
                AcctSeedERP__Movement_Date__c = Date.today(),
                GMBLASERP__Product__c = part.Id,
                AcctSeedERP__Purchase_Order_Line__c = pol.Id,
                GMBLASERP__Purchase_Order__c = po.Id
        );
        gcPurchaseOrderInventoryMovement.disableTrigger = true;
        insert new List<AcctSeedERP__Purchase_Order_Inventory_Movement__c>{movement};

        GMBLASERP.gcInventoryMovementCube.allowDML = true;
        GMBLASERP__Inventory_Movement_Cube__c cube = new GMBLASERP__Inventory_Movement_Cube__c();
        cube.GMBLASERP__Inventory_Balance__c = mapPWLB.get(part.Id).get(idWarehouse).get(loc.Id);
        cube.GMBLASERP__Location__c = loc.Id;
        cube.GMBLASERP__Product__c = part.Id;
        cube.GMBLASERP__Movement_Date__c = Date.today();
        cube.GMBLASERP__Warehouse__c = idWarehouse;
        cube.GMBLASERP__Movement_Type__c = 'AcctSeedERP__Purchase_Order_Inventory_Movement__c';
        cube.GMBLASERP__Quantity__c = 10;
        cube.GMBLASERP__Inventory_GL_Amount__c = 100;

        GMBLASERP.gcInventoryMovementCube.disableTrigger = true;
        insert new List<GMBLASERP__Inventory_Movement_Cube__c>{cube};
    }

    @isTest
    static void testScenario1() {
        init();
        AcctSeedERP__Purchase_Order__c po = [SELECT id FROM AcctSeedERP__Purchase_Order__c limit 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(po);
        Test.startTest();
        PageReference pageRef = Page.gpAccountPayable_Actions;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('idFilter',po.Id);
        gcAccountPayable_Actions accountPayableActions = new gcAccountPayable_Actions(sc);
        accountPayableActions.init();
        Test.stopTest();
        AcctSeed__Account_Payable__c[] ap = [SELECT Id FROM AcctSeed__Account_Payable__c WHERE AcctSeedERP__Purchase_Order__c =: po.Id];
        System.assertEquals(ap.size(),1);
    }
}