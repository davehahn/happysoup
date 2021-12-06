/**
 * Created by Legend on 28/10/21.
 */

public with sharing class ERPPricingUpdate {
    @AuraEnabled
    public static String updateMaterialRecords(List<Id> setIdMaterials,String erpId){
        System.debug('setIdMaterials');
        System.debug(setIdMaterials);
        Set<Id> setIdMatl = new Set<Id>();
        setIdMatl.addAll(setIdMaterials);
        List<AcctSeedERP__Material__c> matlList = Material_Selector.selectAllByIds(setIdMatl);
        System.debug('matlList 1');
        System.debug(matlList);
        Set<Id> setIdProducts = new Set<Id>();
        for(AcctSeedERP__Material__c matl : matlList){
            setIdProducts.add(matl.AcctSeedERP__Product__c);
        }
        Id idPricebook = [SELECT Id, GMBLASERP__Pricebook__c FROM AcctSeed__Project__c WHERE Id=:erpId].GMBLASERP__Pricebook__c;
        Map<Id,Decimal> mapProductPrice = new Map<Id,Decimal>();
        for(PricebookEntry pbe : [SELECT Id, Product2Id, UnitPrice FROM PricebookEntry WHERE Pricebook2Id=:idPricebook AND Product2Id IN:setIdProducts]){
            mapProductPrice.put(pbe.Product2Id, pbe.UnitPrice);
        }
        for(AcctSeedERP__Material__c matl : matlList){
            matl.GMBLASERP__Unit_Price__c = mapProductPrice.get(matl.AcctSeedERP__Product__c);
        }
        System.debug('matlList');
        System.debug(matlList);
        Boolean oldVal = gcMaterial.allowPartUpdate;
        gcMaterial.allowPartUpdate = true;
        update matlList;
        gcMaterial.allowPartUpdate = oldVal;
        return fetchERPItems(erpId);
    }

    @AuraEnabled(Cacheable=true)
    public static String fetchERPItems( Id erpId )
    {
        List<matlWrapper> listWrap = new List<matlWrapper>();
        Set<Id> setIdProducts = new Set<Id>();
        List<AcctSeedERP__Material__c> matlList = Material_Selector.allPartMaterialsByProjectIds( new Set<Id>{erpId} );
        for(AcctSeedERP__Material__c matl : matlList){
            if(matl.AcctSeedERP__Product__r.Family != 'Labour' ||  matl.AcctSeedERP__Product__r.Family != 'Discount') {
                setIdProducts.add(matl.AcctSeedERP__Product__c);
                matlWrapper mw = new matlWrapper(matl);
                listWrap.add(mw);
            }
        }
        Id idPricebook;
        Boolean readyToGo = true;
        for(AcctSeed__Project__c proj : [SELECT Id, GMBLASERP__Pricebook__c, AcctSeed__Status__c FROM AcctSeed__Project__c WHERE Id=:erpId]){
            if(proj.AcctSeed__Status__c == 'Completed' || proj.AcctSeed__Status__c == 'Ready for Accounting'){
                readyToGo = false;
            }
            idPricebook = proj.GMBLASERP__Pricebook__c;
        }
        if(readyToGo && idPricebook != null) {
            Map<Id, Decimal> mapProductPrice = new Map<Id, Decimal>();
            for (PricebookEntry pbe : [SELECT Id, Product2Id, UnitPrice FROM PricebookEntry WHERE Pricebook2Id = :idPricebook AND Product2Id IN:setIdProducts]) {
                mapProductPrice.put(pbe.Product2Id, pbe.UnitPrice);
            }
            for (matlWrapper mw : listWrap) {
                if (mapProductPrice.containsKey(mw.idProduct)) {
                    mw.priceBookUnitPrice = mapProductPrice.get(mw.idProduct);
                    if (mw.priceBookUnitPrice != mw.currentUnitPrice) {
                        mw.isDifferent = true;
                    }
                }
            }
        }else{
            throw new AuraHandledException('The Project is not eligible for price update. Please check if the project is locked or there is no Pricebook.');
        }
        System.debug('listWrap');
        System.debug(listWrap);
        return JSON.serialize(listWrap);
    }

    public class matlWrapper{
        String idMaterial;
        String idProduct;
        String productName;
        Decimal currentUnitPrice;
        Decimal priceBookUnitPrice;
        Boolean isDifferent;
        matlWrapper(AcctSeedERP__Material__c matl){
            idMaterial = matl.Id;
            idProduct = matl.AcctSeedERP__Product__c;
            productName = matl.AcctSeedERP__Product__r.Name;
            currentUnitPrice = matl.GMBLASERP__Unit_Price__c;
            priceBookUnitPrice = 0;
            isDifferent = false;
        }

        matlWrapper(){}
    }
}