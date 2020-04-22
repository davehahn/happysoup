/**
 * Created by dave on 2020-02-18.
 */

public with sharing class CommissionPayment2_Service
{
  public static Decimal defaultGrossMarginPaymentPercent = 10;

  public static List<CommissionPayment2__c> createInitialPayments( Set<Id> commissionRecordIds )
  {
    List<CommissionPayment2__c> payments = new List<CommissionPayment2__c>();
    for( Id crId : commissionRecordIds )
    {
      payments.add( new CommissionPayment2__c(
        Commission_Record2__c = crId
      ));
    }
    insert payments;
    return payments;
  }

  public static void setInitialValues( List<CommissionPayment2__c> payments )
  {
    setInitialOwner( payments );
    setPaymentPercentages( payments );
  }

  public static void setInitialOwner( List<CommissionPayment2__c> payments )
  {
    Set<Id> cRecIds = new Set<Id>();
    Set<Id> ownerIds = new Set<Id>();
    for( CommissionPayment2__c payment : payments )
    {
      cRecIds.add( payment.Commission_Record2__c );
    }
    Map<Id, CommissionRecord2__c> commRecMap = CommissionRecord2_Selector.mapOfAllById_IncludingProjectTask( cRecIds );
    for( CommissionPayment2__c payment : payments )
    {
      if( commRecMap.containsKey( payment.Commission_Record2__c ) )
      {
        CommissionRecord2__c cr = commRecMap.get( payment.Commission_Record2__c );
        if( payment.Owner__c == null )
        {
          if( cr.Project_Task__r.AcctSeed__GL_Account_Variable_2__c == LGND_Constants.GLV2Id_BusinessOffice )
          {
            payment.Owner__c = cr.Project_Task__r.AcctSeed__Project__r.Business_Manager__c;
          }
          else if( cr.Project_Task__r.AcctSeed__GL_Account_Variable_2__c == LGND_Constants.GLV2Id_Sales &&
                   cr.Project_Task__r.Name.contains( 'Retail Sale' ) )
          {
            payment.Owner__c = cr.Project_Task__r.AcctSeed__Project__r.Salesperson__c;
          }
          if (payment.Owner__c == null)
          {
            payment.Owner__c = UserInfo.getUserId();
          }
        }
      }
    }
  }

  public static void setPaymentPercentages( List<CommissionPayment2__c> payments )
  {
    Set<Id> ownerIds = new Set<Id>();
    for( CommissionPayment2__c cp : payments )
    {
      ownerIds.add( cp.Owner__c );
    }
    Map<Id, User> owners = new Map<Id, User>(
      [SELECT Id, Commission_Gross_Margin_Percent_Override__c FROM User WHERE Id IN :ownerIds]
    );
    for( CommissionPayment2__c cp : payments )
    {
      cp.Gross_Margin_Payment_Percent__c =
        owners.get( cp.Owner__c).Commission_Gross_Margin_Percent_Override__c != null ?
          owners.get( cp.Owner__c ).Commission_Gross_Margin_Percent_Override__c :
          defaultGrossMarginPaymentPercent;
    }

  }

  public static void propagateCommissionRecordStageChange( Set<Id> resolved, Set<Id> unApproved )
  {
    Set<Id> commissionRecordIds = new Set<Id>();
    commissionRecordIds.addAll( resolved );
    commissionRecordIds.addAll( unApproved );
    if( commissionRecordIds.size() > 0 )
    {
      List<CommissionPayment2__c> payments = CommissionPayment2_Selector.allByCommissionRecordIds(commissionRecordIds);
      for (CommissionPayment2__c payment : payments)
      {
        if (resolved.contains(payment.Commission_Record2__c) &&
          payment.Status__c == 'Disputed')
        {
          payment.Status__c = 'New';
        }
        if (unApproved.contains(payment.Commission_Record2__c) &&
          payment.Commission_Record2__r.Status__c != 'Disputed')
        {
          payment.Status__c = 'New';
        }
      }
      update payments;
    }
  }

  @Future
  public static void autoAcceptForCommissionRecords( Set<Id> commissionRecordId )
  {
    List<CommissionPayment2__c> payments = CommissionPayment2_Selector.allNewByCommissionRecordIds( commissionRecordId );
    for( CommissionPayment2__c p : payments )
    {
      p.Status__c = 'Accepted';
      p.Auto_Accepted__c = true;
    }
    update payments;
  }

}