@isTest
public class TA_SalesOrderLine_TaxSetup_BI_BU_T {

    @testSetup
    static void dataSetup() {
        new Factory_TestData();
        Factory_CustomSettings.setupInventorySettings();
    }
    
    @isTest
    static void beforeInsert_Test(){
        Account customer = Factory_Account.insertCustomerAccounts(1)[0];
        Id idWarehouseWholesale = gcConstants.idWarehouseWholesale;
        InventoryTestFactory itf = new InventoryTestFactory();
        Product2[] prods = itf.buildTestProducts( 1, 'Part' );
      
        gcProduct.disableTrigger = true;
        insert prods;
        gcProduct.disableTrigger = false;
        AcctSeedERP__Sales_Order__c so = Factory_SalesOrder.createSalesOrder(customer);
		
        AcctSeedERP__Sales_Order_Line__c sol = [SELECT Id,AcctSeedERP__Product__c,AcctSeedERP__GL_Account_Variable_1__c,Sales_Order_Line__c,AcctSeedERP__GL_Account_Variable_2__c,AcctSeedERP__GL_Account_Variable_3__c,AcctSeedERP__Sales_Order__c,Taxable_Retail__c FROM AcctSeedERP__Sales_Order_Line__c WHERE AcctSeedERP__Sales_Order__c =: so.Id limit 1];
		Test.startTest();
        new TA_SalesOrderLine_TaxSetup_BI_BU().beforeInsert(new List<AcctSeedERP__Sales_Order_Line__c>{sol});
		Test.stopTest();
        System.assert(sol.Taxable_Retail__c == false);
        
    }

	@isTest
    static void beforeUpdate_Test(){
        Account customer = Factory_Account.insertCustomerAccounts(1)[0];
        Id idWarehouseWholesale = gcConstants.idWarehouseWholesale;
        InventoryTestFactory itf = new InventoryTestFactory();
        Product2[] prods = itf.buildTestProducts( 1, 'Part' );
      
        gcProduct.disableTrigger = true;
        insert prods;
        gcProduct.disableTrigger = false;
        AcctSeedERP__Sales_Order__c so = Factory_SalesOrder.createSalesOrder(customer);
		AcctSeedERP__Sales_Order_Line__c sol = [SELECT Id,AcctSeedERP__GL_Account_Variable_1__c,AcctSeedERP__Product__c,Sales_Order_Line__c,AcctSeedERP__GL_Account_Variable_2__c,AcctSeedERP__GL_Account_Variable_3__c,AcctSeedERP__Sales_Order__c FROM AcctSeedERP__Sales_Order_Line__c WHERE AcctSeedERP__Sales_Order__c =: so.Id limit 1];
		Test.startTest();
        new TA_SalesOrderLine_TaxSetup_BI_BU().beforeUpdate(new List<AcctSeedERP__Sales_Order_Line__c>{sol},new List<AcctSeedERP__Sales_Order_Line__c>{sol});
		Test.stopTest();
        System.assert(sol.Taxable_Retail__c == false);
    }

}