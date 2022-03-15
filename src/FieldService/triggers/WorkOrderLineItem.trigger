/**
 * Created by dave on 2019-08-11.
 */

trigger WorkOrderLineItem on WorkOrderLineItem (before insert,
                                                before update,
                                                before delete,
                                                after insert,
                                                after update,
                                                after delete,
                                                after undelete) {
  new MetadataTriggerHandler().run();
}