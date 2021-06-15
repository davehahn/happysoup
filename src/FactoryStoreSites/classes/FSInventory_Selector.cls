/**
 * Created by Tim on 2021-06-15.
 */

public with sharing class FSInventory_Selector {

    @AuraEnabled public List<RiggedBoat> riggedInventory;
//    @AuraEnabled public List<SObject> Serials;

    public FSInventory_Selector(List<RiggedBoat> ri){
       // use this to get used
        riggedInventory = ri;
    }

    public static List<RiggedBoat> getSerialNumbers(String location, Integer year, String modelId){
        List<RiggedBoat> boats = new List<RiggedBoat>();
        for( SObject b : [SELECT Id,
                                 Name,
                                 GMBLASERP__Product__r.Name,
                                 Model_Year__c,
                                 GMBLASERP__Product__r.Make__c
                          FROM GMBLASERP__Serial_Number__c
                          WHERE Location__c = :location
                          AND GMBLASERP__Product__r.Id = :modelId
                          AND Product_Record_Type__c = 'Boat'
                          AND GMBLASERP__Product__r.Make__c = 'Legend'
                          AND Model_Year__c >= :year
                          AND Status__c NOT IN ('Used', 'At Supplier', 'Return to Supplier')
                          AND Available_Retail__c = true
                          ORDER BY Model_Year__c ASC])
        {
            String serialId = b.Id;
            List<Sobject> equipment = new List<Sobject>();
            for( SObject e : [SELECT Id,
                                    Name,
                                    GMBLASERP__Product__r.Name,
                                    Model_Year__c,
                                    GMBLASERP__Product__r.Make__c,
                                    Current_Unit_Cost__c,
                                    Product_Record_Type__c
                            FROM GMBLASERP__Serial_Number__c
                            WHERE Nest__c = :serialId
                            AND Product_Record_Type__c IN ('Motor', 'Trailer')])
            {
                equipment.add( e );
            }
            System.debug('getSerialNumbers Equipment: ' + equipment);

            RiggedBoat rb = new RiggedBoat(b, equipment);

            boats.add(rb);
        }
        System.debug('getSerialNumbers Boats: ' + boats);
        FSInventory_Selector selector = new FSInventory_Selector(boats);

        return selector.riggedInventory;
    }

    public class RiggedBoat{
        @AuraEnabled public SObject Serial;
        @AuraEnabled public List<SObject> Equipment;

        public RiggedBoat(SObject s, List<SObject> e){
            Serial = s;
            Equipment = e;
        }
    }

}