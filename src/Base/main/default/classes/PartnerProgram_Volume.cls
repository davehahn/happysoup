/**
 * Created by dave on 2020-07-29.
 */

public virtual class PartnerProgram_Volume extends PartnerProgramItem
{

//  private Decimal orderTotal = 0;
  private final Set<String> applicableBoatFamilies = new Set<String>{
    'Side Console',
    'Full Windshield',
    'Deck Boat'
  };

  public PartnerProgram_Volume()
  {
    this.name = 'V-Hull / Deck Boat Volume Discount';
    this.bookingOrderFieldName = 'V_Hull_Discount_Percent__c';
    this.volumeType = 'V Hull';
  }

  public override void init( PartnerProgram_Service.DealerOrderWrapper orderWrapper )
  {
    super.init( orderWrapper );
//    calcOrderTotal();
//    System.debug( 'Volume order total = ' + this.orderTotal );
  }

  public override Boolean isApplicable()
  {
    if( this.discountPercent > 0 )
      return true;
//    if( !this.orderWrapper.isBookingOrder )
//      return this.hasVerifiedBookingOrder;
    return false;
  }

  public override Decimal getDiscountPercent()
  {
    return this.discountPercent;
  }

  public override List<AcctSeedERP__Material__c> apply()
  {
    List<AcctSeedERP__Material__c> discounts = new List<AcctSeedERP__Material__c>();
    Decimal totalSavings = 0;
    Decimal savingsPercent = determineSavingsPercent();
    for( PartnerProgram_Service.ErpWrapper wrapper : this.erpWrappers )
    {
      if( applicableBoatFamilies.contains( wrapper.boatLine.AcctSeedERP__Product__r.Family ) ||
          ( wrapper.boatLine.AcctSeedERP__Product__r.Family == 'Utility' &&
            wrapper.boatLine.AcctSeedERP__Product__r.Stack_Size__c == null ) )
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

  protected override void calculateVolumeLevel()
  {
    Id discountProdId = LGND_Constants.savingsProductId;
    Id feeRtId = LGND_Constants.productRtId_Fees;
    for( PartnerProgram_Service.ErpWrapper wrapper : this.erpWrappers )
    {
      for( AcctSeedERP__Material__c mat : wrapper.erp.AcctSeedERP__Project_Materials__r )
      {
        if( mat.AcctSeedERP__Product__c != discountProdId &&
            mat.AcctSeedERP__Product__r.RecordTypeId != feeRtId )
        {
          this.volumeLevel += mat.GMBLASERP__Unit_Price__c;
        }
      }
    }
  }

  protected override Decimal determineSavingsPercent()
  {
    return this.determineSavingsPercentByVolume();
  }

}