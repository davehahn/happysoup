/**
 * Created by dave on 2022-01-07.
 */

public inherited sharing class TA_Case_CloseLostERPOnDenied implements TriggerAction.AfterUpdate
{
  public void afterUpdate( List<Case> newList, List<Case> oldList ){
    Map<Id, Case> oldMap = new Map<Id, Case>(oldList);
    List<AcctSeed__Project__c> erps = new List<AcctSeed__Project__c>();
    for( Case c : newList )
    {
      Case oldCase = oldMap.get(c.Id);
      if( c.Status == 'Denied' &&
        oldCase.Status != 'Denied' )
      {
        if( c.Warranty_ERP__c != null )
        {
          erps.add( new AcctSeed__Project__c(
            Id = c.Warranty_ERP__c,
            Stage__c = 'Closed Lost'
          ));
        }
        if( c.Recoverable_ERP__c != null )
        {
          erps.add( new AcctSeed__Project__c(
            Id = c.Recoverable_ERP__c,
            Stage__c = 'Closed Lost'
          ));
        }
        if( c.Parts_Order_ERP__c != null )
        {
          erps.add( new AcctSeed__Project__c(
            Id = c.Parts_Order_ERP__c,
            Stage__c = 'Closed Lost'
          ));
        }
      }
      update erps;
    }
  }
}