/**
 * Created by Legend on 25/4/22.
 */

public inherited sharing class TA_SalesOrderInvMovement_BI implements  TriggerAction.BeforeInsert
{
    public Boolean allowPartUpdate = false;
    public void beforeInsert( List<AcctSeedERP__Sales_Order_Inventory_Movement__c> newList)
    {
        System.debug('I am here on SOIM BI');
        SalesOrderInventoryMovement_Service.checkForSameWarehouse(newList);
    }
}