/**
 * Created by dave on 2022-01-12.
 */

@IsTest
private class TA_CommRec2_CreateInitialPayments_T
{

  @testSetup
  static void dataSetup() {
    TA_CommRec2_TestHelper.testDataSetup();
  }

  @IsTest
  static void TA_afterInsert()
  {
    TA_CommRec2_TestHelper helper = new TA_CommRec2_TestHelper();
    CommissionRecord2__c record = new CommissionRecord2__c(
      Project_Task__c = helper.tasks[0].Id,
      Project__c = helper.tasks[0].AcctSeed__Project__c,
      Calculation_Method__c = helper.tasks[0].Commission_Calculation_Method__c,
      Department_GLV2__c = helper.tasks[0].AcctSeed__GL_Account_Variable_2__c,
      Retail_Pricebook__c = Test_Constants.idRetailPricebook,
      Factory_Pricebook__c = Test_Constants.idFactoryPricebook
    );
    TriggerBase.bypass('CommissionRecord2__c');
    insert record;
    TriggerBase.clearBypass('CommissionRecord2__c');

    List<CommissionRecord2__c> newList = new List<CommissionRecord2__c>
    {
      record
    };

    Test.startTest();
    new TA_CommRec2_CreateInitialPayments().afterInsert(newList);
    Test.stopTest();

    List<CommissionPayment2__c> payments = [SELECT Id FROM CommissionPayment2__c WHERE Commission_Record2__c = :record.Id];

    System.assert(payments.size() > 0);
  }
}