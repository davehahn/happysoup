/**
 * Created by Legend on 10/5/22.
 */

trigger Shipment on AcctSeedERP__Shipment__c(
                                            before insert,
                                            after insert,
                                            before update,
                                            after update,
                                            before delete,
                                            after delete ,
                                            after undelete)
{
    new MetadataTriggerHandler().run();
}