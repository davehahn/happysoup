public with sharing class ProductTransfer_CreationControl {

    public static void creationControl(List<ProductTransfer> newProductTransfer){
        List<ProductTransfer> newProductTransferStandard = new List<ProductTransfer>();
        Set<Id> WorkOrderIds = new Set<Id>();
        Set<Id> WorkOrderLineItemsIds = new Set<Id>();
        Set<Id> WorkOrderAndWorkOrderLinesItemsIds = new Set<Id>();
        List<ProductRequired> productRequired = new List<ProductRequired>();
        List<WorkOrderLineItem> workOrderLineItemsRecords = new List<WorkOrderLineItem>();
        Map<String,Id> productRequiredMappedToParentRecordKey = new Map<String,Id>();
        Map<Id,Id> workOrderMappedToWorkOrderLineItem = new Map<Id,Id>();
        Map<Id,Map<Id,Decimal>> mapProductTransferred = new Map<Id,Map<Id,Decimal>>();
        Map<Id,Map<Id,Decimal>> mapProductRequired = new Map<Id,Map<Id,Decimal>>();
        Set<Id> productRequiredIds = new Set<Id>();
        String mappingKey;
        String mappingKey2;
        map<Id,map<Id,Id>> mapPWL = new map<Id,map<Id,Id>>();

        for(ProductTransfer productTransferRecord: newProductTransfer){
            if(productTransferRecord.Source_Warehouse_Id__c != null) {
                Id idWarehouse = productTransferRecord.Source_Warehouse_Id__c;
                if (!mapPWL.containsKey(productTransferRecord.Product2Id))
                    mapPWL.put(productTransferRecord.Product2Id, new Map<Id, Id>());
                if (!mapPWL.get(productTransferRecord.Product2Id).containsKey(idWarehouse))
                    mapPWL.get(productTransferRecord.Product2Id).put(idWarehouse, null);
            }
            System.debug(LoggingLevel.ERROR,'productTransferRecord:'+productTransferRecord);
            System.debug(LoggingLevel.ERROR,'productTransferRecord.Is_Serialized__c:'+productTransferRecord.Is_Serialized__c);
            System.debug(LoggingLevel.ERROR,'productTransferRecord.QuantitySent:'+productTransferRecord.QuantitySent);

            if(productTransferRecord.Is_Serialized__c
                && productTransferRecord.QuantitySent != null
                && productTransferRecord.QuantitySent != 1
                && productTransferRecord.QuantitySent != -1
                && productTransferRecord.QuantitySent != 0)
            {
                throw new gcException('For serialized products Quantity sent must be -1,1 or 0.');
//                productTransferRecord.addError('For serialized products Quantity sent must be -1,1 or 0.');
            }

            /// Do Not allow transfers from Warehouse to Warehouse
            if(productTransferRecord.Is_Destination_Warehouse__c
                && productTransferRecord.Is_Source_Warehouse__c)
            {
                productTransferRecord.addError('Transfer cannot happen within warehouses from FSL' + productTransferRecord.Destination_Warehouse_Id__c);
            }

            if(productTransferRecord.Type__c == 'Standard'){
                newProductTransferStandard.add(productTransferRecord);
            }
        }

        ProductItemInventoryBalance.findOrCreatePIBalances(mapPWL);

        for(ProductTransfer productTransferRecord: newProductTransfer){
            if(productTransferRecord.Source_Warehouse_Id__c != null) {
                Id idWarehouse = productTransferRecord.Source_Warehouse_Id__c;
                productTransferRecord.SourceProductItemId = mapPWL.get(productTransferRecord.Product2Id).get(idWarehouse);
            }
        }

        for(ProductTransfer productTransferRecord: newProductTransferStandard){
            if(productTransferRecord.Work_Order__c != null && productTransferRecord.Work_Order_Line_Item__c == null) {
                productTransferRecord.addError('If there is a Work Order there must must be a Work Order Line Item on Transfer.');
            }
            if(productTransferRecord.Work_Order__c != null){
                WorkOrderIds.add(productTransferRecord.Work_Order__c);
            }
            if (productTransferRecord.Work_Order_Line_Item__c != null){
                WorkOrderLineItemsIds.add(productTransferRecord.Work_Order_Line_Item__c);
            }
        }

        WorkOrderAndWorkOrderLinesItemsIds.addAll(WorkOrderLineItemsIds);

        workOrderLineItemsRecords = [SELECT Id, WorkOrderId, WorkOrder.ERP_Warehouse_ID__c FROM WorkOrderLineItem WHERE Id IN :WorkOrderLineItemsIds];

        if(workOrderLineItemsRecords.size() > 0){
            for(WorkOrderLineItem woli :workOrderLineItemsRecords){
                WorkOrderIds.add(woli.WorkOrderId);
                workOrderMappedToWorkOrderLineItem.put(woli.Id, woli.WorkOrderId);
            }
        }

        WorkOrderAndWorkOrderLinesItemsIds.addAll(WorkOrderIds);
        System.debug(LoggingLevel.ERROR,'WorkOrderAndWorkOrderLinesItemsIds:'+WorkOrderAndWorkOrderLinesItemsIds);
        productRequired = [SELECT Id, Product2Id, ParentRecordId, QuantityRequired FROM ProductRequired WHERE ParentRecordId IN :WorkOrderAndWorkOrderLinesItemsIds];
        Set<Id> setUniqueProdId = new Set<Id>();
        /// Checking Product Required by WOI and PId
        System.debug(LoggingLevel.ERROR,'productRequired:'+productRequired);
        if(productRequired.size() > 0){
            for(productRequired prodReq: productRequired){
                if(prodReq.ParentRecordId != null && prodReq.ParentRecordId.getSobjectType().getDescribe().getName().equals('WorkOrderLineItem')){
                    setUniqueProdId.add(prodReq.Product2Id);
                    if(!mapProductRequired.containsKey(prodReq.ParentRecordId)){
                        mapProductRequired.put(prodReq.ParentRecordId, new Map<Id,Decimal>());
                    }
                    if(!mapProductRequired.get(prodReq.ParentRecordId).containsKey(prodReq.Product2Id))
                        mapProductRequired.get(prodReq.ParentRecordId).put(prodReq.Product2Id,0);

                    Decimal qty = mapProductRequired.get(prodReq.ParentRecordId).get(prodReq.Product2Id);
                    qty += prodReq.QuantityRequired;
                    mapProductRequired.get(prodReq.ParentRecordId).put(prodReq.Product2Id,qty);
                }
                mappingKey = prodReq.ParentRecordId;
                mappingKey += prodReq.Product2Id;
                productRequiredMappedToParentRecordKey.put(mappingKey, prodReq.Product2Id);
            }
        }
        System.debug(LoggingLevel.ERROR,'productRequiredMappedToParentRecordKey:'+productRequiredMappedToParentRecordKey);
        /// Loading all transfers to compare with required
        for(ProductTransfer pt : [SELECT  Id, Product2Id, QuantitySent, Work_Order_Line_Item__c FROM ProductTransfer WHERE Work_Order_Line_Item__c IN:mapProductRequired.keySet() AND Product2Id IN:setUniqueProdId]){
            Decimal oldQty = 0;
            if(!mapProductTransferred.containsKey(pt.Work_Order_Line_Item__c)){
                mapProductTransferred.put(pt.Work_Order_Line_Item__c, new Map<Id,Decimal>());
            }
            if(!mapProductTransferred.get(pt.Work_Order_Line_Item__c).containsKey(pt.Product2Id))
                mapProductTransferred.get(pt.Work_Order_Line_Item__c).put(pt.Product2Id,0);

            Decimal newQty = oldQty + pt.QuantitySent;
            mapProductTransferred.get(pt.Work_Order_Line_Item__c).put(pt.Product2Id,newQty);
        }
        System.debug(LoggingLevel.ERROR,'mapProductTransferred:'+mapProductTransferred);
        System.debug(LoggingLevel.ERROR,'newProductTransferStandard:'+newProductTransferStandard);
        for(ProductTransfer prodReq: newProductTransferStandard) {
            Decimal reqQty = 0;
            if(mapProductRequired.containsKey(prodReq.Work_Order_Line_Item__c)
                && mapProductRequired.get(prodReq.Work_Order_Line_Item__c).containsKey(prodReq.Product2Id))
                reqQty = mapProductRequired.get(prodReq.Work_Order_Line_Item__c).get(prodReq.Product2Id);
            Decimal tnsQty = 0;
            if(mapProductTransferred.containsKey(prodReq.Work_Order_Line_Item__c)
                && mapProductTransferred.get(prodReq.Work_Order_Line_Item__c).containsKey(prodReq.Product2Id))
                tnsQty = mapProductTransferred.get(prodReq.Work_Order_Line_Item__c).get(prodReq.Product2Id);

            System.debug(LoggingLevel.ERROR,'prodReq.Work_Order_Line_Item__c:'+prodReq.Work_Order_Line_Item__c);
            if(reqQty < (tnsQty + prodReq.QuantitySent))
                prodReq.addError('Cannot transfer more quantity than required.');
        }

        for(ProductTransfer productTransferRecord: newProductTransferStandard){
            if(productTransferRecord.Work_Order_Line_Item__c != null && productTransferRecord.Work_Order__c == null)
                productTransferRecord.Work_Order__c = workOrderMappedToWorkOrderLineItem.get(productTransferRecord.Work_Order_Line_Item__c);
            /*if(productTransferRecord.Work_Order__c != null){

                mappingKey = productTransferRecord.Work_Order__c;
                mappingKey += productTransferRecord.Product2Id;

                if(!(productRequiredMappedToParentRecordKey.get(mappingKey) != null)){
                    productTransferRecord.addError('The Product Transfer cannot be created since the Product selected is not part of the Products Required from the Work Order');
                }

            } else */if(productTransferRecord.Work_Order_Line_Item__c != null){

                mappingKey = productTransferRecord.Work_Order_Line_Item__c;
                mappingKey += productTransferRecord.Product2Id;

                mappingKey2 = workOrderMappedToWorkOrderLineItem.get(productTransferRecord.Work_Order_Line_Item__c);
                mappingKey2 += productTransferRecord.Product2Id;

                if(!(productRequiredMappedToParentRecordKey.get(mappingKey) != null || productRequiredMappedToParentRecordKey.get(mappingKey2) != null)){
                    System.debug('Mapping 1 ' + mappingKey + ' result: ' + productRequiredMappedToParentRecordKey.get(mappingKey));
                    System.debug('Mapping 2 ' + mappingKey2 + ' result: ' + productRequiredMappedToParentRecordKey.get(mappingKey2));
                    productTransferRecord.addError('The Product Transfer cannot be created since the Product selected is not part of the Products Required from the Work Order or the Work Order Line Item');
                }
            }
        }
    }
}