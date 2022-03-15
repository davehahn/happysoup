trigger ServiceAppointment on ServiceAppointment (before insert,
                                before update,
                                before delete,
                                after insert,
                                after update,
                                after delete,
                                after undelete) {
  new MetadataTriggerHandler().run();
}