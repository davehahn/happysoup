/**
 * Created by aminrubel on 15/9/20.
 */

public with sharing class fslInventoryTransfer_Service {
    public class transferWrapper{
        public Id ProductRequiredId{get;set;}
        public String ProductRequired{get;set;}
        public Id ProductId{get;set;}
        public Decimal Quantity{get;set;}
        public Decimal AvailableInventory{get;set;}
        public Decimal Transferred{get;set;}
        public Decimal CanTransfer{get;set;}
        public Decimal TransferNow{get;set;}
    }

    @AuraEnabled(cacheable=true)
    public static String retrieve(Id idWorkOrderLine) {
        List<ProductRequired> listPR = new List<ProductRequired>();
        List<transferWrapper> listWrap = new List<transferWrapper>();
        WorkOrderLineItem woli = [SELECT id, LineItemNumber, ERP_Order_Task__c, ERP_Order_Task__r.AcctSeed__Project__r.GMBLASERP__Warehouse__c FROM WorkOrderLineItem WHERE Id =:idWorkOrderLine];
        Set<String> setIdProducts = new Set<String>();
        for(ProductRequired pr :
            [SELECT Id, CreatedDate,ProductRequiredNumber,
                    Material__c, Material__r.Name,
                    ParentRecordId, Product2Id, Product2.Name, Product_Transfer__c, QuantityRequired,
                    Product2.AcctSeed__Inventory_Product__c
            FROM ProductRequired WHERE ParentRecordId =:idWorkOrderLine])
        {
            if(pr.Product2.AcctSeed__Inventory_Product__c){
                setIdProducts.add(pr.Product2Id);
            }
            listPR.add(pr);
        }
        Map<Id,Decimal> mapPQ = new Map<Id,Decimal>();
        if(!setIdProducts.isEmpty())
        for(ProductTransfer pt : [SELECT  Id, Product2Id, Work_Order_Line_Item__c, Type__c, Source_Warehouse_Id__c, SourceProductItemId, QuantitySent, QuantityReceived FROM ProductTransfer WHERE Work_Order_Line_Item__c =:idWorkOrderLine AND Product2Id IN:setIdProducts]){
            Decimal qty = pt.QuantitySent == null ? 0 : pt.QuantitySent;
            if(!mapPQ.containsKey(pt.Product2Id)){
                mapPQ.put(pt.Product2Id,qty);
            }else{
                Decimal oldQ = mapPQ.get(pt.Product2Id);
                mapPQ.put(pt.Product2Id,qty + oldQ);
            }
        }
        //// Find out current inventory
        map<string,list<string>> mapFilters = new map<string,list<string>>();
        List<String> listStringPRId = new List<String>();
        listStringPRId.addAll(setIdProducts);
        if(woli.ERP_Order_Task__r.AcctSeed__Project__r.GMBLASERP__Warehouse__c != null)
            mapFilters.put('idWarehouse', new list<string>{woli.ERP_Order_Task__r.AcctSeed__Project__r.GMBLASERP__Warehouse__c});
        mapFilters.put('idProduct', listStringPRId);
        list<map<string,string>> listProductInventory = gcInventoryMovementCube_Report.inventorySummary(mapFilters, new list<string>{'idProduct'});
        Map<Id,Decimal> mapPrInvQty = new Map<Id,Decimal>();
        for(Map<String,String> m : listProductInventory){
            Decimal qty = Decimal.valueOf(m.get('qty'));
            mapPrInvQty.put(m.get('idProduct'),qty);
        }

        for(ProductRequired pr : listPR) {
            transferWrapper tw = new transferWrapper();
            tw.ProductRequiredId = pr.Id;
            tw.ProductRequired = pr.Product2.Name;
            tw.Quantity = pr.QuantityRequired;
            tw.ProductId = pr.Product2Id;
            tw.Transferred = mapPQ.get(pr.Product2Id);
            tw.AvailableInventory = mapPrInvQty.get(pr.Product2Id);
            tw.TransferNow = 0;
            listWrap.add(tw);
        }

        return json.serialize(listWrap);
    }

    @RemoteAction @AuraEnabled
    public static String saveTransfer(String idWorkOrderLine, String listProducts) {
        return '';
    }

    @AuraEnabled(cacheable=true)
    public static String getWarehouses() {
        List<Map<String,String>> mapList = new List<Map<String,String>>();
        for(Schema.Location loc : [SELECT Id, Name FROM Location]){
            Map<String,String> m = new Map<String,String>();
            m.put('label',loc.Name);
            m.put('value',loc.Id);
            mapList.add(m);
        }
        return JSON.serialize(mapList);
    }
}