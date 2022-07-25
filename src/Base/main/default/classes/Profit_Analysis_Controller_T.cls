/**
 * Created by dave on 2021-05-14.
 */

@IsTest
private class Profit_Analysis_Controller_T {
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Account customer = Factory_Account.insertFullPersonAccount('Tester', 'McTesterson');
    Id retailPB = LGND_Constants.retailPricebookId;
    Opportunity opp = Factory_Opportunity.insertOpportunityForBoatSale(retailPB, customer);
    GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertFullSerial('Boat', 'Pontoon', 'TestPontoon0001');
    AcctSeedERP__Warehouse__c wh = [
      SELECT Id, Name
      FROM AcctSeedERP__Warehouse__c
      WHERE Name LIKE '%Whitefish%'
      LIMIT 1
    ];
    Factory_ERPOrder.insertRetailBoatSale(customer, wh, DateTime.now().addMonths(1), serial);
  }

  @IsTest
  static void fetchData_Opportunity() {
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

    Test.startTest();
    String resultJSON = Profit_Analysis_Controller.fetchData(opp.Id, LGND_Constants.retailPricebookId, 'Ontario');
    Test.stopTest();
  }

  @IsTest
  static void fetchData_ERP() {
    AcctSeed__Project__c erp = [SELECT Id FROM AcctSeed__Project__c LIMIT 1];

    Test.startTest();
    String resultJSON = Profit_Analysis_Controller.fetchData(erp.Id, LGND_Constants.retailPricebookId, 'Ontario');
    Test.stopTest();
  }
}
