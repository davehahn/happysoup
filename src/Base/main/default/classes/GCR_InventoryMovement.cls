/**
 * Created by Legend on 28/7/21.
 */

public without sharing class GCR_InventoryMovement {

    public static Boolean disableFSL{
        get{
            if(disableFSL == null) return false;
            else return disableFSL;
        }
        set{
            if(value == null) disableFSL = false;
            else disableFSL = value;
        }
    }

    public static Boolean disableCostUpdate{
        get{
            if(disableCostUpdate == null) return false;
            else return disableCostUpdate;
        }
        set{
            if(value == null) disableCostUpdate = false;
            else disableCostUpdate = value;
        }
    }

    public static void triggerHandler
            (map<Id,sObject> oldMap,
                    map<Id,sObject> newMap,
                    list<sObject> listNew,
                    Boolean boolIsBefore,
                    Boolean boolIsInsert,
                    Boolean boolIsUpdate,
                    Boolean boolIsDelete)
    {
        if(oldMap == NULL) oldMap = new map<Id,sObject>();
        if(newMap == NULL) newMap = new map<Id,sObject>();
        if(listNew == NULL) listNew = new list<sObject>();

        updateAndValidate(oldMap,newMap,listNew,boolIsBefore,boolIsInsert,boolIsUpdate,boolIsDelete);

        if(boolIsBefore)
        {
            if(boolIsInsert)
            {

            }
            if(boolIsUpdate)
            {

            }
            if(boolIsDelete)
            {

            }
        }
        else //i.e. trigger.isAfter
        {
            if(boolIsInsert)
            {

            }
            if(boolIsUpdate)
            {

            }
            if(boolIsDelete)
            {

            }
        }
    }

    private static void updateAndValidate
            (map<Id,sObject> oldMap,
                    map<Id,sObject> newMap,
                    list<sObject> listNew,
                    Boolean boolIsBefore,
                    Boolean boolIsInsert,
                    Boolean boolIsUpdate,
                    Boolean boolIsDelete)
    {
        if(boolIsBefore && (boolIsInsert || boolIsUpdate))
        {
            map<Id,AcctSeedERP__Inventory_Balance__c> mapInventoryBalance = new map<Id,AcctSeedERP__Inventory_Balance__c>();
            map<Id,GMBLASERP__Serial_Number__c> mapSerial = new map<Id,GMBLASERP__Serial_Number__c>();
            map<Id,GMBLASERP__Lot__c>  mapLot = new map<Id,GMBLASERP__Lot__c>();
            map<Id,Decimal> mapCost = new map<Id,Decimal>();
            Set<Id> setCheckPosted  = new Set<Id>();
            //prepare to map the inventory balances, lots, and serial numbers
            for(sObject move : listNew)
            {
                mapInventoryBalance.put((Id)move.get('AcctSeedERP__Inventory_Balance__c'), null);
                if((Id)move.get('GMBLASERP__Serial_Number__c')!=null)
                    mapSerial.put((Id)move.get('GMBLASERP__Serial_Number__c'),null);
                if((Id)move.get('GMBLASERP__Lot__c')!= null)
                    mapLot.put((Id)move.get('GMBLASERP__Lot__c'),null);
                if(boolIsUpdate){
                    System.debug('move new'+move);
                    System.debug('move old'+oldMap.get(move.Id));
                    String moveStatus = (String) move.get('AcctSeedERP__Status__c');
                    String oldMoveStatus = (String) oldMap.get(move.Id).get('AcctSeedERP__Status__c');
                    if(moveStatus == 'Posted' && oldMoveStatus != moveStatus){
                        setCheckPosted.add(move.Id);
                    }
                }
            }
            if(setCheckPosted.isEmpty()) {
                System.debug(setCheckPosted);
                mapSerial.remove(null);
                mapLot.remove(null);

                //map the inventory balances
                for (AcctSeedERP__Inventory_Balance__c bal : [
                        SELECT Id,
                                AcctSeedERP__Location__c,
                                AcctSeedERP__Product__c,
                                AcctSeedERP__Product__r.AcctSeed__Inventory_GL_Account__c,
                                AcctSeedERP__Product__r.AcctSeedERP__Serialized__c,
                                AcctSeedERP__Product__r.GMBLASERP__Lot_Tracked__c,
                                AcctSeedERP__Warehouse__c
                        FROM AcctSeedERP__Inventory_Balance__c
                        WHERE Id IN :mapInventoryBalance.keySet()
                ]) {
                    mapInventoryBalance.put(bal.Id, bal);
                }

                //map the serial numbers
                if (mapSerial.size() > 0)
                    for (GMBLASERP__Serial_Number__c serial : [
                            SELECT Id,
                                    GMBLASERP__Lot__c,
                                    GMBLASERP__Product__c
                            FROM GMBLASERP__Serial_Number__c
                            WHERE Id IN :mapSerial.keySet()
                    ]) {
                        mapSerial.put(serial.Id, serial);
                    }

                //map the lots
                if (mapLot.size() > 0)
                    for (GMBLASERP__Lot__c lot : [
                            SELECT Id,
                                    GMBLASERP__Product__c
                            FROM GMBLASERP__Lot__c
                            WHERE Id IN :mapLot.keySet()
                    ]) {
                        mapLot.put(lot.Id, lot);
                    }


                Boolean boolIsInboundMove = false;
                Boolean boolIsManufacturingMove = false;
                Boolean boolIsOutboundMove = false;
                Boolean boolIsPurchaseMove = false;
                Boolean boolIsSalesMove = false;
                System.debug('SOBJ Name');
                System.debug(listNew.getSObjectType().getDescribe().getName());
                if (listNew.getSObjectType() == AcctSeedERP__Inbound_Inventory_Movement__c.sObjectType)
                    boolIsInboundMove = true; else if (listNew.getSObjectType() == AcctSeedERP__Manufacturing_Inventory_Movement__c.sObjectType)
                    boolIsManufacturingMove = true; else if (listNew.getSObjectType() == AcctSeedERP__Outbound_Inventory_Movement__c.sObjectType)
                    boolIsOutboundMove = true; else if (listNew.getSObjectType() == AcctSeedERP__Purchase_Order_Inventory_Movement__c.sObjectType)
                    boolIsPurchaseMove = true; else if (listNew.getSObjectType() == AcctSeedERP__Sales_Order_Inventory_Movement__c.sObjectType)
                    boolIsSalesMove = true;

                list<sObject> listMoveNeedsUnitCost = new list<sObject>();

                for (sObject move : listNew) {
                    AcctSeedERP__Inventory_Balance__c balance = mapInventoryBalance.get((Id) move.get('AcctSeedERP__Inventory_Balance__c'));
                    Product2 product = balance.AcctSeedERP__Product__r;

                    Id idSerial = (Id) move.get('GMBLASERP__Serial_Number__c');
                    Id idLot = (Id) move.get('GMBLASERP__Lot__c');

                    /*** AUTOMATED FIELD SETTING ***/

                    //if there is a serial number, set the Lot of the movement to the Lot of the serial number
                    if (idSerial != null)
                        move.put('GMBLASERP__Lot__c', mapSerial.get(idSerial).GMBLASERP__Lot__c);

                    //if the quantity is blank, set the quantity to zero
                    if ((Decimal) move.get('AcctSeedERP__Quantity__c') == null)
                        move.put('AcctSeedERP__Quantity__c', 0);

                    //round the quantity to six decimals
                    move.put('AcctSeedERP__Quantity__c', ((Decimal) move.get('AcctSeedERP__Quantity__c')).setScale(6));

                    //do not allow manipulation of the Inventory GL Amount; it is updated in the AFTER context
                    if (boolIsSalesMove) {
                        move.put('GMBLASERP__Inventory_GL_Amount__c', 0);
                    } else if (boolIsInsert) {
                        move.put('GMBLASERP__Inventory_GL_Amount__c', 0);
                    } else if ((Decimal) move.get('GMBLASERP__Inventory_GL_Amount__c') == null) {
                        move.put('GMBLASERP__Inventory_GL_Amount__c', 0);
                    }

                    //the intended purpose of populating these fields is (only) to support the placement of related lists of movements on
                    //the pages for Location, Product, and Warehouse
                    move.put('GMBLASERP__Location__c', balance.AcctSeedERP__Location__c);
                    move.put('GMBLASERP__Product__c', balance.AcctSeedERP__Product__c);
                    move.put('GMBLASERP__Warehouse__c', balance.AcctSeedERP__Warehouse__c);

                    if (boolIsUpdate) {
                        Decimal decNew = (Decimal) move.get('GMBLASERP__Inventory_GL_Amount__c');
                        Decimal decOld = (Decimal) (oldMap.get(move.Id).get('GMBLASERP__Inventory_GL_Amount__c'));
                        if (decNew == null) decNew = 0;
                        if (decOld == null) decOld = 0;

                        if (decOld.setScale(6) != decNew.setScale(6))
                            move.addError('The Inventory GL Amount may not be directly manipulated.');
                    }

                    if (boolIsInboundMove || boolIsOutboundMove) {
                        if ((String) move.get('GMBLASERP__Inventory_Transfer__c') != null) {
                            move.put('AcctSeedERP__Type__c', 'Non-Accounting');
                            move.put('AcctSeedERP__Unit_Cost__c', 0);
                        }

                        if (boolIsInsert && (String) move.get('AcctSeedERP__Type__c') != 'Non-Accounting')
                            move.put('AcctSeedERP__Type__c', 'Accounting');

                        if (boolIsInboundMove)
                            move.put('AcctSeedERP__Debit_GL_Account__c', product.AcctSeed__Inventory_GL_Account__c); else
                                move.put('AcctSeedERP__Credit_GL_Account__c', product.AcctSeed__Inventory_GL_Account__c);
                    }

                    /*** VALIDATIONS ***/

                    if (product.AcctSeedERP__Serialized__c && idSerial == NULL) {
                        move.addError('The Movement must specify a Serial Number, because the Product is serialized.');
                    } else if (!product.AcctSeedERP__Serialized__c && idSerial != NULL) {
                        move.addError('The Movement must not specify a Serial Number, because the Product is not serialized.');
                    } else if (product.AcctSeedERP__Serialized__c &&
                            (Decimal) move.get('AcctSeedERP__Quantity__c') != 1 &&
                            (Decimal) move.get('AcctSeedERP__Quantity__c') != -1 &&
                            (Decimal) move.get('AcctSeedERP__Quantity__c') != 0) {
                        move.addError('Movements of serialized products must have a quantity of 1, -1, or 0.');
                    } else if (idSerial != null && mapSerial.get(idSerial).GMBLASERP__Product__c != product.Id) {
                        move.addError('The Product of the Serial Number must match the Product of the Inventory Balance.');
                    } else if (idSerial != null && idLot != null && mapSerial.get(idSerial).GMBLASERP__Product__c != mapLot.get(idLot).GMBLASERP__Product__c) {
                        move.addError('The Product of the Serial Number must match the Product of the Lot.');
                    } else if (product.GMBLASERP__Lot_Tracked__c && idLot == NULL) {
                        move.addError('The Movement must specify a Lot, because the Product is Lot-Tracked.');
                    } else if (!product.GMBLASERP__Lot_Tracked__c && idLot != NULL) {
                        move.addError('The Movement must not specify a Lot, because the Product is not Lot-Tracked.');
                    } else if (idLot != null && mapLot.get(idLot).GMBLASERP__Product__c != product.Id) {
                        move.addError('The Product of the Lot must match the Product of the Inventory Balance.');
                    } else if (boolIsUpdate && idSerial != (Id) oldMap.get(move.Id).get('GMBLASERP__Serial_Number__c')) {
                        move.addError('The Serial Number of an inventory movement cannot be changed.  If necessary, delete or reverse the inventory movement.');
                    } else if (boolIsUpdate && idLot != (Id) oldMap.get(move.Id).get('GMBLASERP__Lot__c')) {
                        move.addError('The Lot of an inventory movement cannot be changed.  If necessary, delete or reverse the inventory movement.');
                    }

                    if (boolIsInsert && !boolIsPurchaseMove && !(Boolean) move.get('GMBLASERP__Cost_Override__c'))
                        listMoveNeedsUnitCost.add(move);
                }

                if (listMoveNeedsUnitCost.size() > 0) {
                    System.debug('listMoveNeedsUnitCost');
                    System.debug(listMoveNeedsUnitCost);
                    assignUnitCost(listMoveNeedsUnitCost);
                }

                for (sObject move : listNew) {
                    if ((Decimal) move.get('AcctSeedERP__Unit_Cost__c') < 0) {
                        move.addError('The unit cost of a movement cannot be negative; if necessary, make the quantity negative.');
                    } else if ((Decimal) move.get('AcctSeedERP__Unit_Cost__c') == null) {
                        move.put('AcctSeedERP__Unit_Cost__c', 0);
                    }
                    //round the cost to six decimals
                    move.put('AcctSeedERP__Unit_Cost__c', ((Decimal) move.get('AcctSeedERP__Unit_Cost__c')).setScale(6));
                }
            }
        }
        else if(!boolIsBefore)
        {
            map<Id,Decimal> mapQty = new map<Id,Decimal>();
            map<Id,Decimal> mapAmt = new map<Id,Decimal>();

            set<Id> setIdBalance = new set<Id>();
            set<Id> setIdProduct = new set<Id>();
            set<Id> setIdLot = new set<Id>();
            set<Id> setIdSerial = new set<Id>();

            list<sObject> listMove = new list<sObject>();
            Set<Id> setCheckPosted  = new Set<Id>();
            //prepare to map the inventory balances, lots, and serial numbers
            for(sObject move : listNew)
            {
                if(boolIsUpdate){
                    String moveStatus = (String) move.get('AcctSeedERP__Status__c');
                    String oldMoveStatus = (String) oldMap.get(move.Id).get('AcctSeedERP__Status__c');
                    if(moveStatus == 'Posted' && oldMoveStatus != moveStatus){
                        setCheckPosted.add(move.Id);
                    }
                }
            }
            System.debug('Before ' + Limits.getQueries());
            if(setCheckPosted.isEmpty()) {
                if(boolIsInsert || boolIsUpdate)
                    updateInventoryGlAmount(newMap.keySet());

                listMove.addAll(listNew);
                listMove.addAll(oldMap.values());
                System.debug('After delete ' + Trigger.isDelete);
                System.debug('After update inventory ' + Limits.getQueries());
                GCR_InventoryMovementCube.recalc(listMove);
                System.debug('After recalc ' + Limits.getQueries());
                for (sObject move : listMove) {
                    Id idBalance = (Id) move.get('AcctSeedERP__Inventory_Balance__c');
                    Id idLot = (Id) move.get('GMBLASERP__Lot__c');
                    Id idSerial = (Id) move.get('GMBLASERP__Serial_Number__c');

                    setIdBalance.add(idBalance);
                    mapQty.put(idBalance, 0);
                    mapAmt.put(idBalance, 0);

                    if (idLot != null) {
                        setIdLot.add(idLot);
                        mapQty.put(idLot, 0);
                        mapAmt.put(idLot, 0);
                    }
                    if (idSerial != null) {
                        setIdSerial.add(idSerial);
                        mapQty.put(idSerial, 0);
                        mapAmt.put(idSerial, 0);
                    }
                }

                map<Id, Id> mapBalanceToProduct = new map<Id, Id>();
                for (AcctSeedERP__Inventory_Balance__c bal : [SELECT Id, AcctSeedERP__Product__c FROM AcctSeedERP__Inventory_Balance__c WHERE Id IN :setIdBalance]) {
                    setIdProduct.add(bal.AcctSeedERP__Product__c);
                    mapQty.put(bal.AcctSeedERP__Product__c, 0);
                    mapAmt.put(bal.AcctSeedERP__Product__c, 0);
                    mapBalanceToProduct.put(bal.Id, bal.AcctSeedERP__Product__c);
                }

                setIdBalance.remove(null);
                setIdProduct.remove(null);
                setIdLot.remove(null);
                setIdSerial.remove(null);

                list<AggregateResult> listAggRes = new list<AggregateResult>();

                listAggRes.addAll([SELECT GMBLASERP__Inventory_Balance__c idBalance, sum(GMBLASERP__Quantity__c) qty FROM GMBLASERP__Inventory_Movement_Cube__c WHERE GMBLASERP__Inventory_Balance__c IN :setIdBalance GROUP BY GMBLASERP__Inventory_Balance__c]);
                for (sObject aggRes : listAggRes) {
                    mapQty.put((Id) aggRes.get('idBalance'), (Decimal) aggRes.get('qty'));
                }

                listAggRes.clear();
                listAggRes.addAll([SELECT GMBLASERP__Product__c idProduct, sum(GMBLASERP__Inventory_GL_Amount__c) amt, sum(GMBLASERP__Quantity__c) qty FROM GMBLASERP__Inventory_Movement_Cube__c WHERE GMBLASERP__Product__c IN :setIdProduct GROUP BY GMBLASERP__Product__c]);
                for (sObject aggRes : listAggRes) {
                    mapQty.put((Id) aggRes.get('idProduct'), (Decimal) aggRes.get('qty'));
                    mapAmt.put((Id) aggRes.get('idProduct'), (Decimal) aggRes.get('amt'));
                }

                listAggRes.clear();
                listAggRes.addAll([SELECT GMBLASERP__Lot__c idLot, sum(GMBLASERP__Inventory_GL_Amount__c) amt, sum(GMBLASERP__Quantity__c) qty FROM GMBLASERP__Inventory_Movement_Cube__c WHERE GMBLASERP__Lot__c IN :setIdLot GROUP BY GMBLASERP__Lot__c]);
                for (sObject aggRes : listAggRes) {
                    mapQty.put((Id) aggRes.get('idLot'), (Decimal) aggRes.get('qty'));
                    mapAmt.put((Id) aggRes.get('idLot'), (Decimal) aggRes.get('amt'));
                }

                listAggRes.clear();
                listAggRes.addAll([SELECT GMBLASERP__Serial_Number__c idSerial, sum(GMBLASERP__Inventory_GL_Amount__c) amt, sum(GMBLASERP__Quantity__c) qty FROM GMBLASERP__Inventory_Movement_Cube__c WHERE GMBLASERP__Serial_Number__c IN :setIdSerial GROUP BY GMBLASERP__Serial_Number__c]);
                for (sObject aggRes : listAggRes) {
                    mapQty.put((Id) aggRes.get('idSerial'), (Decimal) aggRes.get('qty'));
                    mapAmt.put((Id) aggRes.get('idSerial'), (Decimal) aggRes.get('amt'));
                }

                for (sObject move : listMove) {
                    Id idBalance = (Id) move.get('AcctSeedERP__Inventory_Balance__c');
                    Id idLot = (Id) move.get('GMBLASERP__Lot__c');
                    Id idSerial = (Id) move.get('GMBLASERP__Serial_Number__c');
                    Id idProduct = mapBalanceToProduct.get(idBalance);

                    sObject errorTarget = move;
                    if (boolIsUpdate)
                        errorTarget = newMap.get(move.Id);

                    if (mapQty.get(idBalance) < 0)
                        errorTarget.addError('The movement cannot be completed because it would result in negative quantity at Inventory Balance ' + idBalance);

                    else if (mapQty.get(idProduct) != null && mapQty.get(idProduct) < 0)
                        errorTarget.addError('The movement cannot be completed because it would result in negative quantity for Product ' + idProduct);

                    else if (mapQty.get(idLot) != null && mapQty.get(idLot) < 0)
                        errorTarget.addError('The movement cannot be completed because it would result in negative quantity for Lot ' + idLot);

                    else if (mapQty.get(idSerial) != null && mapQty.get(idSerial) != 0 && mapQty.get(idSerial) != 1)
                        errorTarget.addError('The movement cannot be completed because it would result in quantity other than 0 or 1 for Serial Number ' + idSerial);

                    else if (mapAmt.get(idProduct) != null && (mapAmt.get(idProduct)).setScale(2) < 0)
                        errorTarget.addError('The movement cannot be completed because it would result in negative GL balance for Product ' + idProduct);

                    else if (mapAmt.get(idLot) != null && (mapAmt.get(idLot)).setScale(2) < 0)
                        errorTarget.addError('The movement cannot be completed because it would result in negative GL balance for Lot ' + idLot);

                    else if (mapAmt.get(idSerial) != null && (mapAmt.get(idSerial)).setScale(2) < 0)
                        errorTarget.addError('The movement cannot be completed because it would result in negative GL balance for Serial Number ' + idSerial);
                }


                //determine the inventory balance under which each serial number is currently located
                map<Id, Id> mapSerialToBalance = new map<Id, Id>();
                listAggRes.clear();
                listAggRes.addAll([SELECT GMBLASERP__Inventory_Balance__c idBalance, GMBLASERP__Serial_Number__c idSerial FROM GMBLASERP__Inventory_Movement_Cube__c WHERE GMBLASERP__Serial_Number__c IN :setIdSerial GROUP BY GMBLASERP__Inventory_Balance__c, GMBLASERP__Serial_Number__c HAVING sum(GMBLASERP__Quantity__c) = 1]);
                System.debug('Test Debug');
                System.debug(Trigger.isAfter);
                System.debug(Trigger.isBefore);
                System.debug(Trigger.isInsert);
                System.debug(Trigger.isUpdate);
                System.debug(listNew);
                System.debug(listNew.getSObjectType());
                for (sObject aggRes : listAggRes) {
                    mapSerialToBalance.put((Id) aggRes.get('idSerial'), (Id) aggRes.get('idBalance'));
                }

                list<GMBLASERP__Serial_Number__c> listSerialUpdate = new list<GMBLASERP__Serial_Number__c>();
                for (GMBLASERP__Serial_Number__c s : [SELECT Id, GMBLASERP__Inventory_Balance__c FROM GMBLASERP__Serial_Number__c WHERE Id IN :setIdSerial]) {
                    Id idBalance = mapSerialToBalance.get(s.Id);
                    if (s.GMBLASERP__Inventory_Balance__c != idBalance) {
                        s.GMBLASERP__Inventory_Balance__c = idBalance;
                        listSerialUpdate.add(s);
                    }
                }

                if (listSerialUpdate.size() > 0) update listSerialUpdate;
                if(!disableFSL)
                {
                    List<SObject> listAll = new List<SObject>();
                    if (boolIsInsert)
                        listAll.addAll(listNew);
                    else if (boolIsDelete) listAll.addAll(oldMap.values());
                    else if (boolIsUpdate) {
                        for (SObject pol : listNew) {
                            if (pol.get('AcctSeedERP__Quantity__c') != oldMap.get(pol.Id).get('AcctSeedERP__Quantity__c')) {
                                SObject polNew = pol.clone(false, true);
                                polNew.put('AcctSeedERP__Quantity__c', ((Decimal) pol.get('AcctSeedERP__Quantity__c') - (Decimal) oldMap.get(pol.Id).get('AcctSeedERP__Quantity__c')));
                                listAll.add(polNew);
                            }
                        }
                    }
                    if (!listAll.isEmpty()) {
                        List<AcctSeedMovementWrapper_FSL> listWrapPOL = AcctSeedMovementWrapper_FSL.generateMovementWrapperVoid(listAll);
                        Inventory_Service.createPI_FSL(listWrapPOL, 'Inbound');
                    }
                }
            }
        }
    }

    public static void updateInventoryGlAmount(set<Id> setIdMove)
    {
        setIdMove.remove(null);
        if(setIdMove.size() == 0) return;

        list<Id> listIdMove = new list<Id>(setIdMove);

        String objectName = listIdMove[0].getSObjectType().getDescribe().getName();
        listIdMove.clear();

        //if(objectName == 'AcctSeedERP__Sales_Order_Inventory_Movement__c') return;

        String soql = '';
        soql += ' SELECT Id, AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__r.AcctSeed__Inventory_GL_Account__c, GMBLASERP__Inventory_GL_Amount__c, ';
        soql += ' (SELECT Id, AcctSeed__Amount__c, AcctSeed__GL_Account__c FROM AcctSeedERP__Transactions__r WHERE AcctSeed__Amount__c < 0 OR AcctSeed__Amount__c > 0) ';
        soql += ' FROM ' + objectName + ' ';
        soql += ' WHERE Id IN :setIdMove ';
        System.debug('Updating GL Amount');
        if(objectName == 'AcctSeedERP__Inbound_Inventory_Movement__c')
        {
            list<AcctSeedERP__Inbound_Inventory_Movement__c> listMoveUpdate = new list<AcctSeedERP__Inbound_Inventory_Movement__c>();

            for(AcctSeedERP__Inbound_Inventory_Movement__c move : Database.query(soql))
            {
                Decimal amtTxn = 0;
                for(AcctSeed__Transaction__c txn : move.AcctSeedERP__Transactions__r)
                {
                    if(txn.AcctSeed__GL_Account__c == move.AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__r.AcctSeed__Inventory_GL_Account__c && txn.AcctSeed__Amount__c != null)
                        amtTxn += txn.AcctSeed__Amount__c;
                }

                if(move.GMBLASERP__Inventory_GL_Amount__c == null || move.GMBLASERP__Inventory_GL_Amount__c.setScale(6) != amtTxn.setScale(6))
                {
                    move.GMBLASERP__Inventory_GL_Amount__c = amtTxn.setScale(6);
                    listMoveUpdate.add(move);
                }
            }

            if(listMoveUpdate.size() > 0)
            {
                Boolean boolOld = gcInboundInventoryMovement.disableTrigger;
                gcInboundInventoryMovement.disableTrigger = true;
                update listMoveUpdate;
                gcInboundInventoryMovement.disableTrigger = boolOld;
            }
        }

        else if(objectName == 'AcctSeedERP__Manufacturing_Inventory_Movement__c')
        {
            list<AcctSeedERP__Manufacturing_Inventory_Movement__c> listMoveUpdate = new list<AcctSeedERP__Manufacturing_Inventory_Movement__c>();

            for(AcctSeedERP__Manufacturing_Inventory_Movement__c move : Database.query(soql))
            {
                Decimal amtTxn = 0;
                for(AcctSeed__Transaction__c txn : move.AcctSeedERP__Transactions__r)
                {
                    if(txn.AcctSeed__GL_Account__c == move.AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__r.AcctSeed__Inventory_GL_Account__c && txn.AcctSeed__Amount__c != null)
                        amtTxn -= txn.AcctSeed__Amount__c;
                }

                if(move.GMBLASERP__Inventory_GL_Amount__c == null || move.GMBLASERP__Inventory_GL_Amount__c.setScale(6) != amtTxn.setScale(6))
                {
                    move.GMBLASERP__Inventory_GL_Amount__c = amtTxn.setScale(6);
                    listMoveUpdate.add(move);
                }
            }

            if(listMoveUpdate.size() > 0)
            {
                Boolean boolOld = gcManufacturingInventoryMovement.disableTrigger;
                gcManufacturingInventoryMovement.disableTrigger = true;
                update listMoveUpdate;
                gcManufacturingInventoryMovement.disableTrigger = boolOld;
            }
        }

        else if(objectName == 'AcctSeedERP__Outbound_Inventory_Movement__c')
        {
            list<AcctSeedERP__Outbound_Inventory_Movement__c> listMoveUpdate = new list<AcctSeedERP__Outbound_Inventory_Movement__c>();

            for(AcctSeedERP__Outbound_Inventory_Movement__c move : Database.query(soql))
            {
                Decimal amtTxn = 0;
                for(AcctSeed__Transaction__c txn : move.AcctSeedERP__Transactions__r)
                {
                    if(txn.AcctSeed__GL_Account__c == move.AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__r.AcctSeed__Inventory_GL_Account__c && txn.AcctSeed__Amount__c != null)
                        amtTxn -= txn.AcctSeed__Amount__c;
                }

                if(move.GMBLASERP__Inventory_GL_Amount__c == null || move.GMBLASERP__Inventory_GL_Amount__c.setScale(6) != amtTxn.setScale(6))
                {
                    move.GMBLASERP__Inventory_GL_Amount__c = amtTxn.setScale(6);
                    listMoveUpdate.add(move);
                }
            }

            if(listMoveUpdate.size() > 0)
            {
                Boolean boolOld = gcOutboundInventoryMovement.disableTrigger;
                gcOutboundInventoryMovement.disableTrigger = true;
                update listMoveUpdate;
                gcOutboundInventoryMovement.disableTrigger = boolOld;
            }
        }

        else if(objectName == 'AcctSeedERP__Purchase_Order_Inventory_Movement__c')
        {
            list<AcctSeedERP__Purchase_Order_Inventory_Movement__c> listMoveUpdate = new list<AcctSeedERP__Purchase_Order_Inventory_Movement__c>();

            for(AcctSeedERP__Purchase_Order_Inventory_Movement__c move : Database.query(soql))
            {
                Decimal amtTxn = 0;
                for(AcctSeed__Transaction__c txn : move.AcctSeedERP__Transactions__r)
                {
                    if(txn.AcctSeed__GL_Account__c == move.AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__r.AcctSeed__Inventory_GL_Account__c && txn.AcctSeed__Amount__c != null)
                        amtTxn += txn.AcctSeed__Amount__c;
                }

                if(move.GMBLASERP__Inventory_GL_Amount__c == null || move.GMBLASERP__Inventory_GL_Amount__c.setScale(6) != amtTxn.setScale(6))
                {
                    move.GMBLASERP__Inventory_GL_Amount__c = amtTxn.setScale(6);
                    listMoveUpdate.add(move);
                }
            }

            if(listMoveUpdate.size() > 0)
            {
                Boolean boolOld = gcPurchaseOrderInventoryMovement.disableTrigger;
                Boolean boolOld2 = gcPurchaseOrderLine.disableTrigger;
                Boolean boolOld3 = gcPurchaseOrder.disableTrigger;
                gcPurchaseOrderInventoryMovement.disableTrigger = true;
                gcPurchaseOrderLine.disableTrigger = true;
                gcPurchaseOrder.disableTrigger = true;
                update listMoveUpdate;
                gcPurchaseOrderInventoryMovement.disableTrigger = boolOld;
                gcPurchaseOrderLine.disableTrigger = boolOld2;
                gcPurchaseOrder.disableTrigger = boolOld3;
            }
        }
    }

    private static void assignUnitCost(list<sObject> listMove)
    {
        if(listMove.isEmpty()) return;

        map<Date,map<string,set<Id>>> mapFilter = new map<Date,map<string,set<Id>>>();
        map<Date,map<Id,Decimal>> mapCost = new map<Date, map<Id,Decimal>>();
        map<Id,AcctSeedERP__Inventory_Balance__c> mapBalance = new map<Id,AcctSeedERP__Inventory_Balance__c>();

        set<Id> setIdSerial = new set<Id>();
        set<Id> setIdLot = new set<Id>();
        set<Id> setIdProduct = new set<Id>();

        for(sObject move : listMove)
        {
            if(move.get('GMBLASERP__Lot__c') == null && move.get('GMBLASERP__Serial_Number__c') == null)
                mapBalance.put((Id)move.get('AcctSeedERP__Inventory_Balance__c'), null);
        }

        for(AcctSeedERP__Inventory_Balance__c bal : [SELECT Id, AcctSeedERP__Product__c FROM AcctSeedERP__Inventory_Balance__c WHERE Id IN :mapBalance.keySet()])
            mapBalance.put(bal.Id,bal);

        for(sObject move : listMove)
        {
            Date dateMove = (Date)move.get('AcctSeedERP__Movement_Date__c');
            if(dateMove == null)
            {
                dateMove = date.today();
                move.put('AcctSeedERP__Movement_Date__c',dateMove);
            }

            if(!mapFilter.containsKey(dateMove))
            {
                mapFilter.put(dateMove, new map<string,set<Id>>());
                mapCost.put(dateMove, new map<Id,Decimal>());
            }

            if(move.get('GMBLASERP__Serial_Number__c') != null)
            {
                Id idSerial = (Id)move.get('GMBLASERP__Serial_Number__c');

                if(!mapFilter.get(dateMove).containsKey('idSerial'))
                    mapFilter.get(dateMove).put('idSerial', new set<Id>());
                mapFilter.get(dateMove).get('idSerial').add(idSerial);
                mapCost.get(dateMove).put(idSerial,0);
                setIdSerial.add(idSerial);
            }
            else if(move.get('GMBLASERP__Lot__c') != null)
            {
                Id idLot = (Id)move.get('GMBLASERP__Lot__c');

                if(!mapFilter.get(dateMove).containsKey('idLot'))
                    mapFilter.get(dateMove).put('idLot', new set<Id>());
                mapFilter.get(dateMove).get('idLot').add(idLot);
                mapCost.get(dateMove).put(idLot,0);
                setIdLot.add(idLot);
            }
            else
            {
                Id idProduct = mapBalance.get((Id)move.get('AcctSeedERP__Inventory_Balance__c')).AcctSeedERP__Product__c;

                if(!mapFilter.get(dateMove).containsKey('idProduct'))
                    mapFilter.get(dateMove).put('idProduct', new set<Id>());
                mapFilter.get(dateMove).get('idProduct').add(idProduct);
                mapCost.get(dateMove).put(idProduct,0);
                setIdProduct.add(idProduct);
            }
        }

        for(Date moveDate :mapFilter.keySet())
        {
            set<Id> setIdObject = new set<Id>();

            if(mapFilter.get(moveDate).containsKey('idSerial'))
            {
                setIdObject = mapFilter.get(moveDate).get('idSerial');
                setIdObject.remove(null);

                for(AggregateResult aggRes :
                [SELECT GMBLASERP__Serial_Number__c idSerial, sum(GMBLASERP__Quantity__c) qty, sum(GMBLASERP__Inventory_GL_Amount__c) amt
                FROM GMBLASERP__Inventory_Movement_Cube__c
                WHERE GMBLASERP__Serial_Number__c IN :setIdObject
                AND GMBLASERP__Movement_Date__c <= :moveDate
                GROUP BY GMBLASERP__Serial_Number__c
                HAVING sum(GMBLASERP__Quantity__c) < 0 OR sum(GMBLASERP__Quantity__c) > 0 OR sum(GMBLASERP__Inventory_GL_Amount__c) < 0 OR sum(GMBLASERP__Inventory_GL_Amount__c) > 0])
                {
                    Id idSerial = (Id)aggRes.get('idSerial');
                    if(idSerial == null) continue;
                    Decimal qty = (Decimal)aggRes.get('qty');
                    Decimal amt = (Decimal)aggRes.get('amt');

                    if(qty == null) qty = 0;
                    if(amt == null) amt = 0;
                    if(qty == 0 && amt == 0) continue;

                    Decimal avg = 0;
                    if(qty != 0) avg = amt/qty;

                    if(avg < 0) avg = 0;

                    mapCost.get(moveDate).put(idSerial,avg);
                }
            }

            if(mapFilter.get(moveDate).containsKey('idLot'))
            {
                setIdObject = mapFilter.get(moveDate).get('idLot');
                setIdObject.remove(null);

                for(AggregateResult aggRes :
                [SELECT GMBLASERP__Lot__c idLot, sum(GMBLASERP__Quantity__c) qty, sum(GMBLASERP__Inventory_GL_Amount__c) amt
                FROM GMBLASERP__Inventory_Movement_Cube__c
                WHERE GMBLASERP__Lot__c IN :setIdObject
                AND GMBLASERP__Movement_Date__c <= :moveDate
                GROUP BY GMBLASERP__Lot__c
                HAVING sum(GMBLASERP__Quantity__c) < 0 OR sum(GMBLASERP__Quantity__c) > 0 OR sum(GMBLASERP__Inventory_GL_Amount__c) < 0 OR sum(GMBLASERP__Inventory_GL_Amount__c) > 0])
                {
                    Id idLot = (Id)aggRes.get('idLot');
                    if(idLot == null) continue;
                    Decimal qty = (Decimal)aggRes.get('qty');
                    Decimal amt = (Decimal)aggRes.get('amt');

                    if(qty == null) qty = 0;
                    if(amt == null) amt = 0;
                    if(qty == 0 && amt == 0) continue;

                    Decimal avg = 0;
                    if(qty != 0) avg = amt/qty;

                    if(avg < 0) avg = 0;

                    mapCost.get(moveDate).put(idLot,avg);
                }
            }

            if(mapFilter.get(moveDate).containsKey('idProduct'))
            {
                setIdObject = mapFilter.get(moveDate).get('idProduct');
                setIdObject.remove(null);

                for(AggregateResult aggRes :
                [SELECT GMBLASERP__Product__c idProduct, sum(GMBLASERP__Quantity__c) qty, sum(GMBLASERP__Inventory_GL_Amount__c) amt
                FROM GMBLASERP__Inventory_Movement_Cube__c
                WHERE GMBLASERP__Product__c IN :setIdObject
                AND GMBLASERP__Movement_Date__c <= :moveDate
                GROUP BY GMBLASERP__Product__c
                HAVING sum(GMBLASERP__Quantity__c) < 0 OR sum(GMBLASERP__Quantity__c) > 0 OR sum(GMBLASERP__Inventory_GL_Amount__c) < 0 OR sum(GMBLASERP__Inventory_GL_Amount__c) > 0])
                {
                    Id idProduct = (Id)aggRes.get('idProduct');
                    if(idProduct == null) continue;
                    Decimal qty = (Decimal)aggRes.get('qty');
                    Decimal amt = (Decimal)aggRes.get('amt');

                    if(qty == null) qty = 0;
                    if(amt == null) amt = 0;
                    if(qty == 0 && amt == 0) continue;

                    Decimal avg = 0;
                    if(qty != 0) avg = amt/qty;

                    if(avg < 0) avg = 0;

                    mapCost.get(moveDate).put(idProduct,avg);
                }
            }
        }

        list<sObject> listMoveDefaultCost = new list<sObject>();

        Decimal positiveForInbound;

        if     (listMove[0].getSObjectType() == AcctSeedERP__Inbound_Inventory_Movement__c.sObjectType)
            positiveForInbound = 1;
        else if(listMove[0].getSObjectType() == AcctSeedERP__Manufacturing_Inventory_Movement__c.sObjectType)
            positiveForInbound = -1;
        else if(listMove[0].getSObjectType() == AcctSeedERP__Outbound_Inventory_Movement__c.sObjectType)
            positiveForInbound = -1;
        else if(listMove[0].getSObjectType() == AcctSeedERP__Purchase_Order_Inventory_Movement__c.sObjectType)
            positiveForInbound = 0;
        else if(listMove[0].getSObjectType() == AcctSeedERP__Sales_Order_Inventory_Movement__c.sObjectType)
            positiveForInbound = -1;

        for(sObject move : listMove)
        {
            Date dateMove = (Date)move.get('AcctSeedERP__Movement_Date__c');

            if(move.get('GMBLASERP__Serial_Number__c') != null)
                move.put('AcctSeedERP__Unit_Cost__c', mapCost.get(dateMove).get((Id)move.get('GMBLASERP__Serial_Number__c')));
            else if(move.get('GMBLASERP__Lot__c') != null)
                move.put('AcctSeedERP__Unit_Cost__c', mapCost.get(dateMove).get((Id)move.get('GMBLASERP__Lot__c')));
            else
            {
                Id idProduct = mapBalance.get((Id)move.get('AcctSeedERP__Inventory_Balance__c')).AcctSeedERP__Product__c;
                move.put('AcctSeedERP__Unit_Cost__c', mapCost.get(dateMove).get(idProduct));
            }

            //if all else fails, make sure to set the unit cost to zero (as opposed to null), so that the AcctSeedERP managed code does not set the unit cost.
            if(move.get('AcctSeedERP__Unit_Cost__c') == null) move.put('AcctSeedERP__Unit_Cost__c',0);

            //if the unit cost is zero, and if this is a non-purchasing movement that will cause inventory to go up, then use the Unit Cost that is stored on the Product record (i.e. the default unit cost)
            Decimal unitCost = (Decimal)move.get('AcctSeedERP__Unit_Cost__c');
            unitCost = (unitCost == null ? 0 : unitCost);
            Decimal qty = (Decimal)move.get('AcctSeedERP__Quantity__c');
            qty = (qty == null ? 0 : qty);

            if(unitCost == 0 && positiveForInbound != 0)
            {
                qty *= positiveForInbound;

                if(qty >= 0)
                {
                    listMoveDefaultCost.add(move);
                    mapBalance.put((Id)move.get('AcctSeedERP__Inventory_Balance__c'), null);
                }
            }
        }

        if(!listMoveDefaultCost.isEmpty())
        {
            mapBalance.remove(null);
            for(AcctSeedERP__Inventory_Balance__c bal :
            [SELECT Id,
                    AcctSeedERP__Product__c,
                    AcctSeedERP__Product__r.AcctSeed__Unit_Cost__c
            FROM AcctSeedERP__Inventory_Balance__c
            WHERE Id IN : mapBalance.keySet()])
            {
                mapBalance.put(bal.Id,bal);
            }

            for(sObject move : listMoveDefaultCost)
            {
                AcctSeedERP__Inventory_Balance__c bal = mapBalance.get((Id)move.get('AcctSeedERP__Inventory_Balance__c'));
                if(bal != null && bal.AcctSeedERP__Product__r.AcctSeed__Unit_Cost__c > 0)
                    move.put('AcctSeedERP__Unit_Cost__c', bal.AcctSeedERP__Product__r.AcctSeed__Unit_Cost__c);
            }
        }
    }
}