/**
 * Created by aminrubel on 21/1/20.
 */

@isTest
private class ProductTransfer_UpdateControl_Test {

    static Product2 testProduct0;
    static Product2 testProduct1;
    static Account testAccount;
    static AcctSeed__GL_Account__c revenueAccount;
    static AcctSeed__GL_Account__c expenseAccount;
    static WorkOrder testWorkOrder;
    static WorkOrderLineItem testWorkOrderLineItem;
    static ProductRequired testProductRequired;
    static ProductRequired testProductRequired1;
    static ProductTransfer testProductTransfer;
    static PricebookEntry testPricebookEntryProduct1;

    @testSetup static void dataSetup() {

//        Factory_TestData factory = new Factory_TestData();
//        Factory_CustomSettings.setupInventorySettings();
//
//        Id accountBusinessRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND IsActive = true AND DeveloperName LIKE '%business%'][0].Id;
//        Id workOrderServiceRecordType = [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'WorkOrder' AND IsActive = true][0].Id;
//        Id productRecordType = [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Product2' AND IsActive = true AND DeveloperName LIKE '%Part%'][0].Id;
//        Id productRecordTypeBoat = [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Product2' AND IsActive = true AND DeveloperName LIKE '%Boat%'][0].Id;
//        Id standardPriceBookId = Test.getStandardPricebookId();
//        Id idWarehouseWholesale = gcConstants.idWarehouseWholesale;
//        System.debug(loggingLevel.error, 'idWarehouseWholesale:'+idWarehouseWholesale);
//        testAccount = new Account(
//            Name = 'Test Account',
//            Warehouse__c = idWarehouseWholesale,
//            GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale,
//            RecordTypeId = accountBusinessRecordType);
//        insert testAccount;
//
//        testProduct0 = new Product2(
//            Name = 'Test Product 0',
//            ProductCode = 'Test12340',
//            isActive = true,
//            AcctSeed__Inventory_Product__c = false,
//            AcctSeed__Inventory_Type__c = 'Manufactured',
//            RecordTypeId = productRecordTypeBoat,
//            Family = 'Boat',
//            AcctSeedERP__Serialized__c = true,
//            GMBLASERP__Lot_Tracked__c = true,
//            AcctSeed__Accounting_Type__c = 'Taxable_Product',
//            AcctSeed__Unit_Cost__c = 50.00
//        );
//        insert testProduct0;
//
//        testPricebookEntryProduct1 = new PricebookEntry(
//            IsActive = true,
//            Pricebook2Id = standardPriceBookId,
//            Product2Id = testProduct0.Id,
//            UnitPrice = 500.00
//        );
//        insert testPricebookEntryProduct1;
//
//
//        GMBLASERP__Lot__c lot = new GMBLASERP__Lot__c(Name = '2020', GMBLASERP__Product__c = testProduct0.Id);
//        insert lot;
//        System.debug(loggingLevel.error, 'lot:'+lot);
//        GMBLASERP__Serial_Number__c serial = new GMBLASERP__Serial_Number__c(Name = '2020-TP0', GMBLASERP__Product__c = testProduct0.Id, GMBLASERP__Lot__c = lot.Id, Model_Year__c = 2020);
//        insert serial;
//        System.debug(loggingLevel.error, 'serial:'+serial);
//
//        testProduct1 = new Product2(
//            Name = 'Test Product 1',
//            ProductCode = 'Test1234',
//            isActive = true,
//            AcctSeed__Inventory_Product__c = true,
//            AcctSeed__Inventory_Type__c = 'Manufactured',
//            RecordTypeId = productRecordType,
//            Family = 'Remote',
//            AcctSeedERP__Serialized__c = false,
//            GMBLASERP__Lot_Tracked__c = false,
//            AcctSeed__Accounting_Type__c = 'Taxable_Product',
//            AcctSeed__Unit_Cost__c = 50.00
//        );
//        insert testProduct1;
//
//        testPricebookEntryProduct1 = new PricebookEntry(
//            IsActive = true,
//            Pricebook2Id = standardPriceBookId,
//            Product2Id = testProduct1.Id,
//            UnitPrice = 50.00
//        );
//        insert testPricebookEntryProduct1;
//
//        testWorkOrder = new WorkOrder(
//            Subject = 'This is a test',
//            Description = 'This is a test',
//            RecordTypeId = workOrderServiceRecordType,
//            AccountId = testAccount.Id
//        );
//        TriggerBase.bypass('WorkOrder');
//        insert testWorkOrder;
//        TriggerBase.clearBypass('WorkOrder');
//
//        testWorkOrderLineItem = new WorkOrderLineItem(
//            WorkOrderId = testWorkOrder.Id,
//            Description = 'This is a test',
//            Status = 'New'
//        );
//        TriggerBase.bypass('WorkOrderLineItem');
//        insert testWorkOrderLineItem;
//        TriggerBase.clearBypass('WorkOrderLineItem');
//        List<ProductRequired> listPR = new List<ProductRequired>();
//        testProductRequired = new ProductRequired(
//            Product2Id = testProduct1.Id,
//            QuantityRequired = 10,
//            ParentRecordId = testWorkOrderLineItem.Id
//        );
//        testProductRequired1 = new ProductRequired(
//            Product2Id = testProduct0.Id,
//            QuantityRequired = 1,
//            ParentRecordId = testWorkOrderLineItem.Id
//        );
//        listPR.add(testProductRequired);
//        listPR.add(testProductRequired1);
//        TriggerHandler.bypass('ProductRequired_TriggerHandler');
//        insert listPR;
    }

    testMethod static void ProductTransfer_UpdateControlQuantity_Test() {

//        testProduct1 = [SELECT Id FROM Product2 WHERE Name = 'Test Product 1'];
//        testWorkOrder = [SELECT Id FROM WorkOrder WHERE Subject = 'This is a test'];
//        System.debug(loggingLevel.error, 'testWorkOrder:'+testWorkOrder.Id);
//        testWorkOrderLineItem = [SELECT Id, Description, Visible_to_Customer__c, Is_From_Opportunity__c, WorkOrderId, WorkOrder.Opportunity__c, WorkOrder.ERP_Order__c, ERP_Order_Task__c FROM WorkOrderLineItem WHERE WorkOrderId = :testWorkOrder.Id];
//        System.debug(loggingLevel.error, 'testWorkOrderLineItem:'+testWorkOrderLineItem.Id);
//        testProductTransfer = new ProductTransfer(
//            Work_Order__c = testWorkOrder.Id,
//            Work_Order_Line_Item__c = testWorkOrderLineItem.Id,
//            Product2Id = testProduct1.Id,
//            QuantitySent = 1,
//            QuantityReceived = 1,
//            QuantityUnitOfMeasure = 'Each',
//            Type__c = 'Standard'
//        );
//
//        Test.startTest();
//        insert testProductTransfer;
//
//        testProductTransfer.QuantitySent = 2;
//        try{
//            update testProductTransfer;
//        }
//        catch(Exception e) {
//            System.debug('------');
//            System.debug(e.getMessage());
//            Boolean expectedExceptionThrown =  e.getMessage().contains('Quantity of a Transfer cannot be modified.') ? true : false;
//            System.AssertEquals(expectedExceptionThrown, true);
//        }
//        Test.stopTest();
    }
    testMethod static void ProductTransfer_UpdateControlSerialSent_Test() {

//        testProduct0 = [SELECT Id FROM Product2 WHERE Name = 'Test Product 0'];
//        testWorkOrder = [SELECT Id FROM WorkOrder WHERE Subject = 'This is a test'];
//        System.debug(loggingLevel.error, 'testWorkOrder:'+testWorkOrder.Id);
//        testWorkOrderLineItem = [SELECT Id, Description, Visible_to_Customer__c, Is_From_Opportunity__c, WorkOrderId, WorkOrder.Opportunity__c, WorkOrder.ERP_Order__c, ERP_Order_Task__c FROM WorkOrderLineItem WHERE WorkOrderId = :testWorkOrder.Id];
//        System.debug(loggingLevel.error, 'testWorkOrderLineItem:'+testWorkOrderLineItem.Id);
//
//        testProductTransfer = new ProductTransfer(
//            Work_Order__c = testWorkOrder.Id,
//            Work_Order_Line_Item__c = testWorkOrderLineItem.Id,
//            Product2Id = testProduct0.Id,
//            QuantitySent = 1,
//            QuantityReceived = 1,
//            QuantityUnitOfMeasure = 'Each',
//            Type__c = 'Standard'
//        );
//
//        Test.startTest();
//        try{
//            insert testProductTransfer;
//            testProductTransfer.QuantitySent = 2;
//            update testProductTransfer;
//        }
//        catch(Exception e) {
//            System.debug('------');
//            System.debug(e.getMessage());
//            Boolean expectedExceptionThrown =  e.getMessage().contains('For serialized products Quantity Sent must be') ? true : false;
//            System.debug(loggingLevel.ERROR,'expectedExceptionThrown:'+expectedExceptionThrown);
//            System.AssertEquals(expectedExceptionThrown, true);
//        }
//        Test.stopTest();
    }

    testMethod static void ProductTransfer_UpdateControlSerialRece_Test() {

//        testProduct0 = [SELECT Id FROM Product2 WHERE Name = 'Test Product 0'];
//        testWorkOrder = [SELECT Id FROM WorkOrder WHERE Subject = 'This is a test'];
//        System.debug(loggingLevel.error, 'testWorkOrder:'+testWorkOrder.Id);
//        testWorkOrderLineItem = [SELECT Id, Description, Visible_to_Customer__c, Is_From_Opportunity__c, WorkOrderId, WorkOrder.Opportunity__c, WorkOrder.ERP_Order__c, ERP_Order_Task__c FROM WorkOrderLineItem WHERE WorkOrderId = :testWorkOrder.Id];
//        System.debug(loggingLevel.error, 'testWorkOrderLineItem:'+testWorkOrderLineItem.Id);
//
//        testProductTransfer = new ProductTransfer(
//            Work_Order__c = testWorkOrder.Id,
//            Work_Order_Line_Item__c = testWorkOrderLineItem.Id,
//            Product2Id = testProduct0.Id,
//            QuantitySent = 1,
//            QuantityUnitOfMeasure = 'Each',
//            Type__c = 'Standard'
//        );
//
//        Test.startTest();
//        try{
//            insert testProductTransfer;
//            testProductTransfer.QuantityReceived = 2;
//            update testProductTransfer;
//        }
//        catch(Exception e) {
//            System.debug('------');
//            System.debug(e.getMessage());
//            Boolean expectedExceptionThrown =  e.getMessage().contains('For serialized products Quantity Received must be') ? true : false;
//            System.debug(loggingLevel.ERROR,'expectedExceptionThrown:'+expectedExceptionThrown);
//            System.AssertEquals(expectedExceptionThrown, true);
//        }
//        Test.stopTest();
    }

    testMethod static void ProductTransfer_UpdateControlSerialWarehouse_Test() {

//        testProduct0 = [SELECT Id FROM Product2 WHERE Name = 'Test Product 0'];
//        testWorkOrder = [SELECT Id FROM WorkOrder WHERE Subject = 'This is a test'];
//        System.debug(loggingLevel.error, 'testWorkOrder:'+testWorkOrder.Id);
//        testWorkOrderLineItem = [SELECT Id FROM WorkOrderLineItem WHERE WorkOrderId = :testWorkOrder.Id];
//        System.debug(loggingLevel.error, 'testWorkOrderLineItem:'+testWorkOrderLineItem.Id);
//        Schema.Location loc = [SELECT Id, Warehouse__c FROM Location WHERE Name = 'Wholesale - Warehouse' AND LocationType = 'Warehouse' LIMIT 1];
//        System.debug(loggingLevel.error, 'loc:'+loc);
//        testProductTransfer = new ProductTransfer(
//            Work_Order__c = testWorkOrder.Id,
//            Work_Order_Line_Item__c = testWorkOrderLineItem.Id,
//            Product2Id = testProduct0.Id,
//            QuantitySent = 1,
//            QuantityReceived = 1,
//            QuantityUnitOfMeasure = 'Each',
//            Type__c = 'Standard',
//            SourceLocationId = loc.Id
//        );
//
//        Test.startTest();
//        try{
//            insert testProductTransfer;
//            testProductTransfer.DestinationLocationId = loc.Id;
//            update testProductTransfer;
//        }
//        catch(Exception e) {
//            System.debug('------');
//            System.debug(e.getMessage());
//            Boolean expectedExceptionThrown =  e.getMessage().contains('Cannot transfer from warehouse to warehouse') ? true : false;
//            System.debug(loggingLevel.ERROR,'expectedExceptionThrown:'+expectedExceptionThrown);
//            System.AssertEquals(expectedExceptionThrown, true);
//        }
//        Test.stopTest();
    }
}