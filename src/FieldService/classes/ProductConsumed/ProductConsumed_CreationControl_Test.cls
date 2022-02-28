@isTest
private class ProductConsumed_CreationControl_Test {
    
    static Product2 testProduct1;
    static Product2 testProduct2;
    static Product2 testProduct3;
    static Pricebook2 testPricebook;
    static Account testAccount;
    static AcctSeed__GL_Account__c revenueAccount;
    static AcctSeed__GL_Account__c expenseAccount;
    static WorkOrder testWorkOrder;
    static WorkOrderLineItem testWorkOrderLineItem;
    static String substringProductId;

    static ProductConsumed testProductConsumed;
    static ProductConsumed testProductConsumed1;
    static ProductConsumed testProductConsumed2;

    static ProductRequired testProductRequired;
    static ProductRequired testProductRequired1;
    static ProductRequired testProductRequired2;
    
    static PricebookEntry testPricebookEntryProduct1;
    static PricebookEntry testPricebookEntryProduct2;
    static PricebookEntry testPricebookEntryProduct3;

    @testSetup static void dataSetup() {

        new Factory_TestData();
        Factory_CustomSettings.setupInventorySettings();

        Id accountBusinessRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND IsActive = true AND DeveloperName LIKE '%business%'][0].Id;
        Id workOrderServiceRecordType = [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'WorkOrder' AND IsActive = true][0].Id;
        Id productRecordType = [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Product2' AND IsActive = true AND DeveloperName LIKE '%Part%'][0].Id;
        Id standardPriceBookId = Test.getStandardPricebookId();

        testAccount = new Account(
            Name = 'Test Account',
            RecordTypeId = accountBusinessRecordType);
        insert testAccount;

        testProduct1 = new Product2(
            Name = 'Test Product 1',
            ProductCode = 'Test1234',
            Unique_Product_Code__c = 'TestCode1234',
            isActive = true,
            AcctSeed__Inventory_Product__c = false,
            AcctSeed__Inventory_Type__c = 'Manufactured',
            RecordTypeId = productRecordType,
            Family = 'Remote',
            AcctSeedERP__Serialized__c = false,
            GMBLASERP__Lot_Tracked__c = false,
            AcctSeed__Accounting_Type__c = 'Taxable_Product',
            AcctSeed__Unit_Cost__c = 50.00
        );
        insert testProduct1;
        
        testProduct2 = new Product2(
            Name = 'Test Product 2',
            ProductCode = 'Test4567',
            Unique_Product_Code__c = 'TestCode4567',
            isActive = true,
            AcctSeed__Inventory_Product__c = false,
            AcctSeed__Inventory_Type__c = 'Manufactured',
            RecordTypeId = productRecordType
        );
        insert testProduct2;

        testProduct3 = new Product2(
            Name = 'Test Product 3',
            ProductCode = 'Test987',
            Unique_Product_Code__c = 'TestCode987',
            isActive = true,
            AcctSeed__Inventory_Product__c = false,
            AcctSeed__Inventory_Type__c = 'Manufactured',
            RecordTypeId = productRecordType
        );
        insert testProduct3;

        testPricebookEntryProduct1 = new PricebookEntry(
            IsActive = true,
            Pricebook2Id = standardPriceBookId,
            Product2Id = testProduct1.Id,
            UnitPrice = 50.00
        );
        insert testPricebookEntryProduct1;

        testPricebookEntryProduct2 = new PricebookEntry(
            IsActive = true,
            Pricebook2Id = standardPriceBookId,
            Product2Id = testProduct2.Id,
            UnitPrice = 100.00
        );
        insert testPricebookEntryProduct2;

        testPricebookEntryProduct3 = new PricebookEntry(
            IsActive = true,
            Pricebook2Id = standardPriceBookId,
            Product2Id = testProduct3.Id,
            UnitPrice = 25.00
        );
        insert testPricebookEntryProduct3;

        testWorkOrder = new WorkOrder(
            Subject = 'This is a test',
            RecordTypeId = workOrderServiceRecordType,
            Pricebook2Id = standardPriceBookId

        );
        TriggerBase.bypass('WorkOrder');
        insert testWorkOrder;
        TriggerBase.clearBypass('WorkOrder');

        testWorkOrderLineItem = new WorkOrderLineItem(
            WorkOrderId = testWorkOrder.Id,
            Status = 'New'
        );
        TriggerBase.bypass('WorkOrderLineItem');
        insert testWorkOrderLineItem;
        TriggerBase.clearBypass('WorkOrderLineItem');
    }
    
    testMethod static void createNewProductConsumedrOnWorkOrder_ProductRequiredFromWorkOrderMatch_Pass() {

        testProduct1 = [SELECT Id FROM Product2 WHERE Name = 'Test Product 1'];
        testPricebookEntryProduct1 = [SELECT Id FROM PricebookEntry WHERE Product2Id  = :testProduct1.Id];
        testWorkOrder = [SELECT Id FROM WorkOrder WHERE Subject = 'This is a test'];

        testProductRequired = new ProductRequired(
            Product2Id = testProduct1.Id,
            QuantityRequired = 1,
            ParentRecordId = testWorkOrder.Id
        );
        insert testProductRequired;

        testProductConsumed = new ProductConsumed(
            WorkOrderId = testWorkOrder.Id,
            PricebookEntryId = testPricebookEntryProduct1.Id,
            QuantityConsumed = 1,
            Type__c = 'Standard'
        );

        Test.startTest();
        insert testProductConsumed;
        Test.stopTest();

        List<ProductConsumed> ProductConsumedCreated = [SELECT Id, ProductId__c FROM ProductConsumed WHERE WorkOrderId = :testWorkOrder.Id];
        System.assertEquals(1, ProductConsumedCreated.size(), 'The Product Consumed has not been created.');

        substringProductId = testProductRequired.Product2Id;
        substringProductId = substringProductId.substring(0, 15);

        System.assertEquals(substringProductId, ProductConsumedCreated[0].ProductId__c, 'The Product on the Product Required from the Work Order is different than the Product selected on the Product Consumed from the Work Order');
    }

    testMethod static void createNewProductConsumedOnWorkOrderLineItem_ProductRequiredFromWorkOrderLineItemMatch_Pass() {

        testProduct1 = [SELECT Id FROM Product2 WHERE Name = 'Test Product 1'];
        testPricebookEntryProduct1 = [SELECT Id FROM PricebookEntry WHERE Product2Id  = :testProduct1.Id];
        testWorkOrder = [SELECT Id FROM WorkOrder WHERE Subject = 'This is a test'];
        testWorkOrderLineItem = [SELECT Id FROM WorkOrderLineItem WHERE WorkOrderId = :testWorkOrder.Id];

        testProductRequired = new ProductRequired(
            Product2Id = testProduct1.Id,
            QuantityRequired = 1,
            ParentRecordId = testWorkOrderLineItem.Id
        );
        insert testProductRequired;

        testProductConsumed = new ProductConsumed(
            WorkOrderId = testWorkOrder.Id,
            WorkOrderLineItemId = testWorkOrderLineItem.Id,
            PricebookEntryId = testPricebookEntryProduct1.Id,
            QuantityConsumed = 1,
            Type__c = 'Standard'
        );

        Test.startTest();
        insert testProductConsumed;
        Test.stopTest();

        List<ProductConsumed> ProductConsumedCreated = [SELECT Id, ProductId__c FROM ProductConsumed WHERE WorkOrderLineItemId = :testWorkOrderLineItem.Id];
        System.assertEquals(1, ProductConsumedCreated.size(), 'The Product Consumed has not been created.');

        substringProductId = testProductRequired.Product2Id;
        substringProductId = substringProductId.substring(0, 15);

        System.assertEquals(substringProductId, ProductConsumedCreated[0].ProductId__c, 'The Product on the Product Required from the Work Order Line Item is different than the Product selected on the Product Consumed from the Work Order Line Item');
    }

    testMethod static void createNewProductConsumedOnWorkOrderLineItem_ProductRequiredFromWorkOrderMatch_Pass() {

        testProduct1 = [SELECT Id FROM Product2 WHERE Name = 'Test Product 1'];
        testPricebookEntryProduct1 = [SELECT Id FROM PricebookEntry WHERE Product2Id  = :testProduct1.Id];
        testWorkOrder = [SELECT Id FROM WorkOrder WHERE Subject = 'This is a test'];
        testWorkOrderLineItem = [SELECT Id FROM WorkOrderLineItem WHERE WorkOrderId = :testWorkOrder.Id];

        testProductRequired = new ProductRequired(
            Product2Id = testProduct1.Id,
            QuantityRequired = 1,
            ParentRecordId = testWorkOrder.Id
        );
        insert testProductRequired;

        testProductConsumed = new ProductConsumed(
            WorkOrderId = testWorkOrder.Id,
            WorkOrderLineItemId = testWorkOrderLineItem.Id,
            PricebookEntryId = testPricebookEntryProduct1.Id,
            QuantityConsumed = 1,
            Type__c = 'Standard'
        );

        Test.startTest();
        insert testProductConsumed;
        Test.stopTest();

        List<ProductConsumed> ProductConsumedCreated = [SELECT Id, ProductId__c FROM ProductConsumed WHERE WorkOrderLineItemId = :testWorkOrderLineItem.Id];
        System.assertEquals(1, ProductConsumedCreated.size(), 'The Product Consumed has not been created.');

        substringProductId = testProductRequired.Product2Id;
        substringProductId = substringProductId.substring(0, 15);

        System.assertEquals(substringProductId, ProductConsumedCreated[0].ProductId__c, 'The Product on the Product Required from the Work Order is different than the Product selected on the Product Consumed from the Work Order Line Item');
    }

    testMethod static void createNewProductConsumedOnWorkOrder_ProductRequiredFromWorkOrderDoesNotMatch_ShowErrorMessage() {

        testProduct1 = [SELECT Id FROM Product2 WHERE Name = 'Test Product 1'];
        testProduct2 = [SELECT Id FROM Product2 WHERE Name = 'Test Product 2'];
        testPricebookEntryProduct2 = [SELECT Id FROM PricebookEntry WHERE Product2Id  = :testProduct2.Id];
        testWorkOrder = [SELECT Id FROM WorkOrder WHERE Subject = 'This is a test'];

        testProductRequired1 = new ProductRequired(
            Product2Id = testProduct1.Id,
            QuantityRequired = 1,
            ParentRecordId = testWorkOrder.Id
        );
        insert testProductRequired1;

        testProductConsumed = new ProductConsumed(
            WorkOrderId = testWorkOrder.Id,
            PricebookEntryId = testPricebookEntryProduct2.Id,
            QuantityConsumed = 1,
            Type__c = 'Standard'
        );

        Test.startTest();
        try{
            insert testProductConsumed;
        }
        catch(Exception e) {
            Boolean expectedExceptionThrown =  e.getMessage().contains('The Product Consumed cannot be created since the Product selected is not part of the Products Required from the Work Order') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        Test.stopTest();

        List<ProductConsumed> ProductConsumedCreated = [SELECT Id, ProductId__c FROM ProductConsumed WHERE WorkOrderId = :testWorkOrder.Id];
        System.assertEquals(0, ProductConsumedCreated.size(), 'The Product Consumed has been created.');
    }
    
    testMethod static void createNewProductConsumedOnWorkOrderLineItem_ProductRequiredFromWorkOrderAndWorkOrderLineItemDoesNotMatch_ShowErrorMessage() {

        testProduct1 = [SELECT Id FROM Product2 WHERE Name = 'Test Product 1'];
        testProduct2 = [SELECT Id FROM Product2 WHERE Name = 'Test Product 2'];
        testProduct3 = [SELECT Id FROM Product2 WHERE Name = 'Test Product 3'];
        testPricebookEntryProduct3 = [SELECT Id FROM PricebookEntry WHERE Product2Id  = :testProduct3.Id];
        testWorkOrder = [SELECT Id FROM WorkOrder WHERE Subject = 'This is a test'];
        testWorkOrderLineItem = [SELECT Id FROM WorkOrderLineItem WHERE WorkOrderId = :testWorkOrder.Id];


        testProductRequired1 = new ProductRequired(
            Product2Id = testProduct1.Id,
            QuantityRequired = 1,
            ParentRecordId = testWorkOrder.Id
        );
        insert testProductRequired1;

        testProductRequired2 = new ProductRequired(
            Product2Id = testProduct2.Id,
            QuantityRequired = 1,
            ParentRecordId = testWorkOrderLineItem.Id
        );
        insert testProductRequired2;

        testProductConsumed = new ProductConsumed(
            WorkOrderId = testWorkOrder.Id,
            WorkOrderLineItemId = testWorkOrderLineItem.Id,
            PricebookEntryId = testPricebookEntryProduct3.Id,
            QuantityConsumed = 1,
            Type__c = 'Standard'
        );

        Test.startTest();
        try{
            insert testProductConsumed;
        }
        catch(Exception e) {
            Boolean expectedExceptionThrown =  e.getMessage().contains('The Product Consumed cannot be created since the Product selected is not part of the Products Required from the Work Order or the Work Order Line Item') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        Test.stopTest();

        List<ProductConsumed> ProductConsumedCreated = [SELECT Id, ProductId__c FROM ProductConsumed WHERE WorkOrderId = :testWorkOrder.Id];
        System.assertEquals(0, ProductConsumedCreated.size(), 'The Product Consumed has been created.');

    }
}