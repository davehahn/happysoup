/**
 * Created by aminrubel on 21/1/20.
 */

@isTest
private class ProductTransfer_DeleteControl_Test {

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
//        /// Create the ERP
//        AcctSeed__Project__c pr = Factory_ERPOrder.insertServiceOrdersWorkOrder(testAccount,idWarehouseWholesale, Date.today(), testWorkOrder);
//        System.debug(LoggingLevel.ERROR,'pr:'+pr);
//        System.debug(LoggingLevel.ERROR,'pr.Id:'+pr.Id);
//        System.debug(LoggingLevel.ERROR,'pr.GMBLASERP__Warehouse__c:'+pr.GMBLASERP__Warehouse__c);
//        testWorkOrder.ERP_Order__c = pr.Id;
//        TriggerBase.bypass('WorkOrder');
//        update testWorkOrder;
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
//
//        AcctSeed__Project_Task__c pt = new AcctSeed__Project_Task__c(
//            AcctSeed__Project__c = pr.Id,
//            Name = 'Test Task',
//            DisplayOnCustomerInvoice__c = true
//        );
//        insert pt;
//
//        testWorkOrderLineItem.ERP_Order_Task__c = pt.Id;
//        TriggerBase.bypass('WorkOrderLineItem');
//        update testWorkOrderLineItem;
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
//        TriggerHandler.clearBypass('ProductRequired_TriggerHandler');
//        List<AcctSeedERP__Material__c> listMTRL = new List<AcctSeedERP__Material__c>();
//        AcctSeedERP__Material__c prMat = new AcctSeedERP__Material__c(
//            AcctSeedERP__Product__c = testProduct1.Id,
//            AcctSeedERP__Project_Task__c = pt.Id,
//            AcctSeedERP__Project__c = pr.Id,
//            AcctSeedERP__Quantity_Per_Unit__c = testProductRequired.QuantityRequired
//        );
//        listMTRL.add(prMat);
//        AcctSeedERP__Material__c prMatSr = new AcctSeedERP__Material__c(
//            AcctSeedERP__Product__c = testProduct0.Id,
//            AcctSeedERP__Project_Task__c = pt.Id,
//            AcctSeedERP__Project__c = pr.Id,
//            AcctSeedERP__Quantity_Per_Unit__c = testProductRequired1.QuantityRequired
//        );
//        listMTRL.add(prMatSr);
//        System.debug(loggingLevel.error, 'testWorkOrderLineItem:'+testWorkOrderLineItem);
//        System.debug(loggingLevel.error, 'prMat:'+prMat);
//        insert listMTRL;
//
//        testProductRequired.Material__c = prMat.Id;
//        testProductRequired1.Material__c = prMatSr.Id;
//        TriggerHandler.bypass('ProductRequired_TriggerHandler');
//        update listPR;
//        TriggerHandler.clearBypass('ProductRequired_TriggerHandler');

    }

    testMethod static void ProductTransfer_DeleteControl_Test() {
//
//        testProduct1 = [SELECT Id FROM Product2 WHERE Name = 'Test Product 1'];
//        testWorkOrder = [SELECT Id FROM WorkOrder WHERE Subject = 'This is a test'];
//        System.debug(loggingLevel.error, 'testWorkOrder:'+testWorkOrder.Id);
//        testWorkOrderLineItem = [SELECT Id, Description, Visible_to_Customer__c, Is_From_Opportunity__c, WorkOrderId, WorkOrder.Opportunity__c, WorkOrder.ERP_Order__c, ERP_Order_Task__c FROM WorkOrderLineItem WHERE WorkOrderId = :testWorkOrder.Id];
//        System.debug(loggingLevel.error, 'testWorkOrderLineItem:'+testWorkOrderLineItem.Id);
//
//        AcctSeed__Accounting_Settings__c accSetting = [SELECT AcctSeed__Default_Ledger__c FROM AcctSeed__Accounting_Settings__c ORDER BY CreatedDate][0];
//        AcctSeed__GL_Account__c glA = [SELECT Id FROM AcctSeed__GL_Account__c LIMIT 1];
//        Id idWarehouseWholesale = gcConstants.idWarehouseWholesale;
//        AcctSeedERP__Location__c loc = [SELECT Id FROM AcctSeedERP__Location__c  WHERE AcctSeedERP__Warehouse__c =:idWarehouseWholesale LIMIT 1];
//
//        Id idBalance = GMBLASERP.gcInventoryBalance.findOrCreateBalance(testProduct1.Id,idWarehouseWholesale,loc.Id);
//
//        AcctSeedERP__Inbound_Inventory_Movement__c movement = new AcctSeedERP__Inbound_Inventory_Movement__c(
//            AcctSeedERP__Unit_Cost__c = 10,
//            AcctSeedERP__Type__c = 'Accounting',
//            AcctSeedERP__Quantity__c = 10,
//            AcctSeedERP__Credit_GL_Account__c = glA.Id,
//            AcctSeedERP__Inventory_Balance__c = idBalance,
//            AcctSeedERP__Ledger__c = accSetting.AcctSeed__Default_Ledger__c,
//            GMBLASERP__Warehouse__c = idWarehouseWholesale
//        );
//        TriggerHandler.bypass('ProductItemTransaction_TriggerHandler');
//        insert movement;
//        ///
//        testProductTransfer = new ProductTransfer(
//            Work_Order__c = testWorkOrder.Id,
//            Work_Order_Line_Item__c = testWorkOrderLineItem.Id,
//            Product2Id = testProduct1.Id,
//            QuantitySent = 1,
//            QuantityReceived = 1,
//            QuantityUnitOfMeasure = 'Each',
//            Type__c = 'Standard'
//        );
//        ///
//
//        Test.startTest();
//        insert testProductTransfer;
//        delete testProductTransfer;
//        Test.stopTest();
//
//        List<ProductTransfer> ProductTransferCreated = [SELECT Id, Product2Id FROM ProductTransfer WHERE Work_Order_Line_Item__c = :testWorkOrderLineItem.Id];
//        System.assertEquals(0, ProductTransferCreated.size(), 'The Product Transfer has been deleted.');
    }
    testMethod static void ProductTransferSerial_DeleteControl_Test() {

//        testProduct0 = [SELECT Id FROM Product2 WHERE Name = 'Test Product 0'];
//        testWorkOrder = [SELECT Id FROM WorkOrder WHERE Subject = 'This is a test'];
//        System.debug(loggingLevel.error, 'testWorkOrder:'+testWorkOrder.Id);
//        testWorkOrderLineItem = [SELECT Id, Description, Visible_to_Customer__c, Is_From_Opportunity__c, WorkOrderId, WorkOrder.Opportunity__c, WorkOrder.ERP_Order__c, ERP_Order_Task__c FROM WorkOrderLineItem WHERE WorkOrderId = :testWorkOrder.Id];
//        System.debug(loggingLevel.error, 'testWorkOrderLineItem:'+testWorkOrderLineItem.Id);
//
//        AcctSeed__Accounting_Settings__c accSetting = [SELECT AcctSeed__Default_Ledger__c FROM AcctSeed__Accounting_Settings__c ORDER BY CreatedDate][0];
//        AcctSeed__GL_Account__c glA = [SELECT Id FROM AcctSeed__GL_Account__c LIMIT 1];
//        Id idWarehouseWholesale = gcConstants.idWarehouseWholesale;
//        AcctSeedERP__Location__c loc = [SELECT Id FROM AcctSeedERP__Location__c  WHERE AcctSeedERP__Warehouse__c =:idWarehouseWholesale LIMIT 1];
//        GMBLASERP__Serial_Number__c sr = [SELECT Id, GMBLASERP__Lot__c FROM GMBLASERP__Serial_Number__c WHERE GMBLASERP__Product__c =:testProduct0.Id LIMIT 1];
//
//        Id idBalance = GMBLASERP.gcInventoryBalance.findOrCreateBalance(testProduct0.Id,idWarehouseWholesale,loc.Id);
//
//        AcctSeedERP__Inbound_Inventory_Movement__c movement = new AcctSeedERP__Inbound_Inventory_Movement__c(
//            AcctSeedERP__Unit_Cost__c = 100,
//            AcctSeedERP__Type__c = 'Accounting',
//            AcctSeedERP__Quantity__c = 1,
//            AcctSeedERP__Credit_GL_Account__c = glA.Id,
//            AcctSeedERP__Inventory_Balance__c = idBalance,
//            AcctSeedERP__Ledger__c = accSetting.AcctSeed__Default_Ledger__c,
//            GMBLASERP__Warehouse__c = idWarehouseWholesale,
//            GMBLASERP__Lot__c = sr.GMBLASERP__Lot__c,
//            GMBLASERP__Serial_Number__c = sr.Id
//        );
//        TriggerHandler.bypass('ProductItemTransaction_TriggerHandler');
//        insert movement;
//        ///
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
//        insert testProductTransfer;
//        delete testProductTransfer;
//        Test.stopTest();
//
//        List<ProductTransfer> ProductTransferCreated = [SELECT Id, Product2Id FROM ProductTransfer WHERE Work_Order_Line_Item__c = :testWorkOrderLineItem.Id];
//        System.assertEquals(0, ProductTransferCreated.size(), 'The Product Transfer has been deleted.');
    }
}