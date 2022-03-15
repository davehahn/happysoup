/**
 * Created by dave on 2019-08-08.
 */

trigger WorkOrder on WorkOrder (before insert,
                                before update,
                                before delete,
                                after insert,
                                after update,
                                after delete,
                                after undelete)
{
  new MetadataTriggerHandler().run();
}
