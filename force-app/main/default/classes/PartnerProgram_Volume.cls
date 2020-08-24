/**
 * Created by dave on 2020-07-29.
 */

public virtual class PartnerProgram_Volume extends PartnerProgramItem
{


  private Decimal orderTotal = 0;
  private final String fieldName = 'V_Hull_Discount_Percent__c';
  private final Set<String> applicableBoatFamilies = new Set<String>{
    'Side Console',
    'Full Windshield',
    'Deck Boat'
  };

  public PartnerProgram_Volume()
  {
    this.name = 'V-Hull / Deck Boat Volume Discount';
  }

  public override void init( PartnerProgram_Service.DealerOrderWrapper orderWrapper )
  {
    super.init( orderWrapper );
    calcOrderTotal();
    System.debug( 'Volume order total = ' + this.orderTotal );
  }

  public override Boolean isApplicable()
  {
    if( this.discountPercent > 0 )
      return true;
//    if( !this.orderWrapper.isBookingOrder )
//      return this.hasVerifiedBookingOrder;
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
    system.debug('volume apply');
    List<AcctSeedERP__Material__c> discounts = new List<AcctSeedERP__Material__c>();
    Decimal totalSavings = 0;
    Decimal savingsPercent = determineSavingsPercent();
    for( PartnerProgram_Service.ErpWrapper wrapper : this.erpWrappers )
    {
      system.debug('wrapper');
      system.debug(wrapper);
      if( applicableBoatFamilies.contains( wrapper.boatLine.AcctSeedERP__Product__r.Family ) )
      {
        Decimal savings = (wrapper.boatCost * ( savingsPercent / 100 ) )
          .setScale(2, RoundingMode.HALF_UP);

        AcctSeedERP__Material__c mtrl = wrapper.buildDiscountLine( this.name, savings );
        if(mtrl != null) {
          discounts.add(mtrl);
          totalSavings += savings;
        }
      }
    }
    if(totalSavings <> 0) {
      this.resultMessage.totalSaving = totalSavings;
      this.resultMessage.success = 'This order qualifies for the Legend Boats ' + this.name + ' @ ' + this.discountPercent + '%';
    }
    return discounts;
  }

  private void calcOrderTotal()
  {
    Id discountProdId = LGND_Constants.savingsProductId;
    for( PartnerProgram_Service.ErpWrapper wrapper : this.erpWrappers )
    {
      for( AcctSeedERP__Material__c mat : wrapper.erp.AcctSeedERP__Project_Materials__r )
      {
        if( mat.AcctSeedERP__Product__c != discountProdId )
        {
          this.orderTotal += mat.GMBLASERP__Unit_Price__c;
        }
      }
    }
  }

  protected override Decimal determineSavingsPercent()
  {
    if( this.hasVerifiedBookingOrder &&
        !this.orderWrapper.isBookingOrder &&
        orderWrapper.bookingOrder.get( this.fieldName ) != null )
    {
      return (Decimal) orderWrapper.bookingOrder.get(this.fieldName);
    }
    if( this.orderTotal < 150000 )
      return 0;
    if( this.orderTotal < 275000 )
      return 1;
    if( this.orderTotal < 400000 )
      return 2;
    if( this.orderTotal < 600000 )
      return 4;
    if( this.orderTotal < 875000 )
      return 6;
    return 8;
  }
}