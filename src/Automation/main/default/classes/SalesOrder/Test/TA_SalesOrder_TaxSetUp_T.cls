@isTest
public class TA_SalesOrder_TaxSetUp_T {
	@testSetup
    static void dataSetup() {
        new Factory_TestData();
        Factory_CustomSettings.setupInventorySettings();
    }
    @isTest
    static public void beforeInsert_test(){
        Account customer = Factory_Account.insertCustomerAccounts(1)[0];
        Id idWarehouseWholesale = gcConstants.idWarehouseWholesale;
        InventoryTestFactory itf = new InventoryTestFactory();
        Product2[] prods = itf.buildTestProducts( 1, 'Part' );
      
        gcProduct.disableTrigger = true;
        insert prods;
        gcProduct.disableTrigger = false;
        Test.startTest();
        AcctSeedERP__Sales_Order__c so = Factory_SalesOrder.createSalesOrder(customer, idWarehouseWholesale, prods[0].Id);
		AcctSeedERP__Sales_Order_Line__c sol = [SELECT Id FROM AcctSeedERP__Sales_Order_Line__c WHERE AcctSeedERP__Sales_Order__c =: so.Id limit 1];
        new TA_SalesOrder_TaxSetUp().beforeInsert(new List<AcctSeedERP__Sales_Order__c>{so});
        Test.stopTest();
        AcctSeedERP__Sales_Order__c soNew = [Select id, Tax_is_Harmonized__c,Tax_Rate_Provincial__c,Tax_Rate_Retail__c,Tax_Rate_Federal__c FROM AcctSeedERP__Sales_Order__c LIMIT 1];
        System.assert(soNew.Tax_is_Harmonized__c==false);
    	System.assert(soNew.Tax_Rate_Federal__c==5);
        
    
    }
   
    @isTest
    static public void beforeUpdate_test(){
        Account customer = Factory_Account.insertCustomerAccounts(1)[0];
        Id idWarehouseWholesale = gcConstants.idWarehouseWholesale;
        InventoryTestFactory itf = new InventoryTestFactory();
        Product2[] prods = itf.buildTestProducts( 1, 'Part' );
      
        gcProduct.disableTrigger = true;
        insert prods;
        gcProduct.disableTrigger = false;
        AcctSeedERP__Sales_Order__c so = Factory_SalesOrder.createSalesOrder(customer, idWarehouseWholesale, prods[0].Id);
		AcctSeedERP__Sales_Order_Line__c sol = [SELECT Id FROM AcctSeedERP__Sales_Order_Line__c WHERE AcctSeedERP__Sales_Order__c =: so.Id limit 1];
       	Test.startTest();
        new TA_SalesOrder_TaxSetUp().beforeUpdate(new List<AcctSeedERP__Sales_Order__c>{so},new List<AcctSeedERP__Sales_Order__c>{so});
   		Test.stopTest();
            
        AcctSeedERP__Sales_Order__c soNew = [Select id, Tax_is_Harmonized__c,Tax_Rate_Provincial__c,Tax_Rate_Retail__c,Tax_Rate_Federal__c FROM AcctSeedERP__Sales_Order__c LIMIT 1];
        System.assert(soNew.Tax_is_Harmonized__c==false);
    	System.assert(soNew.Tax_Rate_Federal__c==5);
    }
}