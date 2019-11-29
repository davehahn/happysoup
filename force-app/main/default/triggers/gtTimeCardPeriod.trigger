trigger gtTimeCardPeriod on AcctSeed__Time_Card_Period__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    
    if(!gcTimeCardPeriod.disableTrigger)
    {
        gcTimeCardPeriod.triggerHandler
            (trigger.oldMap,
             trigger.newMap,
             trigger.new,
             trigger.isBefore,
             trigger.isInsert,
             trigger.isUpdate,
             trigger.isDelete);
    }
}