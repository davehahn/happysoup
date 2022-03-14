/**
 * Created by dave on 2022-01-12.
 */

@IsTest
private class TA_CommRec2_CreateInitialLines_T
{
  @testSetup
  static void dataSetup() {
    TA_CommRec2_TestHelper.testDataSetup();
  }

  @IsTest
  static void TA_afterInsert(){
    TA_CommRec2_TestHelper helper = new TA_CommRec2_TestHelper();
    AcctSeed__Project_Task__c boTask;
    for( AcctSeed__Project_Task__c task : helper.tasks ){
      if( task.AcctSeed__GL_Account_Variable_2__c == LGND_Constants.GLV2Id_BusinessOffice ){
        boTask = task;
        break;
      }
    }
    CommissionRecord2__c record = new CommissionRecord2__c(
      Project_Task__c = boTask.Id,
      Project__c = boTask.AcctSeed__Project__c,
      Calculation_Method__c = boTask.Commission_Calculation_Method__c,
      Department_GLV2__c = boTask.AcctSeed__GL_Account_Variable_2__c,
      Retail_Pricebook__c = Test_Constants.idRetailPricebook,
      Factory_Pricebook__c = Test_Constants.idFactoryPricebook
    );
    TriggerBase.bypass('CommissionRecord2__c');
    insert record;
    TriggerBase.clearBypass('CommissionRecord2__c');

    List<CommissionRecord2__c> newList = new List<CommissionRecord2__c>{record};

    Test.startTest();
    new TA_CommRec2_CreateInitialLines().afterInsert( newList );
    Test.stopTest();

    List<CommissionLineItem2__c> lines = [SELECT Id FROM CommissionLineItem2__c WHERE CommissionRecord2__c = :record.Id];

    System.assert( lines.size() > 0 );
  }
}