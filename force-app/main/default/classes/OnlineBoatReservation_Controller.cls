/**
 * Created by dave on 2020-04-23.
 */

public with sharing class OnlineBoatReservation_Controller
{


  @AuraEnabled(Cacheable=true)
  public static List<Product2> fetchBoats()
  {
    List<Product2> boats = Product_Selector.allBoatsAvailableForOnlineSale();
    System.debug( boats );
    return boats;
  }
}