/**
 * Created by dhavalmacbook on 02/01/22.
 */

trigger AccountPayable on AcctSeed__Account_Payable__c (
        before insert,
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