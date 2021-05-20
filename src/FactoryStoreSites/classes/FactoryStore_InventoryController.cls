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

//    @AuraEnabled(Cacheable=true)
//    public static Boat fetchBoat( String boatId )
//    {
//        Boat b = new Boat( '01ti0000007ruGkAAI' , 'retail');
//        return b;
//    }
    @AuraEnabled(Cacheable=true)
    public static LGND_APIv2_Product fetchBoat( String boatId )
    {
        LGND_APIv2_Product api = new LGND_APIv2_Product( boatId, 'retail', 'Boat' );
        //System.debug( api );
        return api;
    }

    @AuraEnabled(Cacheable=true)
    public static List<Sobject> fetchBoatsBySeries( String seriesName )
    {
        Set<String> series = new Set<String>();
        if(seriesName != 'R'){
            series.add(seriesName);
        } else {
            series.add('WideBody');
            series.add('ProSport');
            series.add('Angler');
            series.add('AllSport');
            series.add('Ultralite');
        }
        List<Sobject> boats = new List<SObject>();
        for( Product2 p : Product_Selector.allBoatsInSeries( series )){
            boats.add( p );
        }
        return boats;
    }

//    @AuraEnabled(Cacheable=true)
//    public static List<Sobject> fetchStandardProducts(  productIds )
//    {
//        List<Sobject> standards = new List<SObject>();
//        for( Product2 p : Product_Selector.allWithFullDetailsById( productIds )){
//            standards.add( p );
//        }
//        return standards;
//    }

}
