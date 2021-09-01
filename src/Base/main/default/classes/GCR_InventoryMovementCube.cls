/**
 * Created by Legend on 28/7/21.
 */

public without sharing class GCR_InventoryMovementCube {

    public static void recalc(list<sObject> listMove)
    {
        //collect the earliest and latest move date, of the moves that have been passed in.
        //then convert this to the start date of the earliest month, and the end date of the latest month.
        //then create a map of days to periods.

        if(listMove.size() == 0) return;

        String moveType = listMove[0].getSObjectType().getDescribe().getName();
        map<Id,map<Id,map<Id,map<Date,wrapCube>>>> mapBLSDC = new map<Id,map<Id,map<Id,map<Date,wrapCube>>>>(); // map Balance-Lot-Serial-Date to Cube

        list<wrapCube> listWrapCube = new list<wrapCube>();

        set<Id> setIdBalance = new set<Id>();
        set<Id> setIdLot = new set<Id>();
        set<Id> setIdSerial = new set<Id>();
        set<Date> setDate = new set<Date>();

        //cycle over the moves to identify all of the Inventory Movement Cubes that are relevant to this update
        for(sObject obj : listMove)
        {
            Id idBalance = (Id)obj.get('AcctSeedERP__Inventory_Balance__c');
            Id idLot = (Id)obj.get('GMBLASERP__Lot__c');
            Id idSerial = (Id)obj.get('GMBLASERP__Serial_Number__c');
            Date moveDate = (Date)obj.get('AcctSeedERP__Movement_Date__c');

            if(!mapBLSDC.containsKey(idBalance))
            {
                mapBLSDC.put(idBalance, new map<Id,map<Id,map<Date,wrapCube>>>());
                setIdBalance.add(idBalance);
            }

            map<Id,map<Id,map<Date,wrapCube>>> mapLSDC = mapBLSDC.get(idBalance);

            if(!mapLSDC.containsKey(idLot))
            {
                mapLSDC.put(idLot, new map<Id,map<Date,wrapCube>>());
                setIdLot.add(idLot);
            }

            map<Id,map<Date,wrapCube>> mapSDC = mapLSDC.get(idLot);

            if(!mapSDC.containsKey(idSerial))
            {
                mapSDC.put(idSerial, new map<Date,wrapCube>());
                setIdSerial.add(idSerial);
            }

            map<Date,wrapCube> mapDC = mapSDC.get(idSerial);

            if(!mapDC.containsKey(moveDate))
            {
                mapDC.put(moveDate, new wrapCube(idBalance,idLot,idSerial,moveDate,moveType));
                setDate.add(moveDate);
                listWrapCube.add(mapDC.get(moveDate));
            }
        }

        //collect the move cubes that already exist
        for(GMBLASERP__Inventory_Movement_Cube__c cube :
        [SELECT Id, GMBLASERP__Inventory_Balance__c, GMBLASERP__Lot__c, GMBLASERP__Serial_Number__c, GMBLASERP__Movement_Date__c, GMBLASERP__Inventory_GL_Amount__c, GMBLASERP__Quantity__c
        FROM GMBLASERP__Inventory_Movement_Cube__c
        WHERE GMBLASERP__Inventory_Balance__c IN :setIdBalance
        AND GMBLASERP__Lot__c IN :setIdLot
        AND GMBLASERP__Serial_Number__c IN :setIdSerial
        AND GMBLASERP__Movement_Date__c IN :setDate
        AND GMBLASERP__Movement_Type__c = :moveType])
        {
            if(cube.GMBLASERP__Quantity__c == null) cube.GMBLASERP__Quantity__c = 0;
            if(cube.GMBLASERP__Inventory_GL_Amount__c == null) cube.GMBLASERP__Inventory_GL_Amount__c = 0;

            if(mapBLSDC.get(cube.GMBLASERP__Inventory_Balance__c).containsKey(cube.GMBLASERP__Lot__c))
            {
                if(mapBLSDC.get(cube.GMBLASERP__Inventory_Balance__c).get(cube.GMBLASERP__Lot__c).containsKey(cube.GMBLASERP__Serial_Number__c))
                {
                    if(mapBLSDC.get(cube.GMBLASERP__Inventory_Balance__c).get(cube.GMBLASERP__Lot__c).get(cube.GMBLASERP__Serial_Number__c).containsKey(cube.GMBLASERP__Movement_Date__c))
                        mapBLSDC.get(cube.GMBLASERP__Inventory_Balance__c).get(cube.GMBLASERP__Lot__c).get(cube.GMBLASERP__Serial_Number__c).get(cube.GMBLASERP__Movement_Date__c).cube = cube;
                }
            }
        }

        //at this point, every cube that is in the map is either a new cube (i.e. wc.cube.Id == NULL) that will be created
        //or it is a cube that exists (i.e. wc.cube.Id != null)

        String soql = '';
        soql = ' SELECT AcctSeedERP__Inventory_Balance__c idBalance, GMBLASERP__Lot__c idLot, GMBLASERP__Serial_Number__c idSerial, AcctSeedERP__Movement_Date__c moveDate, sum(AcctSeedERP__Quantity__c) qty, sum(GMBLASERP__Inventory_GL_Amount__c) amt ';
        soql += ' FROM '+moveType;
        soql += ' WHERE AcctSeedERP__Inventory_Balance__c IN :setIdBalance ';
        soql +=   ' AND GMBLASERP__Lot__c IN :setIdLot ';
        soql +=   ' AND GMBLASERP__Serial_Number__c IN :setIdSerial ';
        soql +=   ' AND AcctSeedERP__Movement_Date__c IN :setDate ';
        soql += ' GROUP BY AcctSeedERP__Inventory_Balance__c, GMBLASERP__Lot__c, GMBLASERP__Serial_Number__c, AcctSeedERP__Movement_Date__c ';

        list<SObject> listAggRes = new list<SObject>();
        listAggRes.addAll(Database.query(soql));

        Decimal negativeForOutbound = 1;
        if(moveType == 'AcctSeedERP__Outbound_Inventory_Movement__c' ||
                moveType == 'AcctSeedERP__Manufacturing_Inventory_Movement__c' ||
                moveType == 'AcctSeedERP__Sales_Order_Inventory_Movement__c')
            negativeForOutbound = -1;

        for(SObject aggRes : listAggRes)
        {
            Id idBalance = (Id)aggRes.get('idBalance');
            Id idLot = (Id)aggRes.get('idLot');
            Id idSerial = (Id)aggRes.get('idSerial');
            Date moveDate = (Date)aggRes.get('moveDate');

            wrapCube wc;

            if(mapBLSDC.get(idBalance).containsKey(idLot))
            {
                if(mapBLSDC.get(idBalance).get(idLot).containsKey(idSerial))
                {
                    if(mapBLSDC.get(idBalance).get(idLot).get(idSerial).containsKey(moveDate))
                        wc = mapBLSDC.get(idBalance).get(idLot).get(idSerial).get(moveDate);
                }
            }

            if(wc == null) continue;

            Decimal qty = (Decimal)aggRes.get('qty');
            if(qty == null) qty = 0;
            Decimal amt = (Decimal)aggRes.get('amt');
            if(amt == null) amt = 0;

            wc.qtyNew += qty * negativeForOutbound;
            wc.amtNew += amt * negativeForOutbound;
        }

        list<GMBLASERP__Inventory_Movement_Cube__c> listCubeUpsert = new list<GMBLASERP__Inventory_Movement_Cube__c>();
        list<GMBLASERP__Inventory_Movement_Cube__c> listCubeDelete = new list<GMBLASERP__Inventory_Movement_Cube__c>();
        for(wrapCube wc : listWrapCube)
        {
            if(//it's a new cube, and either the new quantity or the new amount is non-zero
                    (wc.cube.Id == NULL && (wc.qtyNew.setScale(6) != 0 || wc.amtNew.setScale(6) != 0)) ||
                            //OR it's an existing cube, and either the quantity or the amount is non-zero, and either the quantity or amount are changing
                            (wc.cube.Id != NULL && (wc.qtyNew.setScale(6) != 0 || wc.amtNew.setScale(6) != 0) && (wc.cube.GMBLASERP__Quantity__c.setScale(6) != wc.qtyNew.setScale(6) || wc.cube.GMBLASERP__Inventory_GL_Amount__c.setScale(6) != wc.amtNew.setScale(6))))
            {
                wc.cube.GMBLASERP__Quantity__c = wc.qtyNew.setScale(6);
                wc.cube.GMBLASERP__Inventory_GL_Amount__c = wc.amtNew.setScale(6);
                listCubeUpsert.add(wc.cube);
            }
            else if(//it's an existing cube, and the new quantity is zero, and the new amount is zero
                    wc.cube.Id != NULL && wc.qtyNew.setScale(6) == 0 && wc.amtNew.setScale(6) == 0)
            {
                listCubeDelete.add(wc.cube);
            }
        }

        Boolean boolOld;
        if(listCubeUpsert.size() > 0)
        {
            System.debug('In the cube upsert');
            boolOld = GMBLASERP.gcInventoryMovementCube.allowDML;
            GMBLASERP.gcInventoryMovementCube.allowDML = true;
            upsert listCubeUpsert;
            GMBLASERP.gcInventoryMovementCube.allowDML = boolOld;
        }
        if(listCubeDelete.size() > 0)
        {
            boolOld = GMBLASERP.gcInventoryMovementCube.allowDML;
            GMBLASERP.gcInventoryMovementCube.allowDML = true;
            delete listCubeDelete;
            GMBLASERP.gcInventoryMovementCube.allowDML = boolOld;
        }
    }

    private class wrapCube
    {
        public GMBLASERP__Inventory_Movement_Cube__c cube{get;set;}
        public Decimal qtyNew{get;set;}
        public Decimal amtNew{get;set;}

        public wrapCube(Id idBalance, Id idLot, Id idSerial, Date moveDate, String moveType)
        {
            cube = new GMBLASERP__Inventory_Movement_Cube__c(GMBLASERP__Inventory_Balance__c = idBalance, GMBLASERP__Lot__c = idLot, GMBLASERP__Serial_Number__c = idSerial, GMBLASERP__Movement_Date__c = moveDate, GMBLASERP__Movement_Type__c = moveType, GMBLASERP__Inventory_GL_Amount__c = 0, GMBLASERP__Quantity__c = 0);
            qtyNew = 0;
            amtNew = 0;
        }
    }
}