/**
 * Created by dave on 2022-03-28.
 */

trigger Task on Task(
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
