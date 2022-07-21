/**
 * Created by Pooja on 03/01/22.
 */
@isTest(SeeAllData=false)
public class gcInboundInventoryMovement_T {
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
    System.debug('@@ glA= ' + glA);
    AcctSeedERP__Warehouse__c wh = [SELECT Id FROM AcctSeedERP__Warehouse__c LIMIT 1];
    AcctSeedERP__Location__c loc = new AcctSeedERP__Location__c(Name = 'Test Loc', AcctSeedERP__Warehouse__c = wh.Id);
    insert loc;
    Product2 part = Factory_Product.createNonSerializedProduct('Part', 'Electronics');
    List<Product2> serializedProducts = Factory_Product.createSerializedProducts(RECORDTYPE, FAMILY, 1);
    // Serial
    // GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertFullSerial(
    //         'Boat',
    //         'Pontoon',
    //         '1234567890-UNIT-TESTER'
    // );
    GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertFullSerialWithProduct(
      RECORDTYPE,
      FAMILY,
      '1234567890-UNIT-TESTER',
      serializedProducts[0]
    );

    Date today = Date.today();
    /*GMBLASERP__Lot__c lot = new GMBLASERP__Lot__c(
                                        GMBLASERP__Product__c = serializedProducts[0].Id,
                                        Name = String.valueOf( today.year() ),
                                        GMBLASERP__Uniquefier__c = serializedProducts[0].Id + '-' + String.valueOf(today.year())
                                    );
        insert lot;*/
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
      // AcctSeedERP__Credit_GL_Account__c = gcConstants.idGLCostVariance
    );
    System.debug('movement= ' + movement);
    GMBLASERP.gcInboundInventoryMovement.disableTrigger = true;
    //gtInboundInventoryMovement.disableTrigger = true;
    Test.StartTest();
    insert movement;
    Test.StopTest();
  }
  @IsTest
  static void testProperties() {
    //disableTrigger Property
    gcInboundInventoryMovement.disableTrigger = null;
    Boolean retFlag1 = gcInboundInventoryMovement.disableTrigger;
    System.assertEquals(false, retFlag1);
    gcInboundInventoryMovement.disableTrigger = true;
    Boolean retFlag2 = gcInboundInventoryMovement.disableTrigger;
    system.assertEquals(true, retFlag2);

    //enableExchangeDelete Property
    gcInboundInventoryMovement.enableExchangeDelete = null;
    Boolean retFlag3 = gcInboundInventoryMovement.enableExchangeDelete;
    System.assertEquals(false, retFlag3);
    gcInboundInventoryMovement.enableExchangeDelete = true;
    Boolean retFlag4 = gcInboundInventoryMovement.enableExchangeDelete;
    system.assertEquals(true, retFlag4);
  }

  @isTest
  static void testDelete() {
    AcctSeedERP__Inbound_Inventory_Movement__c movement = [
      SELECT Id, AcctSeedERP__Quantity__c
      FROM AcctSeedERP__Inbound_Inventory_Movement__c
      LIMIT 1
    ];

    Test.StartTest();
    GMBLASERP.gcInboundInventoryMovement.disableTrigger = true;
    delete movement;
    Test.StopTest();
    List<AcctSeedERP__Inbound_Inventory_Movement__c> movement_list = [
      SELECT Id, AcctSeedERP__Quantity__c
      FROM AcctSeedERP__Inbound_Inventory_Movement__c
    ];
    system.assert(movement_list.isEmpty());
  }
}
