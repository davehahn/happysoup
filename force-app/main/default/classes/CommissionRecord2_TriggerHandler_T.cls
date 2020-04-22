/**
 * Created by dave on 2020-01-29.
 */

@IsTest
private class CommissionRecord2_TriggerHandler_T
{

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Account customer = Factory_Account.insertCustomerAccounts(1)[0];
    GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertFullSerial('Boat', 'Pontoon', 'test12345');
    AcctSeed__Project__c project = Factory_ERPOrder.buildERP( customer, serial.Id, gcConstants.idRtProjectBoatSale );
    project.GMBLASERP__Pricebook__c = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
    insert project;
  }

  @IsTest
  static void beforeInsert_Test()
  {
    AcctSeed__Project__c project = [SELECT Id FROM AcctSeed__Project__c LIMIT 1];
    List<AcctSeed__Project_Task__c> tasks = Factory_ERPOrderTask.insertDefaultRetailBoatSaleTasks( project.Id );
    CommissionRecord2__c record = new CommissionRecord2__c(
      Project_Task__c = tasks[0].Id
    );
    Test.startTest();
    insert record;
    Test.stopTest();

    record = [ SELECT Id,
      Project__c,
      Retail_Pricebook__c,
      Factory_Pricebook__c
    FROM CommissionRecord2__c
    WHERE Id = :record.Id ];
    Legend_Settings__c settings = Legend_Settings__c.getOrgDefaults();
    Id factoryPB = settings.Default_Factory_Pricebook__c;
    Id retailPB = settings.Default_Retail_Pricebook__c;
    System.assertEquals( factoryPB, record.Factory_Pricebook__c, 'Factory PB should be set' );
    System.assertEquals( retailPB, record.Retail_Pricebook__c, 'Retail PB should be set' );
    System.assertEquals( project.Id, record.Project__c, 'Project Id should be set' );
  }
}