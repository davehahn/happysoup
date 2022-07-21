@isTest
public class TA_Shipment_CreateBilling_T {
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  @isTest
  static void afterUpdate_Test() {
    Account customer = Factory_Account.insertCustomerAccounts(1)[0];
    Id idWarehouseWholesale = gcConstants.idWarehouseWholesale;
    AcctSeed__Accounting_Settings__c accSetting = [
      SELECT AcctSeed__Default_Ledger__c
      FROM AcctSeed__Accounting_Settings__c
      ORDER BY CreatedDate
    ][0];
    AcctSeedERP__Location__c loc = [
      SELECT ID
      FROM AcctSeedERP__Location__c
      WHERE AcctSeedERP__Warehouse__c = :idWarehouseWholesale
      LIMIT 1
    ];
    InventoryTestFactory itf = new InventoryTestFactory();
    Product2[] prods = itf.buildTestProducts(1, 'Part');
    gcProduct.disableTrigger = true;
    insert prods;
    gcProduct.disableTrigger = false;
    AcctSeedERP__Sales_Order__c so = Factory_SalesOrder.createSalesOrder(customer, idWarehouseWholesale, prods[0].Id);
    /// Create Balance
    AcctSeedERP__Inventory_Balance__c balance = new AcctSeedERP__Inventory_Balance__c(
      AcctSeedERP__Location__c = loc.Id,
      AcctSeedERP__Warehouse__c = idWarehouseWholesale,
      AcctSeedERP__Product__c = prods[0].Id
    );
    insert balance;
    AcctSeedERP__Inbound_Inventory_Movement__c movement = new AcctSeedERP__Inbound_Inventory_Movement__c(
      AcctSeedERP__Unit_Cost__c = 10,
      AcctSeedERP__Type__c = 'Other',
      AcctSeedERP__Quantity__c = 1,
      AcctSeedERP__Credit_GL_Account__c = prods[0].AcctSeed__Inventory_GL_Account__c,
      AcctSeedERP__Inventory_Balance__c = balance.Id,
      AcctSeedERP__Ledger__c = accSetting.AcctSeed__Default_Ledger__c,
      GMBLASERP__Warehouse__c = idWarehouseWholesale
    );
    insert movement;
    Ecwid_Sales_Order__e evt = new Ecwid_Sales_Order__e(Status__c = true, Sales_Order_Id__c = so.Id);
    Database.SaveResult sr = EventBus.publish(evt);
    AcctSeedERP__Sales_Order_Line__c sol = [
      SELECT Id
      FROM AcctSeedERP__Sales_Order_Line__c
      WHERE AcctSeedERP__Sales_Order__c = :so.Id
      LIMIT 1
    ];
    AcctSeedERP__Sales_Order_Inventory_Movement__c inmove = new AcctSeedERP__Sales_Order_Inventory_Movement__c(
      AcctSeedERP__Unit_Cost__c = 12,
      AcctSeedERP__Quantity__c = 1,
      AcctSeedERP__Inventory_Balance__c = balance.Id,
      AcctSeedERP__Ledger__c = accSetting.AcctSeed__Default_Ledger__c,
      GMBLASERP__Warehouse__c = idWarehouseWholesale,
      AcctSeedERP__Movement_Date__c = Date.today(),
      AcctSeedERP__Sales_Order_Line__c = sol.Id
    );
    insert inmove;
    Test.startTest();
    AcctSeedERP__Shipment__c ship = new AcctSeedERP__Shipment__c(
      AcctSeedERP__Status__c = 'Scheduled',
      AcctSeedERP__Sales_Order__c = so.Id
    );
    insert ship;
    insert new AcctSeedERP__Shipment_Line__c(
      AcctSeedERP__Shipment__c = ship.Id,
      AcctSeedERP__Sales_Order_Line__c = sol.Id,
      AcctSeedERP__Quantity_Shipped__c = 1
    );
    ship.AcctSeedERP__Status__c = 'Shipped';
    update ship;
    new TA_Shipment_CreateBilling()
      .afterUpdate(new List<AcctSeedERP__Shipment__c>{ ship }, new List<AcctSeedERP__Shipment__c>{ ship });
    Test.stopTest();
    AcctSeed__Billing__c b = [
      SELECT Id, GMBLASG__Posted__c
      FROM AcctSeed__Billing__c
      WHERE AcctSeedERP__Sales_Order__c = :so.Id
    ];
    System.assertEquals(b.GMBLASG__Posted__c, true);
  }
}
