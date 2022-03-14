/**
 * Created by dhavalmacbook on 02/01/22.
 */

trigger CashDisbursement on AcctSeed__Cash_Disbursement__c (before insert,
        before update,
        before delete,
        after insert,
        after update,
        after delete,
        after undelete )
{
    new MetadataTriggerHandler().run();
}