/**
 * Created by dave on 2020-02-05.
 */

@IsTest
private class CommissionRecord2_Controller_T
{

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  @IsTest
  static void testBehavior()
  {
  }
}