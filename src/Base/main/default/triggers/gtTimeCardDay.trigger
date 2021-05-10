trigger gtTimeCardDay on AcctSeed__Time_Card_Day__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    
    if(!gcTimeCardDay.disableTrigger)
    {
        gcTimeCardDay.triggerHandler
            (trigger.oldMap,
             trigger.newMap,
             trigger.new,
             trigger.isBefore,
             trigger.isInsert,
             trigger.isUpdate,
             trigger.isDelete);
    }
}