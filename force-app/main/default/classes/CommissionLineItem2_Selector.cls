/**
 * Created by dave on 2020-02-05.
 */

public with sharing class CommissionLineItem2_Selector
{

  public static List<CommissionLineItem2__c> allById( Set<Id> ids )
  {
    return [ SELECT Id,
      CommissionRecord2__c,
      CommissionRecord2__r.Status__c,
      Quantity__c,
      Sale_Price__c,
      Total_Sale__c,
      Cost__c,
      Total_Cost__c,
      Labour_Cost__c,
      Product_Retail_Rigging_Time__c,
      Profit__c,
      Payment_Amount__c,
      Description__c,
      Product__c,
      Product__r.Name,
      Commission_Rate__c,
      Comment__c,
      Material__c,
      Material__r.Material__c
    FROM CommissionLineItem2__c
    WHERE Id In :ids
    ORDER BY Description__c DESC, Product__r.AcctSeedERP__Serialized__c DESC, Product__r.RecordType.Name];
  }

  public static List<CommissionLineItem2__c> allByCommissionRecordId( String comRecId )
  {
    return [ SELECT Id,
                    CommissionRecord2__c,
                    CommissionRecord2__r.Status__c,
                    Quantity__c,
                    Sale_Price__c,
                    Total_Sale__c,
                    Cost__c,
                    Total_Cost__c,
                    Labour_Cost__c,
                    Product_Retail_Rigging_Time__c,
                    Profit__c,
                    Payment_Amount__c,
                    Description__c,
                    Product__c,
                    Product__r.Name,
                    Commission_Rate__c,
                    Comment__c,
                    Material__c,
                    Material__r.Material__c
             FROM CommissionLineItem2__c
             WHERE CommissionRecord2__c = :comRecId
             ORDER BY Description__c DESC, Product__r.AcctSeedERP__Serialized__c DESC, Product__r.RecordType.Name];
  }

  public static List<CommissionLineItem2__c> allByMaterialIds( Set<Id> matIds )
  {
    return [ SELECT Id,
      CommissionRecord2__c,
      CommissionRecord2__r.Status__c,
      Quantity__c,
      Sale_Price__c,
      Total_Sale__c,
      Cost__c,
      Total_Cost__c,
      Labour_Cost__c,
      Product_Retail_Rigging_Time__c,
      Profit__c,
      Payment_Amount__c,
      Description__c,
      Product__c,
      Product__r.Name,
      Commission_Rate__c,
      Comment__c,
      Material__c,
      Material__r.Material__c
    FROM CommissionLineItem2__c
    WHERE Material__c IN :matIds
    ORDER BY Description__c DESC, Product__r.AcctSeedERP__Serialized__c DESC, Product__r.RecordType.Name];
  }
}