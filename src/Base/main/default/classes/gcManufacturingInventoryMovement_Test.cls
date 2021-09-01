@isTest
private class gcManufacturingInventoryMovement_Test{

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Factory_Account.insertFullPersonAccount('TestFname', 'TestLname');
    Factory_SerialNumber.insertFullSerial('Boat','Pontoon','0987654321');
  }

  @isTest
  static void trigger_Test()
  {
    //AcctSeed__Ledger__c ledger = [SELECT Id FROM AcctSeed__Ledger__c LIMIT 1];
    AcctSeed__Accounting_Settings__c accSetting = [SELECT AcctSeed__Default_Ledger__c FROM AcctSeed__Accounting_Settings__c ORDER BY CreatedDate][0];
    System.debug('accSetting');
    System.debug(accSetting);
    AcctSeedERP__Warehouse__c wh = [SELECT Id, Name, GL_Account_Variable_3__c FROM AcctSeedERP__Warehouse__c LIMIT 1];
    AcctSeedERP__Location__c loc = [SELECT Id FROM AcctSeedERP__Location__c WHERE AcctSeedERP__Warehouse__c =:wh.Id LIMIT 1];
    Account cust = [SELECT Id, FirstName, LastName  FROM Account Where LastName = 'TestLname'];//Factory_Account.insertFullPersonAccount('TestFname', 'TestLname');
    GMBLASERP__Serial_Number__c ser = [SELECT Id, Name, GMBLASERP__Product__c, GMBLASERP__Lot__c FROM GMBLASERP__Serial_Number__c WHERE Name = '0987654321' LIMIT 1]; //Factory_SerialNumber.insertFullSerial('Boat','Pontoon','0987654321');
    Boolean orig = gcProject.disableTrigger;
    gcProject.disableTrigger = true;
    AcctSeed__Project__c erp = Factory_ERPOrder.insertRetailBoatSale( cust, wh, DateTime.now(), ser);
    gcProject.disableTrigger = orig;

    //GMBLASERP__Serial_Number__c serial = [SELECT Id, GMBLASERP__Inventory_Balance__c FROM GMBLASERP__Serial_Number__c WHERE Id=:ser.Id][0];
    Product2 prod = [SELECT Id, AcctSeed__Inventory_GL_Account__c FROM Product2 WHERE Id=:ser.GMBLASERP__Product__c LIMIT 1];
    System.debug(LoggingLevel.ERROR,'ser:'+ser);
    AcctSeedERP__Material__c matl = [SELECT Id, AcctSeedERP__Product__c FROM AcctSeedERP__Material__c WHERE AcctSeedERP__Project__c =:erp.Id AND GMBLASERP__Serial_Number__c =:ser.Id][0];
    System.debug(LoggingLevel.ERROR,'matl:'+matl);
    ////
    AcctSeedERP__Inventory_Balance__c balance = new AcctSeedERP__Inventory_Balance__c(
      AcctSeedERP__Location__c = loc.Id,
      AcctSeedERP__Warehouse__c = wh.Id,
      AcctSeedERP__Product__c = ser.GMBLASERP__Product__c
    );
    insert balance;

    AcctSeedERP__Inbound_Inventory_Movement__c inmove = new AcctSeedERP__Inbound_Inventory_Movement__c(
      AcctSeedERP__Unit_Cost__c = 100000,
      AcctSeedERP__Type__c = 'Accounting',
      AcctSeedERP__Quantity__c = 1,
      AcctSeedERP__Credit_GL_Account__c = prod.AcctSeed__Inventory_GL_Account__c,
      AcctSeedERP__Inventory_Balance__c = balance.Id,
      AcctSeedERP__Ledger__c = accSetting.AcctSeed__Default_Ledger__c,
      GMBLASERP__Warehouse__c = wh.Id,
	  AcctSeedERP__Movement_Date__c = Date.today(),
	  GMBLASERP__Lot__c = ser.GMBLASERP__Lot__c,
	  GMBLASERP__Serial_Number__c = ser.Id
    );
    //GMBLASERP.gcInboundInventoryMovement.disableTrigger = true;
    insert inmove;
    ////
    AcctSeedERP__Manufacturing_Inventory_Movement__c movement = new AcctSeedERP__Manufacturing_Inventory_Movement__c(
      AcctSeedERP__Material__c = matl.Id,
      AcctSeedERP__Quantity__c = 1,
      AcctSeedERP__Inventory_Balance__c = balance.Id,
      AcctSeedERP__Ledger__c = accSetting.AcctSeed__Default_Ledger__c,
	  AcctSeedERP__Movement_Date__c = Date.today(),
	  GMBLASERP__Lot__c = ser.GMBLASERP__Lot__c,
	  GMBLASERP__Serial_Number__c = ser.Id,
	  AcctSeedERP__Unit_Cost__c = 0
    );
    //GMBLASERP.gcManufacturingInventoryMovement.disableTrigger = true;
    Test.startTest();
    insert movement;
    /// To test call serial update
    update movement;
    Test.stopTest();
  }

  @isTest
  static void trigger_Test2()
  {
    //AcctSeed__Ledger__c ledger = [SELECT Id FROM AcctSeed__Ledger__c LIMIT 1];
    AcctSeed__Accounting_Settings__c accSetting = [SELECT AcctSeed__Default_Ledger__c FROM AcctSeed__Accounting_Settings__c ORDER BY CreatedDate][0];
    System.debug('accSetting');
    System.debug(accSetting);
    AcctSeedERP__Warehouse__c wh = [SELECT Id, Name, GL_Account_Variable_3__c FROM AcctSeedERP__Warehouse__c LIMIT 1];
    AcctSeedERP__Location__c loc = [SELECT Id FROM AcctSeedERP__Location__c WHERE AcctSeedERP__Warehouse__c =:wh.Id LIMIT 1];
    //Account cust = Factory_Account.insertFullPersonAccount('TestFname', 'TestLname');
    GMBLASERP__Serial_Number__c ser = [SELECT Id, Name, GMBLASERP__Product__c, GMBLASERP__Lot__c FROM GMBLASERP__Serial_Number__c WHERE Name = '0987654321' LIMIT 1];//Factory_SerialNumber.insertFullSerial('Boat','Pontoon','0987654321');
    Product2 prod = [SELECT Id, AcctSeed__Inventory_GL_Account__c FROM Product2 WHERE Id=:ser.GMBLASERP__Product__c LIMIT 1];
    System.debug(LoggingLevel.ERROR,'ser:'+ser);
    AcctSeedERP__Inventory_Balance__c balance = new AcctSeedERP__Inventory_Balance__c(
            AcctSeedERP__Location__c = loc.Id,
            AcctSeedERP__Warehouse__c = wh.Id,
            AcctSeedERP__Product__c = ser.GMBLASERP__Product__c
    );
    insert balance;

    AcctSeedERP__Inbound_Inventory_Movement__c inmove = new AcctSeedERP__Inbound_Inventory_Movement__c(
            AcctSeedERP__Unit_Cost__c = 100000,
            AcctSeedERP__Type__c = 'Accounting',
            AcctSeedERP__Quantity__c = 1,
            AcctSeedERP__Credit_GL_Account__c = prod.AcctSeed__Inventory_GL_Account__c,
            AcctSeedERP__Inventory_Balance__c = balance.Id,
            //AcctSeedERP__Ledger__c = gcConstants.idActualLedger,
            GMBLASERP__Warehouse__c = wh.Id,
            AcctSeedERP__Movement_Date__c = Date.today(),
            GMBLASERP__Lot__c = ser.GMBLASERP__Lot__c,
            GMBLASERP__Serial_Number__c = ser.Id
    );
    //GMBLASERP.gcInboundInventoryMovement.disableTrigger = true;
    insert inmove;
    ////
    gcProject.disableTrigger = true;
    AcctSeed__Project__c p = new AcctSeed__Project__c(
            Name = 'Test',
            RecordTypeId = gcConstants.idRtProjectManufacturing,
            AcctSeedERP__Manufactured_Product__c = ser.GMBLASERP__Product__c,
            AcctSeed__Status__c = 'New',
            Serial_Number__c = ser.Id,
            GMBLASERP__Warehouse__c = wh.Id
    );
    insert p;

    gcProjectTask.disableTrigger = true;
    AcctSeed__Project_Task__c pt = new AcctSeed__Project_Task__c(
            AcctSeed__Project__c = p.Id,
            Name = 'test task',
            Admin_Deletable_Only__c = true
    );
    insert pt;
    gcMaterial.disableTrigger = true;
    AcctSeedERP__Material__c matl2 = new AcctSeedERP__Material__c(
            AcctSeedERP__Project__c = p.Id,
            AcctSeedERP__Product__c = p.AcctSeedERP__Manufactured_Product__c,
            GMBLASERP__Serial_Number__c = p.Serial_Number__c,
            AcctSeedERP__Quantity_Per_Unit__c = 1,
            GMBLASERP__Price_Override__c = true
    );
    insert matl2;

    AcctSeedERP__Manufacturing_Inventory_Movement__c movement = new AcctSeedERP__Manufacturing_Inventory_Movement__c(
            AcctSeedERP__Material__c = matl2.Id,
            AcctSeedERP__Quantity__c = 1,
            AcctSeedERP__Inventory_Balance__c = balance.Id,
            AcctSeedERP__Ledger__c = accSetting.AcctSeed__Default_Ledger__c,
            AcctSeedERP__Movement_Date__c = Date.today(),
            GMBLASERP__Lot__c = ser.GMBLASERP__Lot__c,
            GMBLASERP__Serial_Number__c = ser.Id,
            AcctSeedERP__Unit_Cost__c = 0,
            GMBLASERP__Project__c = p.Id,
            GMBLASERP__Project_Task__c = pt.Id
    );
    Test.startTest();
    //GMBLASERP.gcManufacturingInventoryMovement.disableTrigger = true;
    gcManufacturingInventoryMovement.allowMFGERPSerialWIP = true;
    insert movement;
    /// To test call serial update
    update movement;
    Test.stopTest();
  }
}