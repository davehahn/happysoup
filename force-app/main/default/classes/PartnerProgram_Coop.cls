/**
 * Created by dave on 2020-08-04.
 */

public virtual class PartnerProgram_Coop extends PartnerProgramItem
{

  private final Decimal discountPercent = 2;

  public PartnerProgram_Coop()
  {
    this.name = 'Coop Discount';
  }

  public override Boolean isApplicable()
  {
    return this.orderWrapper.erpWrappers.size() > 0;
  }

  public override List<AcctSeedERP__Material__c> apply()
  {
    return this.doStandardApply();
  }

  protected override Decimal determineSavingsPercent()
  {
    return 2;
  }

}