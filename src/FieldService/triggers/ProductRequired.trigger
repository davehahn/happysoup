/**
 * Created by dave on 2019-08-16.
 */

trigger ProductRequired on ProductRequired (before insert,
                                              before update,
                                              before delete,
                                              after insert,
                                              after update,
                                              after delete,
                                              after undelete) {
  new MetadataTriggerHandler().run();
}