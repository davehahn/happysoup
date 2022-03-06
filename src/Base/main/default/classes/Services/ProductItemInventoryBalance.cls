/**
 * Created by aminrubel on 2019-08-20.
 */

public with sharing class ProductItemInventoryBalance {
    @RemoteAction
    public static String findOrCreatePIBalances(map<Id,map<Id,Id>> mapPWB)
    {
        Map<Id,Id> mapIdWarehouseLocation = new Map<Id,Id>();
        Map<Id,Id> mapIdLocationWarehouse = new Map<Id,Id>();
        for(Schema.Location loc : [SELECT Id, Warehouse__c FROM Location WHERE Warehouse__c != null]){
            mapIdLocationWarehouse.put(loc.Id,loc.Warehouse__c);
            mapIdWarehouseLocation.put(loc.Warehouse__c, loc.Id);
        }
        for(ProductItem pi : [SELECT Id, Product2Id, Location.Warehouse__c
            FROM ProductItem
            WHERE Product2Id IN : mapPWB.keySet()])
        {
            set<Id> setIdWarehouse = mapPWB.get(pi.Product2Id).keySet();
            if(setIdWarehouse.contains(pi.Location.Warehouse__c))
            {
                mapPWB.get(pi.Product2Id).put(pi.Location.Warehouse__c,pi.Id);
            }
        }
        System.debug('mapPWB:'+mapPWB);
        list<ProductItem> listBalInsert = new list<ProductItem>();
        for(Id idProduct : mapPWB.keySet())
        {
            for(Id idWarehouse : mapPWB.get(idProduct).keySet())
            {
                if(mapPWB.get(idProduct).get(idWarehouse) == NULL)
                {
                    System.debug( 'PRODUCT ID = ' + idProduct );
                    listBalInsert.add(new ProductItem(Product2Id = idProduct, LocationId = mapIdWarehouseLocation.get(idWarehouse), QuantityOnHand = 0));
                }
            }
        }
        if(listBalInsert.size() > 0)
        {
            insert listBalInsert;
            for(ProductItem bal : listBalInsert)
            {
                mapPWB.get(bal.Product2Id).put(mapIdLocationWarehouse.get(bal.LocationId), bal.Id);
            }
        }

        return '';
    }
}