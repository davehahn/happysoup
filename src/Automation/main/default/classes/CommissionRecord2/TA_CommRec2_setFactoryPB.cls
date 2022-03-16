/**
 * Created by dave on 2022-01-12.
 */

public without sharing class TA_CommRec2_setFactoryPB implements TriggerAction.BeforeInsert
{
  public void beforeInsert( List<CommissionRecord2__c> newList){
    Map<Id, Id> retail2Factory_Map = Pricebook2_Service.getRetailToFactory_Map();
    System.debug(retail2Factory_Map);
    for( CommissionRecord2__c cr : newList )
    {
      if( retail2Factory_Map.containsKey( cr.Retail_Pricebook__c ) )
      {
        cr.Factory_Pricebook__c = retail2Factory_Map.get( cr.Retail_Pricebook__c );
      }
    }
  }
}