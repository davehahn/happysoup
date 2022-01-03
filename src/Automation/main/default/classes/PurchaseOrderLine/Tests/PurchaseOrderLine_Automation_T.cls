/**
 * Created by dave on 2021-06-28.
 */

@IsTest
private class PurchaseOrderLine_Automation_T {
  static AcctSeedERP__Purchase_Order__c po;
  static Product2 boat;
  static AcctSeed__Project__c erp;
  static final Decimal BOAT_PRICE = 10000.000000;
  static Map<String, Id> erpIdsMap;
  static Date eta;
  static GMBLASERP__Lot__c lot;

  static Account dealer {
    get {
      if (dealer == null) {
        Application_RecordType.AccountRTs rts = new Application_RecordType().getAccountRecordTypes();
        dealer = [SELECT Id, Name FROM Account WHERE RecordTypeId = :rts.getDealerId() LIMIT 1];
      }
      return dealer;
    }
    set {
    }
  }

  static Account supplier {
    get {
      if (supplier == null) {
        Application_RecordType.AccountRTs rts = new Application_RecordType().getAccountRecordTypes();
        supplier = [SELECT Id, Name FROM Account WHERE RecordTypeId = :rts.getSupplierId() LIMIT 1];
      }
      return supplier;
    }
    set {
    }
  }

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();

    Map<String, Account> accts = new Map<String, Account>{
      'supplier' => Factory_Account.buildAccounts(1, 'Supplier')[0],
      'dealer' => Factory_Account.buildAccounts(1, 'Dealer')[0]
    };
    insert accts.values();
    AcctSeedERP__Purchase_Order__c thePO = Factory_PurchaseOrder.buildMinimalPO(
      accts.get('supplier').Id,
      accts.get('dealer').Id
    );
    thePO.GMBLASERP__Pricebook__c = Test_Constants.idRetailPricebook;
    insert thePO;
  }

  private static void init() {
    GMBLASERP.gcPurchaseOrderLine.disableTrigger = true;
    po = [SELECT Id, GMBLASERP__Pricebook__c FROM AcctSeedERP__Purchase_Order__c LIMIT 1];
    boat = Factory_Product.createSerializedProduct('Boat', 'Full Windshield');
    Factory_PricebookEntry.createAllDefaultEntriesEntries(boat.Id, BOAT_PRICE);
  }

  private static Map<String, Id> buildErps() {
    Map<String, Id> result = new Map<String, Id>();
    erp = Factory_ERPOrder.createPartnerBoatSales(dealer, new List<Product2>{ boat }, 1)[0];
    AcctSeed__Project_Task__c erpTask = [
      SELECT Id
      FROM AcctSeed__Project_Task__c
      WHERE AcctSeed__Project__c = :erp.Id
      LIMIT 1
    ];
    result.put('erpId', erp.Id);
    result.put('taskId', erpTask.Id);
    return result;
  }

  private static AcctSeedERP__Purchase_Order_Line__c buildPOL(
    Boolean addErp,
    Boolean setLot,
    Boolean priceOverRide,
    Decimal unitPrice
  ) {
    init();
    erpIdsMap = buildErps();

    eta = Date.today().addMonths(2);
    lot = new GMBLASERP__Lot__c(
      Name = Legend_Settings__c.getOrgDefaults().Purchase_Order_Line_Lot__c,
      GMBLASERP__Product__c = boat.Id
    );
    insert lot;
    AcctSeedERP__Purchase_Order_Line__c pol = Factory_PurchaseOrder.buildLineItem(po.Id, boat.Id, 1);
    pol.deliverDate__c = eta;
    pol.GMBLASERP__Price_Override__c = priceOverRide;
    pol.AcctSeedERP__Unit_Price__c = unitPrice;

    if (addErp) {
      pol.AcctSeedERP__Project__c = erpIdsMap.get('erpId');
      pol.AcctSeedERP__Project_Task__c = erpIdsMap.get('taskId');
    }

    if (setLot) {
      pol.GMBLASERP__Lot__c = lot.Id;
    }
    return pol;
  }

  private static AcctSeedERP__Purchase_Order_Line__c insertPOL_forUpdateTesting(
    Boolean addErp,
    Boolean setLot,
    Boolean priceOverRide,
    Decimal unitPrice
  ) {
    AcctSeedERP__Purchase_Order_Line__c pol = buildPOL(addErp, setLot, priceOverRide, unitPrice);

    TriggerBase.bypass('AcctSeedERP__Purchase_Order_Line__c');
    insert pol;
    TriggerBase.clearBypass('AcctSeedERP__Purchase_Order_Line__c');
    return pol;
  }

  private static void createPayable(Id polId) {
    AcctSeed__Account_Payable__c payable = new AcctSeed__Account_Payable__c(
      AcctSeedERP__Purchase_Order__c = po.Id,
      AcctSeed__Ledger__c = Test_Constants.idLedger,
      AcctSeed__Accounting_Period__c = Test_Constants.idPeriod,
      AcctSeed__Payee_Reference__c = 'Unit Test',
      AcctSeed__Date__c = Date.today(),
      AcctSeed__Due_Date__c = Date.today().addMonths(1),
      AcctSeed__Vendor__c = supplier.Id
    );
    gcAccountPayable.disableTrigger = true;
    insert payable;

    AcctSeed__Account_Payable_Line__c payableLine = new AcctSeed__Account_Payable_Line__c(
      AcctSeed__Account_Payable__c = payable.Id,
      AcctSeed__Project__c = erpIdsMap.get('erpId'),
      AcctSeed__Project_Task__c = erpIdsMap.get('taskId'),
      AcctSeed__Amount__c = BOAT_PRICE,
      AcctSeed__Product__c = boat.Id,
      AcctSeed__Expense_GL_Account__c = Test_Constants.idExpenseGLAccount,
      AcctSeedERP__Purchase_Order_Line__c = polId
    );
    gcAccountPayableLine.disableTrigger = true;
    insert payableLine;
  }

  private static AcctSeed__Project__c createAndLinkRetailERP() {
    GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.buildSerial(boat.Id, lot.Id, 'TEST0001');
    insert serial;

    AcctSeedERP__Warehouse__c wh = [
      SELECT Id, Name
      FROM AcctSeedERP__Warehouse__c
      WHERE Id = :Test_Constants.idWarehouse
    ];

    Account customer = Factory_Account.insertCustomerAccounts(1)[0];
    gcProject.disableTrigger = true;
    AcctSeed__Project__c retailERP = Factory_ERPOrder.insertRetailBoatSale(
      customer,
      wh,
      DateTime.now().addMonths(1),
      serial
    );
    return retailERP;
  }

  private static void createMovement(Id polId) {
    createMovement(polId, boat.Id, 1);
  }

  private static void createMovement(Id polId, Id productId, Decimal quantity) {
    AcctSeedERP__Location__c asLocation = [
      SELECT Id
      FROM AcctSeedERP__Location__c
      WHERE AcctSeedERP__Warehouse__c = :Test_Constants.idWarehouse
      LIMIT 1
    ];

    AcctSeedERP__Inventory_Balance__c balance = Factory_InventoryBalance.createBalance(asLocation.Id, productId);

    AcctSeedERP__Purchase_Order_Inventory_Movement__c movement = Factory_PurchaseOrderInventoryMovement.createMovement(
      polId,
      quantity,
      erpIdsMap.get('erpId'),
      erpIdsMap.get('taskId'),
      balance.Id,
      BOAT_PRICE
    );
  }

  private static User createStandardUser() {
    User u = Factory_User.createUser('Fname', 'Lname', 'Legend Standard User - New');
    return u;
  }

  private static AcctSeedERP__Purchase_Order_Line__c refreshRecord(Id recordId) {
    return [
      SELECT
        Id,
        GMBLASERP__Price_Override__c,
        AcctSeedERP__Quantity__c,
        AcctSeedERP__Unit_Price__c,
        GMBLASERP__Lot__c,
        AcctSeedERP__Project_Task__c,
        AcctSeedERP__Project__c,
        AcctSeedERP__Product__c,
        AcctSeedERP__Quantity_Received__c,
        AcctSeedERP__Quantity_Unreceived__c,
        Reserved__c
      FROM AcctSeedERP__Purchase_Order_Line__c
      WHERE Id = :recordId
    ];
  }

  @IsTest
  static void beforeUpdate_TA_setReserved() {
    GMBLASERP.gcPurchaseOrderLine.disableTrigger = true;
    po = [SELECT Id, GMBLASERP__Pricebook__c FROM AcctSeedERP__Purchase_Order__c LIMIT 1];
    Product2 part = Factory_Product.createNonSerializedProduct('Part', 'Electronics');
    Factory_PricebookEntry.createAllDefaultEntriesEntries(part.Id, 100);
    AcctSeedERP__Purchase_Order_Line__c pol = Factory_PurchaseOrder.buildLineItem(po.Id, part.Id, 100);
    pol.Reserved__c = 50;
    TriggerBase.bypass('AcctSeedERP__Purchase_Order_Line__c');
    insert pol;
    TriggerBase.clearBypass('AcctSeedERP__Purchase_Order_Line__c');

    AcctSeedERP__Location__c asLocation = [
      SELECT Id
      FROM AcctSeedERP__Location__c
      WHERE AcctSeedERP__Warehouse__c = :Test_Constants.idWarehouse
      LIMIT 1
    ];

    AcctSeedERP__Inventory_Balance__c balance = Factory_InventoryBalance.createBalance(asLocation.Id, part.Id);

    Test.startTest();
    AcctSeedERP__Purchase_Order_Inventory_Movement__c movement = Factory_PurchaseOrderInventoryMovement.createMovement(
      pol.Id,
      75,
      null,
      null,
      balance.Id,
      70
    );
    Test.stopTest();

    pol = refreshRecord(pol.Id);

    System.assertEquals(75, pol.AcctSeedERP__Quantity_Received__c);
    System.assertEquals(25, pol.AcctSeedERP__Quantity_Unreceived__c);
    System.assertEquals(pol.AcctSeedERP__Quantity_Unreceived__c, pol.Reserved__c);
  }

  @IsTest
  static void afterInsert_TA_propagateDeliveryDateToRetailERP() {
    AcctSeedERP__Purchase_Order_Line__c pol = buildPOL(true, true, false, null);

    AcctSeed__Project__c retailERP = createAndLinkRetailERP();
    erp.Retail_ERP__c = retailERP.Id;
    update erp;

    Test.startTest();
    insert pol;
    Test.stopTest();

    retailERP = [SELECT Id, Arrival_Date__c FROM AcctSeed__Project__c WHERE Id = :retailERP.Id];

    System.assertEquals(eta, retailERP.Arrival_Date__c);
  }

  @IsTest
  static void afterUpdate_TA_propagateDeliveryDateToRetailERP() {
    AcctSeedERP__Purchase_Order_Line__c pol = buildPOL(true, true, false, null);
    AcctSeed__Project__c retailERP = createAndLinkRetailERP();
    retailERP.Arrival_Date__c = eta;
    erp.Retail_ERP__c = retailERP.Id;
    List<AcctSeed__Project__c> erps = new List<AcctSeed__Project__c>{ erp, retailERP };
    update erps;

    TriggerBase.bypass('AcctSeedERP__Purchase_Order_Line__c');
    insert pol;
    TriggerBase.clearBypass('AcctSeedERP__Purchase_Order_Line__c');

    Date eta2 = eta.addDays(14);
    pol.deliverDate__c = eta2;

    Test.startTest();
    update pol;
    Test.stopTest();

    retailERP = [SELECT Id, Arrival_Date__c FROM AcctSeed__Project__c WHERE Id = :retailERP.Id];

    System.assertEquals(eta2, retailERP.Arrival_Date__c);
  }

  @IsTest
  static void afterUpdate_TA_updateProductLotReservation() {
    AcctSeedERP__Purchase_Order_Line__c pol = insertPOL_forUpdateTesting(true, true, false, BOAT_PRICE);
    ProductLotReservation__c plr = new ProductLotReservation__c(
      Lot__c = lot.Id,
      Product__c = boat.Id,
      Reserved_for_Display__c = 0,
      Reserved_For_Retail_Sale__c = 3
    );
    insert plr;

    Test.startTest();
    pol.Reserved__c = 1;
    Test.stopTest();

    update pol;

    plr = [SELECT Id, Reserved_For_Retail_Sale__c FROM ProductLotReservation__c WHERE Id = :plr.Id];

    System.assertEquals(2, plr.Reserved_For_Retail_Sale__c);
  }

  /* gcPurchaseOrderLine Tests */

  @IsTest
  static void insertTest_pricebookPriceAndWithoutLot() {
    init();
    Map<String, Id> erpIdsMap = buildErps();
    Date eta = Date.today().addMonths(2);
    AcctSeedERP__Purchase_Order_Line__c pol = Factory_PurchaseOrder.buildLineItem(po.Id, boat.Id, 1);
    pol.AcctSeedERP__Project__c = erpIdsMap.get('erpId');
    pol.AcctSeedERP__Project_Task__c = erpIdsMap.get('taskId');
    pol.deliverDate__c = eta;

    Test.startTest();
    insert pol;
    Test.stopTest();

    pol = refreshRecord(pol.Id);

    erp = [SELECT Id, Arrival_Date__c FROM AcctSeed__Project__c WHERE Id = :erpIdsMap.get('erpId')];

    System.assertEquals(BOAT_PRICE, pol.AcctSeedERP__Unit_Price__c);
    System.assertEquals(false, pol.GMBLASERP__Price_Override__c);
    System.assert(pol.GMBLASERP__Lot__c != null);
    System.assertEquals(eta, erp.Arrival_Date__c);
  }

  @IsTest
  static void insertTest_pricebookPriceAndWithLot() {
    init();
    Map<String, Id> erpIdsMap = buildErps();
    GMBLASERP__Lot__c lot = new GMBLASERP__Lot__c(
      Name = Legend_Settings__c.getOrgDefaults().Purchase_Order_Line_Lot__c,
      GMBLASERP__Product__c = boat.Id
    );
    insert lot;
    Date eta = Date.today().addMonths(2);
    AcctSeedERP__Purchase_Order_Line__c pol = Factory_PurchaseOrder.buildLineItem(po.Id, boat.Id, 1);
    pol.AcctSeedERP__Project__c = erpIdsMap.get('erpId');
    pol.AcctSeedERP__Project_Task__c = erpIdsMap.get('taskId');
    pol.deliverDate__c = eta;

    Test.startTest();
    insert pol;
    Test.stopTest();

    pol = refreshRecord(pol.Id);

    erp = [SELECT Id, Arrival_Date__c FROM AcctSeed__Project__c WHERE Id = :erpIdsMap.get('erpId')];

    System.assertEquals(BOAT_PRICE, pol.AcctSeedERP__Unit_Price__c);
    System.assertEquals(false, pol.GMBLASERP__Price_Override__c);
    System.assert(pol.GMBLASERP__Lot__c != null);
    System.assertEquals(lot.Id, pol.GMBLASERP__Lot__c);
    System.assertEquals(eta, erp.Arrival_Date__c);
  }

  @IsTest
  static void insertTest_overridePrice() {
    init();
    Map<String, Id> erpIdsMap = buildErps();
    Date eta = Date.today().addMonths(2);
    AcctSeedERP__Purchase_Order_Line__c pol = Factory_PurchaseOrder.buildLineItem(po.Id, boat.Id, 1);
    pol.AcctSeedERP__Project__c = erpIdsMap.get('erpId');
    pol.AcctSeedERP__Project_Task__c = erpIdsMap.get('taskId');
    pol.deliverDate__c = eta;
    pol.GMBLASERP__Price_Override__c = true;
    pol.AcctSeedERP__Unit_Price__c = 50000;

    Test.startTest();
    insert pol;
    Test.stopTest();

    pol = refreshRecord(pol.Id);

    erp = [SELECT Id, Arrival_Date__c FROM AcctSeed__Project__c WHERE Id = :erpIdsMap.get('erpId')];

    System.assertEquals(50000, pol.AcctSeedERP__Unit_Price__c);
    System.assertEquals(true, pol.GMBLASERP__Price_Override__c);
    System.assertEquals(eta, erp.Arrival_Date__c);
  }

  @IsTest
  static void insertTest_setErpAndTaskFromPO() {
    init();
    Map<String, Id> erpIdsMap = buildErps();
    po.GMBLASERP__Project__c = erpIdsMap.get('erpId');
    po.GMBLASERP__Project_Task__c = erpIdsMap.get('taskId');
    Boolean origPOtriggerState = gcPurchaseOrder.disableTrigger;
    gcPurchaseOrder.disableTrigger = true;
    update po;
    gcPurchaseOrder.disableTrigger = origPOtriggerState;

    AcctSeedERP__Purchase_Order_Line__c pol = Factory_PurchaseOrder.buildLineItem(po.Id, boat.Id, 1);

    Test.startTest();
    insert pol;
    Test.stopTest();

    pol = refreshRecord(pol.Id);

    System.assertEquals(erpIdsMap.get('erpId'), pol.AcctSeedERP__Project__c);
    System.assertEquals(erpIdsMap.get('taskId'), pol.AcctSeedERP__Project_Task__c);
  }

  @IsTest
  static void insert_withSerialandNoProduct() {
    init();
    buildErps();
    Date eta = Date.today().addMonths(2);
    AcctSeedERP__Purchase_Order_Line__c pol = Factory_PurchaseOrder.buildLineItem(po.Id, null, 1);
    GMBLASERP__Lot__c lot = new GMBLASERP__Lot__c(
      Name = Legend_Settings__c.getOrgDefaults().Purchase_Order_Line_Lot__c,
      GMBLASERP__Product__c = boat.Id
    );
    insert lot;
    GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.buildSerial(boat.Id, lot.Id, 'TEST0001');
    insert serial;

    pol.GMBLASERP__Serial_Number__c = serial.Id;

    Test.startTest();
    insert pol;
    Test.stopTest();

    pol = refreshRecord(pol.Id);

    System.assertEquals(boat.Id, pol.AcctSeedERP__Product__c);
    System.assertEquals(lot.Id, pol.GMBLASERP__Lot__c);
  }

  @IsTest
  static void insert_singleBoatValidation() {
    init();
    buildErps();

    AcctSeedERP__Purchase_Order_Line__c pol = Factory_PurchaseOrder.buildLineItem(po.Id, boat.Id, 2);

    Exception ex;

    try {
      Test.startTest();
      insert pol;
      Test.stopTest();
    } catch (Exception e) {
      ex = e;
    }

    System.assert(ex != null);
    System.assert(
      ex.getMessage().contains('The Purchase Order Line Must not have multiple Ordered Quantity for a Boat product.')
    );
  }

  @IsTest
  static void insert_PO_LockedValidation() {
    init();
    po.Locked__c = true;
    po.Stage__c = 'Approved';
    Boolean origPOtriggerState = gcPurchaseOrder.disableTrigger;
    gcPurchaseOrder.disableTrigger = true;
    update po;
    gcPurchaseOrder.disableTrigger = origPOtriggerState;

    AcctSeedERP__Purchase_Order_Line__c pol = Factory_PurchaseOrder.buildLineItem(po.Id, boat.Id, 1);

    Exception ex;

    User standardUser = createStandardUser();
    System.runAs(standardUser) {
      Test.startTest();
      try {
        insert pol;
      } catch (Exception e) {
        ex = e;
      }
      Test.stopTest();
    }

    System.assert(ex != null);
    System.assert(ex.getMessage().contains('Cannot add new PO Line on a locked Purchase Order.'));
  }

  @IsTest
  static void insert_ERPOrder_Mismatch_Validation() {
    init();
    Map<String, Id> erpIdsMap = buildErps();
    po.GMBLASERP__Project__c = erpIdsMap.get('erpId');
    Boolean origPOtriggerState = gcPurchaseOrder.disableTrigger;
    gcPurchaseOrder.disableTrigger = true;
    update po;
    gcPurchaseOrder.disableTrigger = origPOtriggerState;

    GMBLASERP__Lot__c lot = new GMBLASERP__Lot__c(
      Name = Legend_Settings__c.getOrgDefaults().Purchase_Order_Line_Lot__c,
      GMBLASERP__Product__c = boat.Id
    );
    insert lot;
    Map<String, Id> erpIdsMap2 = buildErps();

    AcctSeedERP__Purchase_Order_Line__c pol = Factory_PurchaseOrder.buildLineItem(po.Id, boat.Id, 1);

    pol.AcctSeedERP__Project__c = erpIdsMap2.get('erpId');
    pol.AcctSeedERP__Project_Task__c = erpIdsMap2.get('taskId');
    pol.GMBLASERP__Lot__c = lot.Id;

    Exception ex;

    Test.startTest();
    try {
      insert pol;
    } catch (Exception e) {
      ex = e;
    }
    Test.stopTest();

    System.assert(ex != null);
    System.assert(
      ex.getMessage().contains('The Purchase Order specifies a different Project than this Purchase Order Line.')
    );
  }

  @IsTest
  static void update_PO_LockedValidation() {
    AcctSeedERP__Purchase_Order_Line__c pol = insertPOL_forUpdateTesting(true, true, false, null);
    po.Locked__c = true;
    po.Stage__c = 'Approved';
    Boolean origPOtriggerState = gcPurchaseOrder.disableTrigger;
    gcPurchaseOrder.disableTrigger = true;
    update po;
    gcPurchaseOrder.disableTrigger = origPOtriggerState;

    pol.AcctSeedERP__Project__c = null;

    Exception ex;

    User standardUser = createStandardUser();
    System.runAs(standardUser) {
      Test.startTest();
      try {
        update pol;
      } catch (Exception e) {
        ex = e;
      }
      Test.stopTest();
    }
    System.assert(ex != null);
    System.assert(
      ex.getMessage()
        .contains('The Purchase Order is locked and cannot modify PO Line fields. Please unlock the PO to proceed.')
    );
  }

  @IsTest
  static void update_AddErpAndTask_AndPriceOverride() {
    AcctSeedERP__Purchase_Order_Line__c pol = insertPOL_forUpdateTesting(false, true, false, BOAT_PRICE);

    pol = refreshRecord(pol.Id);

    System.assertEquals(BOAT_PRICE, pol.AcctSeedERP__Unit_Price__c);
    System.assertEquals(false, pol.GMBLASERP__Price_Override__c);
    System.assert(pol.AcctSeedERP__Project__c == null);
    System.assert(pol.AcctSeedERP__Project_Task__c == null);

    pol.AcctSeedERP__Project__c = erpIdsMap.get('erpId');
    pol.AcctSeedERP__Project_Task__c = erpIdsMap.get('taskId');
    pol.GMBLASERP__Price_Override__c = true;
    pol.AcctSeedERP__Unit_Price__c = 50000;
    pol.deliverDate__c = eta;

    Test.startTest();
    update pol;
    Test.stopTest();

    pol = refreshRecord(pol.Id);

    erp = [SELECT Id, Arrival_Date__c FROM AcctSeed__Project__c WHERE Id = :erpIdsMap.get('erpId')];

    System.assertEquals(50000, pol.AcctSeedERP__Unit_Price__c);
    System.assertEquals(true, pol.GMBLASERP__Price_Override__c);
    System.assertEquals(eta, erp.Arrival_Date__c);
    System.assert(pol.AcctSeedERP__Project__c != null);
    System.assert(pol.AcctSeedERP__Project_Task__c != null);
  }

  @IsTest
  static void update_priceOverrideChangeToFalse() {
    AcctSeedERP__Purchase_Order_Line__c pol = insertPOL_forUpdateTesting(true, true, true, 50000);

    pol = refreshRecord(pol.Id);

    System.assertEquals(50000, pol.AcctSeedERP__Unit_Price__c);
    System.assertEquals(true, pol.GMBLASERP__Price_Override__c);

    pol.GMBLASERP__Price_Override__c = false;

    Test.startTest();
    update pol;
    Test.stopTest();

    pol = refreshRecord(pol.Id);

    System.assertEquals(false, pol.GMBLASERP__Price_Override__c);
    System.assertEquals(BOAT_PRICE, pol.AcctSeedERP__Unit_Price__c);
  }

  @IsTest
  static void update_unitPriceChange() {
    AcctSeedERP__Purchase_Order_Line__c pol = insertPOL_forUpdateTesting(true, true, true, 50000);

    pol = refreshRecord(pol.Id);

    System.assertEquals(50000, pol.AcctSeedERP__Unit_Price__c);
    System.assertEquals(true, pol.GMBLASERP__Price_Override__c);

    pol.AcctSeedERP__Unit_Price__c = 25000;

    Test.startTest();
    update pol;
    Test.stopTest();

    pol = refreshRecord(pol.Id);

    System.assertEquals(true, pol.GMBLASERP__Price_Override__c);
    System.assertEquals(25000, pol.AcctSeedERP__Unit_Price__c);
  }

  @IsTest
  static void update_unitPriceChangeToNull() {
    AcctSeedERP__Purchase_Order_Line__c pol = insertPOL_forUpdateTesting(true, true, true, 50000);

    pol = refreshRecord(pol.Id);

    System.assertEquals(50000, pol.AcctSeedERP__Unit_Price__c);
    System.assertEquals(true, pol.GMBLASERP__Price_Override__c);

    pol.AcctSeedERP__Unit_Price__c = null;

    Test.startTest();
    update pol;
    Test.stopTest();

    pol = refreshRecord(pol.Id);

    System.assertEquals(true, pol.GMBLASERP__Price_Override__c);
    System.assertEquals(0, pol.AcctSeedERP__Unit_Price__c);
  }

  @IsTest
  static void delete_hasPayable_Validation() {
    AcctSeedERP__Purchase_Order_Line__c pol = insertPOL_forUpdateTesting(false, true, false, null);

    createPayable(pol.Id);

    Exception ex;

    Test.startTest();
    try {
      delete pol;
    } catch (Exception e) {
      ex = e;
    }
    Test.stopTest();

    System.assert(ex != null);
    System.assert(
      ex.getMessage()
        .contains('The Purchase Order Line cannot be deleted because it has an underlying Account Payable Line:')
    );
  }

  @IsTest
  static void update_hasPayable_unitPriceChange_Validation() {
    AcctSeedERP__Purchase_Order_Line__c pol = insertPOL_forUpdateTesting(false, true, false, null);

    createPayable(pol.Id);

    pol.GMBLASERP__Price_Override__c = true;
    pol.AcctSeedERP__Unit_Price__c = 50000;

    Exception ex;

    Test.startTest();
    try {
      update pol;
    } catch (Exception e) {
      ex = e;
    }
    Test.stopTest();

    System.assert(ex != null);
    System.assert(
      ex.getMessage()
        .contains(
          'The Unit Price of the Purchase Order may not be changed, because the Purchase Order has underlying AP Lines.'
        )
    );
  }

  @IsTest
  static void delete_hasMovement_Validation() {
    AcctSeedERP__Purchase_Order_Line__c pol = insertPOL_forUpdateTesting(false, true, false, null);

    createMovement(pol.Id);

    Exception ex;

    Test.startTest();
    try {
      delete pol;
    } catch (Exception e) {
      ex = e;
    }
    Test.stopTest();

    System.assert(ex != null);
  }

  private static Exception updatePolFail(AcctSeedERP__Purchase_Order_Line__c pol) {
    Exception ex;
    try {
      update pol;
    } catch (Exception e) {
      ex = e;
    }
    return ex;
  }

  @IsTest
  static void update_hasMovement_serialChange_Validation() {
    AcctSeedERP__Purchase_Order_Line__c pol = insertPOL_forUpdateTesting(false, true, false, BOAT_PRICE);

    List<GMBLASERP__Serial_Number__c> serials = new List<GMBLASERP__Serial_Number__c>{
      Factory_SerialNumber.buildSerial(boat.Id, lot.Id, 'TEST0001'),
      Factory_SerialNumber.buildSerial(boat.Id, lot.Id, 'TEST0002')
    };
    insert serials;

    pol.GMBLASERP__Serial_Number__c = serials[0].Id;
    TriggerBase.bypass('AcctSeedERP__Purchase_Order_Line__c');
    update pol;
    TriggerBase.clearBypass('AcctSeedERP__Purchase_Order_Line__c');

    createMovement(pol.Id);

    pol.GMBLASERP__Serial_Number__c = serials[1].Id;
    Test.startTest();
    Exception ex = updatePolFail(pol);
    Test.stopTest();

    System.assert(ex != null);
    System.assert(
      ex.getMessage()
        .contains(
          'The Serial Number of the Purchase Order may not be changed, because the Purchase Order has underlying Inventory Movements.'
        )
    );
  }

  @IsTest
  static void update_hasMovement_lotChange_Validation() {
    AcctSeedERP__Purchase_Order_Line__c pol = insertPOL_forUpdateTesting(false, true, false, BOAT_PRICE);

    GMBLASERP__Lot__c lot2 = new GMBLASERP__Lot__c(Name = '2000', GMBLASERP__Product__c = boat.Id);
    insert lot2;

    createMovement(pol.Id);

    pol.GMBLASERP__Lot__c = lot2.Id;
    Test.startTest();
    Exception ex = updatePolFail(pol);
    Test.stopTest();

    System.assert(ex != null);
    System.assert(
      ex.getMessage()
        .contains(
          'The Lot of the Purchase Order may not be changed, because the Purchase Order has underlying Inventory Movements.'
        )
    );
  }

  @IsTest
  static void update_hasMovement_productChange_Validation() {
    List<Product2> parts = Factory_Product.createNonSerializedProducts('Part', 'Electronics', 2);
    init();
    erpIdsMap = buildErps();

    AcctSeedERP__Purchase_Order_Line__c pol = Factory_PurchaseOrder.buildLineItem(po.Id, parts[0].Id, 1);
    pol.AcctSeedERP__Unit_Price__c = 100;

    TriggerBase.bypass('AcctSeedERP__Purchase_Order_Line__c');
    insert pol;
    TriggerBase.clearBypass('AcctSeedERP__Purchase_Order_Line__c');

    createMovement(pol.Id, parts[0].Id, 1);

    pol.AcctSeedERP__Product__c = parts[1].Id;
    Test.startTest();
    Exception ex = updatePolFail(pol);
    Test.stopTest();

    System.assert(ex != null);
  }
}
