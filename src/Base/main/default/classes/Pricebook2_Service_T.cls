/**
 * Created by dave on 2021-11-02.
 */
@IsTest
private class Pricebook2_Service_T
{

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  @IsTest
  static void getRetailToFactory_Map_Test()
  {
    Map<Id, Id> retail2Factory_Map = Pricebook2_Service.getRetailToFactory_Map();

    System.assertEquals(1, retail2Factory_Map.size() );
  }

}
