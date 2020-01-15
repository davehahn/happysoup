/**
 * Created by dave on 2019-08-28.
 */

public with sharing class Warehouse_Selector {

  public static Set<Id> setIdWarehouseReserved = new Set<Id>{
    GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Adjustment_Warehouse_Id__c,
    GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Transit_Warehouse_Id__c
  };

  public static List<AcctSeedERP__Warehouse__c> selectStandardWarehouses()
  {
    return [SELECT Id, Name
            FROM AcctSeedERP__Warehouse__c
            WHERE Id NOT IN :setIdWarehouseReserved
            ORDER BY CreatedDate ];
  }

  public static AcctSeedERP__Warehouse__c selectDefaultWarehouseForUser()
  {
    AcctSeedERP__Warehouse__c result;
    String dept = [ SELECT Id, Sales_Department__c
                    FROM User
                    WHERE Id = :UserInfo.getUserId() ][0].Sales_Department__c;
    for(AcctSeedERP__Warehouse__c whs : selectStandardWarehouses() )
    {
      if(whs.Name == dept)
      {
        result = whs;
        break;
      }
      result = whs;
    }
    return result;
  }
}