@isTest
public class gcTest_Triggers {
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  //Salesforce Standard Objects
  public static Account createAccount() {
    return new Account(
      Name = 'Test Account',
      AcctSeed__Accounting_Active__c = true,
      AcctSeed__Accounting_Type__c = 'Customer and Vendor'
    );
  }

  public static Attachment createAttachment(Id parentId) {
    return new Attachment(ParentId = parentId, Name = 'Test Attachment', Body = Blob.toPdf('hello'));
  }

  public static Product2 createProduct(Id idGL) {
    return new Product2(
      Name = 'Test Product',
      AcctSeed__Expense_GL_Account__c = idGL,
      AcctSeed__Inventory_GL_Account__c = idGL,
      AcctSeed__Inventory_Product__c = true,
      AcctSeed__Inventory_Type__c = 'Purchased',
      AcctSeed__Revenue_GL_Account__c = idGL,
      AcctSeed__Unit_Cost__c = 1
    );
  }

  //AcctSeed Objects (i.e. excludes AcctSeedERP objects)
  public static AcctSeed__Account_Payable__c createAP(Id idAccount) {
    return new AcctSeed__Account_Payable__c(
      AcctSeed__Date__c = date.Today(),
      AcctSeed__Payee_Reference__c = 'test',
      AcctSeed__Vendor__c = idAccount
    );
  }

  public static AcctSeed__Account_Payable_Line__c createAPL(Id idAP, Id idGL, Id idProduct) {
    return new AcctSeed__Account_Payable_Line__c(
      AcctSeed__Account_Payable__c = idAP,
      AcctSeed__Amount__c = 1,
      AcctSeed__Expense_GL_Account__c = idGL,
      AcctSeed__Product__c = idProduct,
      AcctSeed__Quantity__c = 1
    );
  }

  public static AcctSeed__Billing__c createBilling(Id idAccount) {
    AcctSeed__Ledger__c ledger = [SELECT Id FROM AcctSeed__Ledger__c LIMIT 1];
    AcctSeed__Billing_Format__c format = [
      SELECT Id
      FROM AcctSeed__Billing_Format__c
      WHERE Name = 'Billing PDF Format'
      LIMIT 1
    ];
    return new AcctSeed__Billing__c(
      AcctSeed__Date__c = date.Today(),
      AcctSeed__Customer__c = idAccount,
      AcctSeed__Ledger__c = ledger.Id,
      AcctSeed__Billing_Format__c = format.Id
    );
  }

  public static AcctSeed__Billing_Line__c createBillingLine(Id idBilling) {
    return new AcctSeed__Billing_Line__c(
      AcctSeed__Billing__c = idBilling,
      AcctSeed__Hours_Units__c = 1,
      AcctSeed__Rate__c = 1
    );
  }

  public static AcctSeed__Cash_Disbursement_Batch__c createCashDisbursementBatch() {
    return new AcctSeed__Cash_Disbursement_Batch__c(Name = 'Test Batch');
  }

  public static AcctSeed__Cash_Disbursement__c createCashDisbursement(Id idBatch, Id idGL, Id idAccount) {
    return new AcctSeed__Cash_Disbursement__c(
      AcctSeed__Amount__c = 1,
      AcctSeed__Bank_Account__c = idGL,
      AcctSeed__Cash_Disbursement_Batch__c = idBatch,
      AcctSeed__Debit_GL_Account__c = idGL,
      AcctSeed__Disbursement_Date__c = date.Today(),
      AcctSeed__Vendor__c = idAccount
    );
  }

  public static AcctSeed__Cash_Receipt__c createCashReceipt(Id idAccount) {
    return new AcctSeed__Cash_Receipt__c(
      AcctSeed__Amount__c = 1,
      AcctSeed__Account__c = idAccount,
      AcctSeed__Payment_Reference__c = idAccount,
      AcctSeed__Receipt_Date__c = date.Today()
    );
  }

  public static AcctSeed__Journal_Entry__c createJournalEntry() {
    return new AcctSeed__Journal_Entry__c(Name = 'Test JE');
  }

  public static AcctSeed__Journal_Entry_Line__c createJournalEntryLine(Id idJournalEntry, Id idGL) {
    return new AcctSeed__Journal_Entry_Line__c(
      AcctSeed__Journal_Entry__c = idJournalEntry,
      AcctSeed__GL_Account__c = idGL,
      AcctSeed__Debit__c = 1
    );
  }

  public static AcctSeed__Project__c createProject() {
    return new AcctSeed__Project__c(Name = 'Test Project');
  }

  public static AcctSeed__Project_Task__c createProjectTask(Id idProject) {
    return new AcctSeed__Project_Task__c(Name = 'Test Project Task', AcctSeed__Project__c = idProject);
  }

  public static AcctSeed__Scheduled_Revenue_Expense__c createSRE(Id idGL, Id idPeriod) {
    return new AcctSeed__Scheduled_Revenue_Expense__c(
      Name = 'Test SRE',
      AcctSeed__Accounting_Period__c = idPeriod,
      AcctSeed__Amount__c = 1,
      AcctSeed__Credit_GL_Account__c = idGL,
      AcctSeed__Debit_GL_Account__c = idGL
    );
  }

  //AcctSeedERP__Objects
  public static AcctSeedERP__Inbound_Inventory_Movement__c createInboundInventoryMovement(
    Id idInventoryBalance,
    Id idGL
  ) {
    return new AcctSeedERP__Inbound_Inventory_Movement__c(
      AcctSeedERP__Credit_GL_Account__c = idGL,
      AcctSeedERP__Inventory_Balance__c = idInventoryBalance,
      AcctSeedERP__Movement_Date__c = date.Today(),
      AcctSeedERP__Quantity__c = 1,
      AcctSeedERP__Type__c = 'Accounting',
      AcctSeedERP__Unit_Cost__c = 1
    );
  }

  public static AcctSeedERP__Inventory_Balance__c createInventoryBalance(Id idWarehouse, Id idLocation, Id idProduct) {
    return new AcctSeedERP__Inventory_Balance__c(
      AcctSeedERP__Location__c = idLocation,
      AcctSeedERP__Product__c = idProduct,
      AcctSeedERP__Warehouse__c = idWarehouse
    );
  }

  public static AcctSeedERP__Location__c createLocation(Id idWarehouse) {
    return new AcctSeedERP__Location__c(Name = 'test', AcctSeedERP__Warehouse__c = idWarehouse);
  }

  public static AcctSeedERP__Manufacturing_Inventory_Movement__c createManufacturingInventoryMovement(
    Id idInventoryBalance,
    Id idMaterial
  ) {
    return new AcctSeedERP__Manufacturing_Inventory_Movement__c(
      AcctSeedERP__Inventory_Balance__c = idInventoryBalance,
      AcctSeedERP__Material__c = idMaterial,
      AcctSeedERP__Movement_Date__c = date.Today(),
      AcctSeedERP__Quantity__c = 1,
      AcctSeedERP__Unit_Cost__c = 1
    );
  }

  public static AcctSeedERP__Material__c createMaterial(Id idProject, Id idProduct) {
    return new AcctSeedERP__Material__c(
      AcctSeedERP__Product__c = idProduct,
      AcctSeedERP__Project__c = idProject,
      AcctSeedERP__Quantity_Per_Unit__c = 1
    );
  }

  public static AcctSeedERP__Outbound_Inventory_Movement__c createOutboundInventoryMovement(
    Id idInventoryBalance,
    Id idGL
  ) {
    return new AcctSeedERP__Outbound_Inventory_Movement__c(
      AcctSeedERP__Debit_GL_Account__c = idGL,
      AcctSeedERP__Inventory_Balance__c = idInventoryBalance,
      AcctSeedERP__Movement_Date__c = date.Today(),
      AcctSeedERP__Quantity__c = 1,
      AcctSeedERP__Type__c = 'Accounting',
      AcctSeedERP__Unit_Cost__c = 1
    );
  }

  public static AcctSeedERP__Purchase_Order__c createPurchaseOrder() {
    return new AcctSeedERP__Purchase_Order__c(AcctSeedERP__Order_Date__c = date.Today());
  }

  public static AcctSeedERP__Purchase_Order_Line__c createPurchaseOrderLine(Id idPurchaseOrder, Id idProduct) {
    return new AcctSeedERP__Purchase_Order_Line__c(
      AcctSeedERP__Product__c = idProduct,
      AcctSeedERP__Purchase_Order__c = idPurchaseOrder,
      AcctSeedERP__Quantity__c = 1,
      AcctSeedERP__Unit_Price__c = 1
    );
  }

  public static AcctSeedERP__Purchase_Order_Inventory_Movement__c createPurchaseOrderInventoryMovement(
    Id idInventoryBalance,
    Id idPurchaseOrderLine
  ) {
    return new AcctSeedERP__Purchase_Order_Inventory_Movement__c(
      AcctSeedERP__Inventory_Balance__c = idInventoryBalance,
      AcctSeedERP__Movement_Date__c = date.Today(),
      AcctSeedERP__Purchase_Order_Line__c = idPurchaseOrderLine,
      AcctSeedERP__Quantity__c = 1,
      AcctSeedERP__Unit_Cost__c = 1
    );
  }

  public static AcctSeedERP__Sales_Order__c createSalesOrder(Id idAccount) {
    return new AcctSeedERP__Sales_Order__c(AcctSeedERP__Customer__c = idAccount, AcctSeedERP__Status__c = 'Open');
  }

  public static AcctSeedERP__Sales_Order_Line__c createSalesOrderLine(Id idSalesOrder, Id idProduct) {
    return new AcctSeedERP__Sales_Order_Line__c(
      AcctSeedERP__Product__c = idProduct,
      AcctSeedERP__Quantity_Ordered__c = 1,
      AcctSeedERP__Sales_Order__c = idSalesOrder,
      AcctSeedERP__Unit_Price__c = 1
    );
  }

  public static AcctSeedERP__Sales_Order_Inventory_Movement__c createSalesOrderInventoryMovement(
    Id idInventoryBalance,
    Id idSalesOrderLine
  ) {
    return new AcctSeedERP__Sales_Order_Inventory_Movement__c(
      AcctSeedERP__Inventory_Balance__c = idInventoryBalance,
      AcctSeedERP__Movement_Date__c = date.Today(),
      AcctSeedERP__Sales_Order_Line__c = idSalesOrderLine,
      AcctSeedERP__Quantity__c = 1,
      AcctSeedERP__Unit_Cost__c = 1
    );
  }

  public static AcctSeedERP__Warehouse__c createWarehouse() {
    return new AcctSeedERP__Warehouse__c(Name = 'Test Warehouse');
  }

  //GMBLASERP Objects
  public static GMBLASERP__Serial_Number__c createSerial(Id idProduct) {
    return new GMBLASERP__Serial_Number__c(Name = 'Test Item', GMBLASERP__Product__c = idProduct);
  }

  public static GMBLASERP__Lot__c createLot(Id idProduct) {
    return new GMBLASERP__Lot__c(Name = 'Test Lot', GMBLASERP__Product__c = idProduct);
  }

  public static GMBLASERP__Inventory_Transfer__c createInventoryTransfer(Id idWarehouse) {
    return new GMBLASERP__Inventory_Transfer__c(
      GMBLASERP__Outbound_Date__c = date.Today(),
      GMBLASERP__Warehouse_From__c = idWarehouse,
      GMBLASERP__Warehouse_To__c = idWarehouse
    );
  }

  static testMethod void test_Triggers() {
    //retrieve an existing GL
    Id idGL = [SELECT Id FROM AcctSeed__GL_Account__c LIMIT 1][0].Id;

    //retrieve the current period
    //Id idPeriod = [SELECT Id FROM AcctSeed__Accounting_Period__c WHERE AcctSeed__Start_Date__c <= TODAY AND AcctSeed__End_Date__c >= TODAY][0].Id;

    //create an Account
    Account account = createAccount();
    insert account;

    //create a Billing
    AcctSeed__Billing__c b = createBilling(account.Id);
    insert b;
  }
}
/*
		//create a Billing Line
		AcctSeed__Billing_Line__c bl = createBillingLine(b.Id);
		//gcBillingLine.disableTrigger = true;
		bl.AcctSeed__Project__c 	 = project.Id;
		bl.AcctSeed__Project_Task__c = projectTask.Id;
		insert bl;

		//create a Product
		Product2 product = createProduct(idGL);
		//product.Purchase_From__c = account.Id; Prodigy
		gcProduct.disableTrigger = true;
		insert product;

		//create a Lot
		Lot__c lot = createLot(product.Id);
		gcLot.disableTrigger = true;
		insert lot;

		//create an Item
		Item__c item = createItem(product.Id, lot.Id);
		gcItem.disableTrigger = true;
		insert item;

		//create a Warehouse
		AcctSeedERP__Warehouse__c whs = createWarehouse();
		//whs.Warehouse_Number__c = 'test'; Prodigy
		insert whs;

		//create a Location
		AcctSeedERP__Location__c loc = createLocation(whs.Id);
		insert loc;

		//create an Inventory Balance
		AcctSeedERP__Inventory_Balance__c bal = createInventoryBalance(whs.Id,loc.Id,product.Id);
		insert bal;

		//create an Inbound Inventory Movement
		AcctSeedERP__Inbound_Inventory_Movement__c iim = createInboundInventoryMovement(bal.Id, lot.Id, item.Id, idGL);
		gcInboundInventoryMovement.disableTrigger = true;
		insert iim;

		//create a Project
		AcctSeed__Project__c project = createProject();
		insert project;

		//create a Material
		AcctSeedERP__Material__c matl = createMaterial(project.Id,product.Id);
		insert matl;

		//create a Manufacturing Inventory Movement
		AcctSeedERP__Manufacturing_Inventory_Movement__c mim = createManufacturingInventoryMovement(bal.Id, lot.Id, item.Id, matl.Id);
		gcManufacturingInventoryMovement.disableTrigger = true;
		gcMaterial.disableTrigger = true;
		insert mim;

		//create an Outbound Inventory Movement
		AcctSeedERP__Outbound_Inventory_Movement__c oim = createOutboundInventoryMovement(bal.Id, lot.Id, item.Id, idGL);
		gcOutboundInventoryMovement.disableTrigger = true;
		insert oim;

		//create a Purchase Order
		AcctSeedERP__Purchase_Order__c po = createPurchaseOrder();
		gcPurchaseOrder.disableTrigger = true;
		insert po;

		//create a Purchase Order Line
		AcctSeedERP__Purchase_Order_Line__c pol = createPurchaseOrderLine(po.Id, product.Id);
		gcPurchaseOrderLine.disableTrigger = true;
		insert pol;

		//create a Purchase Order Inventory Movement
		AcctSeedERP__Purchase_Order_Inventory_Movement__c poim = createPurchaseOrderInventoryMovement(bal.Id, lot.Id, item.Id, pol.Id);
		gcPurchaseOrderInventoryMovement.disableTrigger = true;
		gcPurchaseOrderLine.disableTrigger = true;
		insert poim;

		//create a Sales Order
		AcctSeedERP__Sales_Order__c so = createSalesOrder(account.Id);
		//so.Warehouse__c = whs.Id; Prodigy
		gcSalesOrder.disableTrigger = true;
		insert so;

		//create a Sales Order Line
		AcctSeedERP__Sales_Order_Line__c sol = createSalesOrderLine(so.Id, product.Id);
		gcSalesOrderLine.disableTrigger = true;
		insert sol;

		//create a Sales Order Inventory Movement
		AcctSeedERP__Sales_Order_Inventory_Movement__c soim = createSalesOrderInventoryMovement(bal.Id, lot.Id, item.Id, sol.Id);
		gcSalesOrderInventoryMovement.disableTrigger = true;
		insert soim;

		//create an AP
		AcctSeed__Account_Payable__c ap = createAP(account.Id);
		gcAccountPayable.disableTrigger = true;
		insert ap;

		//create an AP Line
		AcctSeed__Account_Payable_Line__c apl = createAPL(ap.Id, idGL, product.Id);
		gcAccountPayableLine.disableTrigger = true;
		insert apl;

		//create an Inventory Transfer
		Inventory_Transfer__c xfr = createInventoryTransfer(whs.Id);
		gcInventoryTransfer.disableTrigger = true;
		insert xfr;

	}
}
*/
