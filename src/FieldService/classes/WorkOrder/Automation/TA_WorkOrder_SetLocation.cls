/**
 * Created by dave on 2021-06-03.
 */

public inherited sharing class TA_WorkOrder_SetLocation implements TriggerAction.BeforeInsert
{

  public void beforeInsert(List<WorkOrder> newList) {
    System.debug('I am here on after insert');
    setLocationOnWO(newList);
  }

  private static void setLocationOnWO(List<WorkOrder> newList) {
    System.debug('*** TA_WorkOrder_SetLocation ***');
    Map<String, AcctSeedERP__Warehouse__c> wh_name_map = new Map<String, AcctSeedERP__Warehouse__c>();
    User currentUser = Application_Constants.getInstance().currentUser;
    Set<Id> whIds = new Set<Id>();
    Schema.Location loc;
    for( AcctSeedERP__Warehouse__c wh : Warehouse_Selector.selectStandardWarehouses() )
    {
      whIds.add( wh.Id );
      wh_name_map.put(wh.Name, wh);
    }

    if( wh_name_map.containsKey( currentUser.Warehouse__c ) ) {
      try {
        loc = [SELECT Id FROM Location WHERE Warehouse__c = :wh_name_map.get( currentUser.Warehouse__c ).Id];
      } catch (Exception e) {
      }
    }
    if( loc != null )
    {
      for( WorkOrder wo : newList )
      {
        if( wo.LocationId == null )
        {
          wo.LocationId = loc.Id;
        }
      }
    }
  }

}