/**
 * Created by aminrubel on 18/2/20.
 */

public without sharing class purchaseOrder_CreateWorkOrder {
    @RemoteAction @AuraEnabled
    public static String createWOFromSerial(String idPurchaseOrder, String listSerial)
    {
        System.debug(loggingLevel.ERROR,'idPurchaseOrder:'+idPurchaseOrder);
        System.debug(loggingLevel.ERROR,'listSerial:'+listSerial);
        AcctSeedERP__Purchase_Order__c po = [SELECT Id, Warehouse__c FROM AcctSeedERP__Purchase_Order__c WHERE Id =:idPurchaseOrder][0];
        if(po.Warehouse__c == null)
            throw new AuraHandledException('A warehouse was not defined in the PO');
        Schema.Location fsl_loc;
        for(Schema.Location fl : [SELECT Id FROM Location WHERE Warehouse__c = :po.Warehouse__c]){
            fsl_loc = fl;
        }
        if(fsl_loc == null)
            throw new AuraHandledException('No FSL Location for the PO warehouse was found!');

        List<Map<String,String>> listMapSerialNumbers = (List<Map<String,String>>) JSON.deserialize(listSerial,List<Map<String,String>>.class);
        System.debug(loggingLevel.ERROR,'listMapSerialNumbers:'+listMapSerialNumbers);
        if(!listMapSerialNumbers.isEmpty()) {
            Map<Id,WorkOrder> mapSerialWO = new Map<Id,WorkOrder>();
            Map<Id,Product2> mapProduct = new Map<Id,Product2>();
            Id idRTWORecordType = gcConstants.idRtWorkOrderManufacturing;
            for (Map<String, String> m : listMapSerialNumbers) {
                mapProduct.put(m.get('idProduct'),null);
            }

            for(Product2 p : [SELECT Id, Pre_Rig_Work_Type__c FROM Product2 WHERE Id IN:mapProduct.keySet()]){
                mapProduct.put(p.Id,p);
            }

            System.debug(LoggingLevel.ERROR,'mapProduct:'+mapProduct);

            for (Map<String, String> m : listMapSerialNumbers) {
                Id idSr = m.get('idSerial');
                Id idProduct = m.get('idProduct');
                Id idWorkType = mapProduct.get(idProduct).Pre_Rig_Work_Type__c;
                mapSerialWO.put(idSr,new WorkOrder(RecordTypeId=idRTWORecordType,Serial_Number__c=idSr,WorkTypeId=idWorkType,LocationId=fsl_loc.Id));
            }
            if(!mapSerialWO.isEmpty()) {
                System.debug(loggingLevel.error,'mapSerialWO:'+mapSerialWO);
                insert mapSerialWO.values();
            }
        }
        return 'ok';
    }
}