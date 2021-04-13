/**
 * Created by dave on 2021-04-13.
 */

@IsTest
private class ERP_CreatePartsBackOrder_Controller_T
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