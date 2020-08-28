/**
 * Created by dave on 2020-08-28.
 */

public with sharing class PartnerProgram_Kickstart_Booking extends PartnerProgramItem
{

  public PartnerProgram_Kickstart_Booking()
  {
    this.name = 'Kickstart Booking Order Discount';
  }

  public override Boolean isApplicable()
  {
    return this.orderWrapper.isBookingOrder && this.erpWrappers.size() > 0;
  }

  public override List<AcctSeedERP__Material__c> apply()
  {
    return this.doStandardApply();
  }

  protected override void filterApplicableERPs( List<PartnerProgram_Service.ErpWrapper> erpWrappers )
  {
    for( PartnerProgram_Service.ErpWrapper wrapper : erpWrappers )
    {
      if( wrapper.boatLine != null )
        this.erpWrappers.add( wrapper );
    }
  }

  protected override Decimal determineSavingsPercent()
  {
    return Partner_Program_Settings__c.getOrgDefaults().Kickstart_Booking_Order_Discount_Percent__c;
  }

}