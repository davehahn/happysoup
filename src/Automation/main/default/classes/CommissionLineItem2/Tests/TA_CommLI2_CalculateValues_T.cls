/**
 * Created by dave on 2022-01-17.
 */

@IsTest
private class TA_CommLI2_CalculateValues_T {
  @testSetup
  static void dataSetup() {
    TA_CommLI2_TestHelper.testDataSetup();
  }

  @IsTest
  static void TA_BeforeInsert_Insurance() {
    TA_CommLI2_TestHelper helper = new TA_CommLI2_TestHelper();
    helper.initForInsurance();
    List<CommissionLineItem2__c> newList = new List<CommissionLineItem2__c>{ helper.lineItem };

    Test.startTest();
    new TA_CommLI2_CalculateValues().beforeInsert(newList);
    Test.stopTest();

    System.assertEquals(750, newList[0].Cost__c, 'Commission Line Item should have a Cost of 750');
    System.assertEquals(1000, newList[0].Sale_Price__c, 'Commission Line Item should have a Sale Price of 1000');
    System.assertEquals(250, newList[0].Profit__c, 'Commission Line Profit should be 250');
    System.assertEquals(0.30, newList[0].Commission_Rate__c, 'Commission Line, Commission Rate should be 30');
    System.assertEquals(250 * 0.3, newList[0].Payment_Amount__c);
  }

  @IsTest
  static void TA_BeforeInsert_Fee() {
    TA_CommLI2_TestHelper helper = new TA_CommLI2_TestHelper();
    helper.initForFee();
    List<CommissionLineItem2__c> newList = new List<CommissionLineItem2__c>{ helper.lineItem };

    Test.startTest();
    new TA_CommLI2_CalculateValues().beforeInsert(newList);
    Test.stopTest();

    System.assertEquals(500, newList[0].Cost__c, 'Commission Line Item should have a Cost of 500');
    System.assertEquals(0, newList[0].Sale_Price__c, 'Commission Line Item should have a Sale Price of 0');
    System.assertEquals(-500, newList[0].Profit__c, 'Commission Line Profit should be -500');
    System.assertEquals(0.10, newList[0].Commission_Rate__c, 'Commission Line, Commission Rate should be 10');
    System.assertEquals(-500 * 0.1, newList[0].Payment_Amount__c);
  }

  @IsTest
  static void Trigger_BeforeInsert_Part() {
    TA_CommLI2_TestHelper helper = new TA_CommLI2_TestHelper();
    helper.initForPart();

    Test.startTest();
    Id lineItemId = helper.insertLineItem();
    Test.stopTest();

    CommissionLineItem2__c result = [
      SELECT Id, Cost__c, Profit__c, Sale_Price__c, Commission_Rate__c, Payment_Amount__c
      FROM CommissionLineItem2__c
      WHERE Id = :lineItemId
    ];

    System.assertEquals(helper.PART_COST, result.Cost__c, 'Commission Line Item should have a Cost of 10000');
    System.assertEquals(
      helper.PART_SALE_PRICE,
      result.Sale_Price__c,
      'Commission Line Item should have a Sale Price of 20000'
    );
    System.assertEquals(
      (helper.PART_SALE_PRICE - helper.PART_COST) - (helper.retailHourlyRate * helper.RIGGING_TIME),
      result.Profit__c
    );
    System.assertEquals(0.10, result.Commission_Rate__c);
    System.assertEquals(
      0.10 * ((helper.PART_SALE_PRICE - helper.PART_COST) - (helper.retailHourlyRate * helper.RIGGING_TIME)),
      result.Payment_Amount__c
    );
  }

  @IsTest
  static void TA_BeforeUpdate_Part() {
    TA_CommLI2_TestHelper helper = new TA_CommLI2_TestHelper();
    helper.initForPart();
    helper.populateLineItemForPart();

    CommissionLineItem2__c oldRec = helper.lineItem.clone(true, true, true, true);
    CommissionLineItem2__c newRec = helper.lineItem.clone(true, true, true, true);

    newRec.Sale_Price__c = 25000;

    List<CommissionLineItem2__c> oldList = new List<CommissionLineItem2__c>{ oldRec };
    List<CommissionLineItem2__c> newList = new List<CommissionLineItem2__c>{ newRec };

    Test.startTest();
    new TA_CommLI2_CalculateValues().beforeUpdate(newList, oldList);
    Test.stopTest();

    System.assertEquals(helper.PART_COST, newList[0].Cost__c, 'Commission Line Item should have a Cost of 10000');
    System.assertEquals(25000, newList[0].Sale_Price__c, 'Commission Line Item should have a Sale Price of 25000');
    System.assertEquals(
      (25000 - helper.PART_COST) - (helper.retailHourlyRate * helper.RIGGING_TIME),
      newList[0].Profit__c
    );
    System.assertEquals(0.10, newList[0].Commission_Rate__c);
    System.assertEquals(
      0.10 * ((25000 - helper.PART_COST) - (helper.retailHourlyRate * helper.RIGGING_TIME)),
      newList[0].Payment_Amount__c
    );
  }
}
