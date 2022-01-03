/**
 * Created by Pooja on 2022-01-01.
 */

public inherited sharing class TA_EmployeeWageRate_Legacy
        implements
                        TriggerAction.BeforeInsert,
                        TriggerAction.BeforeUpdate,
                        TriggerAction.BeforeDelete,
                        TriggerAction.AfterInsert,
                        TriggerAction.AfterUpdate,
                        TriggerAction.AfterDelete
{

    public void beforeInsert(
            List<Employee_Wage_Rate__c> newList
    )
    {
        if (!gcEmployeeWageRate.disableTrigger)
        {

            gcEmployeeWageRate.triggerHandler(
                    null,
                    null,
                    newList,
                    true,
                    true,
                    false,
                    false
            );
        }
    }

    public void afterInsert(
            List<Employee_Wage_Rate__c> newList
    )
    {
        if (!gcEmployeeWageRate.disableTrigger)
        {
            Map<Id, Employee_Wage_Rate__c> newMap =
                    new Map<Id, Employee_Wage_Rate__c>(newList);
            gcEmployeeWageRate.triggerHandler(
                    null,
                    newMap,
                    newList,
                    false,
                    true,
                    false,
                    false
            );
        }
    }

    public void beforeUpdate(
            List<Employee_Wage_Rate__c> newList,
            List<Employee_Wage_Rate__c> oldList
    )
    {
        if (!gcEmployeeWageRate.disableTrigger)
        {
            Map<Id, Employee_Wage_Rate__c> newMap =
                    new Map<Id, Employee_Wage_Rate__c>(newList);
            Map<Id, Employee_Wage_Rate__c> oldMap =
                    new Map<Id, Employee_Wage_Rate__c>(oldList);
            gcEmployeeWageRate.triggerHandler(
                    oldMap,
                    newMap,
                    newList,
                    true,
                    false,
                    true,
                    false
            );
        }
    }

    public void afterUpdate(
            List<Employee_Wage_Rate__c> newList,
            List<Employee_Wage_Rate__c> oldList
    )
    {
        if (!gcEmployeeWageRate.disableTrigger)
        {
            Map<Id, Employee_Wage_Rate__c> newMap =
                    new Map<Id, Employee_Wage_Rate__c>(newList);
            Map<Id, Employee_Wage_Rate__c> oldMap =
                    new Map<Id, Employee_Wage_Rate__c>(oldList);
            gcEmployeeWageRate.triggerHandler(
                    oldMap,
                    newMap,
                    newList,
                    false,
                    false,
                    true,
                    false
            );
        }
    }

    public void beforeDelete(
            List<Employee_Wage_Rate__c> oldList
    )
    {
        if (!gcEmployeeWageRate.disableTrigger)
        {
            Map<Id, Employee_Wage_Rate__c> oldMap =
                    new Map<Id, Employee_Wage_Rate__c>(oldList);
            gcEmployeeWageRate.triggerHandler(
                    oldMap,
                    null,
                    null,
                    true,
                    false,
                    false,
                    true
            );
        }
    }

    public void afterDelete(
            List<Employee_Wage_Rate__c> oldList
    )
    {
        if (!gcEmployeeWageRate.disableTrigger)
        {
            Map<Id, Employee_Wage_Rate__c> oldMap =
                    new Map<Id, Employee_Wage_Rate__c>(oldList);
            gcEmployeeWageRate.triggerHandler(
                    oldMap,
                    null,
                    null,
                    false,
                    false,
                    false,
                    true
            );
        }
    }

}