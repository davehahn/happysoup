/**
 * Created by aminrubel on 2019-08-23.
 */

public with sharing class AcctSeedMovementWrapper_FSL {
    public static List<wrapMovement> generateMovementWrapperVoid(List<SObject> listMovements) {
        Boolean negativeMove = false;
        if (listMovements.getSObjectType() == AcctSeedERP__Manufacturing_Inventory_Movement__c.SObjectType)
            negativeMove = true;
        else if (listMovements.getSObjectType() == AcctSeedERP__Outbound_Inventory_Movement__c.SObjectType)
            negativeMove = true;

        if(Trigger.isExecuting && Trigger.isDelete)
            negativeMove = true;
        List<wrapMovement> listWrapMoves = new List<wrapMovement>();
        for (SObject obj : listMovements) {
            System.debug('pol pol');
            System.debug(obj);
            wrapMovement wm = new wrapMovement(obj, negativeMove);
            listWrapMoves.add(wm);
        }

        return listWrapMoves;
    }
}