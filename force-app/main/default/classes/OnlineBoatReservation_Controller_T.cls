/**
 * Created by dave on 2020-04-29.
 */

@IsTest
private class OnlineBoatReservation_Controller_T
{

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Factory_Product.createSerializedProducts_AvailableOnline( 'Boat', 'Pontoon', 5 );
  }

  @IsTest
  static void fetchBoats_Test()
  {
    Test.startTest();
    List<Map<String, String>> result = OnlineBoatReservation_Controller.fetchBoats();
    Test.stopTest();

    System.assertEquals( 5, result.size(), 'There should be 5 boats available for online sale');
  }
}