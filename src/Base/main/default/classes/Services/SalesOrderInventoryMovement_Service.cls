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

        if(!setIdBalance.isEmpty() || !setIdSOL.isEmpty()){
            retrieveData(setIdSOL, setIdBalance);
            for(AcctSeedERP__Sales_Order_Inventory_Movement__c soim : listSOIM){
                if(soim.AcctSeedERP__Sales_Order_Line__c != null && mapSOLWarehouse != null && mapSOL != null && mapSOLWarehouse.get(soim.AcctSeedERP__Sales_Order_Line__c) != mapSOL.get(soim.AcctSeedERP__Inventory_Balance__c)) {
                    soim.addError('Inventory Allocation must be from the same warehouse as selected in the Sales Order.');
                }
            }
        }
    }

    @future
    public static void createJEFuture(Set<Id> setIdSO){
        createJE(setIdSO);
    }

    public static void createJE(Set<Id> setFilter)
    {
        Date cogsDate = Date.today();
        Id idGlWip = gcConstants.idGlWip;
        Id idGlCogsParts = gcConstants.idGlCogsParts;
        Id idGlProjectParts = gcConstants.idGlProjectParts;
        Id idGlProjectPartsClearing = gcConstants.idGlProjectPartsClearing;
        Set<Id> setIdSO = new Set<Id>();
        list<AcctSeed__Journal_Entry_Line__c> listJEL = new list<AcctSeed__Journal_Entry_Line__c>();
        for(AcctSeedERP__Sales_Order_Line__c soLine :
        [SELECT Id,
                AcctSeedERP__Product__c,
                AcctSeedERP__Product__r.RecordType.Name,
                AcctSeedERP__Product__r.AcctSeed__Unit_Cost__c,
                AcctSeedERP__Product__r.Partner_Price__c,
                AcctSeedERP__Product__r.Loaded_Cost__c,
                AcctSeedERP__Product__r.AcctSeed__Inventory_GL_Account__c,
                AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__c,
                AcctSeedERP__Sales_Order__c,
                AcctSeedERP__Sales_Order__r.RecordTypeId,
                AcctSeedERP__Sales_Order__r.GL_Account_Variable_1__c,
                AcctSeedERP__Sales_Order__r.GL_Account_Variable_2__c,
                AcctSeedERP__Project_Task__c,
                AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_1__c,
                AcctSeedERP__Project_Task__r.AcctSeed__GL_Account_Variable_2__c,
                AcctSeedERP__Quantity_Allocated__c,
                AcctSeedERP__Quantity_Ordered__c,
                GMBLASERP__Serial_Number__c,
                AcctSeedERP__Unit_Price__c,
                AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c,
        (SELECT Id, AcctSeed__Units__c FROM Journal_Entry_Lines__r),
        (SELECT Id, AcctSeedERP__Unit_Cost__c FROM AcctSeedERP__Sales_Order_Inventory_Movements__r LIMIT 1)
        FROM AcctSeedERP__Sales_Order_Line__c
        WHERE (AcctSeedERP__Sales_Order__c IN :setFilter OR Id = :setFilter)])
        {
            setIdSO.add(soLine.AcctSeedERP__Sales_Order__c);
            if((soLine.AcctSeedERP__Sales_Order__r.RecordTypeId != gcConstants.idRtProjectManufacturing && soLine.AcctSeedERP__Sales_Order__r.RecordTypeId != gcConstants.idRtTradeIn)
                    || (!soLine.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c && (soLine.AcctSeedERP__Sales_Order__r.RecordTypeId == gcConstants.idRtProjectManufacturing
                    || soLine.AcctSeedERP__Sales_Order__r.RecordTypeId == gcConstants.idRtTradeIn)))
            {
                System.debug('Inside');
                Decimal qty = soLine.AcctSeedERP__Quantity_Ordered__c;
                Decimal amt = soLine.AcctSeedERP__Product__r.AcctSeed__Unit_Cost__c;
                Decimal unitCost = 0;
                if (soLine.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c && !soLine.AcctSeedERP__Sales_Order_Inventory_Movements__r.isEmpty()) {
                    qty = soLine.AcctSeedERP__Quantity_Allocated__c;
                    unitCost = soLine.AcctSeedERP__Sales_Order_Inventory_Movements__r[0].AcctSeedERP__Unit_Cost__c;
                }

                if (!soLine.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c) {
                    unitCost = soLine.AcctSeedERP__Product__r.AcctSeed__Unit_Cost__c;
                }

                if (!soLine.Journal_Entry_Lines__r.isEmpty())
                    for (AcctSeed__Journal_Entry_Line__c jel : soLine.Journal_Entry_Lines__r) {
                        qty -= jel.AcctSeed__Units__c == null ? 0 : jel.AcctSeed__Units__c;
                    }
                if (soLine.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c || (!soLine.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c && (soLine.AcctSeedERP__Sales_Order__r.RecordTypeId == gcConstants.idRtProjectManufacturing || soLine.AcctSeedERP__Sales_Order__r.RecordTypeId == gcConstants.idRtTradeIn)))
                    amt = qty * unitCost;

                if (qty != null && qty != 0) {
                    if (amt == null) amt = 0;

                    amt = amt.setScale(6);
                    qty = qty.setScale(6);
                    Id idDebitGL = idGlProjectParts;
                    Id idCreditGL = idGlProjectPartsClearing;
                    if (soLine.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c && (soLine.AcctSeedERP__Sales_Order__r.RecordTypeId != gcConstants.idRtProjectManufacturing || soLine.AcctSeedERP__Sales_Order__r.RecordTypeId != gcConstants.idRtTradeIn)) {
                        idDebitGL = idGlCogsParts;
                        idCreditGL = idGlWIP;
                    } else if (!soLine.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c && (soLine.AcctSeedERP__Sales_Order__r.RecordTypeId == gcConstants.idRtProjectManufacturing || soLine.AcctSeedERP__Sales_Order__r.RecordTypeId == gcConstants.idRtTradeIn)) {
                        idDebitGL = idGlWIP;
                        idCreditGL = soLine.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__c;
                    }
                    AcctSeed__Journal_Entry_Line__c debitJE = new AcctSeed__Journal_Entry_Line__c(
                            AcctSeed__Debit__c = amt,
                            AcctSeed__GL_Account__c = idDebitGL,
                            AcctSeed__Product__c = soLine.AcctSeedERP__Product__c,
                            Sales_Order__c = soLine.AcctSeedERP__Sales_Order__c,
                            Sales_Order_Line__c = soLine.Id,
                            AcctSeed__Date__c = cogsDate,
                            AcctSeed__Units__c = qty
                    );

                    AcctSeed__Journal_Entry_Line__c creditJE = new AcctSeed__Journal_Entry_Line__c(
                            AcctSeed__Credit__c = amt,
                            AcctSeed__GL_Account__c = idCreditGL,
                            AcctSeed__Product__c = soLine.AcctSeedERP__Product__c,
                            Sales_Order__c = soLine.AcctSeedERP__Sales_Order__c,
                            Sales_Order_Line__c = soLine.Id,
                            AcctSeed__Date__c = cogsDate,
                            AcctSeed__Units__c = qty * (-1)
                    );

                    listJEL.add(debitJE);
                    listJEL.add(creditJE);
                }
            }
        }
        System.debug('listJEL');
        System.debug(listJEL);
        if(!listJEL.isEmpty())
        {
            Map<Id,AcctSeedERP__Sales_Order__c> mapIdSO = new Map<Id,AcctSeedERP__Sales_Order__c>();
            for(AcctSeedERP__Sales_Order__c so :
            [SELECT Id,
                    Name,
                    GL_Account_Variable_1__c,
                    GL_Account_Variable_2__c,
                    GL_Account_Variable_3__c,
                    RecordTypeId
            FROM AcctSeedERP__Sales_Order__c
            WHERE Id IN :setIdSO]){
                mapIdSO.put(so.Id,so);
            }

            Map<Id,AcctSeed__Journal_Entry__c> listJE = new Map<Id,AcctSeed__Journal_Entry__c>();
            if(!listJEL.isEmpty()){
                String jobCostName = 'Job Cost for ';
                for(AcctSeed__Journal_Entry_Line__c jel : listJEL) {
                    AcctSeedERP__Sales_Order__c so = mapIdSO.get(jel.Sales_Order__c);
                    AcctSeed__Journal_Entry__c je = new AcctSeed__Journal_Entry__c(
                            Name = jobCostName + so.Name,
                            AcctSeed__Journal_Date__c = cogsDate,
                            AcctSeed__Status__c = 'Approved',
                            Sales_Order__c = jel.Sales_Order__c
                    );
                    if(jel.AcctSeed__GL_Account_Variable_1__c == null)
                        jel.AcctSeed__GL_Account_Variable_1__c = so.GL_Account_Variable_1__c;
                    if(jel.AcctSeed__GL_Account_Variable_2__c == null)
                        jel.AcctSeed__GL_Account_Variable_2__c = so.GL_Account_Variable_2__c;

                    listJE.put(so.Id,je);
                }
            }
            insert listJE.values();
            for(AcctSeed__Journal_Entry_Line__c jel : listJEL)
            {
                jel.AcctSeed__Journal_Entry__c = listJE.get(jel.Sales_Order__c).Id;
            }
            insert listJEL;

            AcctSeed.PostResult[] postResults = AcctSeed.JournalEntryPostService.postJournalEntries(listJE.values());
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