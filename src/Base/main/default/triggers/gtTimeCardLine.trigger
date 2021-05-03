trigger gtTimeCardLine on AcctSeed__Time_Card_Line__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    
    if(!gcTimeCardLine.disableTrigger)
    {
        gcTimeCardLine.triggerHandler
            (trigger.oldMap,
             trigger.newMap,
             trigger.new,
             trigger.isBefore,
             trigger.isInsert,
             trigger.isUpdate,
             trigger.isDelete);
    }
}