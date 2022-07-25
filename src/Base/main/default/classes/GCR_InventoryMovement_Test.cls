/**
 * Created by Legend on 29/7/21.
 */

@isTest
public class GCR_InventoryMovement_Test {
  static Account cust;
  static GMBLASERP__Serial_Number__c ser;
  static AcctSeedERP__Warehouse__c wh;
  static AcctSeedERP__Location__c loc;
  static AcctSeed__Project__c erp;
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    AcctSeedERP__Warehouse__c whMon = [
      SELECT Id, Name, GL_Account_Variable_3__c
      FROM AcctSeedERP__Warehouse__c
      WHERE Name = 'Montreal'
    ];
    Account dealer = AccountFactory.buildDealerAccount('Test Dealer UnitTester');
    dealer.Warehouse__c = whMon.Id;
    insert dealer;
    Factory_SerialNumber.insertFullSerial('Boat', 'Pontoon', '0987654321');
  }

  static void init() {
    cust = [SELECT Id, Name FROM Account WHERE Name = 'Test Dealer UnitTester'];
    ser = [
      SELECT Id, Name, GMBLASERP__Product__c, GMBLASERP__Product__r.AcctSeed__Inventory_GL_Account__c, GMBLASERP__Lot__c
      FROM GMBLASERP__Serial_Number__c
      WHERE Name = '0987654321'
      LIMIT 1
    ];
    wh = [SELECT Id, Name, GL_Account_Variable_3__c FROM AcctSeedERP__Warehouse__c WHERE Name = 'Wholesale'];
    loc = [SELECT Id FROM AcctSeedERP__Location__c WHERE AcctSeedERP__Warehouse__c = :wh.Id LIMIT 1];
    erp = Factory_ERPOrder.buildERP(cust, ser.Id, gcConstants.idRtProjectPartnerBoatSale);
    erp.GMBLASERP__Warehouse__c = wh.Id;
    GMBLASERP.gcProject.disableTrigger = true;
    gcProject.disableTrigger = true;
    insert erp;
    gcProject.disableTrigger = false;
    GMBLASERP.gcProject.disableTrigger = false;
    AcctSeed__Project_Task__c task = Factory_ERPOrder.buildProjectTask(erp.Id, 'Dealer Order');
    task.Product__c = ser.GMBLASERP__Product__c;
    insert task;
    AcctSeedERP__Material__c mat = Factory_ERPOrder.buildMaterial(erp.Id, task.Id, ser.GMBLASERP__Product__c);
    mat.GMBLASERP__Serial_Number__c = ser.Id;
    mat.GMBLASERP__Lot__c = ser.GMBLASERP__Lot__c;
    mat.GMBLASERP__Unit_Price__c = 25000;
    insert mat;
  }

  static void initMFG() {
    cust = [SELECT Id, Name FROM Account WHERE Name = 'Test Dealer UnitTester'];
    ser = [
      SELECT Id, Name, GMBLASERP__Product__c, GMBLASERP__Product__r.AcctSeed__Inventory_GL_Account__c, GMBLASERP__Lot__c
      FROM GMBLASERP__Serial_Number__c
      WHERE Name = '0987654321'
      LIMIT 1
    ];
    wh = [SELECT Id, Name, GL_Account_Variable_3__c FROM AcctSeedERP__Warehouse__c WHERE Name = 'Wholesale'];
    loc = [SELECT Id FROM AcctSeedERP__Location__c WHERE AcctSeedERP__Warehouse__c = :wh.Id LIMIT 1];
    erp = Factory_ERPOrder.buildERP(cust, ser.Id, gcConstants.idRtProjectManufacturing);
    erp.AcctSeedERP__Manufactured_Product__c = ser.GMBLASERP__Product__c;
    erp.GMBLASERP__Warehouse__c = wh.Id;
    GMBLASERP.gcProject.disableTrigger = true;
    gcProject.disableTrigger = true;
    insert erp;
    gcProject.disableTrigger = false;
    GMBLASERP.gcProject.disableTrigger = false;
    AcctSeed__Project_Task__c task = Factory_ERPOrder.buildProjectTask(erp.Id, 'Pre-Rig');
    task.Product__c = ser.GMBLASERP__Product__c;
    insert task;
    AcctSeedERP__Material__c mat = Factory_ERPOrder.buildMaterial(erp.Id, task.Id, ser.GMBLASERP__Product__c);
    mat.GMBLASERP__Serial_Number__c = ser.Id;
    mat.GMBLASERP__Lot__c = ser.GMBLASERP__Lot__c;
    insert mat;
  }

  @IsTest
  static void testManufacturingOrder() {
    initMFG();
    AcctSeed__Accounting_Settings__c accSetting = [
      SELECT AcctSeed__Default_Ledger__c
      FROM AcctSeed__Accounting_Settings__c
      ORDER BY CreatedDate
    ][0];
    System.debug('accSetting');
    System.debug(accSetting);
    AcctSeedERP__Warehouse__c wh = [
      SELECT Id, Name, GL_Account_Variable_3__c
      FROM AcctSeedERP__Warehouse__c
      WHERE Name = 'Wholesale'
    ];
    AcctSeedERP__Location__c loc = [
      SELECT Id
      FROM AcctSeedERP__Location__c
      WHERE AcctSeedERP__Warehouse__c = :wh.Id
      LIMIT 1
    ];
    /// Inbound the inventory for the serial
    Id idBalance = GCR_InventoryBalance.findOrCreateBalance(ser.GMBLASERP__Product__c, wh.Id, loc.Id);
    /// Bring the inventory in
    AcctSeedERP__Inbound_Inventory_Movement__c inmove = new AcctSeedERP__Inbound_Inventory_Movement__c(
      AcctSeedERP__Unit_Cost__c = 9000,
      AcctSeedERP__Type__c = 'Accounting',
      AcctSeedERP__Quantity__c = 1,
      AcctSeedERP__Credit_GL_Account__c = ser.GMBLASERP__Product__r.AcctSeed__Inventory_GL_Account__c,
      AcctSeedERP__Inventory_Balance__c = idBalance,
      AcctSeedERP__Ledger__c = accSetting.AcctSeed__Default_Ledger__c,
      GMBLASERP__Warehouse__c = wh.Id,
      AcctSeedERP__Movement_Date__c = Date.today(),
      GMBLASERP__Lot__c = ser.GMBLASERP__Lot__c,
      GMBLASERP__Serial_Number__c = ser.Id
    );
    Test.startTest();
    insert inmove;
    /// Inv to WIP to COGS
    String currentDate = Datetime.now().format('dd/MM/yyyy');
    gcProject_AccountingActions.createWipRA(erp.Id, wh.Id, currentDate);
    gcProject_AccountingActions.takeExpenseRA(erp.Id, currentDate);
    gcProject_AccountingActions.buildFinishedGoodsRA(erp.Id, currentDate);
    Test.stopTest();
  }

  @IsTest
  static void testOutboundWithCost() {
    ser = [
      SELECT Id, Name, GMBLASERP__Product__c, GMBLASERP__Product__r.AcctSeed__Inventory_GL_Account__c, GMBLASERP__Lot__c
      FROM GMBLASERP__Serial_Number__c
      WHERE Name = '0987654321'
      LIMIT 1
    ];
    AcctSeed__Accounting_Settings__c accSetting = [
      SELECT AcctSeed__Default_Ledger__c
      FROM AcctSeed__Accounting_Settings__c
      ORDER BY CreatedDate
    ][0];
    System.debug('accSetting');
    System.debug(accSetting);
    AcctSeedERP__Warehouse__c wh = [
      SELECT Id, Name, GL_Account_Variable_3__c
      FROM AcctSeedERP__Warehouse__c
      WHERE Name = 'Wholesale'
    ];
    AcctSeedERP__Location__c loc = [
      SELECT Id
      FROM AcctSeedERP__Location__c
      WHERE AcctSeedERP__Warehouse__c = :wh.Id
      LIMIT 1
    ];
    /// Inbound the inventory for the serial
    Id idBalance = GCR_InventoryBalance.findOrCreateBalance(ser.GMBLASERP__Product__c, wh.Id, loc.Id);
    /// Bring the inventory in
    AcctSeedERP__Inbound_Inventory_Movement__c inmove = new AcctSeedERP__Inbound_Inventory_Movement__c(
      AcctSeedERP__Unit_Cost__c = 9000,
      AcctSeedERP__Type__c = 'Accounting',
      AcctSeedERP__Quantity__c = 1,
      AcctSeedERP__Credit_GL_Account__c = ser.GMBLASERP__Product__r.AcctSeed__Inventory_GL_Account__c,
      AcctSeedERP__Inventory_Balance__c = idBalance,
      AcctSeedERP__Ledger__c = accSetting.AcctSeed__Default_Ledger__c,
      GMBLASERP__Warehouse__c = wh.Id,
      AcctSeedERP__Movement_Date__c = Date.today(),
      GMBLASERP__Lot__c = ser.GMBLASERP__Lot__c,
      GMBLASERP__Serial_Number__c = ser.Id
    );
    Test.startTest();
    insert inmove;
    /// Now Making an outbound
    AcctSeedERP__Outbound_Inventory_Movement__c outmove = new AcctSeedERP__Outbound_Inventory_Movement__c(
      AcctSeedERP__Unit_Cost__c = 9000,
      AcctSeedERP__Type__c = 'Accounting',
      AcctSeedERP__Quantity__c = 1,
      AcctSeedERP__Debit_GL_Account__c = ser.GMBLASERP__Product__r.AcctSeed__Inventory_GL_Account__c,
      AcctSeedERP__Inventory_Balance__c = idBalance,
      AcctSeedERP__Ledger__c = accSetting.AcctSeed__Default_Ledger__c,
      GMBLASERP__Warehouse__c = wh.Id,
      AcctSeedERP__Movement_Date__c = Date.today(),
      GMBLASERP__Lot__c = ser.GMBLASERP__Lot__c,
      GMBLASERP__Serial_Number__c = ser.Id
    );
    insert outmove;
    Test.stopTest();
  }

  @IsTest
  static void testPartnerBoatSaleJE() {
    init();
    Account vendor = Factory_Account.insertSupplierAccounts(1)[0];
    AcctSeed__Accounting_Settings__c accSetting = [
      SELECT AcctSeed__Default_Ledger__c
      FROM AcctSeed__Accounting_Settings__c
      ORDER BY CreatedDate
    ][0];
    System.debug('accSetting');
    System.debug(accSetting);
    AcctSeedERP__Purchase_Order__c po = Factory_PurchaseOrder.createMinimalPO(vendor.Id, null);

    AcctSeedERP__Purchase_Order_Line__c pol = Factory_PurchaseOrder.buildLineItem(po.Id, ser.GMBLASERP__Product__c, 1);
    pol.AcctSeedERP__Unit_Price__c = 20000;
    pol.GMBLASERP__Serial_Number__c = ser.Id;
    pol.GMBLASERP__Lot__c = ser.GMBLASERP__Lot__c;
    pol.deliverDate__c = Date.today();
    insert pol;
    /// Inbound the inventory for the serial
    Id idBalance = GCR_InventoryBalance.findOrCreateBalance(ser.GMBLASERP__Product__c, wh.Id, loc.Id);
    /// Bring the inventory in
    AcctSeedERP__Purchase_Order_Inventory_Movement__c movement = new AcctSeedERP__Purchase_Order_Inventory_Movement__c(
      AcctSeedERP__Unit_Cost__c = 10000,
      AcctSeedERP__Quantity__c = 1,
      AcctSeedERP__Inventory_Balance__c = idBalance,
      AcctSeedERP__Ledger__c = accSetting.AcctSeed__Default_Ledger__c,
      GMBLASERP__Warehouse__c = wh.Id,
      AcctSeedERP__Movement_Date__c = Date.today(),
      GMBLASERP__Product__c = ser.GMBLASERP__Product__c,
      GMBLASERP__Serial_Number__c = ser.Id,
      GMBLASERP__Lot__c = ser.GMBLASERP__Lot__c,
      AcctSeedERP__Purchase_Order_Line__c = pol.Id,
      GMBLASERP__Purchase_Order__c = po.Id
    );
    Test.startTest();
    insert movement;
    String currentDate = Datetime.now().format('dd/MM/yyyy');
    list<String> listMSG = gcProject_AccountingActions.createWipRA(erp.Id, wh.Id, currentDate);
    list<String> listMSGEx = gcProject_AccountingActions.takeExpenseRA(erp.Id, currentDate);
    Test.stopTest();
    // Should not be any error messages
    System.assertEquals(listMSG.size(), 0);
    System.assertEquals(listMSGEx.size(), 0);
    // There should be a JOB Cost JE for the ERP
    AcctSeed__Journal_Entry__c je = [SELECT Id, Name, Project__c FROM AcctSeed__Journal_Entry__c];
    System.assertEquals(je.Project__c, erp.Id);
    //        list<String> listMSGFg = gcProject_AccountingActions.createInboundInboundMovesRA(erp.Id,currentDate);
    //        System.debug('listMSGFg');
    //        System.debug(listMSGFg);
    //        for(AcctSeedERP__Inbound_Inventory_Movement__c mfg : [SELECT Id, AcctSeedERP__Unit_Cost__c, AcctSeedERP__Project__c,GMBLASERP__Serial_Number__c FROM AcctSeedERP__Inbound_Inventory_Movement__c]){
    //            System.debug('paisi FG');
    //            System.debug(mfg);
    //        }
    // We have brought the Inventory by PO
    AcctSeedERP__Purchase_Order_Inventory_Movement__c pom = [
      SELECT Id, AcctSeedERP__Unit_Cost__c, GMBLASERP__Serial_Number__c
      FROM AcctSeedERP__Purchase_Order_Inventory_Movement__c
    ];
    System.assertEquals(pom.AcctSeedERP__Unit_Cost__c, 20000);
    // There Movement Cube should be 2
    GMBLASERP__Inventory_Movement_Cube__c[] cube = [
      SELECT GMBLASERP__Serial_Number__c, GMBLASERP__Quantity__c, GMBLASERP__Inventory_GL_Amount__c
      FROM GMBLASERP__Inventory_Movement_Cube__c
    ];
    System.assertEquals(cube.size(), 2);
    /// There should be a MFG  movement
    AcctSeedERP__Manufacturing_Inventory_Movement__c mfg = [
      SELECT Id, AcctSeedERP__Unit_Cost__c, AcctSeedERP__Material__c, GMBLASERP__Project__c, GMBLASERP__Serial_Number__c
      FROM AcctSeedERP__Manufacturing_Inventory_Movement__c
      WHERE GMBLASERP__Serial_Number__c = :ser.Id
    ];
    System.assertEquals(mfg.GMBLASERP__Project__c, erp.Id);
    System.assertEquals(mfg.AcctSeedERP__Unit_Cost__c, 20000);
  }

  @IsTest
  static void testPartnerBoatSaleInbound() {
    init();
    Account vendor = Factory_Account.insertSupplierAccounts(1)[0];
    AcctSeed__Accounting_Settings__c accSetting = [
      SELECT AcctSeed__Default_Ledger__c
      FROM AcctSeed__Accounting_Settings__c
      ORDER BY CreatedDate
    ][0];
    System.debug('accSetting');
    System.debug(accSetting);
    AcctSeedERP__Purchase_Order__c po = Factory_PurchaseOrder.createMinimalPO(vendor.Id, null);

    AcctSeedERP__Purchase_Order_Line__c pol = Factory_PurchaseOrder.buildLineItem(po.Id, ser.GMBLASERP__Product__c, 1);
    pol.AcctSeedERP__Unit_Price__c = 20000;
    pol.GMBLASERP__Serial_Number__c = ser.Id;
    pol.GMBLASERP__Lot__c = ser.GMBLASERP__Lot__c;
    pol.deliverDate__c = Date.today();
    insert pol;
    /// Inbound the inventory for the serial
    Id idBalance = GCR_InventoryBalance.findOrCreateBalance(ser.GMBLASERP__Product__c, wh.Id, loc.Id);
    /// Bring the inventory in
    AcctSeedERP__Purchase_Order_Inventory_Movement__c movement = new AcctSeedERP__Purchase_Order_Inventory_Movement__c(
      AcctSeedERP__Unit_Cost__c = 10000,
      AcctSeedERP__Quantity__c = 1,
      AcctSeedERP__Inventory_Balance__c = idBalance,
      AcctSeedERP__Ledger__c = accSetting.AcctSeed__Default_Ledger__c,
      GMBLASERP__Warehouse__c = wh.Id,
      AcctSeedERP__Movement_Date__c = Date.today(),
      GMBLASERP__Product__c = ser.GMBLASERP__Product__c,
      GMBLASERP__Serial_Number__c = ser.Id,
      GMBLASERP__Lot__c = ser.GMBLASERP__Lot__c,
      AcctSeedERP__Purchase_Order_Line__c = pol.Id,
      GMBLASERP__Purchase_Order__c = po.Id
    );
    Test.startTest();
    insert movement;
    String currentDate = Datetime.now().format('dd/MM/yyyy');
    gcSerialNumber.disableTrigger = true;
    list<String> listMSG = gcProject_AccountingActions.createWipRA(erp.Id, wh.Id, currentDate);
    list<String> listMSGFg = gcProject_AccountingActions.createInboundInboundMovesRA(erp.Id, currentDate);
    Test.stopTest();
    // Should not be any error messages
    System.assertEquals(listMSG.size(), 0);
    System.assertEquals(listMSGFg.size(), 0);
    AcctSeedERP__Inbound_Inventory_Movement__c inb = [
      SELECT Id, AcctSeedERP__Unit_Cost__c, AcctSeedERP__Project__c, GMBLASERP__Serial_Number__c
      FROM AcctSeedERP__Inbound_Inventory_Movement__c
    ];
    System.assertEquals(inb.AcctSeedERP__Unit_Cost__c, 25000);
  }
}
