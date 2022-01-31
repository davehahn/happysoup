/**
 * Created by dhavalmacbook on 03/01/22.
 */

trigger EmployeeWageRate on Employee_Wage_Rate__c (before insert,
        before update,
        before delete,
        after insert,
        after update,
        after delete,
        after undelete) {
    new MetadataTriggerHandler().run();
}