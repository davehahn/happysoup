/**
 * Created by dave on 2021-06-09.
 */

@IsTest
private class WorkOrder_Automation_T
{

  static Id pbId;
  static Account acct;
  static AcctSeedERP__Warehouse__c warehouse;
  static User barrieUser;

  @testSetup static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void init() {
    acct = Factory_Account.insertFullPersonAccount('Testy', 'McTesterson' );
    pbId = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
    warehouse = [SELECT Id, Name FROM AcctSeedERP__Warehouse__c WHERE Name LIKE '%Barrie%' ];
    barrieUser = Factory_User.newUser('fName', 'lName', 'System Administrator', warehouse );
  }

  @IsTest
  static void onInsert()
  {
    init();
    System.runAs( barrieUser )
    {
      Test.startTest();
      WorkOrder wo = Factory_WorkOrder.createNew( acct.Id, pbId );
      Test.stopTest();
      AcctSeed__Project__c[] erps = [ SELECT Id, GMBLASERP__Warehouse__c FROM AcctSeed__Project__c WHERE Work_Order__c = :wo.Id ];
      wo = [ SELECT Id, Location.Warehouse__c FROM WorkOrder WHERE Id = :wo.Id ];
      System.assertEquals( 1, erps.size(), 'One Erp should have been automatically created' );
      System.assertEquals( warehouse.Id, erps[0].GMBLASERP__Warehouse__c, 'ERP Warehouse should be the Users warehouse');
      System.assertEquals( warehouse.Id, wo.Location.Warehouse__c, 'Location on Work Order should be associated to the Users Warehouse' );
    }
  }

  @IsTest
  static void onDelete()
  {
    init();
    TriggerBase.bypass('WorkOrder');
    WorkOrder wo = Factory_WorkOrder.createNew( acct.Id, pbId );
    AcctSeed__Project__c erp = new AcctSeed__Project__c(
      Name = (wo.Account.Name + ' - ' + String.valueOf( wo.WorkOrderNumber)).LEFT(80),
      AcctSeed__Account__c = wo.AccountId,
      Work_Order__c = wo.Id
    );
    gcProject.disableTrigger = true;
    insert erp;
    wo.ERP_Order__c = erp.Id;
    update wo;
    TriggerBase.clearBypass('WorkOrder');

    List<AcctSeed__Project__c> erps = [SELECT Id FROM AcctSeed__Project__c WHERE AcctSeed__Account__c = :acct.Id];

    System.assertEquals( 1, erps.size() );

    Test.startTest();
    delete wo;
    Test.stopTest();

    erps = [SELECT Id FROM AcctSeed__Project__c WHERE AcctSeed__Account__c = :acct.Id];

    System.assertEquals( 0, erps.size() );
  }
}