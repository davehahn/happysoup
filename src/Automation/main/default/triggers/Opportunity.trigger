/**
 * Created by dave on 2022-02-22.
 */

trigger Opportunity on Opportunity(
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
