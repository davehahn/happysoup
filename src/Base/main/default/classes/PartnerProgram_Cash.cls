/**
 * Created by dave on 2020-08-07.
 */

public virtual class PartnerProgram_Cash extends PartnerProgramItem {
  private Decimal orderTotal = 0;

  public PartnerProgram_Cash() {
    this.name = 'Cash Discount';
  }

  public override Boolean isApplicable() {
    return this.orderWrapper.isCashOrder;
  }

  public override List<AcctSeedERP__Material__c> apply() {
    system.debug('cash apply');
    List<AcctSeedERP__Material__c> discounts = new List<AcctSeedERP__Material__c>();
    Decimal totalSavings = 0;
    for (PartnerProgram_Service.ErpWrapper wrapper : this.erpWrappers) {
      Decimal erpTotal = 0;
      for (AcctSeedERP__Material__c mat : wrapper.allLines) {
        if (
          mat.Applied_Partner_Program_Discount__c == null ||
          (mat.Applied_Partner_Program_Discount__c != null &&
          mat.Applied_Partner_Program_Discount__c != this.name)
        ) {
          erpTotal += mat.GMBLASERP__Unit_Price__c;
        }
      }
      Decimal savings = (erpTotal * (this.discountPercent / 100)).setScale(2, RoundingMode.HALF_UP);

      discounts.add(wrapper.buildDiscountLine(this.name, savings));
      totalSavings += savings;
    }
    this.resultMessage.totalSaving = totalSavings;
    this.resultMessage.success = 'This order qualifies for the Legend Boats ' + this.name;
    return discounts;
  }

  protected override Decimal determineSavingsPercent() {
    return PartnerProgram_Cash.determinePercentageFromDate(this.orderWrapper.createdDate);
  }

  public static Decimal determinePercentageFromDate( Date orderCreatedDate ){
    /* ***** 2022 *****/
    //    if (orderCreatedDate.month() >= 8) {
    //      if (orderCreatedDate.month() == 12 && orderCreatedDate.day() > 18) {
    //        return 1;
    //      }
    //      return 3;
    //    }
    //    return 1;
    /* ***** 2023 ****/
    return orderCreatedDate.month() >= 9 ? 2 : 1;
  }
}
