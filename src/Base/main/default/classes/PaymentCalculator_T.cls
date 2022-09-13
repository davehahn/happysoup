/**
 * Created by dave on 2019-11-13.
 */

@IsTest
private class PaymentCalculator_T {
  @IsTest
  static void constructor_Test() {
    PaymentCalculator pc1 = new PaymentCalculator(9999);
    PaymentCalculator pc2 = new PaymentCalculator(15000);
    PaymentCalculator pc3 = new PaymentCalculator(25000);
    Map<String, Decimal> variables1 = PaymentCalculator.findVariables(9999);
    Map<String, Decimal> variables2 = PaymentCalculator.findVariables(15000);
    Map<String, Decimal> variables3 = PaymentCalculator.findVariables(25000);
    System.assertEquals(variables1.get('amortization'), pc1.amortization);
    System.assertEquals(variables1.get('interestRate'), pc1.interestRate);
    System.assertEquals(variables2.get('amortization'), pc2.amortization);
    System.assertEquals(variables2.get('interestRate'), pc2.interestRate);
    System.assertEquals(variables3.get('amortization'), pc3.amortization);
    System.assertEquals(variables3.get('interestRate'), pc3.interestRate);
  }

  @IsTest
  static void calculateWeeklyPayment_Test() {
    Decimal SALEPRICE = 39999;
    Decimal UPGRADECOST = 6699;
    PaymentCalculator pc = new PaymentCalculator(SALEPRICE);
    Map<String, Decimal> variables = PaymentCalculator.findVariables(SALEPRICE);
    Decimal expected = PaymentCalculator.doWeeklyCalc(
      UPGRADECOST,
      variables.get('amortization'),
      variables.get('interestRate')
    );
    Decimal cost = pc.calculateWeeklyPayment(UPGRADECOST);
    System.assertEquals(expected, cost);
  }
}
