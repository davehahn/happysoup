/**
 * Created by dave on 2022-01-05.
 */

public inherited sharing class TA_Case_CommentOnWarrantyERP implements TriggerAction.AfterInsert
{
  public void afterInsert( List<Case> newList ){
    List<AcctSeed__Project__c> erps = new List<AcctSeed__Project__c>();
    for( Case c : newList )
    {
      if( c.Warranty_ERP__c != null )
      {
        String comment = 'Warranty Case # ' + c.CaseNumber;
        if (c.Partner_Reference__c != null)
          comment += '<br> Partner Reference # ' + c.Partner_Reference__c;
        erps.add( new AcctSeed__Project__c(
          Id = c.Warranty_ERP__c,
          Customer_Notes__c = comment,
          Warranty_Case__c = c.Id
        ));
      }
      TriggerBase.bypass('AcctSeed__Project__c');
      update erps;
      TriggerBase.clearBypass('AcctSeed__Project__c');
    }
  }
}