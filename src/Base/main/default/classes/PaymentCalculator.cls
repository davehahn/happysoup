/**
 * Created by dave on 2019-11-13.
 */

public with sharing class PaymentCalculator {
  public Decimal salePrice;
  public Decimal amortization;
  public Decimal interestRate;

  public PaymentCalculator(Decimal salePrice) {
    this.salePrice = salePrice;
    setVariables();
  }

  public Decimal calculateWeeklyPayment(Decimal upgradeCost) {
    Double payments = this.amortization / 12 * 52;
    Double effectiveInterestRate = this.interestRate / 100 / 52;
    Decimal result =
      upgradeCost *
      ((effectiveInterestRate * Math.pow((1 + effectiveInterestRate), payments)) /
      (Math.pow((1 + effectiveInterestRate), payments) - 1));
    return result.setScale(2);
  }

  private void setVariables() {
    for (Payment_Variable__mdt var : [
      SELECT Upper_Sale_Total__c, Lower_Sale_Total__c, Amortization__c, Interest_Rate__c
      FROM Payment_Variable__mdt
      ORDER BY Lower_Sale_Total__c ASC
    ]) {
      if (this.salePrice >= var.Lower_Sale_Total__c) {
        this.amortization = var.Amortization__c;
        this.interestRate = var.Interest_Rate__c;
      }
    }
  }
}
