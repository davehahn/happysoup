trigger SurveyQuestionResponse on SurveyQuestionResponse__c (
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete)
{

  SurveyQuestionResponse.triggerHandler
    (trigger.oldMap,
     trigger.newMap,
     trigger.new,
     trigger.isBefore,
     trigger.isInsert,
     trigger.isUpdate,
     trigger.isDelete);
}