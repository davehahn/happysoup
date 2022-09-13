/**
 * Created by dave on 2019-11-13.
 */

public with sharing class PaymentCalculator {
  public Decimal salePrice;
  public Decimal amortization;
  public Decimal interestRate;
  private static List<Payment_Variable__mdt> paymentVariables {
    get {
      if (paymentVariables == null) {
        paymentVariables = [
          SELECT Upper_Sale_Total__c, Lower_Sale_Total__c, Amortization__c, Interest_Rate__c
          FROM Payment_Variable__mdt
          ORDER BY Lower_Sale_Total__c ASC
        ];
      }
      return paymentVariables;
    }
    set {
    }
  }

  public PaymentCalculator(Decimal salePrice) {
    this.salePrice = salePrice;
    setVariables();
  }

  public Decimal calculateWeeklyPayment(Decimal upgradeCost) {
    return doWeeklyCalc(upgradeCost, this.amortization, this.interestRate);
  }

  private void setVariables() {
    Map<String, Decimal> result = findVariables(this.salePrice);
    this.amortization = result.get('amortization');
    this.interestRate = result.get('interestRate');
  }

  @TestVisible
  private static Map<String, Decimal> findVariables(Decimal salePrice) {
    Map<String, Decimal> result = new Map<String, Decimal>();
    for (Payment_Variable__mdt var : paymentVariables) {
      if (salePrice >= var.Lower_Sale_Total__c) {
        result.put('amortization', var.Amortization__c);
        result.put('interestRate', var.Interest_Rate__c);
      }
    }
    return result;
  }

  @TestVisible
  private static Decimal doWeeklyCalc(Decimal upgradeCost, Decimal amortization, Decimal interestRate) {
    Double payments = amortization / 12 * 52;
    Double effectiveInterestRate = interestRate / 100 / 52;
    Decimal result =
      upgradeCost *
      ((effectiveInterestRate * Math.pow((1 + effectiveInterestRate), payments)) /
      (Math.pow((1 + effectiveInterestRate), payments) - 1));
    return result.setScale(2);
  }
}
