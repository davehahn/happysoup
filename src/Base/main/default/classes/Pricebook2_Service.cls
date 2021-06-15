/**
 * Created by dave on 2020-01-29.
 */

public with sharing class Pricebook2_Service
{

  public static Map<Id, Id> getRetailToFactory_Map()
  {
    Map<Id, Id> retail2Factory_Map = new Map<Id, Id>();
    Map<String, Id> retail_pbId2Year_Map = new Map<String, Id>();
    Map<String, Id> factory_pbId2Year_Map = new Map<String, Id>();
    Id retailRT = LGND_Utilities.recordTypeIdFromName('Pricebook2', 'Sales');
    Id factoryRT = LGND_Utilities.recordTypeIdFromName('Pricebook2', 'Factory');
    Set<Id> pbs = new Set<Id>{ retailRT, factoryRT };
    for( Pricebook2 pb : [SELECT Id, Sales_Year__c, RecordTypeId FROM Pricebook2 WHERE RecordTYpeId IN : pbs] )
    {
      if( pb.RecordTypeId == retailRT )
      {
        retail_pbId2Year_Map.put( pb.Sales_Year__c, pb.Id );
      }
      if( pb.RecordTypeId == factoryRT )
      {
        factory_pbId2Year_Map.put( pb.Sales_Year__c, pb.Id );
      }
    }
    for( String year : retail_pbId2Year_Map.keySet() )
    {
      if( factory_pbId2Year_Map.containsKey( year ) )
      {
        retail2Factory_Map.put( retail_pbId2Year_Map.get( year ), factory_pbId2Year_Map.get( year ) );
      }
    }
    return retail2Factory_Map;
  }
}