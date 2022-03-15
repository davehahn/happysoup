/**
 * Created by dave on 2022-01-13.
 */

@IsTest
private class TA_CommRec2_AutoAccept_T
{
  @testSetup
  static void dataSetup() {
    TA_CommRec2_TestHelper.testDataSetup();
  }

  @IsTest
  static void TA_AfterUpdate() {
    TA_CommRec2_TestHelper helper = new TA_CommRec2_TestHelper();
    helper.commRec.Project_Task__c = helper.tasks[0].Id;
    helper.commRec.Project__c = helper.tasks[0].AcctSeed__Project__c;
    helper.commRec.Calculation_Method__c = helper.tasks[0].Commission_Calculation_Method__c;
    helper.commRec.Department_GLV2__c = helper.tasks[0].AcctSeed__GL_Account_Variable_2__c;
    helper.commRec.Retail_Pricebook__c = Test_Constants.idRetailPricebook;
    helper.commRec.Factory_Pricebook__c = Test_Constants.idFactoryPricebook;

    TriggerBase.bypass('CommissionRecord2__c');
    helper.insertCommRec();
    TriggerBase.clearBypass('CommissionRecord2__c');

    CommissionPayment2__c payment = new CommissionPayment2__c(
      Commission_Record2__c = helper.commRec.Id,
      Owner__c = helper.project.Salesperson__c
    );
    insert payment;

    payment = [SELECT Id, Status__c, Auto_Accepted__c FROM CommissionPayment2__c WHERE Id = :payment.Id];
    System.assert( payment.Status__c != 'Accepted' );
    System.assert( !payment.Auto_Accepted__c );


    List<CommissionRecord2__c> newList = helper.getNewList();
    List<CommissionRecord2__c> oldList = helper.getOldList();

    newList[0].Sales_Acceptable_Expired__c = true;

    Test.startTest();
    new TA_CommRec2_AutoAccept().afterUpdate( newList, oldList );
    Test.stopTest();

    payment = [SELECT Id, Status__c, Auto_Accepted__c FROM CommissionPayment2__c WHERE Id = :payment.Id];
    System.assert( payment.Status__c == 'Accepted' );
    System.assert( payment.Auto_Accepted__c );
  }
}
