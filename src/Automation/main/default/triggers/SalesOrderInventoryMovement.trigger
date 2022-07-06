/**
 * Created by Legend on 21/4/22.
 */ 
trigger SalesOrderInventoryMovement on AcctSeedERP__Sales_Order_Inventory_Movement__c (before insert,
        before update,
        before delete,
        after insert,
        after update,
        after delete,
        after undelete )
{
    new MetadataTriggerHandler().run();
}