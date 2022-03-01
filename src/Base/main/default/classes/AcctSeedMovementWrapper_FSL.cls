/**
 * Created by aminrubel on 2019-08-23.
 */

public with sharing class AcctSeedMovementWrapper_FSL {

    public SObject obj{get;set;}
    public String objId{get;set;}
    public String idBalance{get;set;}
    public String idProduct{get;set;}
    public String moveStatus{get;set;}
    public Decimal qtyNew{get;set;}

    public AcctSeedMovementWrapper_FSL(SObject pObj, Boolean isNegative)
    {
        this.obj = pObj;
        this.objId = (String) pObj.get('Id');
        this.moveStatus = (String) pObj.get('AcctSeedERP__Status__c');
        this.idBalance = (String) pObj.get('AcctSeedERP__Inventory_Balance__c');
        this.idProduct = (String) pObj.get('GMBLASERP__Product__c');
        if(this.idProduct == null)
            this.idProduct = (String) pObj.get('AcctSeedERP__ProductId__c');
        Decimal newQty = (Decimal) pObj.get('AcctSeedERP__Quantity__c');
        if(isNegative) newQty = newQty * -1;
        this.qtyNew = newQty;
    }

    public static List<AcctSeedMovementWrapper_FSL> generateMovementWrapperVoid(List<SObject> listMovements) {
        Boolean negativeMove = false;
        if (listMovements.getSObjectType() == AcctSeedERP__Manufacturing_Inventory_Movement__c.SObjectType)
            negativeMove = true;
        else if (listMovements.getSObjectType() == AcctSeedERP__Outbound_Inventory_Movement__c.SObjectType)
            negativeMove = true;

        if(Trigger.isExecuting && Trigger.isDelete)
            negativeMove = true;
        List<AcctSeedMovementWrapper_FSL> listWrapMoves = new List<AcctSeedMovementWrapper_FSL>();
        for (SObject obj : listMovements) {
            AcctSeedMovementWrapper_FSL wm = new AcctSeedMovementWrapper_FSL(obj, negativeMove);
            listWrapMoves.add(wm);
        }

        return listWrapMoves;
    }
}