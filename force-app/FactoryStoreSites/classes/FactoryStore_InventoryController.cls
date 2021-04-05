/**
 * Created by Tim on 2021-03-23.
 */

public with sharing class FactoryStore_InventoryController {
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
        OnlineBoat b = new OnlineBoat(
            Product_Selector.getOnlineBoat( boatId )
        );
        return b;
    }

    @AuraEnabled(Cacheable=true)
    public static List<Sobject> fetchBoatsBySeries( String seriesName )
    {
        List<Sobject> boats = new List<SObject>();
        for( Product2 p : Product_Selector.allBoatsInSeries( seriesName )){
            boats.add( p );
        }
        return boats;
    }
}