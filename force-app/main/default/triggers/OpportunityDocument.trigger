trigger OpportunityDocument on Opportunity_Document__c (before insert, before update, before delete, after insert, after update, after delete) {


  OpportunityDocument.triggerHandler
      (trigger.oldMap,
       trigger.newMap,
       trigger.new,
       trigger.isBefore,
       trigger.isInsert,
       trigger.isUpdate,
       trigger.isDelete);

}