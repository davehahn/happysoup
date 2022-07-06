/**
 * Created by dave on 2022-06-22.
 */

trigger ActivityMetric on ActivityMetric(
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
