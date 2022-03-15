/**
 * Created by dave on 2022-01-04.
 */

public inherited sharing class TA_Case_DeleteERPs implements TriggerAction.BeforeDelete
{
  public void beforeDelete( List<Case> oldList ){
    List<AcctSeed__Project__c> erpsToDelete = new List<AcctSeed__Project__c>();
    for( Case c : oldList )
    {
      if( c.Warranty_ERP__c != null )
      {
        erpsToDelete.add( new AcctSeed__Project__c(
          Id = c.Warranty_ERP__c
        ));
      }
    }
    delete erpsToDelete;
  }
}