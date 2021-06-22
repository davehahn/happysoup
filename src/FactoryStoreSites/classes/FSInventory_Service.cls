/**
 * Created by Tim on 2021-06-15.
 */

public with sharing class FSInventory_Service {

    @AuraEnabled public List<RiggedBoat> riggedInventory;
//    @AuraEnabled public List<SObject> Serials;

    public FSInventory_Service(List<RiggedBoat> ri){
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

            List<Product2> options = new List<Product2>();
            String boatId = b.GMBLASERP__Product__r.Id;
            for( Product2 p : [SELECT Name, Make__c,
                    (SELECT  Pricebook2Id, PriceBook2.Name, UnitPrice, Special_Price__c, Special_Price_Description__c, CreatedDate FROM PricebookEntries WHERE Pricebook2.isStandard = false AND isActive = true AND Pricebook2.isActive = true ORDER BY CreatedDate DESC),
                    (SELECT Id, Feature_ID__r.Description__c, Feature_ID__r.Description_Fr__c,Feature_ID__r.Category__c, Feature_ID__r.Value__c FROM Product_Feature_Maps__r),
                    (SELECT Id, Standard__C, Maximum__c, displayOnWeb__c, isBiggestMotor__c, From_Product__r.Id, From_Product__r.Name, From_Product__r.RecordType.Name, From_Product__r.Family FROM To_Product_Options__r ORDER BY From_Product__r.Name),
                    (SELECT Id, Fee_Product__c FROM Parent_Product_Fee_Maps__r)
                    FROM Product2 WHERE Id = :boatId])
            {
                options.add(p);
            }

            RiggedBoat rb = new RiggedBoat(boatModel, equipment, options);

            boats.add(rb);
        }
        System.debug('getSerialNumbers Boats: ' + boats);
        FSInventory_Service selector = new FSInventory_Service(boats);

        return selector.riggedInventory;
    }

    public class RiggedBoat{
        @AuraEnabled public BoatModel Serial;
        @AuraEnabled public List<Equipment> Equipment;
        @AuraEnabled public List<Product2> Options;

        public RiggedBoat(BoatModel s, List<Equipment> e, List<Product2> o){
            Serial = s;
            Equipment = e;
            Options = o;
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
        @AuraEnabled public String productManufacturer;
        @AuraEnabled public String productType;            
        @AuraEnabled public String productName;
        @AuraEnabled public String productId;

        public Equipment(GMBLASERP__Serial_Number__c e){
            System.debug('Equipment eq: ' + e);
            unitCost = e.Current_Unit_Cost__c;
            serialNumber = e.Name;
            productManufacturer = e.GMBLASERP__Product__r.Make__c;
            productType = e.Product_Record_Type__c;
            productName = e.GMBLASERP__Product__r.Name;
            productId = e.GMBLASERP__Product__r.Id;
        }
    }

//    public class StandardOption{
//        @AuraEnabled public feeMap;
//        public StandardOption(Product2 p){
//            System.debug('Option op: ' + p);
//
//        }
//    }



}