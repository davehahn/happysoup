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
    System.assertEquals(84, pc1.amortization);
    System.assertEquals(7.99, pc1.interestRate);
    System.assertEquals(180, pc2.amortization);
    System.assertEquals(5.99, pc2.interestRate);
    System.assertEquals(240, pc3.amortization);
    System.assertEquals(5.99, pc3.interestRate);
  }

  @IsTest
  static void calculateWeeklyPayment_Test() {
    PaymentCalculator pc = new PaymentCalculator(39999);
    Decimal cost = pc.calculateWeeklyPayment(6699);
    System.assertEquals(11.06, cost);
  }
}
