/**
 * Created by dave on 2020-01-30.
 */

trigger CommissionLineItem2 on CommissionLineItem2__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new MetadataTriggerHandler().run();
}