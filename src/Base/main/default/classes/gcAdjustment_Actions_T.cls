@isTest(SeeAllData=false)
public class gcAdjustment_Actions_T {
    
    @TestSetup
    static void testData(){
        new Factory_TestData();
        Factory_CustomSettings.setupInventorySettings();
        Factory_AccountPayable.insertAccountPayable(5);
        new Factory_AccountingVariables();
        //List<Product2> serializedProducts = Factory_Product.createSerializedProducts(RECORDTYPE, FAMILY, 10);
    }
    @isTest
    static void testMethod1WithSingleRecord(){
        Product2 part = Factory_Product.createNonSerializedProduct('Part', 'Electronics');

        GMBLASERP__Inventory_Adjustment__c adj = new GMBLASERP__Inventory_Adjustment__c();
        adj.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
        adj.Department_GLV_2__c = gcConstants.idGlv2Sales;
        adj.GMBLASERP__GL_Account__c = gcConstants.idGlCostVariance;
        adj.GMBLASERP__Product__c = part.Id;
        adj.GMBLASERP__Adjustment_Type__c = 'Value';
        insert adj;
        
        ApexPages.currentPage().getParameters().put('idFilter',adj.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(adj);
        gcAdjustment_Actions gcAdjustmentActions = new gcAdjustment_Actions(sc);

        gcAdjustmentActions.init();

    }
    
    @isTest
    static void testMethod1WithSingleRecordWithoutIdFilter(){
        Product2 part = Factory_Product.createNonSerializedProduct('Part', 'Electronics');

        GMBLASERP__Inventory_Adjustment__c adj = new GMBLASERP__Inventory_Adjustment__c();
        adj.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
        adj.Department_GLV_2__c = gcConstants.idGlv2Sales;
        adj.GMBLASERP__GL_Account__c = gcConstants.idGlCostVariance;
        adj.GMBLASERP__Product__c = part.Id;
        adj.GMBLASERP__Adjustment_Type__c = 'Value';
        insert adj;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(adj);
        gcAdjustment_Actions gcAdjustmentActions = new gcAdjustment_Actions(sc);

        gcAdjustmentActions.init();

    }
    @isTest
    static void testMethod1WithStandardSetRecordWithProduct(){
        Product2 part = Factory_Product.createNonSerializedProduct('Part', 'Electronics');
		List<GMBLASERP__Inventory_Adjustment__c> listAdj = new List<GMBLASERP__Inventory_Adjustment__c>();
        GMBLASERP__Inventory_Adjustment__c adj1 = new GMBLASERP__Inventory_Adjustment__c();
        adj1.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
        adj1.Department_GLV_2__c = gcConstants.idGlv2Sales;
        adj1.GMBLASERP__GL_Account__c = gcConstants.idGlCostVariance;
        adj1.GMBLASERP__Product__c = part.Id;
        adj1.GMBLASERP__Adjustment_Type__c = 'Value';
        listAdj.add(adj1);
        
        GMBLASERP__Inventory_Adjustment__c adj2 = new GMBLASERP__Inventory_Adjustment__c();
        adj2.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
        adj2.Department_GLV_2__c = gcConstants.idGlv2Sales;
        adj2.GMBLASERP__GL_Account__c = gcConstants.idGlCostVariance;
        adj2.GMBLASERP__Adjustment_Type__c = 'Value';
        listAdj.add(adj2);
        
        insert listAdj;

        ApexPages.currentPage().getParameters().put('idFilter',adj1.Id);
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(listAdj);
        gcAdjustment_Actions gcAdjustmentActions = new gcAdjustment_Actions(ssc);
        
        gcAdjustmentActions.init();
        new gcAdjustment_Actions();
    }
    
    
    @isTest
    static void testMethod1WithStandardSetRecordWithNonInventoryProduct(){
        Product2 part = Factory_Product.createNonSerializedProduct('Motor', 'Motor Accessories');
                
        AcctSeedERP__Warehouse__c warehouse = new AcctSeedERP__Warehouse__c();
        warehouse.Name = 'Test Warehouse';
        warehouse.City__c = 'Test City';
        warehouse.Country__c = 'Canada';
        warehouse.Phone__c = '3333333333';
        warehouse.State__c = 'Ontario';
        warehouse.Street__c = '123 test street';
        warehouse.GL_Account_Variable_3__c = gcConstants.idGlv3Others;
        insert warehouse;

        Product2 nonInvProduct = [Select Id, AcctSeed__Inventory_Product__c From Product2 where Id=:part.Id];
        nonInvProduct.AcctSeed__Inventory_Product__c = false;
        //update nonInvProduct;
                
		List<GMBLASERP__Inventory_Adjustment__c> listAdj = new List<GMBLASERP__Inventory_Adjustment__c>();
        GMBLASERP__Inventory_Adjustment__c adj1 = new GMBLASERP__Inventory_Adjustment__c();
        adj1.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
        adj1.Department_GLV_2__c = gcConstants.idGlv2Sales;
        adj1.GMBLASERP__GL_Account__c = gcConstants.idGlCostVariance;
        adj1.GMBLASERP__Product__c = part.Id;
        adj1.GMBLASERP__Adjustment_Type__c = 'Quantity';
        adj1.GMBLASERP__Warehouse__c = warehouse.Id;
        listAdj.add(adj1);
        
        GMBLASERP__Inventory_Adjustment__c adj2 = new GMBLASERP__Inventory_Adjustment__c();
        adj2.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
        adj2.Department_GLV_2__c = gcConstants.idGlv2Sales;
        adj2.GMBLASERP__GL_Account__c = gcConstants.idGlCostVariance;
        adj2.GMBLASERP__Adjustment_Type__c = 'Quantity';
        adj2.GMBLASERP__Warehouse__c = warehouse.Id;
        listAdj.add(adj2);
        
        insert listAdj;

        ApexPages.currentPage().getParameters().put('idFilter',adj1.Id);
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(listAdj);
        gcAdjustment_Actions gcAdjustmentActions = new gcAdjustment_Actions(ssc);
        
        //gcAdjustmentActions.init();
        new gcAdjustment_Actions();
    }
    
    
    @isTest
    static void testMethod1WithStandardSetRecordWithoutProduct(){
        Product2 part = Factory_Product.createNonSerializedProduct('Part', 'Electronics');
        AcctSeedERP__Warehouse__c warehouse = new AcctSeedERP__Warehouse__c();
        warehouse.Name = 'Test Warehouse';
        warehouse.City__c = 'Test City';
        warehouse.Country__c = 'Canada';
        warehouse.Phone__c = '3333333333';
        warehouse.State__c = 'Ontario';
        warehouse.Street__c = '123 test street';
        warehouse.GL_Account_Variable_3__c = gcConstants.idGlv3Others;

        insert warehouse;
        
		List<GMBLASERP__Inventory_Adjustment__c> listAdj = new List<GMBLASERP__Inventory_Adjustment__c>();
        GMBLASERP__Inventory_Adjustment__c adj1 = new GMBLASERP__Inventory_Adjustment__c();
        adj1.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
        adj1.Department_GLV_2__c = gcConstants.idGlv2Sales;
        adj1.GMBLASERP__GL_Account__c = gcConstants.idGlCostVariance;
        adj1.GMBLASERP__Product__c = null; //part.Id;
        adj1.GMBLASERP__Adjustment_Type__c = 'Quantity';
        adj1.GMBLASERP__Warehouse__c = warehouse.Id;
        listAdj.add(adj1);
        
        GMBLASERP__Inventory_Adjustment__c adj2 = new GMBLASERP__Inventory_Adjustment__c();
        adj2.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
        adj2.Department_GLV_2__c = gcConstants.idGlv2Sales;
        adj2.GMBLASERP__GL_Account__c = gcConstants.idGlCostVariance;
        adj2.GMBLASERP__Adjustment_Type__c = 'Quantity';
        adj2.GMBLASERP__Product__c = null;
        adj2.GMBLASERP__Warehouse__c = warehouse.Id;
        listAdj.add(adj2);
        
        insert listAdj;

        ApexPages.currentPage().getParameters().put('retUrl','google.com');
        ApexPages.currentPage().getParameters().put('idFilter',adj2.Id);
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(listAdj);
        gcAdjustment_Actions gcAdjustmentActions = new gcAdjustment_Actions(ssc);
        
        gcAdjustmentActions.init();
        Pagereference pg = gcAdjustmentActions.back();
        System.assertEquals('google.com',pg.getUrl());
    }
    
    
    @isTest
    static void testMethod1WithStandardSetRecordIdNotExist(){
        Product2 part = Factory_Product.createNonSerializedProduct('Part', 'Electronics');
        AcctSeedERP__Warehouse__c warehouse = new AcctSeedERP__Warehouse__c();
        warehouse.Name = 'Test Warehouse';
        warehouse.City__c = 'Test City';
        warehouse.Country__c = 'Canada';
        warehouse.Phone__c = '3333333333';
        warehouse.State__c = 'Ontario';
        warehouse.Street__c = '123 test street';
        warehouse.GL_Account_Variable_3__c = gcConstants.idGlv3Others;
        insert warehouse;
        
		List<GMBLASERP__Inventory_Adjustment__c> listAdj = new List<GMBLASERP__Inventory_Adjustment__c>();
        GMBLASERP__Inventory_Adjustment__c adj1 = new GMBLASERP__Inventory_Adjustment__c();
        adj1.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
        adj1.Department_GLV_2__c = gcConstants.idGlv2Sales;
        adj1.GMBLASERP__GL_Account__c = gcConstants.idGlCostVariance;
        adj1.GMBLASERP__Product__c = null; //part.Id;
        adj1.GMBLASERP__Adjustment_Type__c = 'Quantity';
        adj1.GMBLASERP__Warehouse__c = warehouse.Id;
        insert adj1;
        
        GMBLASERP__Inventory_Adjustment__c adj2 = new GMBLASERP__Inventory_Adjustment__c();
        adj2.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
        adj2.Department_GLV_2__c = gcConstants.idGlv2Sales;
        adj2.GMBLASERP__GL_Account__c = gcConstants.idGlCostVariance;
        adj2.GMBLASERP__Adjustment_Type__c = 'Quantity';
        adj2.GMBLASERP__Product__c = null;
        adj2.GMBLASERP__Warehouse__c = warehouse.Id;
        insert adj2;
        

        ApexPages.currentPage().getParameters().put('retUrl','google.com');
        ApexPages.currentPage().getParameters().put('idFilter',adj1.Id);
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(new List<GMBLASERP__Inventory_Adjustment__c> {adj2});
        gcAdjustment_Actions gcAdjustmentActions = new gcAdjustment_Actions(ssc);
        delete adj1;
        gcAdjustmentActions.init();
        Pagereference pg = gcAdjustmentActions.back();
        System.assertEquals('google.com',pg.getUrl());
    }
    
    @isTest
    static void testMethod1WithInventoryMovement(){
        AcctSeedERP__Warehouse__c wh = [SELECT Id FROM AcctSeedERP__Warehouse__c LIMIT 1];
        Product2 part = Factory_Product.createNonSerializedProduct('Part', 'Electronics');
		List<GMBLASERP__Inventory_Adjustment__c> listAdj = new List<GMBLASERP__Inventory_Adjustment__c>();
        GMBLASERP__Inventory_Adjustment__c adj1 = new GMBLASERP__Inventory_Adjustment__c();
        adj1.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
        adj1.Department_GLV_2__c = gcConstants.idGlv2Sales;
        adj1.GMBLASERP__GL_Account__c = gcConstants.idGlCostVariance;
        adj1.GMBLASERP__Product__c = part.Id;
        adj1.GMBLASERP__Adjustment_Type__c = 'Quantity';
        adj1.GMBLASERP__Warehouse__c = wh.Id;
        insert adj1;
        
        
        AcctSeed__Accounting_Settings__c accSetting = [SELECT AcctSeed__Default_Ledger__c FROM AcctSeed__Accounting_Settings__c ORDER BY CreatedDate][0];
        AcctSeed__GL_Account__c glA = [SELECT Id
                                       FROM AcctSeed__GL_Account__c
                                       LIMIT 1];
        
        AcctSeedERP__Location__c loc = new AcctSeedERP__Location__c(
          Name = 'Test Loc',
          AcctSeedERP__Warehouse__c = wh.Id
        );
        insert loc;
        AcctSeedERP__Inventory_Balance__c balance = new AcctSeedERP__Inventory_Balance__c(
          AcctSeedERP__Location__c = loc.Id,
          AcctSeedERP__Warehouse__c = wh.Id,
          AcctSeedERP__Product__c = part.Id
        );
        insert balance;
        AcctSeedERP__Inbound_Inventory_Movement__c movement = new AcctSeedERP__Inbound_Inventory_Movement__c(
          AcctSeedERP__Unit_Cost__c = 10,
          AcctSeedERP__Type__c = 'Inventory Transfer',
          AcctSeedERP__Quantity__c = 1,
          AcctSeedERP__Credit_GL_Account__c = glA.Id,
          AcctSeedERP__Inventory_Balance__c = balance.Id,
          AcctSeedERP__Ledger__c = accSetting.AcctSeed__Default_Ledger__c,
          GMBLASERP__Warehouse__c = wh.Id,
          GMBLASERP__Inventory_Adjustment__c =adj1.Id
        );
        GMBLASERP.gcInboundInventoryMovement.disableTrigger = true;
        insert movement;
        
        
        ApexPages.currentPage().getParameters().put('idFilter',adj1.Id);
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(new List<GMBLASERP__Inventory_Adjustment__c> {adj1});
        gcAdjustment_Actions gcAdjustmentActions = new gcAdjustment_Actions(ssc);
        gcAdjustmentActions.init();
    }
}