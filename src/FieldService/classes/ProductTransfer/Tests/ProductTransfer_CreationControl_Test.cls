@isTest
private class ProductTransfer_CreationControl_Test {

    static Product2 testProduct0;
    static Product2 testProduct1;
    static Product2 testProduct2;
    static Product2 testProduct3;
    static Pricebook2 testPricebook;
    static Account testAccount;
    static AcctSeed__GL_Account__c revenueAccount;
    static AcctSeed__GL_Account__c expenseAccount;
    static WorkOrder testWorkOrder;
    static WorkOrderLineItem testWorkOrderLineItem;
    static ProductRequired testProductRequired;
    static ProductRequired testProductRequired1;
    static ProductRequired testProductRequired2;
    static ProductTransfer testProductTransfer;
    static PricebookEntry testPricebookEntryProduct1;
    static PricebookEntry testPricebookEntryProduct2;

    @testSetup static void dataSetup() {

//        new Factory_TestData();
//        Factory_CustomSettings.setupInventorySettings();
//
//        Id accountBusinessRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND IsActive = true AND DeveloperName LIKE '%business%'][0].Id;
//        Id workOrderServiceRecordType = [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'WorkOrder' AND IsActive = true][0].Id;
//        Id productRecordType = [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Product2' AND IsActive = true AND DeveloperName LIKE '%Part%'][0].Id;
//        Id productRecordTypeBoat = [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Product2' AND IsActive = true AND DeveloperName LIKE '%Boat%'][0].Id;
//        Id standardPriceBookId = Test.getStandardPricebookId();
//
//        testAccount = new Account(
//            Name = 'Test Account',
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
//        testProduct1 = new Product2(
//            Name = 'Test Product 1',
//            ProductCode = 'Test1234',
//            isActive = true,
//            AcctSeed__Inventory_Product__c = false,
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
//        testProduct2 = new Product2(
//            Name = 'Test Product 2',
//            ProductCode = 'Test4567',
//            isActive = true,
//            AcctSeed__Inventory_Product__c = false,
//            AcctSeed__Inventory_Type__c = 'Manufactured',
//            RecordTypeId = productRecordType
//        );
//        insert testProduct2;
//
//        testProduct3 = new Product2(
//            Name = 'Test Product 3',
//            ProductCode = 'Test987',
//            isActive = true,
//            AcctSeed__Inventory_Product__c = false,
//            AcctSeed__Inventory_Type__c = 'Manufactured',
//            RecordTypeId = productRecordType
//        );
//        insert testProduct3;
//
//        testPricebookEntryProduct1 = new PricebookEntry(
//            IsActive = true,
//            Pricebook2Id = standardPriceBookId,
//            Product2Id = testProduct1.Id,
//            UnitPrice = 50.00
//        );
//        insert testPricebookEntryProduct1;
//
//        testPricebookEntryProduct2 = new PricebookEntry(
//            IsActive = true,
//            Pricebook2Id = standardPriceBookId,
//            Product2Id = testProduct2.Id,
//            UnitPrice = 100.00
//        );
//        insert testPricebookEntryProduct2;
//
//        testWorkOrder = new WorkOrder(
//            Subject = 'This is a test',
//            RecordTypeId = workOrderServiceRecordType
//
//        );
//        TriggerBase.bypass('WorkOrder');
//        insert testWorkOrder;
//        TriggerBase.clearBypass('WorkOrder');
//
//        testWorkOrderLineItem = new WorkOrderLineItem(
//            WorkOrderId = testWorkOrder.Id,
//            Status = 'New'
//        );
//        TriggerBase.bypass('WorkOrderLineItem');
//        insert testWorkOrderLineItem;
//        TriggerBase.clearBypass('WorkOrderLineItem');
    }

//    testMethod static void createNewProductTransferOnWorkOrder_SerializedProduct() {
//
//        testProduct0 = [SELECT Id FROM Product2 WHERE Name = 'Test Product 0'];
//        testWorkOrder = [SELECT Id FROM WorkOrder WHERE Subject = 'This is a test'];
//        testWorkOrderLineItem = [SELECT Id FROM WorkOrderLineItem WHERE WorkOrderId = :testWorkOrder.Id];
//
//        testProductRequired = new ProductRequired(
//            Product2Id = testProduct0.Id,
//            QuantityRequired = 2,
//            ParentRecordId = testWorkOrder.Id
//        );
//        insert testProductRequired;
//
//        testProductTransfer = new ProductTransfer(
//            Work_Order__c = testWorkOrder.Id,
//            Work_Order_Line_Item__c = testWorkOrderLineItem.Id,
//            Product2Id = testProduct0.Id,
//            QuantitySent = 2,
//            QuantityUnitOfMeasure = 'Each',
//            Type__c = 'Standard'
//        );
//
//        System.debug('Work Order ID: ' + testWorkOrder.Id);
//
//        Test.startTest();
//        try{
//            insert testProductTransfer;
//        }
//        catch(Exception e) {
//            System.debug('------');
//            System.debug(e.getMessage());
//            Boolean expectedExceptionThrown =  e.getMessage().contains('For serialized products Quantity sent must be -1,1 or 0.') ? true : false;
//            System.AssertEquals(expectedExceptionThrown, true);
//        }
//        Test.stopTest();
//
//        List<ProductTransfer> ProductTransferCreated = [SELECT Id, Product2Id FROM ProductTransfer WHERE Work_Order__c = :testWorkOrder.Id];
//        System.assertEquals(0, ProductTransferCreated.size(), 'The Product Transfer has not been created.');
//    }
//
//    testMethod static void createNewProductTransferOnWorkOrder_ProductRequiredFromWorkOrderMatch_Pass() {
//
//        testProduct1 = [SELECT Id FROM Product2 WHERE Name = 'Test Product 1'];
//        testWorkOrder = [SELECT Id FROM WorkOrder WHERE Subject = 'This is a test'];
//        testWorkOrderLineItem = [SELECT Id FROM WorkOrderLineItem WHERE WorkOrderId = :testWorkOrder.Id];
//
//        testProductRequired = new ProductRequired(
//            Product2Id = testProduct1.Id,
//            QuantityRequired = 10,
//            ParentRecordId = testWorkOrder.Id
//        );
//        insert testProductRequired;
//
//        testProductTransfer = new ProductTransfer(
//            Work_Order__c = testWorkOrder.Id,
//            Work_Order_Line_Item__c = testWorkOrderLineItem.Id,
//            Product2Id = testProduct1.Id,
//            QuantitySent = 1,
//            QuantityUnitOfMeasure = 'Each',
//            Type__c = 'Standard'
//        );
//
//        System.debug('Work Order ID: ' + testWorkOrder.Id);
//
//        Test.startTest();
//        try{
//            insert testProductTransfer;
//        }
//        catch(Exception e) {
//            Boolean expectedExceptionThrown =  e.getMessage().contains('Cannot transfer more quantity than required.') ? true : false;
//            System.AssertEquals(expectedExceptionThrown, true);
//        }
//        Test.stopTest();
//
//        List<ProductTransfer> ProductTransferCreated = [SELECT Id, Product2Id FROM ProductTransfer WHERE Work_Order__c = :testWorkOrder.Id];
//        System.assertEquals(0, ProductTransferCreated.size(), 'The Product Transfer has not been created.');
//    }
//
//    testMethod static void createNewProductTransferOnWorkOrderLineItem_ProductRequiredFromWorkOrderLineItemMatch_Pass() {
//
//        testProduct1 = [SELECT Id FROM Product2 WHERE Name = 'Test Product 1'];
//        testWorkOrder = [SELECT Id FROM WorkOrder WHERE Subject = 'This is a test'];
//        System.debug(loggingLevel.error, 'testWorkOrder:'+testWorkOrder.Id);
//        testWorkOrderLineItem = [SELECT Id FROM WorkOrderLineItem WHERE WorkOrderId = :testWorkOrder.Id];
//        System.debug(loggingLevel.error, 'testWorkOrderLineItem:'+testWorkOrderLineItem.Id);
//
//        testProductRequired = new ProductRequired(
//            Product2Id = testProduct1.Id,
//            QuantityRequired = 10,
//            ParentRecordId = testWorkOrderLineItem.Id
//        );
//        insert testProductRequired;
//
//        testProductTransfer = new ProductTransfer(
//            Work_Order__c = testWorkOrder.Id,
//            Work_Order_Line_Item__c = testWorkOrderLineItem.Id,
//            Product2Id = testProduct1.Id,
//            QuantitySent = 1,
//            QuantityUnitOfMeasure = 'Each',
//            Type__c = 'Standard'
//        );
//
//        Test.startTest();
//        insert testProductTransfer;
//        Test.stopTest();
//
//        List<ProductTransfer> ProductTransferCreated = [SELECT Id, Product2Id FROM ProductTransfer WHERE Work_Order_Line_Item__c = :testWorkOrderLineItem.Id];
//        System.assertEquals(1, ProductTransferCreated.size(), 'The Product Transfer has not been created.');
//        System.assertEquals(testProductRequired.Product2Id, ProductTransferCreated[0].Product2Id, 'The Product on the Product Required from the Work Order Line Item is different than the Product selected on the Product Transfer from the Work Order Line Item');
//    }
//
//    testMethod static void createNewProductTransferOnWorkOrder_ProductRequiredFromWorkOrderDoesNotMatch_ShowErrorMessage() {
//
//        testProduct1 = [SELECT Id FROM Product2 WHERE Name = 'Test Product 1'];
//        testProduct2 = [SELECT Id FROM Product2 WHERE Name = 'Test Product 2'];
//        testWorkOrder = [SELECT Id FROM WorkOrder WHERE Subject = 'This is a test'];
//        testWorkOrderLineItem = [SELECT Id FROM WorkOrderLineItem WHERE WorkOrderId = :testWorkOrder.Id];
//
//        testProductRequired1 = new ProductRequired(
//            Product2Id = testProduct1.Id,
//            QuantityRequired = 10,
//            ParentRecordId = testWorkOrder.Id
//        );
//        insert testProductRequired1;
//
//        testProductTransfer = new ProductTransfer(
//            Work_Order__c = testWorkOrder.Id,
//            Work_Order_Line_Item__c = testWorkOrderLineItem.Id,
//            Product2Id = testProduct2.Id,
//            QuantitySent = 1,
//            QuantityUnitOfMeasure = 'Each',
//            Type__c = 'Standard'
//        );
//
//        Test.startTest();
//        try{
//            insert testProductTransfer;
//        }
//        catch(Exception e) {
//            Boolean expectedExceptionThrown =  e.getMessage().contains('The Product Transfer cannot be created since the Product selected is not part of the Products Required from the Work Order') ? true : false;
//            System.AssertEquals(expectedExceptionThrown, true);
//        }
//        Test.stopTest();
//
//        List<ProductTransfer> ProductTransferCreated = [SELECT Id, Product2Id FROM ProductTransfer WHERE Work_Order__c = :testWorkOrder.Id];
//        System.assertEquals(0, ProductTransferCreated.size(), 'The Product Transfer has been created.');
//    }

}