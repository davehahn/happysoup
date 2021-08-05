/**
 * Created by Tim on 2021-07-28.
 */

@IsTest
private class FSInventory_Service_T {

    static Factory_Boat boatFactory;
    static Product2 inventoryBoat;

    @TestSetup static void dataSetup()
    {
        new Factory_TestData();
        Factory_CustomSettings.setupInventorySettings();
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

        List<GMBLASERP__Serial_Number__c> boatSerials = new List<GMBLASERP__Serial_Number__c>();


        for(Integer i=0; i<5; i++){
            GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.buildSerial(inventoryBoat.Id, lot.Id, 'testSerial-0' + String.valueOf(i));
            serial.Model_Year__c = year;
            serial.GMBLASERP__Inventory_Balance__c = balance.Id;
            serial.Available_Retail__c = true;
            boatSerials.add(serial);
        }

        insert boatSerials;

        List<Product2> motors = Factory_Product.buildSerializedProducts('Motor', 'Remote', 5);
        Boolean origMotors = gcProduct.disableTrigger;
        gcProduct.disableTrigger = true;
        insert motors;
        gcProduct.disableTrigger = origMotors;

        List<GMBLASERP__Serial_Number__c> motorSerialNumbers = new List<GMBLASERP__Serial_Number__c>();

        Integer motorIndex = 0;
        for(Product2 motor : motors){
            GMBLASERP__Lot__c motorLot = Factory_SerialNumber.insertLot(motor);
            GMBLASERP__Serial_Number__c motorSerialNumber = Factory_SerialNumber.buildSerial(motor.Id, motorLot.Id, 'motorSerial-0' + motorIndex);
            motorSerialNumber.Nest__c = boatSerials.get(motorIndex).Id;
            motorSerialNumbers.add(motorSerialNumber);
            motorIndex++;
        }

        insert motorSerialNumbers;

        List<Product2> trailers = Factory_Product.buildSerializedProducts('Trailer', 'Boat Trailer', 5);
        Boolean origTrailers = gcProduct.disableTrigger;
        gcProduct.disableTrigger = true;
        insert trailers;
        gcProduct.disableTrigger = origTrailers;

        List<GMBLASERP__Serial_Number__c> trailerSerialNumbers = new List<GMBLASERP__Serial_Number__c>();

        Integer trailerIndex = 0;
        for(Product2 trailer : trailers){
            GMBLASERP__Lot__c trailerLot = Factory_SerialNumber.insertLot(trailer);
            GMBLASERP__Serial_Number__c trailerSerialNumber = Factory_SerialNumber.buildSerial(trailer.Id, trailerLot.Id, 'trailerSerial-0' + trailerIndex);
            trailerSerialNumber.Nest__c = boatSerials.get(trailerIndex).Id;
            trailerSerialNumbers.add(trailerSerialNumber);
            trailerIndex++;
        }

        insert trailerSerialNumbers;

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
        FSInventory_Service result = new FSInventory_Service(
                location,
                year,
                inventoryBoat.Id
        );
        Test.stopTest();

        System.assertEquals(5, result.RiggedBoats.size());
    }
}