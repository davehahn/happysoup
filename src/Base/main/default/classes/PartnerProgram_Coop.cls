/**
 * Created by dave on 2020-08-04.
 */

public virtual class PartnerProgram_Coop extends PartnerProgramItem
{

  public PartnerProgram_Coop()
  {
    this.name = 'Coop Discount';
  }

  public override Boolean isApplicable()
  {
    return this.erpWrappers.size() > 0;
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
    return Partner_Program_Settings__c.getOrgDefaults().Coop_Discount_Percent__c;
  }

}