/**
 * Created by Tim on 2021-07-27.
 */

@IsTest
private class FactoryStore_InventoryController_T
{

    static Factory_Boat boatFactory;
    static Product2 inventoryBoat;

    @TestSetup static void dataSetup()
    {
        new Factory_TestData();
        Factory_CustomSettings.setupInventorySettings();
        Factory_Product.createSerializedProducts('Boat', 'Pontoon', 5);
    }

    private static void dataSetupForBoatSeries(String series){
        List<Product2> boats = Factory_Product.buildSerializedProducts('Boat', 'Full Windshield', 20);
        List<String> rVariants = new List<String>{
            'WideBody',
            'ProSport',
            'Angler',
            'AllSport',
            'Ultralite'
        };
        for(Product2 boat : boats){

            if(series == 'R'){
                Integer randomIndex = Integer.valueOf((Math.random() * rVariants.size()));
                series = rVariants.get(randomIndex);
            }

            boat.Series__c = series;
            boat.Available_on_Factory_Store_Sites__c = true;
        }
        Boolean orig = gcProduct.disableTrigger;
        gcProduct.disableTrigger = true;
        insert boats;
        gcProduct.disableTrigger = orig;
    }

    private static void dataSetupForInStockInventory(Integer year){
        inventoryBoat = Factory_Product.buildSerializedProduct('Boat', 'Full Windshield');
        inventoryBoat.Make__c = 'Legend';
        Boolean orig = gcProduct.disableTrigger;
        gcProduct.disableTrigger = true;
        insert inventoryBoat;
        gcProduct.disableTrigger = orig;
        GMBLASERP__Lot__c lot = Factory_SerialNumber.insertLot(inventoryBoat);
        AcctSeedERP__Location__c asLocation = [
                SELECT
                        Id
                FROM AcctSeedERP__Location__c
                WHERE AcctSeedERP__Warehouse__c = :Test_Constants.idWarehouse
                LIMIT 1
        ];

        AcctSeedERP__Inventory_Balance__c balance = Factory_InventoryBalance.createBalance(
                asLocation.Id,
                inventoryBoat.Id
        );

        List<GMBLASERP__Serial_Number__c> serials = new List<GMBLASERP__Serial_Number__c>();


        for(Integer i=0; i<5; i++){
            GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.buildSerial(inventoryBoat.Id, lot.Id, 'testSerial-0' + String.valueOf(i));
            serial.Model_Year__c = year;
            serial.GMBLASERP__Inventory_Balance__c = balance.Id;
            serial.List_on_Retail_Website__c = true;
            serials.add(serial);
        }

        insert serials;
    }

    private static void dataSetupForPartialBoat(){
        List<Map<String, String>> rtFamily = new List<Map<String, String>>();
        rtFamily.add( new Map<String, String>
        {
           'recordTypeName' => 'Motor', 'family' => 'Remote'
        });
        rtFamily.add(new Map<String, String>
        {
           'recordTypeName' => 'Trailer', 'family' => 'Boat Trailer'
        });

        boatFactory = new Factory_Boat('Full Windshield', LGND_Constants.retailPricebookId)
                .addStandardProducts(rtFamily);
        boatFactory.finish();
    }

    private static void dataSetupForFullBoat()
    {
        List<Map<String, String>> rtFamily = new List<Map<String, String>>();
        rtFamily.add(new Map<String, String>
        {
                'recordTypeName' => 'Motor', 'family' => 'Remote'
        });
        rtFamily.add(new Map<String, String>
        {
                'recordTypeName' => 'Trailer', 'family' => 'Boat Trailer'
        });

        boatFactory = new Factory_Boat('Full Windshield', LGND_Constants.retailPricebookId)
                .addStandardProducts(rtFamily)
                .addMotorUpgrades(2)
                .addTrailerUpgrades(2)
                .addPremiumPackage()
                .addOptions();
        boatFactory.addAdditionalFees(boatFactory.boat.Id);
        boatFactory.addMarketingContent(boatFactory.boat.Id, 3);
        boatFactory.finish();
    }

    @IsTest
    static void fetchBoat_Test()
    {
        dataSetupForPartialBoat();

        Test.startTest();
        LGND_APIv2_Product result = FactoryStore_InventoryController.fetchBoat(boatFactory.boat.Id);
        Test.stopTest();

        Product2 boat = [
                SELECT
                        Id,
                        Name
                FROM Product2
                WHERE Id = :boatFactory.boat.Id
        ];

        System.debug(result.standardTrailer);
        System.assertEquals(boat.Id, result.id);
        System.assertEquals(boat.Name, result.name);
        System.assertEquals(Factory_Boat.BOAT_PRICE, result.retailPrice);
        System.assertEquals(boatFactory.standardMotor.Id, result.standardMotor.id);
        System.assertEquals(boatFactory.standardTrailer.Id, result.standardTrailer.id);
    }

    @IsTest
    static void fetchFullBoatDetails_Test()
    {
        dataSetupForFullBoat();

        Test.startTest();
        FSBoatDetails_Service result = FactoryStore_InventoryController.fetchFullBoatDetails(boatFactory.boat.Id);
        Test.stopTest();

        Product2 boat = [
                SELECT
                        Id,
                        Name,
                        Series__c
                FROM Product2
                WHERE Id = :boatFactory.boat.Id
        ];

        System.debug(result);
        System.assertEquals(boat.Id, result.id);
        System.assertEquals(boat.Name, result.name);
        System.assertEquals(boat.Series__c, result.Series);
        System.assertEquals(Factory_Boat.BOAT_PRICE, result.retailPrice);
        System.assertEquals(2, result.motorUpgrades.size());
        System.assertEquals(2, result.trailerUpgrades.size());
        System.assertEquals(Factory_Boat.PART_FAMILIES.size(), result.optionalProducts.size());
    }

    @IsTest
    static void fetchBoatsBySeries_Test()
    {
        String seriesName = 'X';
        dataSetupForBoatSeries(seriesName);

        Test.startTest();
        List<Sobject> result = FactoryStore_InventoryController.fetchBoatsBySeries(
                seriesName
        );
        Test.stopTest();

        System.assertEquals(20, result.size());
    }

    @IsTest
    static void fetchBoatsBySeries_RSeries_Test()
    {
        String seriesName = 'R';
        dataSetupForBoatSeries(seriesName);

        Test.startTest();
        List<Sobject> result = FactoryStore_InventoryController.fetchBoatsBySeries(
                seriesName
        );
        Test.stopTest();

        System.assertEquals(20, result.size());
    }

    @IsTest
    static void fetchNewInStockInventory_Test()
    {
        String location = [SELECT Name FROM AcctSeedERP__Warehouse__c WHERE Id = :Test_Constants.idWarehouse].Name;
        Integer year = 2021;

        dataSetupForInStockInventory(year);

        GMBLASERP__Serial_Number__c testSerial = [ SELECT Id, Model_Year__c, Location__c FROM GMBLASERP__Serial_Number__c LIMIT 1 ][0];
        System.debug( 'WAREHOUSE NAME = ' + location);
        System.debug( testSerial );

        Test.startTest();
        FSInventory_Service result = FactoryStore_InventoryController.fetchNewInStockInventory(
                location,
                year,
                inventoryBoat.Id
        );
        Test.stopTest();

        System.assertEquals(5, result.RiggedBoats.size());
    }

}