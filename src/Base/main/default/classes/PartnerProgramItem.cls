/**
 * Created by dave on 2020-07-24.
 */

public virtual class PartnerProgramItem implements PartnerProgramItem_I, Promise.Deferred
{
  protected String name;
  public Dealer_Order__c dealerOrder;
  public String programYear;
  public List<PartnerProgram_Service.ErpWrapper> erpWrappers;
  public PartnerProgram_Service.DealerOrderWrapper orderWrapper;

  protected PartnerProgram_Service.ResultMessage resultMessage;
  protected Boolean hasVerifiedBookingOrder = false;
  protected Decimal discountPercent {
    get {
      if( discountPercent == null )
      {
        discountPercent = determineSavingsPercent();
      }
      return discountPercent;
    }
    set {
      if(value == null) discountPercent = 0;
      else discountPercent = value;
    }
  }

  public PartnerProgramItem()
  {
    this.name = 'Default Partner Program Item Name';
  }

  public virtual void init( PartnerProgram_Service.DealerOrderWrapper orderWrapper )
  {
    this.orderWrapper = orderWrapper;
    this.dealerOrder = orderWrapper.dealerOrder;
    this.programYear = orderWrapper.programYear;
    this.erpWrappers = new List<PartnerProgram_Service.ErpWrapper>();
    this.resultMessage = new PartnerProgram_Service.ResultMessage();
    if( !this.orderWrapper.isBookingOrder && this.orderWrapper.bookingOrder != null )
    {
      this.hasVerifiedBookingOrder = true;
    }
    filterApplicableERPs( orderWrapper.erpWrappers );
  }

  public virtual String getName()
  {
    return this.name;
  }

  public PartnerProgram_Service.DealerOrderWrapper getOrderWrapper()
  {
    return this.orderWrapper;
  }

  public virtual String getBookingOrderFieldName()
  {
    return null;
  }

  public virtual Decimal getDiscountPercent()
  {
    return this.discountPercent.stripTrailingZeros();
  }

  public virtual PartnerProgram_Service.ResultMessage getResult()
  {
    return this.resultMessage;
  }

  public virtual Boolean isApplicable()
  {
    return false;
  }

  public virtual Boolean wasAppliedPreviously()
  {
    if( this.erpWrappers.size() == 0 ) return false;
    if( this.name == null ) return false;
    if( this.orderWrapper.appliedPrograms.contains( this.name ) ) return true;
    return false;
  }

  public virtual List<AcctSeedERP__Material__c> apply()
  {
    List<AcctSeedERP__Material__c> discounts = new List<AcctSeedERP__Material__c>();
    return discounts;
  }

  public virtual List<AcctSeedERP__Material__c> revert()
  {
    List<AcctSeedERP__Material__c> todelete = new List<AcctSeedERP__Material__c>();
    for( PartnerProgram_Service.ErpWrapper wrapper : this.erpWrappers )
    {
      for( AcctSeedERP__Material__c saving : wrapper.savingLines )
      {
        if( saving.Applied_Partner_Program_Discount__c ==  this.name )
          todelete.add(saving);
      }
    }
    return toDelete;
  }

  public Object resolve( Object dealerOrderWrapper )
  {
    PartnerProgram_Service.DealerOrderWrapper wrapper = (PartnerProgram_Service.DealerOrderWrapper)dealerOrderWrapper;
    Decimal percent = null;
    init( wrapper );
    Boolean updateDealerOrder = false;
    if( this.isApplicable() )
    {
      List<AcctSeedERP__Material__c> discountLines = this.apply();
      if( !wrapper.checkOnly ) upsert discountLines;
      percent = this.getDiscountPercent();
      wrapper.appliedPrograms.add( this.getName() );
      wrapper.result.addAppliedDiscount( this );
      updateDealerOrder = !wrapper.checkOnly;
    }
    else
    {
      if( this.wasAppliedPreviously() )
      {
        List<AcctSeedERP__Material__c> deleteMats = this.revert();
        if( !wrapper.checkOnly ) delete deleteMats;
        wrapper.appliedPrograms.remove( this.getName() );
        updateDealerOrder = !wrapper.checkOnly;
      }
    }

    if( wrapper.isBookingOrder &&
        wrapper.bookingOrder != null &&
        this.getBookingOrderFieldName() != null )
    {
      wrapper.bookingOrder.put(
        this.getBookingOrderFieldName(),
        percent
      );
      if( !wrapper.checkOnly ) upsert wrapper.bookingOrder;
    }
    if( updateDealerOrder )
      wrapper.updateDealerOrder();
    return wrapper;
  }

  protected virtual void filterApplicableERPs( List<PartnerProgram_Service.ErpWrapper> erpWrappers )
  {
    this.erpWrappers = erpWrappers;
  }

  protected virtual Decimal determineSavingsPercent()
  {
    return 0;
  }

  protected List<AcctSeedERP__Material__c> doStandardApply()
  {
    List<AcctSeedERP__Material__c> discounts = new List<AcctSeedERP__Material__c>();
    Decimal totalSavings = 0;
    for( PartnerProgram_Service.ErpWrapper wrapper : this.erpWrappers )
    {
      Decimal savings = ( wrapper.boatCost * ( this.discountPercent / 100 ) )
        .setScale(2, RoundingMode.HALF_UP );

      discounts.add(
        wrapper.buildDiscountLine( this.name, savings )
      );
      totalSavings += savings;
    }
    this.resultMessage.totalSaving = totalSavings;
    this.resultMessage.success = 'This order qualifies for the Legend Boats ' + this.name + ' @ ' + this.discountPercent + '%';
    return discounts;
  }

}