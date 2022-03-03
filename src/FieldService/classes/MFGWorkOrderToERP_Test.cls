/**
 * Created by Legend on 24/6/21.
 */

@IsTest
private class MFGWorkOrderToERP_Test {

    static WorkOrder wo;
    static Account supplier;
    static AcctSeedERP__Purchase_Order__c  po;
    static AcctSeedERP__Purchase_Order_Line__c pol;
    static Product2 boat;
    static GMBLASERP__Serial_Number__c serial;

    @testSetup static void dataSetup() {
        new Factory_TestData();
        Factory_CustomSettings.setupInventorySettings();
    }

    private static void init() {
        supplier = Factory_Account.insertSupplierAccounts(1)[0];
        po = Factory_PurchaseOrder.createMinimalPO( supplier.Id, null );
        boat = Factory_Product.buildSerializedProduct( 'Boat', 'Pontoon' );
        insert boat;

        GMBLASERP__Lot__c lot = new GMBLASERP__Lot__c(
                GMBLASERP__Product__c = boat.Id,
                Name = String.valueOf( Date.today().year() ),
                GMBLASERP__Uniquefier__c = boat.Id + '-' + String.valueOf(Date.today().year())
        );
        insert lot;
        System.debug('lot');
        System.debug(lot);

        serial = Factory_SerialNumber.insertSerialNumber( boat, 'Test666', lot.Id );
        System.debug('serial');
        System.debug(serial);
        AcctSeedERP__Location__c loc = [SELECT ID FROM AcctSeedERP__Location__c WHERE AcctSeedERP__Warehouse__c =: po.Warehouse__c][0];
        AcctSeedERP__Inventory_Balance__c balance = new AcctSeedERP__Inventory_Balance__c(
                AcctSeedERP__Location__c = loc.Id,
                AcctSeedERP__Warehouse__c = po.Warehouse__c,
                AcctSeedERP__Product__c = boat.Id
        );
        // Required for Hibiscus;
        //balance.AcctSeedERP__Ledger__c = ledger.Id;
        insert balance;
        System.debug('balance');
        System.debug(balance);
        pol = Factory_PurchaseOrder.buildLineItem(
                po.Id,
                boat.Id,
                1
        );
        pol.deliverDate__c = Date.today();
        insert pol;
        //'Create Manufacturing WO on insert of POL for Boat' Flow creates Wo, Woli and Service Appointment
        AcctSeedERP__Purchase_Order_Inventory_Movement__c movement = new AcctSeedERP__Purchase_Order_Inventory_Movement__c(
                AcctSeedERP__Unit_Cost__c = 10,
                AcctSeedERP__Quantity__c = 1,
                AcctSeedERP__Inventory_Balance__c = balance.Id,
                AcctSeedERP__Ledger__c = gcConstants.idActualLedger,
                GMBLASERP__Warehouse__c = po.Warehouse__c,
                AcctSeedERP__Movement_Date__c = Date.today(),
                GMBLASERP__Product__c = boat.Id,
                AcctSeedERP__Purchase_Order_Line__c = pol.Id,
                GMBLASERP__Serial_Number__c = serial.Id,
                GMBLASERP__Lot__c = lot.Id
        );

        TriggerHandler.bypass('ProductItemTransaction_TriggerHandler');
        insert movement;
    }

    @IsTest
    static void stepOne_Test()
    {
        init();
        AcctSeedERP__Purchase_Order_Line__c polSelect = [SELECT ID, Work_Order__c FROM AcctSeedERP__Purchase_Order_Line__c WHERE Id =:pol.Id][0];
        Set<Id> woIds = new Set<Id>{polSelect.Work_Order__c};
        System.debug('### WOIDS = ' + woIds );
        Test.startTest();
        //new MFGWorkOrderToERP_Promise.createMFGERP_Promise().resolve( (Object) erpIds );
        MFGWorkOrderToERP_Promise.stepOne(  woIds );
        Test.stopTest();
        WorkOrder woSelect = [SELECT Id, ERP_Order__c FROM WorkOrder WHERE Id =:polSelect.Work_Order__c][0];
        System.assertEquals( woSelect.ERP_Order__c != null, true, 'The ERP Has Been Created');
    }

    @IsTest
    static void stepTwo_Test()
    {
        init();
        gcProject.disableTrigger = true;
        gcProjectTask.disableTrigger = true;
        AcctSeedERP__Purchase_Order_Line__c polSelect = [SELECT ID, Work_Order__c FROM AcctSeedERP__Purchase_Order_Line__c WHERE Id =:pol.Id][0];
        MFGWorkOrderToERP_Promise.stepOne( new Set<Id>{polSelect.Work_Order__c} );
        Object woliId;
        Test.startTest();
        woliId = new MFGWorkOrderToERP_Promise.createErpTask_Promise().resolve(new Set<Id>{polSelect.Work_Order__c} );
        Test.stopTest();
        Set<Id> woliIds = new Set<Id>();
        for(WorkOrderLineItem woli : [SELECT Id, ERP_Order_Task__c  FROM WorkOrderLineItem WHERE ERP_Order_Task__c !=null AND ID IN:(Set<Id>)woliId]){
            woliIds.add(woli.Id);
        }
        System.assertEquals( 1, woliIds.size(), 'The ERP Tasks have Been Created');
    }

    @IsTest
    static void stepThree_Test() {
        init();
        TriggerBase.bypass('WorkOrder');
        TriggerBase.bypass('WorkOrderLine');
        AcctSeedERP__Purchase_Order_Line__c polSelect = [SELECT ID, Work_Order__c, Work_Order__r.ERP_Order__c, Work_Order_Line_Item__c FROM AcctSeedERP__Purchase_Order_Line__c WHERE Id =:pol.Id][0];
        Product2[] parts = Factory_Product.buildNonSerializedProducts('Part', 'Electronics', 5 );
        insert parts;
        List<ProductRequired> requiredProducts = new List<ProductRequired>();
        for( Product2 p : parts )
        {
            requiredProducts.add( new ProductRequired(
                    ParentRecordId = polSelect.Work_Order_Line_Item__c,
                    Product2Id = p.Id,
                    QuantityRequired = 1
            ));
        }
        insert requiredProducts;
        gcProject.disableTrigger = true;
        gcProjectTask.disableTrigger = true;
        MFGWorkOrderToERP_Promise.stepOne( new Set<Id>{polSelect.Work_Order__c} );
        Object woliId = new MFGWorkOrderToERP_Promise.createErpTask_Promise().resolve(new Set<Id>{polSelect.Work_Order__c} );
        Test.startTest();
        new MFGWorkOrderToERP_Promise().executeStepThree( (Set<Id>) woliId );
        Test.stopTest();
        System.debug('woliId');
        System.debug((Set<Id>) woliId);
        Set<Id> setIdMatl = new Set<Id>();
        for(AcctSeedERP__Material__c pr : [SELECT Id FROM AcctSeedERP__Material__c WHERE AcctSeedERP__Project__c =:polSelect.Work_Order__r.ERP_Order__c]){
            setIdMatl.add(pr.Id);
        }
        System.debug('setIdMatl');
        System.debug(setIdMatl);
        System.assertEquals( 5, requiredProducts.size(), 'The ERP Line Items Were Created');
    }
}