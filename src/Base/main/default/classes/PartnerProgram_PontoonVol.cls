/**
 * Created by dave on 2020-07-27.
 */

public virtual class PartnerProgram_PontoonVol extends PartnerProgramItem
{

  public PartnerProgram_PontoonVol()
  {
    this.name = 'Pontoon Volume Discount';
    this.bookingOrderFieldName = 'Pontoon_Volume_Discount_Percent__c';
    this.volumeType = 'Pontoon';
  }

  public override Boolean isApplicable()
  {
    if( this.orderWrapper.isBookingOrder && this.erpWrappers.size() >= 4 )
      return true;
    if( !this.orderWrapper.isBookingOrder &&
        this.erpWrappers.size() > 0 )
    {
      if( this.orderWrapper.bookingOrder.get( this.bookingOrderFieldName ) == null ) return false;
      if( (Decimal)this.orderWrapper.bookingOrder.get( this.bookingOrderFieldName ) > 0 ) return true;
    }
    return false;
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

  protected override void calculateVolumeLevel()
  {
    this.volumeLevel = this.erpWrappers.size();
  }

  protected override Decimal determineSavingsPercent()
  {
    return this.determineSavingsPercentByVolume();
  }

}