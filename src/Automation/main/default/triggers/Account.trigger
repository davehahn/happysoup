/**
 * Created by dave on 2020-05-01.
 */

trigger Account on Account (
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete )
{
//  new Account_TriggerHandler().run();
  new MetadataTriggerHandler().run();
}