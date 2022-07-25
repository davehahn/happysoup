/**
 * Created by Legend on 29/11/21.
 */

@IsTest
private class ERPPricingUpdate_Test {
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Factory_Account.insertFullPersonAccount('TestFname', 'TestLname');
    Factory_SerialNumber.insertFullSerial('Boat', 'Pontoon', '0987654321');
  }

  @isTest
  static void trigger_Test() {
    //AcctSeed__Ledger__c ledger = [SELECT Id FROM AcctSeed__Ledger__c LIMIT 1];
    AcctSeed__Accounting_Settings__c accSetting = [
      SELECT AcctSeed__Default_Ledger__c
      FROM AcctSeed__Accounting_Settings__c
      ORDER BY CreatedDate
    ][0];
    System.debug('accSetting');
    System.debug(accSetting);
    AcctSeedERP__Warehouse__c wh = [SELECT Id, Name, GL_Account_Variable_3__c FROM AcctSeedERP__Warehouse__c LIMIT 1];
    AcctSeedERP__Location__c loc = [
      SELECT Id
      FROM AcctSeedERP__Location__c
      WHERE AcctSeedERP__Warehouse__c = :wh.Id
      LIMIT 1
    ];
    Account cust = [SELECT Id, FirstName, LastName FROM Account WHERE LastName = 'TestLname']; //Factory_Account.insertFullPersonAccount('TestFname', 'TestLname');
    GMBLASERP__Serial_Number__c ser = [
      SELECT Id, Name, GMBLASERP__Product__c, GMBLASERP__Lot__c
      FROM GMBLASERP__Serial_Number__c
      WHERE Name = '0987654321'
      LIMIT 1
    ]; //Factory_SerialNumber.insertFullSerial('Boat','Pontoon','0987654321');
    Boolean orig = gcProject.disableTrigger;
    gcProject.disableTrigger = true;
    AcctSeed__Project__c erp = Factory_ERPOrder.insertRetailBoatSale(cust, wh, DateTime.now(), ser);
    erp.GMBLASERP__Pricebook__c = LGND_Constants.retailPricebookId;
    update erp;
    List<Id> listIdMatl = new List<Id>();
    for (AcctSeedERP__Material__c matl : [
      SELECT Id
      FROM AcctSeedERP__Material__c
      WHERE AcctSeedERP__Project__c = :erp.Id
    ]) {
      listIdMatl.add(matl.Id);
    }
    Test.startTest();
    ERPPricingUpdate.fetchERPItems(erp.Id);
    ERPPricingUpdate.updateMaterialRecords(listIdMatl, erp.Id);
    Test.stopTest();
  }
}
