/**
 * Created by dave on 2020-02-21.
 */

public with sharing class CommissionPayment2_Selector
{

  public static List<CommissionPayment2__c> allByIds( Set<Id> ids )
  {
    return[
      SELECT
        Id,
        Owner__c,
        Owner__r.Name,
        Owner__r.SmallPhotoUrl,
        Amount__c,
        Status__c,
        Gross_Margin_Payment_Percent__c,
        Use_Gross_Margin_Calculation__c,
        Split_Percent__c,
        Commission_Record2__c,
        Commission_Record2__r.Total_Profit__c,
        Commission_Record2__r.Total_Payment_Amount__c,
        Commission_Record2__r.Status__c
      FROM CommissionPayment2__c
      WHERE Id IN :ids
      ORDER BY Owner__r.Name ASC
    ];
  }


  public static List<CommissionPayment2__c> allByCommissionRecordId( String cRecId )
  {
    return[
      SELECT
        Id,
        Owner__c,
        Owner__r.Name,
        Owner__r.SmallPhotoUrl,
        Amount__c,
        Status__c,
        Gross_Margin_Payment_Percent__c,
        Use_Gross_Margin_Calculation__c,
        Split_Percent__c,
        Commission_Record2__c,
        Commission_Record2__r.Total_Profit__c,
        Commission_Record2__r.Total_Payment_Amount__c,
        Commission_Record2__r.Status__c
      FROM CommissionPayment2__c
      WHERE Commission_Record2__c = :cRecId
      ORDER BY Owner__r.Name ASC
    ];
  }

  public static List<CommissionPayment2__c> allByCommissionRecordIds( Set<Id> commissionRecordIds )
  {
    return [
      SELECT
        Id,
        Owner__c,
        Owner__r.Name,
        Owner__r.SmallPhotoUrl,
        Amount__c,
        Status__c,
        Gross_Margin_Payment_Percent__c,
        Use_Gross_Margin_Calculation__c,
        Split_Percent__c,
        Commission_Record2__c,
        Commission_Record2__r.Total_Profit__c,
        Commission_Record2__r.Total_Payment_Amount__c,
        Commission_Record2__r.Status__c
      FROM CommissionPayment2__c
      WHERE Commission_Record2__c = :commissionRecordIds
      ORDER BY Owner__r.Name ASC
    ];
  }

  public static List<CommissionPayment2__c> allNewByCommissionRecordIds( Set<Id> commissionRecordIds )
  {
    return [
      SELECT
        Id,
        Owner__c,
        Owner__r.Name,
        Owner__r.SmallPhotoUrl,
        Amount__c,
        Status__c,
        Gross_Margin_Payment_Percent__c,
        Use_Gross_Margin_Calculation__c,
        Split_Percent__c,
        Commission_Record2__c,
        Commission_Record2__r.Total_Profit__c,
        Commission_Record2__r.Total_Payment_Amount__c,
        Commission_Record2__r.Status__c
      FROM CommissionPayment2__c
      WHERE Commission_Record2__c = :commissionRecordIds
      AND Status__c = 'New'
      ORDER BY Owner__r.Name ASC
    ];
  }

  public static List<CommissionPayment2__c> allDisputedByCommissionRecordIdsAndStatus( Set<Id> cRecIds, String status )
  {
    return[
      SELECT
        Id,
        Owner__c,
        Owner__r.Name,
        Owner__r.SmallPhotoUrl,
        Amount__c,
        Status__c,
        Gross_Margin_Payment_Percent__c,
        Use_Gross_Margin_Calculation__c,
        Split_Percent__c,
        Commission_Record2__c,
        Commission_Record2__r.Total_Profit__c,
        Commission_Record2__r.Total_Payment_Amount__c,
        Commission_Record2__r.Status__c
      FROM CommissionPayment2__c
      WHERE Commission_Record2__c IN :cRecIds
      AND Status__c = :status
      ORDER BY Owner__r.Name ASC
    ];
  }

}