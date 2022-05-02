/**
 * Created by Legend on 25/4/22.
 */

public without sharing class SalesOrderInventoryMovement_Service {
    public static Map<Id,Id> mapSOLWarehouse;
    public static Map<Id,Id> mapSOL;
    public static void checkForSameWarehouse(List<AcctSeedERP__Sales_Order_Inventory_Movement__c> listSOIM){
        System.debug('listSOIM');
        System.debug(listSOIM);
        Set<Id> setIdSOL = new Set<Id>();
        Set<Id> setIdBalance = new Set<Id>();
        for(AcctSeedERP__Sales_Order_Inventory_Movement__c soim : listSOIM){
            if(soim.AcctSeedERP__Sales_Order_Line__c != null) {
                setIdSOL.add(soim.AcctSeedERP__Sales_Order_Line__c);
            }
            if(soim.AcctSeedERP__Inventory_Balance__c != null){
                setIdBalance.add(soim.AcctSeedERP__Inventory_Balance__c);
            }
        }
        System.debug('setIdSOL');
        System.debug(setIdSOL);
        System.debug('setIdBalance');
        System.debug(setIdBalance);

        if(!setIdBalance.isEmpty() || !setIdSOL.isEmpty()){
            retrieveData(setIdSOL, setIdBalance);
            System.debug('mapSOLWarehouse');
            System.debug(mapSOLWarehouse);
            System.debug('mapSOL');
            System.debug(mapSOL);

            for(AcctSeedERP__Sales_Order_Inventory_Movement__c soim : listSOIM){
                if(soim.AcctSeedERP__Sales_Order_Line__c != null && mapSOLWarehouse != null && mapSOL != null && mapSOLWarehouse.get(soim.AcctSeedERP__Sales_Order_Line__c) != mapSOL.get(soim.AcctSeedERP__Inventory_Balance__c)) {
                    soim.addError('Inventory Allocation must be from the same warehouse as selected in the Sales Order.');
                }
            }
        }
    }

    private static void retrieveData(Set<Id> setIdSOL, Set<Id> setIdBalance){
        if(mapSOLWarehouse == null)
            mapSOLWarehouse = new Map<Id,Id>();
        if(mapSOL == null)
            mapSOL = new Map<Id,Id>();

        if(!setIdSOL.isEmpty()){
            for(AcctSeedERP__Sales_Order_Line__c sol : [SELECT Id, AcctSeedERP__Sales_Order__c, AcctSeedERP__Sales_Order__r.Warehouse__c FROM AcctSeedERP__Sales_Order_Line__c WHERE Id IN:setIdSOL]){
                mapSOLWarehouse.put(sol.Id, sol.AcctSeedERP__Sales_Order__r.Warehouse__c);
            }
        }

        if(!setIdBalance.isEmpty()){
            for(AcctSeedERP__Inventory_Balance__c ib : [SELECT Id, AcctSeedERP__Warehouse__c FROM AcctSeedERP__Inventory_Balance__c WHERE Id IN:setIdBalance]){
                mapSOL.put(ib.Id,ib.AcctSeedERP__Warehouse__c);
            }
        }
    }
}