/**
 * Created by dave on 2021-05-07.
 */

public virtual class PartnerBookingOrder_Selector extends Application_Selector
{


  private final List<String> defaultFields = new List<String>
  {
    'Id',
    'Name',
    'Dealer_Order__c',
    'Account__c',
    'V_Hull_Discount_Percent__c',
    'Pontoon_Volume_Discount_Percent__c',
    'Uniquifier__c'
  };

  public PartnerBookingOrder_Selector()
  {
    this.sObjectName = 'Partner_Booking_Order__c';
    this.fields = defaultFields;
  }

  public static Partner_Booking_Order__c getUnique( String uniquifier )
  {
    List<SObject> results = new PartnerBookingOrder_Selector()
      .addWhere( 'Uniquifier__c = \'' + uniquifier + '\'')
      .query();
    return (Partner_Booking_Order__c)results[0];
  }
}