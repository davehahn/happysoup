/**
 * Created by dhavalmacbook on 02/01/22.
 */

trigger Employee on Employee__c (before insert,
        before update,
        before delete,
        after insert,
        after update,
        after delete,
        after undelete) {
    new MetadataTriggerHandler().run();
}