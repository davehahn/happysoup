/**
 * Created by dave on 2021-11-22.
 */

trigger IT_Issue on IT_Issue__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new IT_Issue_TriggerHandler().run();
}
