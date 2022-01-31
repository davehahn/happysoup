/**
 * Created by dave on 2020-02-18.
 */

trigger CommissionPayment2 on CommissionPayment2__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new MetadataTriggerHandler().run();
  //new CommissionPayment2_TriggerHandler().run();
}
