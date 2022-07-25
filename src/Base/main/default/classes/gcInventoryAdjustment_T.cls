/**
 * Created by Pooja on 03/01/22.
 */
@isTest
public class gcInventoryAdjustment_T {
  final static String RECORDTYPE = 'Boat';
  final static String FAMILY = 'Electronics';

  @TestSetup
  static void makeData() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();

    Account dealer = AccountFactory.buildDealerAccount('Test Dealer UnitTester');
    insert dealer;
    AcctSeed__Accounting_Settings__c accSetting = [
      SELECT AcctSeed__Default_Ledger__c
      FROM AcctSeed__Accounting_Settings__c
      ORDER BY CreatedDate
    ][0];
    AcctSeed__GL_Account__c glA = [SELECT Id FROM AcctSeed__GL_Account__c LIMIT 1];

    AcctSeedERP__Warehouse__c wh = [SELECT Id FROM AcctSeedERP__Warehouse__c LIMIT 1];
    AcctSeedERP__Location__c loc = new AcctSeedERP__Location__c(Name = 'Test Loc', AcctSeedERP__Warehouse__c = wh.Id);
    insert loc;
    Product2 part = Factory_Product.createNonSerializedProduct('Part', 'Electronics');
    List<Product2> serializedProducts = Factory_Product.createSerializedProducts(RECORDTYPE, FAMILY, 1);

    GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertFullSerialWithProduct(
      RECORDTYPE,
      FAMILY,
      '1234567890-UNIT-TESTER',
      serializedProducts[0]
    );

    Date today = Date.today();

    GMBLASERP__Lot__c lot = [SELECT Id FROM GMBLASERP__Lot__c WHERE GMBLASERP__Product__c = :serializedProducts[0].Id];

    AcctSeed__Project__c erp = Factory_ERPOrder.buildERP(dealer, serial.Id, gcConstants.idRtPartnerPartsOrder);
    insert erp;
    AcctSeed__Project_Task__c erp_task = Factory_ERPOrder.buildProjectTask(erp.Id, 'Dealer Order');
    insert erp_task;

    GMBLASERP__Inventory_Adjustment__c adj = new GMBLASERP__Inventory_Adjustment__c();
    adj.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
    adj.Department_GLV_2__c = gcConstants.idGlv2Sales;
    adj.GMBLASERP__GL_Account__c = gcConstants.idGlCostVariance;
    adj.GMBLASERP__Product__c = serializedProducts[0].Id;
    adj.GMBLASERP__Adjustment_Type__c = 'Value';
    insert adj;

    AcctSeedERP__Inventory_Balance__c balance = new AcctSeedERP__Inventory_Balance__c(
      AcctSeedERP__Location__c = loc.Id,
      AcctSeedERP__Warehouse__c = wh.Id,
      AcctSeedERP__Product__c = serializedProducts[0].Id //part.Id
    );
    insert balance;

    AcctSeedERP__Inbound_Inventory_Movement__c movement = new AcctSeedERP__Inbound_Inventory_Movement__c(
      AcctSeedERP__Unit_Cost__c = 10,
      AcctSeedERP__Type__c = 'Other',
      AcctSeedERP__Quantity__c = 1,
      AcctSeedERP__Credit_GL_Account__c = glA.Id,
      AcctSeedERP__Inventory_Balance__c = balance.Id,
      AcctSeedERP__Ledger__c = accSetting.AcctSeed__Default_Ledger__c,
      GMBLASERP__Warehouse__c = wh.Id,
      GMBLASERP__Serial_Number__c = serial.Id,
      GMBLASERP__Lot__c = lot.Id,
      GMBLASERP__Inventory_Adjustment__c = adj.Id,
      AcctSeedERP__Project_Task__c = erp_task.Id,
      AcctSeedERP__Project__c = erp.Id
    );
    GMBLASERP.gcInboundInventoryMovement.disableTrigger = true;
    Test.StartTest();
    MetadataTriggerHandler.bypass('TA_Inbound_CreateInvTransactionsFSL');
    insert movement;
    MetadataTriggerHandler.clearBypass('TA_Inbound_CreateInvTransactionsFSL');
    Test.StopTest();

    AcctSeedERP__Outbound_Inventory_Movement__c outBoundMovement = new AcctSeedERP__Outbound_Inventory_Movement__c(
      AcctSeedERP__Unit_Cost__c = 10,
      AcctSeedERP__Type__c = 'Other',
      AcctSeedERP__Quantity__c = 1,
      AcctSeedERP__Debit_GL_Account__c = glA.Id,
      AcctSeedERP__Inventory_Balance__c = balance.Id,
      AcctSeedERP__Ledger__c = accSetting.AcctSeed__Default_Ledger__c,
      GMBLASERP__Warehouse__c = wh.Id,
      GMBLASERP__Serial_Number__c = serial.Id,
      AcctSeedERP__Inbound_Inventory_Movement__c = movement.Id,
      GMBLASERP__Lot__c = lot.Id
    );

    GMBLASERP.gcOutboundInventoryMovement.disableTrigger = true;
    MetadataTriggerHandler.bypass('TA_Outbound_CreateInvTransactionsFSL');
    insert outBoundMovement;
    MetadataTriggerHandler.clearBypass('TA_Outbound_CreateInvTransactionsFSL');
  }

  @IsTest
  static void testProperties() {
    gcInventoryAdjustment.disableTrigger = null;
    Boolean retFlag1 = gcInventoryAdjustment.disableTrigger;
    System.assertEquals(false, retFlag1);
    gcInventoryAdjustment.disableTrigger = true;
    Boolean retFlag2 = gcInventoryAdjustment.disableTrigger;
    system.assertEquals(true, retFlag2);
  }

  @IsTest
  static void testCascadeDeleteChildrenOfInbounds() {
    AcctSeedERP__Inbound_Inventory_Movement__c movement = [
      SELECT Id, AcctSeedERP__Quantity__c
      FROM AcctSeedERP__Inbound_Inventory_Movement__c
      LIMIT 1
    ];
    set<Id> setIdMoveIn = new Set<Id>{ movement.id };

    Test.StartTest();
    //GMBLASERP.gcOutboundInventoryMovement.disableTrigger = true;
    gcInboundInventoryMovement.disableTrigger = true;
    MetadataTriggerHandler.bypass('TA_Inbound_CreateInvTransactionsFSL');
    MetadataTriggerHandler.bypass('TA_Outbound_CreateInvTransactionsFSL');
    gcInventoryAdjustment.cascadeDeleteChildrenOfInbound(setIdMoveIn);
    MetadataTriggerHandler.clearBypass('TA_Inbound_CreateInvTransactionsFSL');
    MetadataTriggerHandler.clearBypass('TA_Outbound_CreateInvTransactionsFSL');
    Test.StopTest();
    movement = [SELECT Id, AcctSeedERP__Quantity__c FROM AcctSeedERP__Inbound_Inventory_Movement__c LIMIT 1];
    system.assertEquals(0, movement.AcctSeedERP__Quantity__c);
  }
}
