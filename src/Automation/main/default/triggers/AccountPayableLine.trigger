/**
 * Created by dhavalmacbook on 02/01/22.
 */

trigger AccountPayableLine on AcctSeed__Account_Payable_Line__c (before insert,
        before update,
        before delete,
        after insert,
        after update,
        after delete,
        after undelete )
{
//  new Account_TriggerHandler().run();
    new MetadataTriggerHandler().run();
}