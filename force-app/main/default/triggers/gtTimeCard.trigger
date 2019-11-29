trigger gtTimeCard on AcctSeed__Time_Card__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    
    if(!gcTimeCard.disableTrigger)
    {
        gcTimeCard.triggerHandler
            (trigger.oldMap,
             trigger.newMap,
             trigger.new,
             trigger.isBefore,
             trigger.isInsert,
             trigger.isUpdate,
             trigger.isDelete);
    }
}