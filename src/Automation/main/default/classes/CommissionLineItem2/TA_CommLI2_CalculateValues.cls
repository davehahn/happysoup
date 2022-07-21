/**
 * Created by dave on 2022-01-14.
 */

public without sharing class TA_CommLI2_CalculateValues implements TriggerAction.BeforeInsert, TriggerAction.BeforeUpdate {
  public void beforeInsert(List<CommissionLineItem2__c> newList) {
    doCalculation(newList);
  }

  public void beforeUpdate(List<CommissionLineItem2__c> newList, List<CommissionLineItem2__c> oldList) {
    doCalculation(newList);
  }

  private void doCalculation(List<CommissionLineItem2__c> newList) {
    CommissionLineItem2_Service.RateCostCalculator rateCalculator = new CommissionLineItem2_Service.RateCostCalculator(
      newList
    );

    for (CommissionLineItem2__c cli : newList) {
      if (cli.Product__c != null) {
        rateCalculator.calculate(cli);
      }
      calculateValues(cli);
    }
  }

  private static void calculateValues(CommissionLineItem2__c cli) {
    Decimal riggingTime = cli.Product_Retail_Rigging_Time__c == null ? 0 : cli.Product_Retail_Rigging_Time__c;
    if (cli.Labour_Cost__c == null) {
      cli.Labour_Cost__c = LGND_Constants.retailLabourRate * riggingTime;
    }

    cli.Profit__c = (cli.Sale_Price__c - cli.Cost__c - cli.Labour_Cost__c) * cli.Quantity__c;

    if (cli.Payment_Based_on_Profit__c) {
      cli.Payment_Amount__c = cli.Profit__c * cli.Commission_Rate__c;
      cli.Actual_Amount_for_Commission__c = cli.Profit__c;
    } else {
      System.debug('COMMISSION LINE RATE');
      System.debug(cli.Commission_Rate__c);
      cli.Payment_Amount__c = cli.Sale_Price__c * cli.Quantity__c * cli.Commission_Rate__c;
      cli.Actual_Amount_for_Commission__c = cli.Sale_Price__c * cli.Quantity__c;
    }
  }
}
