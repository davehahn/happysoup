//trigger SalesOrderLine on AcctSeedERP__Sales_Order_Line__c(after delete, after insert, after undelete, after update, before delete, before insert, before update) {
/*
  if(!SalesOrderLine.disableTrigger)
  {
    SalesOrderLine.triggerHandler
      (trigger.oldMap,
       trigger.newMap,
       trigger.new,
       trigger.isBefore,
       trigger.isInsert,
       trigger.isUpdate,
       trigger.isDelete);
  }*/
//}

trigger SalesOrderLine on AcctSeedERP__Sales_Order_Line__c(
                                            before insert, 
                                            after insert, 
                                            before update, 
                                            after update, 
                                            before delete,
                                            after delete , 
                                            after undelete) {
                            
    new MetadataTriggerHandler().run();

}