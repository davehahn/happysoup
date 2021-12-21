/**
 * Created by dave on 2021-06-28.
 */

trigger PurchaseOrderLine on AcctSeedERP__Purchase_Order_Line__c (before insert, before update, before delete, after insert, after update, after delete, after undelete)
{
  new MetadataTriggerHandler().run();
}