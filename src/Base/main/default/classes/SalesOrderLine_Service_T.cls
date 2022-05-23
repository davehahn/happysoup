@IsTest
public class SalesOrderLine_Service_T {
		@testSetup
    static void dataSetup() {
        new Factory_TestData();
        Factory_CustomSettings.setupInventorySettings();
    }
    @isTest
    static public void generateSO(){
        Account customer = Factory_Account.insertCustomerAccounts(1)[0];
        Id idWarehouseWholesale = gcConstants.idWarehouseWholesale;
        InventoryTestFactory itf = new InventoryTestFactory();
        Product2[] prods = itf.buildTestProducts( 1, 'Part' );
      
        gcProduct.disableTrigger = true;
        insert prods;
        gcProduct.disableTrigger = false;
        AcctSeedERP__Sales_Order__c so = Factory_SalesOrder.createSalesOrder(customer);
		
        AcctSeedERP__Sales_Order_Line__c sol = [SELECT Id FROM AcctSeedERP__Sales_Order_Line__c WHERE AcctSeedERP__Sales_Order__c =: so.Id limit 1];
        SalesOrderLine_Service.cascadeDeleteKitMaterial(new Set<Id>{sol.id});
        SalesOrderLine_Service.updateMaterialSpec(new Set<Id>{sol.id});
        //updateMaterialSpec
    }
   
     @isTest
    static public void updateMaterialSpec_Test(){
        Account customer = Factory_Account.insertCustomerAccounts(1)[0];
        Id idWarehouseWholesale = gcConstants.idWarehouseWholesale;
        InventoryTestFactory itf = new InventoryTestFactory();
        Product2[] prods = itf.buildTestProducts( 1, 'Part' );
      
        gcProduct.disableTrigger = true;
        insert prods;
        gcProduct.disableTrigger = false;
        AcctSeedERP__Sales_Order__c so = Factory_SalesOrder.createSalesOrder(customer);
		
        AcctSeedERP__Sales_Order_Line__c sol = [SELECT Id FROM AcctSeedERP__Sales_Order_Line__c WHERE AcctSeedERP__Sales_Order__c =: so.Id limit 1];
        SalesOrderLine_Service.cascadeDeleteKitMaterial(new Set<Id>{sol.id});
        SalesOrderLine_Service.updateMaterialSpec(new Set<Id>{sol.id});
        //updateMaterialSpec
    }
   
}