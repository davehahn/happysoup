/**
 * Created by dave on 2020-07-27.
 */

public virtual class PartnerProgram_PontoonVol extends PartnerProgramItem
{
  private final String fieldName = 'Pontoon_Volume_Discount_Percent__c';

  public PartnerProgram_PontoonVol()
  {
    this.name = 'Pontoon Volume Discount';
  }

  public override Boolean isApplicable()
  {
    if( this.orderWrapper.isBookingOrder && this.erpWrappers.size() >= 4 )
      return true;
    if( !this.orderWrapper.isBookingOrder && this.erpWrappers.size() > 0 )
      return this.hasVerifiedBookingOrder;
    return false;
  }

  public override String getBookingOrderFieldName()
  {
    return this.fieldName;
  }

  public override Decimal getDiscountPercent()
  {
    return this.discountPercent;
  }

  public override List<AcctSeedERP__Material__c> apply()
  {
    return this.doStandardApply();
  }

  protected override void filterApplicableERPs( List<PartnerProgram_Service.ErpWrapper> erpWrappers )
  {
    for( PartnerProgram_Service.ErpWrapper wrapper : erpWrappers )
    {
      if( wrapper.boatFamily == 'Pontoon' )
        this.erpWrappers.add( wrapper );
    }
  }

  protected override Decimal determineSavingsPercent()
  {
    Integer count = this.erpWrappers.size();
    if( this.hasVerifiedBookingOrder &&
        !this.orderWrapper.isBookingOrder &&
        this.orderWrapper.bookingOrder.get( this.fieldName ) != null )
    {
      return (Decimal) orderWrapper.bookingOrder.get(this.fieldName);
    }
    if( count < 4 )
      return 0;
    if( count < 8 )
      return 1;
    if( count < 12 )
      return 2;
    if( count < 15 )
      return 4;
    if( count < 18 )
      return 6;
    return 8;
  }

}