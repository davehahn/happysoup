/**
 * Created by rubel on 2019-08-19.
 */
public with sharing class Inventory_Service {

    public static void createPI_FSL( List<wrapMovement> pListMovements, String movementType ) {
        if( Test.isRunningTest() )
        {
            CreateInventoryTransaction_FSL queue = new CreateInventoryTransaction_FSL(pListMovements, movementType);
            queue.execute( null );
        }
        else
        {
            QueueableUtil.enqueueJob(new CreateInventoryTransaction_FSL(pListMovements, movementType));
        }
    }

    public static void createAcctSeedInv( List<ProductItemTransaction> listMovements) {
        if( Test.isRunningTest() )
        {
            CreateWIPTransaction_FSL queue = new CreateWIPTransaction_FSL( listMovements);
            queue.execute( null );
        }
        else
        {
            QueueableUtil.enqueueJob(new CreateWIPTransaction_FSL( listMovements));
        }
    }

    public class CreateInventoryTransaction_FSL implements Queueable
    {
        public final List<wrapMovement> listMovements;
        public final String moveType;
        public Set<String> moveIds;

        public CreateInventoryTransaction_FSL( List<wrapMovement> pListMovements, String movementType)
        {
            this.listMovements = pListMovements;
            this.moveType = movementType;
        }

        public void execute( QueueableContext context )
        {
            System.debug('this.moveType:'+this.moveType);
            System.debug('this.listMovements:'+this.listMovements);
            List<wrapMovement> listPOL = new List<wrapMovement>();
            Map<Id,AcctSeedERP__Inventory_Balance__c> mapInventoryBalance = new Map<Id,AcctSeedERP__Inventory_Balance__c>();
            for(wrapMovement pol : this.listMovements){
                if(this.moveIds == null)
                    this.moveIds = new Set<String>();
                //if(!this.moveIds.contains(pol.objId)) {
                    listPOL.add(pol);
                    mapInventoryBalance.put(pol.idBalance, null);
                    this.moveIds.add(pol.objId);
                //}
            }
            if(!mapInventoryBalance.isEmpty()){
                for(AcctSeedERP__Inventory_Balance__c bal :
                [SELECT Id,
                    AcctSeedERP__Location__c,
                    AcctSeedERP__Product__c,
                    AcctSeedERP__Product__r.AcctSeed__Inventory_GL_Account__c,
                    AcctSeedERP__Product__r.AcctSeedERP__Serialized__c,
                    AcctSeedERP__Warehouse__c
                FROM AcctSeedERP__Inventory_Balance__c
                WHERE Id IN : mapInventoryBalance.keySet()])
                {
                    mapInventoryBalance.put(bal.Id,bal);
                }
                map<Id,map<Id,Id>> mapPWL = new map<Id,map<Id,Id>>();
                List<ProductItemTransaction> listPIT = new List<ProductItemTransaction>();
                for(wrapMovement pol : listPOL){
                    System.debug('pol:'+pol);
                    if(!mapPWL.containsKey(pol.idProduct))
                        mapPWL.put(pol.idProduct, new Map<Id,Id>());
                    Id idWarehouse = mapInventoryBalance.get(pol.idBalance).AcctSeedERP__Warehouse__c;
                    if(!mapPWL.get(pol.idProduct).containsKey(idWarehouse))
                        mapPWL.get(pol.idProduct).put(idWarehouse,null);
                }
                ProductItemInventoryBalance.findOrCreatePIBalances(mapPWL);
                System.debug('mapPWL');
                System.debug(mapPWL);
                for(wrapMovement pol : listPOL){
                    Id idWarehouse = mapInventoryBalance.get(pol.idBalance).AcctSeedERP__Warehouse__c;
                    Id idProductItem;
                    if(mapPWL.containsKey(pol.idProduct)
                        && mapPWL.get(pol.idProduct).containsKey(idWarehouse))
                        idProductItem = mapPWL.get(pol.idProduct).get(idWarehouse);
                    System.debug('pol:'+pol);
                    System.debug('pol.AcctSeedERP__Quantity__c:'+pol.qtyNew);

                    listPIT.add(new ProductItemTransaction(ProductItemId = idProductItem, Quantity = pol.qtyNew, TransactionType = 'Replenished'));
                }
                if(!listPIT.isEmpty()){
                    /// Disabling the trigger so that is does not call the AcctSeed inventory sync again.
                    /// This code is being executed from AcctSeed to sync FSL inventory
                    TriggerHandler.bypass('ProductItemTransaction_TriggerHandler');
                    insert listPIT;
                    System.debug('listPIT');
                    System.debug(listPIT);
                    TriggerHandler.clearBypass('ProductItemTransaction_TriggerHandler');
                }
            }
        }
    }

    public class CreateWIPTransaction_FSL implements Queueable
    {
        public final List<ProductItemTransaction> listMovements;
        public final String moveType;

        public CreateWIPTransaction_FSL( List<ProductItemTransaction> listPIT)
        {
            this.listMovements = listPIT;
        }

        public void execute( QueueableContext context )
        {
            /// Check for Material by looking into the Product Required
            /// Then move it to MFG
            Set<Id> setIdPIT = new Set<Id>();
            List<ProductItemTransaction> listPITAcctSeed = new List<ProductItemTransaction>();
            Set<Id> setIdP = new Set<Id>();
            Set<Id> setIdRelatedTns = new Set<Id>();
            for (ProductItemTransaction pit : this.listMovements) {
                if(pit.Inventory_Product__c && pit.RelatedRecordId != null && pit.Quantity <> 0){
                    setIdP.add(pit.Product_Id__c);
                    if(pit.RelatedRecordId.getSobjectType().getDescribe().getName().equals('ProductTransfer'))
                        setIdRelatedTns.add(pit.RelatedRecordId);
                }
            }
            if (!setIdP.isEmpty()) {
                Map<Id,Id> mapPTIWOI = new Map<Id,Id>();
                /// Get all the Transfers
                if(!setIdRelatedTns.isEmpty()){
                    // Only if there is a source or destination is a warehouse
                    // And there is a WOI
                    for(ProductTransfer pt : [SELECT  Id, Is_Destination_Warehouse__c, Is_Source_Warehouse__c, Work_Order_Line_Item__c FROM ProductTransfer WHERE Id IN:setIdRelatedTns]){
                        if((pt.Is_Destination_Warehouse__c || pt.Is_Source_Warehouse__c) && pt.Work_Order_Line_Item__c != null)
                            mapPTIWOI.put(pt.Id,pt.Work_Order_Line_Item__c);
                        else if(pt.Is_Destination_Warehouse__c && pt.Is_Source_Warehouse__c){
                            setIdPIT.add(pt.Id);
                        }
                    }
                }
                System.debug(loggingLevel.error, 'mapPTIWOI:'+mapPTIWOI);
                if(!mapPTIWOI.isEmpty()) {
                    /// Retrieve all the Product Required
                    Map<Id, Map<Id, ProductRequired>> mapPR = new Map<Id, Map<Id, ProductRequired>>();
                    Map<Id, Id> mapMatSerial = new Map<Id, Id>();
                    for (ProductRequired pr : [SELECT Id, Product2Id, Material__c, ParentRecordId FROM ProductRequired WHERE ParentRecordId IN:mapPTIWOI.values() AND Product2Id IN:setIdP]) {
                        if (!mapPR.containsKey(pr.Product2Id))
                            mapPR.put(pr.Product2Id, new Map<Id, ProductRequired>());
                        if (!mapPR.get(pr.Product2Id).containsKey(pr.ParentRecordId))
                            mapPR.get(pr.Product2Id).put(pr.ParentRecordId, pr);
                        mapMatSerial.put(pr.Material__c, null);
                    }
                    /// Load all serial numbers based on Material
                    if (!mapMatSerial.isEmpty()) {
                        for (AcctSeedERP__Material__c matl : [SELECT Id, GMBLASERP__Serial_Number__c FROM AcctSeedERP__Material__c WHERE Id IN:mapMatSerial.keySet()])
                            mapMatSerial.put(matl.Id, matl.GMBLASERP__Serial_Number__c);
                    }
                    Map<Id, List<Map<String, String>>> mapWOMapString = new Map<Id, List<Map<String, String>>>();
                    for (ProductItemTransaction pit : this.listMovements) {
                        if (pit.Inventory_Product__c && pit.RelatedRecordId != null && pit.Quantity <> 0) {
                            Map<String, String> mapMaterial = new Map<String, String>();
                            Id idWOI = mapPTIWOI.get(pit.RelatedRecordId);
                            if (!mapWOMapString.containsKey(idWOI))
                                mapWOMapString.put(idWOI, new List<Map<String, String>>());
                            Id idMaterial = mapPR.get(pit.Product_Id__c).get(idWOI).Material__c;
                            mapMaterial.put('idMaterial', idMaterial);
                            mapMaterial.put('qtyToMove', String.valueOf(pit.Quantity * -1));
                            mapWOMapString.get(idWOI).add(mapMaterial);
                        }
                    }
                    System.debug(loggingLevel.error, 'mapWOMapString:'+mapWOMapString);
                    if (!mapWOMapString.isEmpty())
                        callMaterialsWIP(mapWOMapString);
                }
                if(!setIdPIT.isEmpty()){
                    for (ProductItemTransaction pit : this.listMovements) {
                        if(setIdPIT.contains(pit.Id))
                            listPITAcctSeed.add(pit);
                    }

                    if(!listPITAcctSeed.isEmpty())
                        updateAcctSeedInventory(listPITAcctSeed);
                }
            }
        }
    }

    public static void callMaterialsWIP(Map<Id,List<Map<String,String>>> mapWOMapString){
        Map<Id,WorkOrderLineItem> mapWarehouseIdByWOLineItem = new Map<Id,WorkOrderLineItem>();
        for(WorkOrderLineItem woi : [SELECT Id, WorkOrder.ERP_Order__c, WorkOrder.ERP_Order__r.GMBLASERP__Warehouse__c FROM WorkOrderLineItem WHERE Id IN:mapWOMapString.keySet() AND WorkOrder.ERP_Order__c != null]){
            mapWarehouseIdByWOLineItem.put(woi.Id,woi);
        }
        for(Id idWOI : mapWOMapString.keySet()){
            if(mapWarehouseIdByWOLineItem.containsKey(idWOI)) {
                Id idWarehouse = mapWarehouseIdByWOLineItem.get(idWOI).WorkOrder.ERP_Order__r.GMBLASERP__Warehouse__c;
                Id idERP = mapWarehouseIdByWOLineItem.get(idWOI).WorkOrder.ERP_Order__c;
                GCR_InventoryMovement.disableFSL = true;
                gcProject_AccountingActions.createWipRASelected(idERP, idWarehouse, mapWOMapString.get(idWOI), Date.today().format());
                GCR_InventoryMovement.disableFSL = false;
            }
        }
    }
//    When a Product Item Transaction happens then this method is called.
    public static void updateAcctSeedInventory(List<ProductItemTransaction> listPIT){
        Set<Id> setIdPIT = new Set<Id>();
        for(ProductItemTransaction pit : listPIT){
            setIdPIT.add(pit.ProductItemId);
        }
        if(!setIdPIT.isEmpty()){
            Map<Id,Id> mapIdWarehouseLocation = new Map<Id,Id>();
            /// Now collect all PI information for location
            Map<Id,ProductItem> mapIdPI = new Map<Id,ProductItem>();
            for(ProductItem pi : [SELECT Id, LocationId, Location.Warehouse__c, Product2Id, Product2.AcctSeed__Inventory_GL_Account__c FROM ProductItem WHERE Id IN:setIdPIT AND Location.Warehouse__c != null]){
                mapIdPI.put(pi.Id,pi);
                mapIdWarehouseLocation.put(pi.Location.Warehouse__c,null);
            }
            if(!mapIdWarehouseLocation.isEmpty()){
                for(AcctSeedERP__Location__c loc : [SELECT Id, AcctSeedERP__Warehouse__c FROM AcctSeedERP__Location__c WHERE AcctSeedERP__Warehouse__c IN:mapIdWarehouseLocation.keySet()]){
                    mapIdWarehouseLocation.put(loc.AcctSeedERP__Warehouse__c,loc.Id);
                }
            }
            Map<Id,Map<Id,Map<Id,Id>>> mapPWLB = new Map<Id,Map<Id,Map<Id,Id>>>();
            for(Id piId : mapIdPI.keySet()){
                ProductItem pi = mapIdPI.get(piId);
                if(!mapPWLB.containsKey(pi.Product2Id)){
                    mapPWLB.put(pi.Product2Id, new map<Id,map<Id,Id>>{pi.Location.Warehouse__c => new map<Id,Id>{mapIdWarehouseLocation.get(pi.Location.Warehouse__c) => null}});
                }else if(!mapPWLB.get(pi.Product2Id).containsKey(pi.Location.Warehouse__c)){
                    mapPWLB.get(pi.Product2Id).put(pi.Location.Warehouse__c, new map<Id,Id>{mapIdWarehouseLocation.get(pi.Location.Warehouse__c) => null});
                }
            }
            GMBLASERP.gcInventoryBalance.findOrCreateBalances(mapPWLB);
            List<sObject> listObj = new List<sObject>();
            for(ProductItemTransaction pit : listPIT){
                /// Each Product Id and Warehouse will have a balance
                /// Based on the Type and Quantity (+-) we will add Outbound or Inbound
                ProductItem pi = mapIdPI.get(pit.ProductItemId);
                Id idProduct = pi.Product2Id;
                Id idWarehouse = pi.Location.Warehouse__c;
                Id idLocation = mapIdWarehouseLocation.get(idWarehouse);
                Id idBalance = mapPWLB.get(idProduct).get(idWarehouse).get(idLocation);
                if((pit.TransactionType == 'Transferred' && pit.Quantity < 0) || pit.TransactionType == 'Replenished')
                {
                    AcctSeedERP__Inbound_Inventory_Movement__c inbMov = new AcctSeedERP__Inbound_Inventory_Movement__c(
                        AcctSeedERP__Credit_GL_Account__c = pi.Product2.AcctSeed__Inventory_GL_Account__c,
                        AcctSeedERP__Inventory_Balance__c = idBalance,
                        AcctSeedERP__Movement_Date__c = Date.today(),
                        AcctSeedERP__Quantity__c = pit.Quantity,
                        AcctSeedERP__Type__c = 'Non-Accounting',
                        AcctSeedERP__Unit_Cost__c = 0,
                        GMBLASERP__Cost_Override__c = false
                    );
                    listObj.add(inbMov);
                }else{
                    AcctSeedERP__Outbound_Inventory_Movement__c outMove = new AcctSeedERP__Outbound_Inventory_Movement__c(
                        AcctSeedERP__Debit_GL_Account__c = pi.Product2.AcctSeed__Inventory_GL_Account__c,
                        AcctSeedERP__Inventory_Balance__c = idBalance,
                        AcctSeedERP__Movement_Date__c = Date.today(),
                        AcctSeedERP__Quantity__c = pit.Quantity,
                        AcctSeedERP__Type__c = 'Non-Accounting',
                        AcctSeedERP__Unit_Cost__c = 0,
                        GMBLASERP__Cost_Override__c = true
                    );
                    listObj.add(outMove);
                }
            }
            if(!listObj.isEmpty())
                insert listObj;
            System.debug('mapPWLB:' + mapPWLB);
        }
    }

    public static void validateForSerializedItems(List<ProductItemTransaction> listPIT) {
        /// Only if the product is serialized do the following validation
        /// Look for the Transfer or the Consumed to get the WOI
        /// Look for the specific product in Product Required
        /// Get the Material ID and check to see if a serial number has been added
        /// Otherwise do not allow the transaction

        Set<Id> setIdP = new Set<Id>();
        Set<Id> setIdRelatedTns = new Set<Id>();
        Set<Id> setIdRelatedConsumed = new Set<Id>();
        for (ProductItemTransaction pit : listPIT) {
            if(pit.Is_Serialized__c && pit.RelatedRecordId != null){
                setIdP.add(pit.Product_Id__c);
                if(pit.RelatedRecordId.getSobjectType().getDescribe().getName().equals('ProductTransfer'))
                    setIdRelatedTns.add(pit.RelatedRecordId);
                else
                    setIdRelatedConsumed.add(pit.RelatedRecordId);
            }
        }
        if (!setIdP.isEmpty()) {
            Map<Id,Id> mapPTIWOI = new Map<Id,Id>();
            /// Get all the Transfers
            if(!setIdRelatedTns.isEmpty()){
                for(ProductTransfer pt : [SELECT  Id, Work_Order_Line_Item__c FROM ProductTransfer WHERE Id IN:setIdRelatedTns])
                    mapPTIWOI.put(pt.Id,pt.Work_Order_Line_Item__c);
            }
            /// Get all the consumptions
            if(!setIdRelatedConsumed.isEmpty()){
                for(ProductConsumed pt : [SELECT  Id, WorkOrderLineItemId FROM ProductConsumed WHERE Id IN:setIdRelatedConsumed])
                    mapPTIWOI.put(pt.Id, pt.WorkOrderLineItemId);
            }
            /// Retrieve all the Product Required
            Map<Id,Map<Id,ProductRequired>> mapPR = new Map<Id,Map<Id,ProductRequired>>();
            Map<Id,Id> mapMatSerial = new Map<Id,Id>();
            for(ProductRequired pr : [SELECT Id, Product2Id, Material__c, ParentRecordId FROM ProductRequired WHERE ParentRecordId IN:mapPTIWOI.values() AND Product2Id IN:setIdP]){
                if(!mapPR.containsKey(pr.Product2Id))
                    mapPR.put(pr.Product2Id,new Map<Id,ProductRequired>());
                if(!mapPR.get(pr.Product2Id).containsKey(pr.ParentRecordId))
                    mapPR.get(pr.Product2Id).put(pr.ParentRecordId,pr);
                mapMatSerial.put(pr.Material__c,null);
            }
            /// Load all serial numbers based on Material
            if(!mapMatSerial.isEmpty()){
                for(AcctSeedERP__Material__c matl : [SELECT  Id, GMBLASERP__Serial_Number__c FROM AcctSeedERP__Material__c WHERE Id IN:mapMatSerial.keySet()])
                    mapMatSerial.put(matl.Id,matl.GMBLASERP__Serial_Number__c);
            }
            for (ProductItemTransaction pit : listPIT) {
                if(pit.Is_Serialized__c && pit.RelatedRecordId != null){
                    Id idWOI = mapPTIWOI.get(pit.RelatedRecordId);
                    Id idMaterial = mapPR.get(pit.Product_Id__c).get(idWOI).Material__c;
                    if(mapMatSerial.get(idMaterial) == null)
                        pit.addError('Cannot proceed with Product Item Transaction as the product is serialized. You must define a serial number on the ERP order line item to proceed.');
                }
            }
        }
    }
}