/**
 * Created by dave on 2020-04-23.
 */

public with sharing class OnlineBoatReservation_Controller
{


  @AuraEnabled(Cacheable=true)
  public static List<Map<String, String>> fetchBoats()
  {
    List<Map<String, String>> boats = new List<Map<String, String>>();
    for( Product2 p : Product_Selector.allBoatsAvailableForOnlineSale() )
    {
      Map<String, String> b = new Map<String, String>();
      b.put( 'id', p.Id );
      b.put( 'name', p.Name );
      b.put( 'imageURL', p.Default_Gallery_Image_Original__c );
      boats.add( b );
    }
    return boats;
  }

  @AuraEnabled(Cacheable=true)
  public static OnlineBoat fetchBoat( String boatId )
  {
    OnlineBoat b = new OnlineBoat( boatId );
    return b;
  }
}
