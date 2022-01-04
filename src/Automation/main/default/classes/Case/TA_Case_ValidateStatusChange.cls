/**
 * Created by dave on 2022-01-04.
 */

public inherited sharing class TA_Case_ValidateStatusChange implements TriggerAction.BeforeUpdate
{
  public void beforeUpdate( List<Case> newList, List<Case> oldList ){
    Map<Id, Case> oldMap = new Map<Id, Case>( oldList );
    for(Case c : newList)
    {
      if( c.Can_Add_Parts__c &&
        !oldMap.get(c.Id).Can_Add_Parts__c &&
        c.Parts_Order_ERP__c != null )
      {
        c.Status.addError('This case has a related parts order. Please remove the parts order first to change status.');
      }
    }
  }
}