/**
 * Created by dave on 2021-07-27.
 */

public inherited sharing class TA_POL_SetReserved
  implements TriggerAction.BeforeUpdate
{

  public void beforeUpdate(
    List<AcctSeedERP__Purchase_Order_Line__c> newList,
    List<AcctSeedERP__Purchase_Order_Line__c> oldList
  )
  {
    for( AcctSeedERP__Purchase_Order_Line__c pol :newList )
    {
      if( pol.AcctSeedERP__Quantity_Unreceived__c < pol.Reserved__c )
      {
        pol.Reserved__c = pol.AcctSeedERP__Quantity_Unreceived__c;
      }
    }
  }

}