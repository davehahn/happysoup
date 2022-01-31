/**
 * Created by dave on 2022-01-11.
 */

@IsTest
private class TA_CommRec2_setValuesFromProjectTask_T {
  @testSetup
  static void dataSetup() {
    TA_CommRec2_TestHelper.testDataSetup();
  }

  @IsTest
  static void TA_BeforeInsert() {
    TA_CommRec2_TestHelper helper = new TA_CommRec2_TestHelper();
    List<CommissionRecord2__c> newList = helper.getNewList();
    Test.startTest();
    new TA_CommRec2_setValuesFromProjectTask().beforeInsert(newList);
    Test.stopTest();

    Legend_Settings__c settings = Legend_Settings__c.getOrgDefaults();
    Id retailPB = settings.Default_Retail_Pricebook__c;
    System.assertEquals(retailPB, newList[0].Retail_Pricebook__c, 'Retail PB should be set');
    System.assertEquals(helper.project.Id, newList[0].Project__c, 'Project Id should be set');
    System.assertEquals( helper.tasks[0].Commission_Calculation_Method__c, newList[0].Calculation_Method__c );
    System.assertEquals( helper.tasks[0].AcctSeed__GL_Account_Variable_2__c, newList[0].Department_GLV2__c );
  }

  @IsTest
  static void Trigger_BeforeInsert() {
    TA_CommRec2_TestHelper helper = new TA_CommRec2_TestHelper();
    Test.startTest();
    helper.insertCommRec();
    Test.stopTest();

    CommissionRecord2__c result = [
      SELECT Id, Project__c, Retail_Pricebook__c, Calculation_Method__c, Department_GLV2__c
      FROM CommissionRecord2__c
      WHERE Id = :helper.commRec.Id
    ];

    Legend_Settings__c settings = Legend_Settings__c.getOrgDefaults();
    Id retailPB = settings.Default_Retail_Pricebook__c;
    System.assertEquals(retailPB, result.Retail_Pricebook__c, 'Retail PB should be set');
    System.assertEquals(helper.project.Id, result.Project__c, 'Project Id should be set');
    System.assertEquals( helper.tasks[0].Commission_Calculation_Method__c, result.Calculation_Method__c );
    System.assertEquals( helper.tasks[0].AcctSeed__GL_Account_Variable_2__c, result.Department_GLV2__c );
  }
}
