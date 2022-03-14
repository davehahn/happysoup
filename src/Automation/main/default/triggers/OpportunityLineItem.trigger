trigger OpportunityLineItem on OpportunityLineItem(
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
