/**
 * Created by dave on 2020-02-21.
 */

public with sharing class CommissionPayment2_Selector extends Application_Selector
{

  public CommissionPayment2_Selector()
  {
    this.sObjectName = 'CommissionPayment2__c';
    this.fields = new List<String>{
      'Id',
      'Owner__c',
      'Type__c',
      'Owner__r.Name',
      'Owner__r.SmallPhotoUrl',
      'Amount__c',
      'Status__c',
      'Gross_Margin_Payment_Percent__c',
      'Use_Gross_Margin_Calculation__c',
      'Split_Percent__c',
      'Commission_Record2__c',
      'Commission_Record2__r.Total_Profit__c',
      'Commission_Record2__r.Total_Payment_Amount__c',
      'Commission_Record2__r.Status__c'
    };
  }

  public static List<CommissionPayment2__c> allByIds( Set<Id> ids )
  {
    CommissionPayment2_Selector selector = new CommissionPayment2_Selector();
    selector.addWhere(
      whereInClauseBuilder(
        'Id',
        (Set<String>)JSON.deserialize( JSON.serialize(ids), Set<String>.class )
      )
    )
    .addOrderBy('Owner__r.Name ASC');
    return (List<CommissionPayment2__c>)selector.query();
//    return[
//      SELECT
//        Id,
//        Owner__c,
//        Owner__r.Name,
//        Owner__r.SmallPhotoUrl,
//        Amount__c,
//        Status__c,
//        Gross_Margin_Payment_Percent__c,
//        Use_Gross_Margin_Calculation__c,
//        Split_Percent__c,
//        Commission_Record2__c,
//        Commission_Record2__r.Total_Profit__c,
//        Commission_Record2__r.Total_Payment_Amount__c,
//        Commission_Record2__r.Status__c
//      FROM CommissionPayment2__c
//      WHERE Id IN :ids
//      ORDER BY Owner__r.Name ASC
//    ];
  }


  public static List<CommissionPayment2__c> allByCommissionRecordId( String cRecId )
  {
    CommissionPayment2_Selector selector = new CommissionPayment2_Selector();
    selector.addWhere('Commission_Record2__c = \'' + cRecId + '\'' )
    .addOrderBy( 'Owner__r.Name ASC' );
    return (List<CommissionPayment2__c>)selector.query();
  }

  public static List<CommissionPayment2__c> allByCommissionRecordIds( Set<Id> commissionRecordIds )
  {
    CommissionPayment2_Selector selector = new CommissionPayment2_Selector();
    selector.addWhere( whereInClauseBuilder(
      'Commission_Record2__c',
      (Set<String>)JSON.deserialize( JSON.serialize(commissionRecordIds), Set<String>.class )
    ))
      .addOrderBy('Owner__r.Name ASC');
    return (List<CommissionPayment2__c>)selector.query();
  }

  public static List<CommissionPayment2__c> allNewByCommissionRecordIds( Set<Id> commissionRecordIds )
  {
    CommissionPayment2_Selector selector = new CommissionPayment2_Selector();
    selector.addWhere( whereInClauseBuilder(
      'Commission_Record2__c',
      (Set<String>)JSON.deserialize( JSON.serialize(commissionRecordIds), Set<String>.class )
    ))
      .addWhere('Status__c = \'New\'')
      .addOrderBy('Owner__r.Name ASC');
    return (List<CommissionPayment2__c>)selector.query();
  }

//  public static List<CommissionPayment2__c> allDisputedByCommissionRecordIdsAndStatus( Set<Id> cRecIds, String status )
//  {
//    CommissionPayment2_Selector selector = new CommissionPayment2_Selector();
//    selector.addWhere( whereInClauseBuilder(
//      'Commission_Record2__c',
//      (Set<String>)JSON.deserialize( JSON.serialize(cRecIds), Set<String>.class )
//    ))
//      .addWhere('Status__c = \'' + status + '\'')
//      .addOrderBy('Owner__r.Name ASC');
//    return (List<CommissionPayment2__c>)selector.query();
//  }

}