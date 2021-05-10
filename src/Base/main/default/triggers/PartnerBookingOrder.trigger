/**
 * Created by dave on 2020-08-04.
 */

trigger PartnerBookingOrder on Partner_Booking_Order__c ( before insert,
                                                          before update,
                                                          before delete,
                                                          after insert,
                                                          after update,
                                                          after delete,
                                                          after undelete)
{
  new PartnerBookingOrder_TriggerHandler().run();
}