//trigger SalesOrder on AcctSeedERP__Sales_Order__c(after delete, after insert, after undelete, after update, before delete, before insert, before update) {

  /*if(!SalesOrder.disableTrigger)
  {
    SalesOrder.triggerHandler
      (trigger.oldMap,
       trigger.newMap,
       trigger.new,
       trigger.isBefore,
       trigger.isInsert,
       trigger.isUpdate,
       trigger.isDelete);
  }*/
    trigger SalesOrder on AcctSeedERP__Sales_Order__c(
                                            before insert, 
                                            after insert, 
                                            before update, 
                                            after update, 
                                            before delete,
                                            after delete , 
                                            after undelete) {
                            
    new MetadataTriggerHandler().run();

}
//}