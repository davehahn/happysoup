/**
 * Created by Legend on 28/7/21.
 */

public without sharing class GCR_InventoryBalance {

    @RemoteAction
    public static Id findOrCreateBalance(Id idProduct, Id idWarehouse, Id idLocation)
    {
        AcctSeedERP__Inventory_Balance__c bal = new AcctSeedERP__Inventory_Balance__c();
        for(AcctSeedERP__Inventory_Balance__c b :
        [SELECT Id
        FROM AcctSeedERP__Inventory_Balance__c
        WHERE AcctSeedERP__Product__c = :idProduct
        AND AcctSeedERP__Warehouse__c = :idWarehouse
        AND AcctSeedERP__Location__c = :idLocation
        ORDER BY Id
        LIMIT 1])
        {
            bal = b;
        }

        if(bal.Id == NULL)
        {
            bal = new AcctSeedERP__Inventory_Balance__c
                    (
                            AcctSeedERP__Product__c = idProduct,
                            AcctSeedERP__Warehouse__c = idWarehouse,
                            AcctSeedERP__Location__c = idLocation
                    );

            insert bal;
        }

        return bal.Id;
    }


    @RemoteAction
    public static String findOrCreateBalances(map<Id,map<Id,map<Id,Id>>> mapPWLB)
    {
        for(AcctSeedERP__Inventory_Balance__c bal :
        [SELECT Id, AcctSeedERP__Product__c, AcctSeedERP__Warehouse__c, AcctSeedERP__Location__c
        FROM AcctSeedERP__Inventory_Balance__c
        WHERE AcctSeedERP__Product__c IN : mapPWLB.keySet()])
        {
            set<Id> setIdWarehouse = mapPWLB.get(bal.AcctSeedERP__Product__c).keySet();
            if(setIdWarehouse.contains(bal.AcctSeedERP__Warehouse__c))
            {
                set<Id> setIdLocation = mapPWLB.get(bal.AcctSeedERP__Product__c).get(bal.AcctSeedERP__Warehouse__c).keySet();
                if(setIdLocation.contains(bal.AcctSeedERP__Location__c))
                {
                    mapPWLB.get(bal.AcctSeedERP__Product__c).get(bal.AcctSeedERP__Warehouse__c).put(bal.AcctSeedERP__Location__c,bal.Id);
                }
            }
        }

        list<AcctSeedERP__Inventory_Balance__c> listBalInsert = new list<AcctSeedERP__Inventory_Balance__c>();
        for(Id idProduct : mapPWLB.keySet())
        {
            for(Id idWarehouse : mapPWLB.get(idProduct).keySet())
            {
                for(Id idLocation : mapPWLB.get(idProduct).get(idWarehouse).keySet())
                {
                    if(mapPWLB.get(idProduct).get(idWarehouse).get(idLocation) == NULL)
                    {
                        listBalInsert.add(new AcctSeedERP__Inventory_Balance__c(AcctSeedERP__Product__c = idProduct, AcctSeedERP__Warehouse__c = idWarehouse, AcctSeedERP__Location__c = idLocation));
                    }
                }
            }
        }
        if(listBalInsert.size() > 0)
        {
            insert listBalInsert;
            for(AcctSeedERP__Inventory_Balance__c bal : listBalInsert)
            {
                mapPWLB.get(bal.AcctSeedERP__Product__c).get(bal.AcctSeedERP__Warehouse__c).put(bal.AcctSeedERP__Location__c, bal.Id);
            }
        }

        return '';
    }
}