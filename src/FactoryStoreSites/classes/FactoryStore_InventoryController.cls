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

    @AuraEnabled(Cacheable=true)
    public static List<FSInventory_Selector.RiggedBoat> fetchNewInStockInventory(String location, Integer year, String modelId)
    {
        List<FSInventory_Selector.RiggedBoat> inventory = new List<FSInventory_Selector.RiggedBoat>();
        for( FSInventory_Selector.RiggedBoat s : FSInventory_Selector.getSerialNumbers(location, year, modelId)){
            inventory.add( s );
        }
        System.debug('Returned Inventory: ' + inventory);
        return inventory;
    }

//    @AuraEnabled(Cacheable=true)
//    public static List<Sobject> fetchNewInStockNonCurrentBoats( String location, Decimal year, String id )
//    {
//        String fromLocation = location;
//        Decimal currentModelYear = year;
//        String modelId = id;
//        List<Sobject> boats = new List<Sobject>();
//        for( SObject b : [SELECT Id,
//                                Name,
//                                GMBLASERP__Product__r.Name,
//                                Model_Year__c,
//                                GMBLASERP__Product__r.Make__c,
//                                GMBLASERP__Product__r.Id
//                        FROM GMBLASERP__Serial_Number__c
//                        WHERE Location__c = :fromLocation
//                        AND GMBLASERP__Product__r.Id = :modelId
//                        AND Product_Record_Type__c = 'Boat'
//                        AND GMBLASERP__Product__r.Make__c = 'Legend'
//                        AND Model_Year__c < :currentModelYear
//                        AND Status__c NOT IN ('Used', 'At Supplier', 'Return to Supplier')
//                        AND Available_Retail__c = true
//                        ORDER BY Model_Year__c ASC])
//        {
//            boats.add( b );
//        }
//        System.debug('Boats: ' + boats);
//        return boats;
//    }
//
//    @AuraEnabled(Cacheable=true)
//    public static List<Sobject> fetchUsedInStockBoats( String location )
//    {
//        String fromLocation = location;
//        List<Sobject> boats = new List<Sobject>();
//        for( SObject b : [SELECT Id,
//                                Name,
//                                GMBLASERP__Product__r.Name,
//                                Model_Year__c
//                            FROM GMBLASERP__Serial_Number__c
//                            WHERE Location__c = :fromLocation
//                            AND Product_Record_Type__c = 'Boat'
//                            AND Status__c = 'Used'
//                            AND Available_Retail__c = true
//                            ORDER BY Model_Year__c ASC])
//        {
//            boats.add( b );
//        }
//        System.debug('Boats: ' + boats);
//        return boats;
//    }


    // Currents - Legends Only by Location
    // SELECT Id, Name, GMBLASERP__Product__r.Name, Model_Year__c, GMBLASERP__Product__r.Make__c FROM GMBLASERP__Serial_Number__c WHERE Location__c = 'Whitefish' AND Product_Record_Type__c = 'Boat' AND GMBLASERP__Product__r.Make__c = 'Legend' AND Model_Year__c >= 2021 AND Status__c NOT IN ('Used', 'At Supplier', 'Return to Supplier') AND Available_Retail__c = true ORDER BY Model_Year__c ASC

    // Non-Currents - Legends Only by Location
    // SELECT Id, Name, GMBLASERP__Product__r.Name, Model_Year__c, GMBLASERP__Product__r.Make__c FROM GMBLASERP__Serial_Number__c WHERE Location__c = 'Whitefish' AND Product_Record_Type__c = 'Boat' AND GMBLASERP__Product__r.Make__c = 'Legend' AND Model_Year__c < 2021 AND Status__c NOT IN ('Used', 'At Supplier', 'Return to Supplier') AND Available_Retail__c = true ORDER BY Model_Year__c ASC

    // Used by location
    // SELECT Id, Name, GMBLASERP__Product__r.Name, Model_Year__c FROM GMBLASERP__Serial_Number__c WHERE Location__c = 'Montreal' AND Product_Record_Type__c = 'Boat' AND Status__c = 'Used' AND Available_Retail__c = true ORDER BY Model_Year__c ASC

    // Get rigged Motor and Trailer associated to specific boat serial number record id (not the serial number (Name) the Id)
    // SELECT Id, Name, GMBLASERP__Product__r.Name, Model_Year__c, GMBLASERP__Product__r.Make__c, Current_Unit_Cost__c, Product_Record_Type__c FROM GMBLASERP__Serial_Number__c WHERE Nest__c = 'a2I4z000000f4YAEAY' AND Product_Record_Type__c IN ('Motor', 'Trailer')


}
