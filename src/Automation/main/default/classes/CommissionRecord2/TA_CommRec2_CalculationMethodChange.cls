/**
 * Created by dave on 2022-01-13.
 */

public without sharing class TA_CommRec2_CalculationMethodChange implements TriggerAction.AfterUpdate
{
  public void afterUpdate( List<CommissionRecord2__c> newList, List<CommissionRecord2__c> oldList){
    Map<Id, CommissionRecord2__c> oldMap = new Map<Id, CommissionRecord2__c>(oldList);
    Set<Id> calcHasChanged = new Set<Id>();
    for( CommissionRecord2__c rec : newList )
    {
      CommissionRecord2__c oldRec = oldMap.get(rec.Id);
      if (rec.Calculation_Method__c != oldRec.Calculation_Method__c)
      {
        calcHasChanged.add( rec.Id );
      }
    }
    if( calcHasChanged.size() > 0 )
    {
      CommissionLineItem2_Service service = new CommissionLineItem2_Service();
      service.recalculate( calcHasChanged );
    }
  }
}