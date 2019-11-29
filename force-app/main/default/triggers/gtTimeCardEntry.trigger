trigger gtTimeCardEntry on Time_Card_Entry__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    
    if(!gcTimeCardEntry.disableTrigger)
    {
        gcTimeCardEntry.triggerHandler
            (trigger.oldMap,
             trigger.newMap,
             trigger.new,
             trigger.isBefore,
             trigger.isInsert,
             trigger.isUpdate,
             trigger.isDelete);
    }
}