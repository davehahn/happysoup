@isTest
public class TA_OutboundtInventoryMovement_Legacy_T {
  static List<AcctSeedERP__Outbound_Inventory_Movement__c> outBoundInventory;
  private static List<AcctSeedERP__Outbound_Inventory_Movement__c> getData() {
    return Database.query(LGND_Utilities.getAllFieldsSOQL('AcctSeedERP__Outbound_Inventory_Movement__c'));
  }
  @testSetup
  static void dataSetup() {
    bypassFSLTransactions();
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    AcctSeed__Accounting_Settings__c accSetting = [
      SELECT AcctSeed__Default_Ledger__c
      FROM AcctSeed__Accounting_Settings__c
      ORDER BY CreatedDate
    ][0];
    AcctSeed__GL_Account__c glA = [SELECT Id, AcctSeed__Type__c FROM AcctSeed__GL_Account__c LIMIT 1];
    System.debug(glA.AcctSeed__Type__c);
    AcctSeedERP__Warehouse__c wh = [SELECT Id FROM AcctSeedERP__Warehouse__c LIMIT 1];
    AcctSeedERP__Location__c loc = new AcctSeedERP__Location__c(Name = 'Test Loc', AcctSeedERP__Warehouse__c = wh.Id);
    insert loc;
    Product2 part = Factory_Product.buildNonSerializedProduct('Part', 'Hardware');
    //part.AcctSeed__Inventory_GL_Account__c = glA.Id;
    insert part;
    AcctSeedERP__Inventory_Balance__c balance = new AcctSeedERP__Inventory_Balance__c(
      AcctSeedERP__Location__c = loc.Id,
      AcctSeedERP__Warehouse__c = wh.Id,
      AcctSeedERP__Product__c = part.Id
    );
    insert balance;
    //GMBLASERP__Serial_Number__c ser = Factory_SerialNumber.insertFullSerial('Boat','Pontoon','0987654321');
    AcctSeedERP__Outbound_Inventory_Movement__c movement = new AcctSeedERP__Outbound_Inventory_Movement__c(
      AcctSeedERP__Unit_Cost__c = 10,
      AcctSeedERP__Type__c = 'Inventory Transfer',
      AcctSeedERP__Quantity__c = 1,
      AcctSeedERP__Debit_GL_Account__c = part.AcctSeed__Inventory_GL_Account__c,
      AcctSeedERP__Inventory_Balance__c = balance.Id,
      AcctSeedERP__Ledger__c = accSetting.AcctSeed__Default_Ledger__c,
      GMBLASERP__Warehouse__c = wh.Id
      //                GMBLASERP__Serial_Number__c = ser.id
    );

    // GMBLASERP.gcOutboundInventoryMovement.disableTrigger = true;
    gcOutboundInventoryMovement.disableGCR_InventoryMovement = true;
    insert movement;
  }

  private static void bypassFSLTransactions() {
    MetadataTriggerHandler.bypass('TA_Inbound_CreateInvTransactionsFSL');
    MetadataTriggerHandler.bypass('TA_Outbound_CreateInvTransactionsFSL');
    MetadataTriggerHandler.bypass('TA_Purchase_Order_CreateInvTransactionsFSL');
  }

  @IsTest
  static void beforeInsertTest() {
    outBoundInventory = getData();
    bypassFSLTransactions();
    Test.startTest();
    new TA_OutboundtInventoryMovement_Legacy().beforeInsert(outBoundInventory);
    Test.stopTest();
  }
  @IsTest
  static void afterInsertTest() {
    Test.startTest();
    new TA_OutboundtInventoryMovement_Legacy().afterInsert(getData());
    Test.stopTest();
  }
  @IsTest
  static void afterUpdateTest() {
    Test.startTest();
    outBoundInventory = getData();
    AcctSeedERP__Outbound_Inventory_Movement__c outboundClone = outBoundInventory[0].clone(true, true, true, true);
    new TA_OutboundtInventoryMovement_Legacy()
      .afterUpdate(
        new List<AcctSeedERP__Outbound_Inventory_Movement__c>{ outBoundInventory[0] },
        new List<AcctSeedERP__Outbound_Inventory_Movement__c>{ outboundClone }
      );
    Test.stopTest();
  }
  @IsTest
  static void beforeUpdateTest() {
    Test.startTest();
    outBoundInventory = getData();
    AcctSeedERP__Outbound_Inventory_Movement__c outboundClone = outBoundInventory[0].clone(true, true, true, true);
    new TA_OutboundtInventoryMovement_Legacy()
      .beforeUpdate(
        new List<AcctSeedERP__Outbound_Inventory_Movement__c>{ outBoundInventory[0] },
        new List<AcctSeedERP__Outbound_Inventory_Movement__c>{ outboundClone }
      );
    Test.stopTest();
  }

  @IsTest
  static void beforeDeleteTest() {
    Test.startTest();
    try {
      new TA_OutboundtInventoryMovement_Legacy().beforeDelete(getData());
    } catch (Exception ex) {
      System.debug('ex= ' + getExceptionDetail(ex));
    }
    //delete getData();
    Test.stopTest();
  }
  @IsTest
  static void afterDeleteTest() {
    Test.startTest();
    new TA_OutboundtInventoryMovement_Legacy().afterDelete(getData());
    Test.stopTest();
  }

  static string getExceptionDetail(Exception ex) {
    String errorMsg = '';
    errorMsg += 'Message: ' + ex.getMessage() + '\n';
    errorMsg += 'Cause: ' + ex.getCause() + '\n';
    errorMsg += 'Line: ' + ex.getLineNumber() + '\n';
    errorMsg += 'Stack Trace: ' + ex.getStackTraceString() + '\n';
    errorMsg += 'Type: ' + ex.getTypeName() + '\n';

    return errorMsg + '\n';
  }
}
