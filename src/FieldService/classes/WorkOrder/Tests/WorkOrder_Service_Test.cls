/**
 * Created by dave on 2019-08-06.
 */

@IsTest
private class WorkOrder_Service_Test {
  static Opportunity opp;
  static Id pbId;
  static Account acct;
  static AcctSeedERP__Warehouse__c warehouse;
  static User barrieUser;
  static AcctSeed__Project__c erp;
  static GMBLASERP__Serial_Number__c[] serials;

  @TestSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void init() {
    pbId = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
    warehouse = [SELECT Id, Name FROM AcctSeedERP__Warehouse__c WHERE Name LIKE '%Barrie%'];
    System.debug('WAREHOUSE = ' + warehouse);
    barrieUser = Factory_User.newUser('fName', 'lName', 'System Administrator', warehouse);
  }

  private static void initOpp() {
    acct = Factory_Account.insertFullPersonAccount('Testy', 'McTesterson');
    opp = Factory_Opportunity.insertOpportunityForBoatSale(pbId, acct);
    opp = [SELECT Id, Pricebook2Id, AccountId, Name, Warehouse__c FROM Opportunity WHERE Id = :opp.Id];
  }

  private static void initPartnerErp() {
    acct = Factory_Account.insertDealerAccounts(1)[0];
    serials = Factory_SerialNumber.insertFullSerials(4, 'Boat', 'Pontoon');
    erp = Factory_ERPOrder.createPartnerBoatSale(acct, serials[0]);
  }

  @isTest
  static void createFromOppy_Test() {
    init();
    System.runAs(barrieUser) {
      initOpp();
      Test.startTest();
      WorkOrder wo = WorkOrder_Service.createFromOppy(opp);
      insert wo;
      Test.stopTest();
      wo = [SELECT Id, Location.Warehouse__c FROM WorkOrder WHERE Id = :wo.Id];
      System.assertEquals(
        warehouse.Id,
        wo.Location.Warehouse__c,
        'Work Orders location should be related to Opportunities Warehouse'
      );
    }
  }

  @IsTest
  static void newFromPartnerBoatSaleERP_Test() {
    init();
    initPartnerErp();
    Test.startTest();
    WorkOrder wo = WorkOrder_Service.newFromPartnerBoatSaleERP(erp);
    Test.stopTest();
    System.assertEquals(erp.Id, wo.ERP_Order__c);
  }
}
