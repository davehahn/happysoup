/**
 * Created by dave on 2020-02-05.
 */

public with sharing class CommissionLineItem2_Selector extends Application_Selector
{

  public CommissionLineItem2_Selector()
  {
    this.sObjectName = 'CommissionLineItem2__c';
    this.fields = new List<String>{
      'Id',
      'CommissionRecord2__c',
      'CommissionRecord2__r.Status__c',
      'Quantity__c',
      'Sale_Price__c',
      'Total_Sale__c',
      'Cost__c',
      'Total_Cost__c',
      'Labour_Cost__c',
      'Total_Labour__c',
      'Product_Retail_Rigging_Time__c',
      'Profit__c',
      'Payment_Based_on_Profit__c',
      'Payment_Amount__c',
      'Description__c',
      'Product__c',
      'Product__r.Name',
      'Commission_Rate__c',
      'Comment__c',
      'Material__c',
      'Material__r.Material__c'
    };
  }

  public static List<CommissionLineItem2__c> allById( Set<Id> ids )
  {
    CommissionLineItem2_Selector selector = new CommissionLineItem2_Selector();
    selector
      .addWhere( whereInClauseBuilder(
        'Id',
        (Set<String>)JSON.deserialize( JSON.serialize(ids), Set<String>.class)
      ))
      .addOrderBy( 'Description__c DESC, Product__r.AcctSeedERP__Serialized__c DESC, Product__r.RecordType.Name' );
    return (List<CommissionLineItem2__c>)selector.query();
//    return [ SELECT Id,
//      CommissionRecord2__c,
//      CommissionRecord2__r.Status__c,
//      Quantity__c,
//      Sale_Price__c,
//      Total_Sale__c,
//      Cost__c,
//      Total_Cost__c,
//      Labour_Cost__c,
//      Product_Retail_Rigging_Time__c,
//      Profit__c,
//      Payment_Amount__c,
//      Description__c,
//      Product__c,
//      Product__r.Name,
//      Commission_Rate__c,
//      Comment__c,
//      Material__c,
//      Material__r.Material__c
//    FROM CommissionLineItem2__c
//    WHERE Id In :ids
//    ORDER BY Description__c DESC, Product__r.AcctSeedERP__Serialized__c DESC, Product__r.RecordType.Name];
  }

  public static List<CommissionLineItem2__c> allByCommissionRecordId( String comRecId )
  {
    CommissionLineItem2_Selector selector = new CommissionLineItem2_Selector();
    selector
      .addWhere( 'CommissionRecord2__c = \'' + comRecId + '\'' )
      .addOrderBy( 'Description__c DESC, Product__r.AcctSeedERP__Serialized__c DESC, Product__r.RecordType.Name' );
    return (List<CommissionLineItem2__c>)selector.query();
//    return [ SELECT Id,
//                    CommissionRecord2__c,
//                    CommissionRecord2__r.Status__c,
//                    Quantity__c,
//                    Sale_Price__c,
//                    Total_Sale__c,
//                    Cost__c,
//                    Total_Cost__c,
//                    Labour_Cost__c,
//                    Product_Retail_Rigging_Time__c,
//                    Profit__c,
//                    Payment_Amount__c,
//                    Description__c,
//                    Product__c,
//                    Product__r.Name,
//                    Commission_Rate__c,
//                    Comment__c,
//                    Material__c,
//                    Material__r.Material__c
//             FROM CommissionLineItem2__c
//             WHERE CommissionRecord2__c = :comRecId
//             ORDER BY Description__c DESC, Product__r.AcctSeedERP__Serialized__c DESC, Product__r.RecordType.Name];
  }

  public static List<CommissionLineItem2__c> allByMaterialIds( Set<Id> matIds )
  {
    CommissionLineItem2_Selector selector = new CommissionLineItem2_Selector();
    selector
      .addWhere( whereInClauseBuilder(
        'Material__c',
        (Set<String>)JSON.deserialize( JSON.serialize(matIds), Set<String>.class)
      ))
      .addOrderBy( 'Description__c DESC, Product__r.AcctSeedERP__Serialized__c DESC, Product__r.RecordType.Name' );
    return (List<CommissionLineItem2__c>)selector.query();
//    return [ SELECT Id,
//      CommissionRecord2__c,
//      CommissionRecord2__r.Status__c,
//      Quantity__c,
//      Sale_Price__c,
//      Total_Sale__c,
//      Cost__c,
//      Total_Cost__c,
//      Labour_Cost__c,
//      Product_Retail_Rigging_Time__c,
//      Profit__c,
//      Payment_Amount__c,
//      Description__c,
//      Product__c,
//      Product__r.Name,
//      Commission_Rate__c,
//      Comment__c,
//      Material__c,
//      Material__r.Material__c
//    FROM CommissionLineItem2__c
//    WHERE Material__c IN :matIds
//    ORDER BY Description__c DESC, Product__r.AcctSeedERP__Serialized__c DESC, Product__r.RecordType.Name];
  }
}