@isTest
public class TA_SalesOrder_UpdateSalesTax_T {
	@testSetup
    static void dataSetup() {
        new Factory_TestData();
        Factory_CustomSettings.setupInventorySettings();
    }
    @isTest
    static public void afterUpdate_test(){
        Account customer = Factory_Account.insertCustomerAccounts(1)[0];
        Id idWarehouseWholesale = gcConstants.idWarehouseWholesale;
        InventoryTestFactory itf = new InventoryTestFactory();
        Product2[] prods = itf.buildTestProducts( 1, 'Part' );
      
        gcProduct.disableTrigger = true;
        insert prods;
        gcProduct.disableTrigger = false;
        AcctSeedERP__Sales_Order__c so = Factory_SalesOrder.createSalesOrder(customer, idWarehouseWholesale, prods[0].Id);
        AcctSeedERP__Sales_Order__c soNew = so.clone(false,false,false,false);
        soNew.Tax_is_Harmonized__c = true;
        insert soNew;
		AcctSeedERP__Sales_Order_Line__c sol = [SELECT Id FROM AcctSeedERP__Sales_Order_Line__c WHERE AcctSeedERP__Sales_Order__c =: so.Id limit 1];
        Test.startTest();
        new TA_SalesOrder_UpdateSalesTax().afterUpdate(new List<AcctSeedERP__Sales_Order__c>{so},new List<AcctSeedERP__Sales_Order__c>{so});
        Test.stopTest();
    }
}