/**
 * Created by dave on 2022-06-06.
 */

@IsTest
private class TA_Project_R_B_SaleSetCompletedDate_T {
  static AcctSeed__Project__c retailBoatSale;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    setup();
  }

  private static void setup() {
    Account customer = Factory_Account.insertFullPersonAccount('HomerTest', 'SimpsonTest');
    AcctSeedERP__Warehouse__c wh = [
      SELECT Id, Name
      FROM AcctSeedERP__Warehouse__c
      WHERE Id = :Test_Constants.idWarehouse
    ];
    GMBLASERP__Serial_Number__c boatSerial = Factory_SerialNumber.insertFullSerial(
      'Boat',
      'Pontoon',
      'test1234Serial9876'
    );
    TriggerBase.bypass('AcctSeed__Project__c');
    Factory_ERPOrder.insertRetailBoatSale(customer, wh, DateTime.now().addMonths(1), boatSerial);
    TriggerBase.clearBypass('AcctSeed__Project__c');
  }

  private static void getData() {
    retailBoatSale = (AcctSeed__Project__c) Database.query(LGND_Utilities.getAllFieldsSOQL('AcctSeed__Project__c'))[0];
  }

  @IsTest
  static void beforeUpdate_Set() {
    getData();
    List<AcctSeed__Project__c> oldList = new List<AcctSeed__Project__c>{ retailBoatSale };
    AcctSeed__Project__c clone = retailBoatSale.clone(true, true, true, true);
    clone.Stage__c = TA_Project_R_B_SaleSetCompletedDate.getTriggeringStageName();
    List<AcctSeed__Project__c> newList = new List<AcctSeed__Project__c>{ clone };

    Test.startTest();
    new TA_Project_R_B_SaleSetCompletedDate().beforeUpdate(newList, oldList);
    Test.stopTest();

    System.assert(newList[0].Completed_Date__c != null);
  }

  @IsTest
  static void beforeUpdate_SetByTrigger() {
    getData();
    retailBoatSale.Stage__c = TA_Project_R_B_SaleSetCompletedDate.getTriggeringStageName();
    System.assert(retailBoatSale.Completed_Date__c == null);

    Test.startTest();
    MetadataTriggerHandler.bypass('TA_Project_Legacy');
    update retailBoatSale;
    MetadataTriggerHandler.clearBypass('TA_Project_Legacy');
    Test.stopTest();

    retailBoatSale = [SELECT Id, Completed_Date__c FROM AcctSeed__Project__c WHERE Id = :retailBoatSale.Id];

    System.assert(retailBoatSale.Completed_Date__c != null);
  }

  @IsTest
  static void beforeUpdate_unSet() {
    getData();
    retailBoatSale.Stage__c = TA_Project_R_B_SaleSetCompletedDate.getTriggeringStageName();
    retailBoatSale.Completed_Date__c = DateTime.now();
    List<AcctSeed__Project__c> oldList = new List<AcctSeed__Project__c>{ retailBoatSale };

    AcctSeed__Project__c clone = retailBoatSale.clone(true, true, true, true);
    clone.Stage__c = TA_Project_R_B_SaleSetCompletedDate.getBeforeTriggeringState();
    List<AcctSeed__Project__c> newList = new List<AcctSeed__Project__c>{ clone };

    System.assert(newList[0].Completed_Date__c != null);
    Test.startTest();
    new TA_Project_R_B_SaleSetCompletedDate().beforeUpdate(newList, oldList);
    Test.stopTest();

    System.assert(newList[0].Completed_Date__c == null);
  }

  @IsTest
  static void beforeUpdate_NoChange() {
    getData();
    DateTime completedOn = Datetime.now().addDays(-14);
    retailBoatSale.Stage__c = TA_Project_R_B_SaleSetCompletedDate.getTriggeringStageName();
    retailBoatSale.Completed_Date__c = completedOn;
    List<AcctSeed__Project__c> oldList = new List<AcctSeed__Project__c>{ retailBoatSale };

    AcctSeed__Project__c clone = retailBoatSale.clone(true, true, true, true);
    clone.Stage__c = TA_Project_R_B_SaleSetCompletedDate.getAfterTriggeringState();
    List<AcctSeed__Project__c> newList = new List<AcctSeed__Project__c>{ clone };

    System.assertEquals(newList[0].Completed_Date__c, completedOn);
    Test.startTest();
    new TA_Project_R_B_SaleSetCompletedDate().beforeUpdate(newList, oldList);
    Test.stopTest();

    System.assertEquals(newList[0].Completed_Date__c, completedOn);
  }
}
