/**
 * Created by Legend on 28/7/21.
 */

public with sharing class GCR_InventoryTransfer {
    private static Id idWarehouseTransit{get;set;}
    private static Id idLocationTransit{get;set;}
    private static Id idWarehouseAdjustment{get;set;}

    private static date dateEarliestOpen{get;set;}

    private static map<Id,Id> mapDefaultLocation{get;set;}

    private static list<sObject> listSObjectUpdate{get;set;}
    private static list<sObject> listSObjectInsert{get;set;}
    private static list<sObject> listSObjectDelete{get;set;}

    private static map<Id,map<Id,map<Id,Id>>> mapPWLB{get;set;}

    private static integer intChildren{get;set;}

    private static Boolean sameDay{get;set;}
    private static GMBLASERP__Inventory_Transfer__c xfr{
        get;
        set{
            xfr = value;
            sameDay = false;
            if(xfr.GMBLASERP__Inbound_Date__c == xfr.GMBLASERP__Outbound_Date__c)
                sameDay = true;
        }
    }

    private static void initStatics()
    {
        System.debug('initStatics Transfer');
        if(idWarehouseTransit == null || idLocationTransit == null || idWarehouseAdjustment == null)
        {
            Id idWarehouseTransitSetting = GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Transit_Warehouse_Id__c;
            Id idWarehouseAdjustmentSetting = GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Adjustment_Warehouse_Id__c;
            for(AcctSeedERP__Warehouse__c whs :
            [SELECT Id, (SELECT Id FROM AcctSeedERP__Locations__r ORDER BY CreatedDate LIMIT 1)
            FROM AcctSeedERP__Warehouse__c
            WHERE Id = :idWarehouseTransitSetting OR Id = :idWarehouseAdjustmentSetting])
            {
                if(whs.Id == idWarehouseTransitSetting)
                {
                    idWarehouseTransit = whs.Id;
                    if(whs.AcctSeedERP__Locations__r.size() > 0)
                        idLocationTransit = whs.AcctSeedERP__Locations__r[0].Id;
                }
                else
                        idWarehouseAdjustment = whs.Id;
            }

            if(idWarehouseTransit == null)
                throw new gcException('The Transit Warehouse does not exist.');
            else if(idLocationTransit == null)
                throw new gcException('The Transit Location does not exist.');
            else if(idWarehouseAdjustment == null)
                throw new gcException('The Adjustment Warehouse does not exist.');
        }

        if(dateEarliestOpen == null)
            dateEarliestOpen = GCR_AccountingPeriod.dateEarliestOpen();

        if(mapDefaultLocation == null)
            mapDefaultLocation = new map<Id,Id>();

        listSObjectDelete = new list<sObject>();
        listSObjectUpdate = new list<sObject>();
        listSObjectInsert = new list<sObject>();
        mapPWLB = new map<Id,map<Id,map<Id,Id>>>();
    }

    private static void retrieveDefaultLocations()
    {
        mapDefaultLocation.remove(null);

        set<Id> setIdWarehouse = new set<Id>();
        for(Id idWarehouse : mapDefaultLocation.keySet())
        {
            if(mapDefaultLocation.get(idWarehouse) == null)
                setIdWarehouse.add(idWarehouse);
        }

        if(setIdWarehouse.size() > 0)
        {
            for(AcctSeedERP__Warehouse__c whs :
            [SELECT Id, (SELECT Id FROM AcctSeedERP__Locations__r ORDER BY CreatedDate LIMIT 1)
            FROM AcctSeedERP__Warehouse__c
            WHERE Id IN :setIdWarehouse])
            {
                if(whs.AcctSeedERP__Locations__r.size() > 0)
                    mapDefaultLocation.put(whs.Id,whs.AcctSeedERP__Locations__r[0].Id);
                else
                        throw new gcException('A location for warehouse '+whs.Id+' does not exist.');
            }
        }
    }

    /*
    A completed inventory transfer consists of TWO PAIRS of inventory movements, for a total of FOUR inventory movements:
    1) Outbound from Origin - the "root" movement that starts it all, and that looks up directly to the Inventory Transfer record.
    2) Inbound to Transit - the child of the Outbound from Origin, that completes the first pair of movements.
    3) Outbound from Transit - the child of the Inbound to Transit, that starts the inbound movement to the destination.
    4) Inbound to Destination - the child of the Outbound from Transit, that completes the transfer.

    Movements #1 and #2 happen within the same execution context.
    Movements #3 and #4 happen within the same execution context.

    If the Outbound and Inbound date are the same, then movements #3 and #4 don't happen, and movement #2 is inbound to destination.
    */

    public static void cascadeDeleteChildrenOfInbound(set<Id> setIdInboundMove)
    {
        setIdInboundMove.remove(NULL);
        //the purpose of this method is to delete the outbound movements that underlie an inbound movement
        list<Id> listIdOutboundMoveDelete = new list<Id>();
        for(AcctSeedERP__Outbound_Inventory_Movement__c move :
        [SELECT Id
        FROM AcctSeedERP__Outbound_Inventory_Movement__c
        WHERE AcctSeedERP__Inbound_Inventory_Movement__c IN : setIdInboundMove])
        {
            listIdOutboundMoveDelete.add(move.Id);
        }

        Database.delete(listIdOutboundMoveDelete);
    }

    public static void cascadeDeleteChildrenOfOutbound(set<Id> setIdOutboundMove)
    {
        setIdOutboundMove.remove(NULL);
        //the purpose of this method is to delete the inbound movements that underlie an outbound movement
        list<Id> listIdInboundMoveDelete = new list<Id>();
        for(AcctSeedERP__Inbound_Inventory_Movement__c move :
        [SELECT Id
        FROM AcctSeedERP__Inbound_Inventory_Movement__c
        WHERE AcctSeedERP__Outbound_Inventory_Movement__c IN : setIdOutboundMove])
        {
            listIdInboundMoveDelete.add(move.Id);
        }

        Database.delete(listIdInboundMoveDelete);
    }

    /*
    VERIFY INBOUND TO TRANSIT, I.E. CHILDREN OF OUTBOUND FROM ORIGIN
    CALL THIS METHOD AFTER INSERT, AFTER UPDATE OF OUTBOUND INVENTORY MOVEMENT
    */
    /*
    The purpose of this method is to ensure that the "Outbound from Origin" movement has all and only the correct children, i.e. that the "Inbound to Transit" movements are correct.
    */
    /// Commenting this method off
    /// This is not really required as we do not try this normally
    public static void verifyChildrenOfOutboundFromOrigin(set<Id> setIdMove)
    {
        initStatics();

        list<AcctSeedERP__Outbound_Inventory_Movement__c> listMove = new list<AcctSeedERP__Outbound_Inventory_Movement__c>();
        map<Id,list<AcctSeedERP__Inbound_Inventory_Movement__c>> mapMoveToChildren = new map<Id, list<AcctSeedERP__Inbound_Inventory_Movement__c>>();
        list<AcctSeedERP__Inbound_Inventory_Movement__c> listChildren = new list<AcctSeedERP__Inbound_Inventory_Movement__c>();
        AcctSeedERP__Inbound_Inventory_Movement__c moveChild;

        for(AcctSeedERP__Outbound_Inventory_Movement__c move :
        [SELECT Id,
                AcctSeedERP__Debit_GL_Account__c,
                AcctSeedERP__Inventory_Balance__c,
                AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__c,
                AcctSeedERP__Movement_Date__c,
                AcctSeedERP__Quantity__c,
                AcctSeedERP__Type__c,
                AcctSeedERP__Unit_Cost__c,
                GMBLASERP__Cost_Override__c,
                GMBLASERP__Inventory_Transfer__c,
                GMBLASERP__Inventory_Transfer__r.Id,
                GMBLASERP__Inventory_Transfer__r.CreatedDate,
                GMBLASERP__Inventory_Transfer__r.GMBLASERP__Inbound_Date__c,
                GMBLASERP__Inventory_Transfer__r.GMBLASERP__Outbound_Date__c,
                GMBLASERP__Inventory_Transfer__r.GMBLASERP__Warehouse_To__c,
                GMBLASERP__Serial_Number__c,
                GMBLASERP__Lot__c,
        (SELECT Id,
                AcctSeedERP__Credit_GL_Account__c,
                AcctSeedERP__Inventory_Balance__c,
                AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__c,
                AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c,
                AcctSeedERP__Movement_Date__c,
                AcctSeedERP__Quantity__c,
                AcctSeedERP__Type__c,
                AcctSeedERP__Unit_Cost__c,
                GMBLASERP__Cost_Override__c,
                GMBLASERP__Inventory_Transfer__c,
                GMBLASERP__Serial_Number__c,
                GMBLASERP__Lot__c
        FROM AcctSeedERP__Inbound_Inventory_Movements__r)
        FROM AcctSeedERP__Outbound_Inventory_Movement__c
        WHERE Id IN : setIdMove
        AND GMBLASERP__Inventory_Transfer__c != NULL
        AND GMBLASERP__Inventory_Transfer__r.GMBLASERP__Outbound_Date__c >= :dateEarliestOpen
        AND AcctSeedERP__Inbound_Inventory_Movement__c = NULL]) //i.e. this is the "root" move
        {
            listMove.add(move);
            mapMoveToChildren.put(move.Id,move.AcctSeedERP__Inbound_Inventory_Movements__r.clone());

            if(!mapDefaultLocation.containsKey(move.GMBLASERP__Inventory_Transfer__r.GMBLASERP__Warehouse_To__c))
                mapDefaultLocation.put(move.GMBLASERP__Inventory_Transfer__r.GMBLASERP__Warehouse_To__c, null);
        }
        if(listMove.size() == 0) return;

        retrieveDefaultLocations();

        for(AcctSeedERP__Outbound_Inventory_Movement__c move : listMove)
        {
            //must move children into their own list, because the subquery cannot be manipulated
            listChildren = mapMoveToChildren.get(move.Id);

            xfr = move.GMBLASERP__Inventory_Transfer__r;

            intChildren = listChildren.size();
            for(Integer i = intChildren -1; i >= 0 ; i--)
            {
                moveChild = listChildren[i];

                if(moveChild.AcctSeedERP__Movement_Date__c >= dateEarliestOpen)
                {
                    //if there's a moveChild whose master inventory balance does not match the move parent, remove it
                    if((!sameDay && moveChild.AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c != idWarehouseTransit) ||
                            ( sameDay && moveChild.AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c != xfr.GMBLASERP__Warehouse_To__c) ||
                            moveChild.AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__c != move.AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__c)
                    {
                        listSObjectDelete.add(moveChild);
                        listChildren.remove(i);
                    }
                    //update all children, for cascade effect, and to synchronize with parent
                    else if(listChildren.size() == 1)
                    {
                        moveChild.AcctSeedERP__Credit_GL_Account__c = move.AcctSeedERP__Debit_GL_Account__c;
                        moveChild.AcctSeedERP__Movement_Date__c = move.AcctSeedERP__Movement_Date__c;
                        moveChild.AcctSeedERP__Quantity__c = move.AcctSeedERP__Quantity__c;
                        moveChild.AcctSeedERP__Type__c = move.AcctSeedERP__Type__c;
                        moveChild.AcctSeedERP__Unit_Cost__c = move.AcctSeedERP__Unit_Cost__c;
                        moveChild.GMBLASERP__Cost_Override__c = true;
                        moveChild.GMBLASERP__Inventory_Transfer__c = xfr.Id;
                        moveChild.GMBLASERP__Serial_Number__c = move.GMBLASERP__Serial_Number__c;
                        moveChild.GMBLASERP__Lot__c = move.GMBLASERP__Lot__c;

                        listSObjectUpdate.add(moveChild);
                    }
                }
            }

            //if there exist more than one underlying move, then that's a mistake, so eliminate all of them.
            intChildren = listChildren.size();
            if(intChildren > 1)
            {
                for(Integer i = intChildren - 1; i >= 0 ; i--)
                {
                    moveChild = listChildren[i];
                    if(moveChild.AcctSeedERP__Movement_Date__c >= dateEarliestOpen)
                    {
                        listSObjectDelete.add(moveChild);
                        listChildren.remove(i);
                    }
                }
            }

            //if there is no child, create one.  first, we'll need to get the inventorybalanceId
            intChildren = listChildren.size();
            if(intChildren == 0)
            {
                Id idProduct = move.AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__c;
                Id idWarehouse = idWarehouseTransit;
                Id idLocation  = idLocationTransit;
                if(sameDay)
                {
                    idWarehouse = xfr.GMBLASERP__Warehouse_To__c;
                    idLocation = mapDefaultLocation.get(xfr.GMBLASERP__Warehouse_To__c);
                }

                if(!mapPWLB.containsKey(idProduct))
                    mapPWLB.put(idProduct, new map<Id,map<Id,Id>>());
                if(!mapPWLB.get(idProduct).containsKey(idWarehouse))
                    mapPWLB.get(idProduct).put(idWarehouse, new map<Id,Id>());
                if(!mapPWLB.get(idProduct).get(idWarehouse).containsKey(idLocation))
                    mapPWLB.get(idProduct).get(idWarehouse).put(idLocation,null);
            }
        }

        if(mapPWLB.size() > 0)
            GCR_InventoryBalance.findOrCreateBalances(mapPWLB);

        for(AcctSeedERP__Outbound_Inventory_Movement__c move : listMove)
        {
            listChildren = mapMoveToChildren.get(move.Id);

            xfr = move.GMBLASERP__Inventory_Transfer__r;

            intChildren = listChildren.size();
            if(intChildren == 0)
            {
                Id idProduct = move.AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__c;
                Id idWarehouse = idWarehouseTransit;
                Id idLocation  = idLocationTransit;
                if(sameDay)
                {
                    idWarehouse = xfr.GMBLASERP__Warehouse_To__c;
                    idLocation = mapDefaultLocation.get(xfr.GMBLASERP__Warehouse_To__c);
                }
                Id idBalance = mapPWLB.get(idProduct).get(idWarehouse).get(idLocation);

                listSObjectInsert.add(new AcctSeedERP__Inbound_Inventory_Movement__c
                        (
                                AcctSeedERP__Credit_GL_Account__c = move.AcctSeedERP__Debit_GL_Account__c,
                                AcctSeedERP__Inventory_Balance__c = idBalance,
                                AcctSeedERP__Movement_Date__c = move.AcctSeedERP__Movement_Date__c,
                                AcctSeedERP__Outbound_Inventory_Movement__c = move.Id,
                                AcctSeedERP__Quantity__c = move.AcctSeedERP__Quantity__c,
                                AcctSeedERP__Type__c = move.AcctSeedERP__Type__c,
                                AcctSeedERP__Unit_Cost__c = move.AcctSeedERP__Unit_Cost__c,
                                GMBLASERP__Cost_Override__c = true,
                                GMBLASERP__Inventory_Transfer__c = xfr.Id,
                                GMBLASERP__Serial_Number__c = move.GMBLASERP__Serial_Number__c,
                                GMBLASERP__Lot__c = move.GMBLASERP__Lot__c
                        ));
            }
        }

        if(listSObjectDelete.size() > 0) delete listSObjectDelete;
        if(listSObjectUpdate.size() > 0) update listSObjectUpdate;
        if(listSObjectInsert.size() > 0) insert listSObjectInsert;
    }

/*
VERIFY OUTBOUND FROM TRANSIT, I.E. CHILDREN OF INBOUND TO TRANSIT
CALL THIS METHOD AFTER INSERT, AFTER UPDATE OF INBOUND INVENTORY MOVEMENT
*/
    /*
    The purpose of this method is to ensure that the "Inbound to Transit" movement has all and only the correct children, i.e. that the "Outbound from Transit" movements are correct.
    */
    /// Commenting this method off
    /// This is not really required as we do not try this normally
    /*public static void verifyChildrenOfInboundToTransit(set<Id> setIdMove)
    {
        System.debug('verifyChildrenOfInboundToTransit');
        initStatics();

        list<AcctSeedERP__Inbound_Inventory_Movement__c> listMove = new list<AcctSeedERP__Inbound_Inventory_Movement__c>();
        map<Id,list<AcctSeedERP__Outbound_Inventory_Movement__c>> mapMoveToChildren = new map<Id, list<AcctSeedERP__Outbound_Inventory_Movement__c>>();
        list<AcctSeedERP__Outbound_Inventory_Movement__c> listChildren = new list<AcctSeedERP__Outbound_Inventory_Movement__c>();
        AcctSeedERP__Outbound_Inventory_Movement__c moveChild;

        for(AcctSeedERP__Inbound_Inventory_Movement__c move :
        [SELECT Id,
                AcctSeedERP__Credit_GL_Account__c,
                AcctSeedERP__Inventory_Balance__c,
                AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__c,
                AcctSeedERP__Movement_Date__c,
                AcctSeedERP__Quantity__c,
                AcctSeedERP__Type__c,
                AcctSeedERP__Unit_Cost__c,
                AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Inventory_Transfer__c,
                AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Inventory_Transfer__r.Id,
                AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Inventory_Transfer__r.CreatedDate,
                AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Inventory_Transfer__r.GMBLASERP__Inbound_Date__c,
                AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Inventory_Transfer__r.GMBLASERP__Outbound_Date__c,
                AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Inventory_Transfer__r.GMBLASERP__Warehouse_To__c,
                GMBLASERP__Cost_Override__c,
                GMBLASERP__Serial_Number__c,
                GMBLASERP__Lot__c,
        (SELECT Id,
                AcctSeedERP__Debit_GL_Account__c,
                AcctSeedERP__Inventory_Balance__c,
                AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__c,
                AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c,
                AcctSeedERP__Movement_Date__c,
                AcctSeedERP__Quantity__c,
                AcctSeedERP__Type__c,
                AcctSeedERP__Unit_Cost__c,
                GMBLASERP__Cost_Override__c,
                GMBLASERP__Inventory_Transfer__c,
                GMBLASERP__Serial_Number__c,
                GMBLASERP__Lot__c
        FROM AcctSeedERP__Outbound_Inventory_Movements__r)
        FROM AcctSeedERP__Inbound_Inventory_Movement__c
        WHERE Id IN : setIdMove
        AND AcctSeedERP__Outbound_Inventory_Movement__c != NULL
        AND AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Inventory_Transfer__c != NULL
        AND AcctSeedERP__Outbound_Inventory_Movement__r.AcctSeedERP__Inbound_Inventory_Movement__c = NULL]) //make sure that this inbound is under the "root" outbound
        {
            listMove.add(move);
            mapMoveToChildren.put(move.Id,move.AcctSeedERP__Outbound_Inventory_Movements__r.clone());
        }
        if(listMove.size() == 0) return;

        for(AcctSeedERP__Inbound_Inventory_Movement__c move : listMove)
        {
            xfr = move.AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Inventory_Transfer__r;

            listChildren = mapMoveToChildren.get(move.Id);

            //if there's a moveChild that does not match the move parent, remove it
            intChildren = listChildren.size();
            for(Integer i = intChildren - 1; i >= 0 ; i--)
            {
                moveChild = listChildren[i];

                if(moveChild.AcctSeedERP__Movement_Date__c >= dateEarliestOpen)
                {
                    if(moveChild.AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c != idWarehouseTransit ||
                            moveChild.AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__c != move.AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__c ||
                            xfr.GMBLASERP__Inbound_Date__c == null ||
                            sameDay)
                    {
                        listSObjectDelete.add(moveChild);
                        listChildren.remove(i);
                    }
                    else if(listChildren.size() == 1)
                    {
                        moveChild.AcctSeedERP__Debit_GL_Account__c = move.AcctSeedERP__Credit_GL_Account__c;
                        moveChild.AcctSeedERP__Movement_Date__c = xfr.GMBLASERP__Inbound_Date__c;
                        moveChild.AcctSeedERP__Quantity__c = move.AcctSeedERP__Quantity__c;
                        moveChild.AcctSeedERP__Type__c = move.AcctSeedERP__Type__c;
                        moveChild.AcctSeedERP__Unit_Cost__c = move.AcctSeedERP__Unit_Cost__c;
                        moveChild.GMBLASERP__Cost_Override__c = true;
                        moveChild.GMBLASERP__Inventory_Transfer__c = xfr.Id;
                        moveChild.GMBLASERP__Serial_Number__c = move.GMBLASERP__Serial_Number__c;
                        moveChild.GMBLASERP__Lot__c = move.GMBLASERP__Lot__c;

                        listSObjectUpdate.add(moveChild);
                    }
                }
            }

            //if there exist more than one underlying move, then that's a mistake, so eliminate all of them.
            intChildren = listChildren.size();
            if(intChildren > 1)
            {
                for(Integer i = intChildren - 1; i >= 0 ; i--)
                {
                    moveChild = listChildren[i];
                    if(moveChild.AcctSeedERP__Movement_Date__c >= dateEarliestOpen)
                    {
                        listSObjectDelete.add(moveChild);
                        listChildren.remove(i);
                    }
                }
            }

            //if there is no child, create one.  first, we'll need to get the inventorybalanceId
            intChildren = listChildren.size();
            if(intChildren == 0 && xfr.GMBLASERP__Inbound_Date__c != NULL && xfr.GMBLASERP__Inbound_Date__c >= dateEarliestOpen && !sameDay)
            {
                Id idProduct = move.AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__c;
                Id idWarehouse = idWarehouseTransit;
                Id idLocation  = idLocationTransit;

                if(!mapPWLB.containsKey(idProduct))
                    mapPWLB.put(idProduct, new map<Id,map<Id,Id>>());
                if(!mapPWLB.get(idProduct).containsKey(idWarehouse))
                    mapPWLB.get(idProduct).put(idWarehouse, new map<Id,Id>());
                if(!mapPWLB.get(idProduct).get(idWarehouse).containsKey(idLocation))
                    mapPWLB.get(idProduct).get(idWarehouse).put(idLocation,null);
            }
        }

        if(mapPWLB.size() > 0)
            GCR_InventoryBalance.findOrCreateBalances(mapPWLB);

        for(AcctSeedERP__Inbound_Inventory_Movement__c move : listMove)
        {
            xfr = move.AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Inventory_Transfer__r;

            listChildren = mapMoveToChildren.get(move.Id);

            intChildren = listChildren.size();
            if(intChildren == 0 && xfr.GMBLASERP__Inbound_Date__c != null && xfr.GMBLASERP__Inbound_Date__c >= dateEarliestOpen && !sameDay)
            {
                Id idProduct = move.AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__c;
                Id idBalance = mapPWLB.get(idProduct).get(idWarehouseTransit).get(idLocationTransit);

                listSObjectInsert.add(new AcctSeedERP__Outbound_Inventory_Movement__c
                        (
                                AcctSeedERP__Debit_GL_Account__c = move.AcctSeedERP__Credit_GL_Account__c,
                                AcctSeedERP__Inventory_Balance__c = idBalance,
                                AcctSeedERP__Movement_Date__c = xfr.GMBLASERP__Inbound_Date__c,
                                AcctSeedERP__Inbound_Inventory_Movement__c = move.Id,
                                AcctSeedERP__Quantity__c = move.AcctSeedERP__Quantity__c,
                                AcctSeedERP__Type__c = move.AcctSeedERP__Type__c,
                                AcctSeedERP__Unit_Cost__c = move.AcctSeedERP__Unit_Cost__c,
                                GMBLASERP__Cost_Override__c = true,
                                GMBLASERP__Inventory_Transfer__c = xfr.Id,
                                GMBLASERP__Serial_Number__c = move.GMBLASERP__Serial_Number__c,
                                GMBLASERP__Lot__c = move.GMBLASERP__Lot__c
                        ));
            }
        }
        if(listSObjectDelete.size() > 0) delete listSObjectDelete;
        if(listSObjectUpdate.size() > 0) update listSObjectUpdate;
        if(listSObjectInsert.size() > 0) insert listSObjectInsert;
    }*/

/*
VERIFY INBOUND TO DESTINATION, I.E. CHILDREN OF OUTBOUND FROM TRANSIT
CALL THIS METHOD AFTER INSERT, AFTER UPDATE OF OUTBOUND INVENTORY MOVEMENT
*/
    public static void verifyChildrenOfOutboundFromTransit(set<Id> setIdMove)
    {
        System.debug('verifyChildrenOfOutboundFromTransit');
        initStatics();
        list<AcctSeedERP__Outbound_Inventory_Movement__c> listMove = new list<AcctSeedERP__Outbound_Inventory_Movement__c>();
        map<Id,list<AcctSeedERP__Inbound_Inventory_Movement__c>> mapMoveToChildren = new map<Id, list<AcctSeedERP__Inbound_Inventory_Movement__c>>();
        list<AcctSeedERP__Inbound_Inventory_Movement__c> listChildren = new list<AcctSeedERP__Inbound_Inventory_Movement__c>();
        AcctSeedERP__Inbound_Inventory_Movement__c moveChild;

        for(AcctSeedERP__Outbound_Inventory_Movement__c move :
        [SELECT Id,
                AcctSeedERP__Debit_GL_Account__c,
                AcctSeedERP__Inventory_Balance__c,
                AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__c,
                AcctSeedERP__Movement_Date__c,
                AcctSeedERP__Quantity__c,
                AcctSeedERP__Type__c,
                AcctSeedERP__Unit_Cost__c,
                AcctSeedERP__Inbound_Inventory_Movement__r.AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Inventory_Transfer__c,
                AcctSeedERP__Inbound_Inventory_Movement__r.AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Inventory_Transfer__r.Id,
                AcctSeedERP__Inbound_Inventory_Movement__r.AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Inventory_Transfer__r.CreatedDate,
                AcctSeedERP__Inbound_Inventory_Movement__r.AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Inventory_Transfer__r.GMBLASERP__Inbound_Date__c,
                AcctSeedERP__Inbound_Inventory_Movement__r.AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Inventory_Transfer__r.GMBLASERP__Outbound_Date__c,
                AcctSeedERP__Inbound_Inventory_Movement__r.AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Inventory_Transfer__r.GMBLASERP__Warehouse_To__c,
                GMBLASERP__Cost_Override__c,
                GMBLASERP__Inventory_Transfer__c,
                GMBLASERP__Serial_Number__c,
                GMBLASERP__Lot__c,
        (SELECT Id,
                AcctSeedERP__Credit_GL_Account__c,
                AcctSeedERP__Inventory_Balance__c,
                AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__c,
                AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c,
                AcctSeedERP__Movement_Date__c,
                AcctSeedERP__Quantity__c,
                AcctSeedERP__Type__c,
                AcctSeedERP__Unit_Cost__c,
                GMBLASERP__Cost_Override__c,
                GMBLASERP__Inventory_Transfer__c,
                GMBLASERP__Serial_Number__c,
                GMBLASERP__Lot__c
        FROM AcctSeedERP__Inbound_Inventory_Movements__r)
        FROM AcctSeedERP__Outbound_Inventory_Movement__c
        WHERE Id IN : setIdMove
        AND AcctSeedERP__Inbound_Inventory_Movement__r.AcctSeedERP__Outbound_Inventory_Movement__r.AcctSeedERP__Inbound_Inventory_Movement__c = NULL
        AND AcctSeedERP__Inbound_Inventory_Movement__r.AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Inventory_Transfer__c != NULL
        AND AcctSeedERP__Inbound_Inventory_Movement__r.AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Inventory_Transfer__r.GMBLASERP__Inbound_Date__c >= :dateEarliestOpen]) //i.e. this is the grandchild of the "root" move
        {
            listMove.add(move);
            mapMoveToChildren.put(move.Id,move.AcctSeedERP__Inbound_Inventory_Movements__r.clone());

            if(!mapDefaultLocation.containsKey(move.AcctSeedERP__Inbound_Inventory_Movement__r.AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Inventory_Transfer__r.GMBLASERP__Warehouse_To__c))
                mapDefaultLocation.put(move.AcctSeedERP__Inbound_Inventory_Movement__r.AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Inventory_Transfer__r.GMBLASERP__Warehouse_To__c, null);
        }
        if(listMove.size() == 0) return;

        retrieveDefaultLocations();

        for(AcctSeedERP__Outbound_Inventory_Movement__c move : listMove)
        {
            xfr = move.AcctSeedERP__Inbound_Inventory_Movement__r.AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Inventory_Transfer__r;

            listChildren = mapMoveToChildren.get(move.Id);

            intChildren = listChildren.size();
            for(Integer i = intChildren - 1; i >= 0 ; i--)
            {
                moveChild = listChildren[i];

                if(moveChild.AcctSeedERP__Movement_Date__c >= dateEarliestOpen)
                {
                    //if there's a moveChild whose master inventory balance does not match the move parent, remove it
                    if(moveChild.AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c != xfr.GMBLASERP__Warehouse_To__c ||
                            moveChild.AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__c != move.AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__c)
                    {
                        listSObjectDelete.add(moveChild);
                        listChildren.remove(i);
                    }
                    //update all children, for cascade effect
                    else if(listChildren.size() == 1)
                    {
                        moveChild.AcctSeedERP__Credit_GL_Account__c = move.AcctSeedERP__Debit_GL_Account__c;
                        moveChild.AcctSeedERP__Movement_Date__c = move.AcctSeedERP__Movement_Date__c;
                        moveChild.AcctSeedERP__Quantity__c = move.AcctSeedERP__Quantity__c;
                        moveChild.AcctSeedERP__Type__c = move.AcctSeedERP__Type__c;
                        moveChild.AcctSeedERP__Unit_Cost__c = move.AcctSeedERP__Unit_Cost__c;
                        moveChild.GMBLASERP__Cost_Override__c = true;
                        moveChild.GMBLASERP__Inventory_Transfer__c = xfr.Id;
                        moveChild.GMBLASERP__Serial_Number__c = move.GMBLASERP__Serial_Number__c;
                        moveChild.GMBLASERP__Lot__c = move.GMBLASERP__Lot__c;

                        listSObjectUpdate.add(moveChild);
                    }
                }
            }

            //if there exist more than one underlying move, then that's a mistake, so eliminate all of them.
            intChildren = listChildren.size();
            if(intChildren > 1)
            {
                for(Integer i = intChildren - 1; i >= 0 ; i--)
                {
                    moveChild = listChildren[i];
                    if(moveChild.AcctSeedERP__Movement_Date__c >= dateEarliestOpen)
                    {
                        listSObjectDelete.add(moveChild);
                        listChildren.remove(i);
                    }
                }
            }

            //if there is no child, create one.  first, we'll need to get the inventorybalanceId
            intChildren = listChildren.size();
            if(intChildren == 0)
            {
                Id idProduct = move.AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__c;
                Id idWarehouse = xfr.GMBLASERP__Warehouse_To__c;
                Id idLocation = mapDefaultLocation.get(xfr.GMBLASERP__Warehouse_To__c);

                if(!mapPWLB.containsKey(idProduct))
                    mapPWLB.put(idProduct, new map<Id,map<Id,Id>>());
                if(!mapPWLB.get(idProduct).containsKey(idWarehouse))
                    mapPWLB.get(idProduct).put(idWarehouse, new map<Id,Id>());
                if(!mapPWLB.get(idProduct).get(idWarehouse).containsKey(idLocation))
                    mapPWLB.get(idProduct).get(idWarehouse).put(idLocation,null);
            }
        }

        if(mapPWLB.size() > 0)
            GCR_InventoryBalance.findOrCreateBalances(mapPWLB);

        for(AcctSeedERP__Outbound_Inventory_Movement__c move : listMove)
        {
            xfr = move.AcctSeedERP__Inbound_Inventory_Movement__r.AcctSeedERP__Outbound_Inventory_Movement__r.GMBLASERP__Inventory_Transfer__r;
            listChildren = mapMoveToChildren.get(move.Id);

            intChildren = listChildren.size();
            if(intChildren == 0)
            {
                Id idProduct = move.AcctSeedERP__Inventory_Balance__r.AcctSeedERP__Product__c;
                Id idBalance = mapPWLB.get(idProduct).get(xfr.GMBLASERP__Warehouse_To__c).get(mapDefaultLocation.get(xfr.GMBLASERP__Warehouse_To__c));

                listSObjectInsert.add(new AcctSeedERP__Inbound_Inventory_Movement__c
                        (
                                AcctSeedERP__Credit_GL_Account__c = move.AcctSeedERP__Debit_GL_Account__c,
                                AcctSeedERP__Inventory_Balance__c = idBalance,
                                AcctSeedERP__Movement_Date__c = move.AcctSeedERP__Movement_Date__c,
                                AcctSeedERP__Outbound_Inventory_Movement__c = move.Id,
                                AcctSeedERP__Quantity__c = move.AcctSeedERP__Quantity__c,
                                AcctSeedERP__Type__c = move.AcctSeedERP__Type__c,
                                AcctSeedERP__Unit_Cost__c = move.AcctSeedERP__Unit_Cost__c,
                                GMBLASERP__Cost_Override__c = true,
                                GMBLASERP__Inventory_Transfer__c = xfr.Id,
                                GMBLASERP__Serial_Number__c = move.GMBLASERP__Serial_Number__c,
                                GMBLASERP__Lot__c = move.GMBLASERP__Lot__c
                        ));
            }
        }
        if(listSObjectDelete.size() > 0) delete listSObjectDelete;
        if(listSObjectUpdate.size() > 0) update listSObjectUpdate;
        if(listSObjectInsert.size() > 0) insert listSObjectInsert;
    }
}