/**
 * Created by Tim on 2021-06-15.
 */

public with sharing class FSInventory_Service {

    /**
    ┌─┐┬ ┬┬─┐┬─┐┌─┐┌┐┌┌┬┐  ┌─┐┌┬┐┌─┐┌─┐┬┌─
    │  │ │├┬┘├┬┘├┤ │││ │   └─┐ │ │ ││  ├┴┐
    └─┘└─┘┴└─┴└─└─┘┘└┘ ┴   └─┘ ┴ └─┘└─┘┴ ┴
     */
    @AuraEnabled public List<RiggedBoat> RiggedBoats;

    public FSInventory_Service(String location, Integer year, String modelId){
        init(getSerialObjects(location, year, modelId));
    }

    public void init(List<SerialNumberObject> serialNumbers){
        this.getRiggedEquipmentSerials(serialNumbers);
    }

    private List<SerialNumberObject> getSerialObjects(String location, Integer year, String modelId){
        //define a list of serial number objects
        List<SerialNumberObject> boatsSerialNumbers = new List<SerialNumberObject>();

        //loop through the serial number results of the following SOQL
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
            //create a SerialNumber out of each
            SerialNumberObject serialNumber = new SerialNumberObject( b );
            //Add the new Serial Number to the boatSerialNumbers List
            boatsSerialNumbers.add(serialNumber);
        }

        //return the list of boatSerialNumbers
        return boatsSerialNumbers;
    }

    private List<RiggedEquipment> getRiggedEquipmentSerials(List<SerialNumberObject> serialNumberObjects){
        //define a list of equipment rigged serials to all available boats (SerialNumbers)
        List<RiggedEquipment> equipment = new List<RiggedEquipment>();

        //create a list of just the serial number values from each serial number object
        // this will pass into the 'WHERE IN' of the SOQL query to get the equipment
        List<String> serialNumbers = new List<String>();
        for(SerialNumberObject sno : serialNumberObjects){
            serialNumbers.add(sno.serialNumberId);
        }
        Integer loopCount = 0;

        //loop through the serial number objects returned
        for( GMBLASERP__Serial_Number__c e : [SELECT Id,
                Nest__c,
                Name,
                GMBLASERP__Product__r.Name,
                Model_Year__c,
                GMBLASERP__Product__r.Make__c,
                Current_Unit_Cost__c,
                Product_Record_Type__c
        FROM GMBLASERP__Serial_Number__c
        WHERE Nest__c IN :serialNumbers
        AND Product_Record_Type__c IN ('Motor', 'Trailer')])
        {

            System.debug('SOQL Equipment return: ' + e);

            //create an Equipment object out of each
            RiggedEquipment eq = new RiggedEquipment( e );
            //add the new Equipment to the equipment list
            equipment.add( eq );

        }

        this.setRiggedBoats(serialNumberObjects, equipment);

        return null;
    }

    private List<RiggedBoat> setRiggedBoats(List<SerialNumberObject> s, List<RiggedEquipment> e){
        Map<String, List<RiggedEquipment>> equipmentObjMap = new Map<String, List<RiggedEquipment>>();

        System.debug('setRiggedBoats using Serial Numbers: ' + s);
        System.debug('setRiggedBoats using Rigged Equipment: ' + e);

        List<RiggedBoat> rbs = new List<RiggedBoat>();

        for(RiggedEquipment item : e){

            if(equipmentObjMap.containsKey(item.parentSerialNumberId)){
                List<RiggedEquipment> equipmentSet = equipmentObjMap.get(item.parentSerialNumberId);
                equipmentSet.add(item);
                equipmentObjMap.put(item.parentSerialNumberId, equipmentSet);
            } else {
                equipmentObjMap.put(item.parentSerialNumberId, new List<RiggedEquipment> {item});
            }
//            equipmentObjMap.put(item.parentSerialNumberId, item);
        }

        System.debug('equipmentObjMap: ' + equipmentObjMap);

        for(SerialNumberObject snoItem : s){
            System.debug('snoItem.serialNumberId: ' + snoItem.serialNumberId);
            List<RiggedEquipment> relatedEquipment = equipmentObjMap.get(snoItem.serialNumberId);
            System.debug('run if != null');
            if(relatedEquipment != null){
                System.debug('relatedEquipment != null: ' + relatedEquipment);
                RiggedBoat rb = new RiggedBoat(snoItem, relatedEquipment);
                rbs.add( rb );
            } else {
                RiggedBoat rb = new RiggedBoat(snoItem, null);
                rbs.add( rb );
            }
        }

        System.debug('rbs list: ' + rbs);
        this.RiggedBoats = rbs;
        return null;
        //return rbs;
    }

    private class SerialNumberObject{
        @AuraEnabled public GMBLASERP__Serial_Number__c serialNumberObject;
        @AuraEnabled public String serialNumberId;
        @AuraEnabled public String serialNumberValue;
        @AuraEnabled public Decimal serialModelYear;
        @AuraEnabled public String productId;
        @AuraEnabled public String productMake;
        @AuraEnabled public String productName;
//        @AuraEnabled public List<RiggedEquipment> equipment;

        public SerialNumberObject(GMBLASERP__Serial_Number__c s){
            serialNumberObject = s;
            serialNumberId = s.Id;
            serialNumberValue = s.Name;
            serialModelYear = s.Model_Year__c;
            productId = s.GMBLASERP__Product__r.Id;
            productMake = s.GMBLASERP__Product__r.Make__c;
            productName = s.GMBLASERP__Product__r.Name;

        }
    }

    private class RiggedEquipment{
        @AuraEnabled public Decimal unitCost;
        @AuraEnabled public String serialNumber;
        @AuraEnabled public String productManufacturer;
        @AuraEnabled public String productType;
        @AuraEnabled public String productName;
        @AuraEnabled public String productId;
        @AuraEnabled public String parentSerialNumberId;

        public RiggedEquipment(GMBLASERP__Serial_Number__c e){
            System.debug('Equipment eq: ' + e);
            unitCost = e.Current_Unit_Cost__c;
            serialNumber = e.Name;
            productManufacturer = e.GMBLASERP__Product__r.Make__c;
            productType = e.Product_Record_Type__c;
            productName = e.GMBLASERP__Product__r.Name;
            productId = e.GMBLASERP__Product__r.Id;
            parentSerialNumberId = e.Nest__c;
        }
    }
//
    private class RiggedBoat{
        @AuraEnabled public SerialNumberObject Serial;
        @AuraEnabled public List<RiggedEquipment> Equipment;

        public RiggedBoat(SerialNumberObject s, List<RiggedEquipment> e){
            Serial = s;
            Equipment = e;
        }
    }


}