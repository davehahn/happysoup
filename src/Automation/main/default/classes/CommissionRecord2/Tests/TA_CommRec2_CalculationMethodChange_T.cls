/**
 * Created by dave on 2022-01-13.
 */

@IsTest
private class TA_CommRec2_CalculationMethodChange_T {
  private static final List<String> calcMethods = LGND_Utilities.getPicklistValues(
    'CommissionRecord2__c',
    'Calculation_Method__c'
  );

  @testSetup
  static void dataSetup() {
    TA_CommRec2_TestHelper.testDataSetup();
  }

  @IsTest
  static void TA_AfterInsert() {
    TA_CommRec2_TestHelper helper = new TA_CommRec2_TestHelper();
    helper.commRec.Id = TestUtility.getFakeId(CommissionRecord2__C.SObjectType);
    helper.commRec.Project_Task__c = helper.tasks[0].Id;
    helper.commRec.Project__c = helper.tasks[0].AcctSeed__Project__c;
    helper.commRec.Calculation_Method__c = calcMethods[0];
    helper.commRec.Department_GLV2__c = helper.tasks[0].AcctSeed__GL_Account_Variable_2__c;
    helper.commRec.Retail_Pricebook__c = Test_Constants.idRetailPricebook;
    helper.commRec.Factory_Pricebook__c = Test_Constants.idFactoryPricebook;

    List<CommissionRecord2__c> newList = helper.getNewList();
    List<CommissionRecord2__c> oldList = helper.getOldList();

    newList[0].Calculation_Method__c = calcMethods[1];

    Test.startTest();
    new TA_CommRec2_CalculationMethodChange().afterUpdate(newList, oldList);
    Test.stopTest();
  }
}
