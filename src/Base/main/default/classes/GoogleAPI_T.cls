/**
 * Created by dave on 2019-10-31.
 */

@IsTest
private class GoogleAPI_T
{

  @IsTest
  static void DistanceMatrix_Test()
  {
    Test.setMock( HttpCalloutMock.class, new Tests_CalloutMocks.GoogleDestinationsMatrixMock() );
    String destinations = '44.62840928065218,-79.41666966709374|44.29638562156834,-79.68193162911972';
    Test.startTest();
    GoogleAPI.GoogleDestinationsResult result = new GoogleAPI.DistanceMatrix( 'orillia', destinations ).execute();
    Test.stopTest();
    System.debug( result );
    System.assertEquals( 1, result.origin_addresses.size() );
    System.assertEquals( 2, result.rows[0].elements.size() );
  }

}