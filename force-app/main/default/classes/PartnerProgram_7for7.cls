/**
 * Created by dave on 2020-07-24.
 */

public virtual class PartnerProgram_7for7 extends PartnerProgramItem
{
  private Map<Id, BoatStack> stacks;
  private final Integer qualifyingCount = 7;

  public class BoatStack {
    public final Decimal discount;
    public Integer stackSize;
    public Id boatId;
    public String boatName;
    public Decimal boatCost;
    public List<PartnerProgram_Service.ErpWrapper> erpWrappers;
    public Decimal savingsPerBoat;
    public Integer count {
      get {
        return this.erpWrappers == null ? 0 : this.erpWrappers.size();
      }
    }
    public Integer completeStacks {
      get {
        return this.count / this.stackSize;
      }
    }
    public Integer incompleteCount {
      get {
        return this.count - ( this.completeStacks * this.stackSize );
      }
    }

    public String toGetPromotionMessage {
      get {
        if( incompleteCount == 0 ) return null;
        String msg =  'Add ' + ( this.stackSize - this.incompleteCount ) + ' - ' + this.boatName;
        if( this.stackSize - this.incompleteCount > 1 )
          msg += '\'s';
        msg += ' and receive a $' + String.valueOf( this.savingsPerBoat );
        msg += ' discount on each unit.';
        return msg;
      }
    }

    public BoatStack( PartnerProgram_Service.ErpWrapper wrapper, decimal discountPercent )
    {
      Product2 boat = wrapper.boatLine.AcctSeedERP__Product__r;
      this.discount = discountPercent;
      this.stackSize = boat.Stack_Size__c != null ? Integer.valueOf( boat.Stack_Size__c ) : null;
      this.boatId = boat.Id;
      this.boatName = boat.Name;
      this.boatCost = wrapper.boatCost;
      this.savingsPerBoat = ( wrapper.boatCost * ( discount / 100 ))
        .setScale(2, RoundingMode.HALF_UP );
      this.erpWrappers = new List<PartnerProgram_Service.ErpWrapper>();
    }
  }

  public PartnerProgram_7for7()
  {
    this.name = '7 for 7 Discount';
  }

  public override void init( PartnerProgram_Service.DealerOrderWrapper orderWrapper )
  {
    super.init( orderWrapper );
    this.stacks = new Map<Id, BoatStack>();
    buildStacks();
  }

  public override Boolean isApplicable()
  {
    Integer c = 0;
    for( BoatStack bs : this.stacks.values() )
    {
      if( bs.completeStacks > 0 )
        c += bs.completeStacks * bs.stackSize;
    }
    Boolean result = c >= this.qualifyingCount;
    return result;
  }

  public override List<AcctSeedERP__Material__c> apply()
  {
    system.debug('apply');
    List<AcctSeedERP__Material__c> discounts = new List<AcctSeedERP__Material__c>();
    Decimal totalSavings = 0;
    Set<Id> erpIds_withSaving = new Set<Id>();
    for( BoatStack bs : this.stacks.values() )
    {
      system.debug('bs');
      system.debug(bs);
      if( bs.completeStacks > 0 )
      {
        for( Integer i=0; i<( bs.stackSize * bs.completeStacks ); i++ )
        {
          PartnerProgram_Service.ErpWrapper wrapper = bs.erpWrappers[i];
          if( !wrapper.promotionClaimed( this.name ) )
          {
            AcctSeedERP__Material__c mtrl = wrapper.buildDiscountLine( this.name, bs.savingsPerBoat );
            if(mtrl != null){
              discounts.add(mtrl);
              totalSavings += bs.savingsPerBoat;
              erpIds_withSaving.add( wrapper.boatLine.AcctSeedERP__Project__c );
            }
          }
        }
      }
    }
    if(totalSavings <> 0) {
      this.resultMessage.totalSaving = totalSavings;
      this.resultMessage.success = 'This order qualifies for the Legend Boats 7 for 7 Promotion and has been applied. <br /> You saved a total of <b>$' + String.valueOf(totalSavings.setScale(2, RoundingMode.HALF_UP)) + '</b>';
    }
    return discounts;
  }

  protected override void filterApplicableERPs( List<PartnerProgram_Service.ErpWrapper> erpWrappers)
  {
    for( PartnerProgram_Service.ErpWrapper wrapper : erpWrappers )
    {
      if( wrapper.boatLine.AcctSeedERP__Product__r.Stack_Size__c != null )
        this.erpWrappers.add( wrapper );
    }
  }

  private void buildStacks()
  {
    for( PartnerProgram_Service.ErpWrapper ew : this.erpWrappers )
    {
      if( ew.boatLine != null )
      {
        if (!this.stacks.containsKey(ew.boatId))
          this.stacks.put( ew.boatId, new BoatStack( ew, this.discountPercent ) );
        this.stacks.get(ew.boatId).erpWrappers.add(ew);
      }
    }
  }

  protected override Decimal determineSavingsPercent()
  {
    return 7;
  }

}