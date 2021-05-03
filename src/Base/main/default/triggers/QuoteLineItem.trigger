trigger QuoteLineItem on QuoteLineItem ( before insert,
                                         before update,
                                         before delete,
                                         after insert,
                                         after update,
                                         after delete,
                                         after undelete )
{
    QuoteLineItem_TriggerHandler.doHandle( trigger.oldMap,
                                           trigger.newMap,
                                           trigger.new,
                                           trigger.isBefore,
                                           trigger.isInsert,
                                           trigger.isUpdate,
                                           trigger.isDelete );
}