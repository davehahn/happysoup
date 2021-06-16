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
        for( GMBLASERP__Serial_Number__c b : [SELECT Id,
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

            BoatModel boatModel = new BoatModel( b );

            List<Equipment> equipment = new List<Equipment>();
            for( GMBLASERP__Serial_Number__c e : [SELECT Id,
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
                System.debug('SOQL return: ' + e);
                Equipment eq = new Equipment( e );
                equipment.add( eq );
            }
            System.debug('getSerialNumbers Equipment: ' + equipment);

            RiggedBoat rb = new RiggedBoat(boatModel, equipment);

            boats.add(rb);
        }
        System.debug('getSerialNumbers Boats: ' + boats);
        FSInventory_Selector selector = new FSInventory_Selector(boats);

        return selector.riggedInventory;
    }

    public class RiggedBoat{
        @AuraEnabled public BoatModel Serial;
        @AuraEnabled public List<Equipment> Equipment;

        public RiggedBoat(BoatModel s, List<Equipment> e){
            Serial = s;
            Equipment = e;
        }
    }

    public class BoatModel{
        @AuraEnabled public String serialId;
        @AuraEnabled public String serialNumber;
        @AuraEnabled public Decimal serialModelYear;
        @AuraEnabled public String productId;
        @AuraEnabled public String productMake;
        @AuraEnabled public String productName;

        public BoatModel(GMBLASERP__Serial_Number__c b){
            serialId = b.Id;
            serialNumber = b.Name;
            serialModelYear = b.Model_Year__c;
            productId = b.GMBLASERP__Product__r.Id;
            productMake = b.GMBLASERP__Product__r.Make__c;
            productName = b.GMBLASERP__Product__r.Name;
        }
    }

    public class Equipment{
        @AuraEnabled public Decimal unitCost;
        @AuraEnabled public String serialNumber;
        @AuraEnabled public String productMake;
        @AuraEnabled public String productName;
        @AuraEnabled public String productId;

        public Equipment(GMBLASERP__Serial_Number__c e){
            System.debug('Equipment eq: ' + e);
            unitCost = e.Current_Unit_Cost__c;
            serialNumber = e.Name;
            productMake = e.GMBLASERP__Product__r.Make__c;
            productName = e.GMBLASERP__Product__r.Name;
            productId = e.GMBLASERP__Product__r.Id;
        }
    }

}