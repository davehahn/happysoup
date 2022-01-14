/**
 * Created by dave on 2022-01-12.
 */

@IsTest
private class TA_CommRec2_setFactoryPB_T {
  @testSetup
  static void dataSetup() {
    TA_CommRec2_TestHelper.testDataSetup();
  }

  @IsTest
  static void TA_BeforeInsert() {
    TA_CommRec2_TestHelper helper = new TA_CommRec2_TestHelper();
    List<CommissionRecord2__c> newList = helper.getNewList();
    newList[0].Retail_Pricebook__c = Test_Constants.idRetailPricebook;
    Test.startTest();
    new TA_CommRec2_setFactoryPB().beforeInsert(newList);
    Test.stopTest();

    Legend_Settings__c settings = Legend_Settings__c.getOrgDefaults();
    Id factoryPB = settings.Default_Factory_Pricebook__c;
    System.assertEquals(factoryPB, newList[0].Factory_Pricebook__c, 'Factory PB should be set');
  }
}
