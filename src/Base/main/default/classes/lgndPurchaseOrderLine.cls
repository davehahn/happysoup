public with sharing class lgndPurchaseOrderLine {
  //	public static Boolean disableTrigger{
  //    get{
  //      if(disableTrigger == null) return false;
  //      else return disableTrigger;
  //    }
  //    set{
  //      if(value == null) disableTrigger = false;
  //      else disableTrigger = value;
  //    }
  //  }
  //
  //  public static void triggerHandler
  //    (map<Id,AcctSeedERP__Purchase_Order_Line__c> oldMap,
  //     map<Id,AcctSeedERP__Purchase_Order_Line__c> newMap,
  //     list<AcctSeedERP__Purchase_Order_Line__c> listNew,
  //     Boolean boolIsBefore,
  //     Boolean boolIsInsert,
  //     Boolean boolIsUpdate,
  //     Boolean boolIsDelete)
  //  {
  //    if(oldMap == NULL) oldMap = new map<Id,AcctSeedERP__Purchase_Order_Line__c>();
  //    if(newMap == NULL) newMap = new map<Id,AcctSeedERP__Purchase_Order_Line__c>();
  //    if(listNew == NULL) listNew = new list<AcctSeedERP__Purchase_Order_Line__c>();
  //
  //    if(boolIsBefore)
  //    {
  //      if(boolIsInsert)
  //      {
  //      }
  //      if(boolIsUpdate)
  //      {
  //        for( AcctSeedERP__Purchase_Order_Line__c pol :listNew )
  //        {
  //          if( pol.AcctSeedERP__Quantity_Unreceived__c < pol.Reserved__c )
  //          {
  //            pol.Reserved__c = pol.AcctSeedERP__Quantity_Unreceived__c;
  //          }
  //        }
  //      }
  //      if(boolIsDelete)
  //      {
  //      }
  //    }
  //    else //i.e. trigger.isAfter
  //    {
  //      if(boolIsInsert)
  //      {
  //        Set<Id> deliverDateSet = new Set<Id>();
  //        for( AcctSeedERP__Purchase_Order_Line__c pol : listNew )
  //        {
  //          if( pol.deliverDate__c != null )
  //          {
  //            deliverDateSet.add( pol.Id );
  //          }
  //        }
  //        if( deliverDateSet.size() > 0 )
  //        {
  //          PurchaseOrderLine_Service.propagateDeliveryDate( deliverDateSet );
  //        }
  //      }
  //      if(boolIsUpdate)
  //      {
  //        Map<String, Integer> pl_q_map = new Map<String, Integer>();
  //        Set<Id> prodIds = new Set<Id>();
  //        Set<Id> lotIds = new Set<Id>();
  //        Set<Id> hasDeliverDateChanges = new Set<Id>();
  //        for( AcctSeedERP__Purchase_Order_Line__c pol : listNew )
  //        {
  //           /*
  //            map to hold product-lot ids together with the value to change the
  //            productlotReservation reservedForRetail field by
  //          */
  //          AcctSeedERP__Purchase_Order_Line__c oldPol = oldMap.get( pol.Id );
  //          String idString;
  //          System.debug( '** OLD RESERVED = ' + oldPol.Reserved__c );
  //          System.debug( '** NEW RESERVED = ' + pol.Reserved__c );
  //          if( pol.Reserved__c < oldPol.Reserved__c &&
  //              pol.AcctSeedERP__Product__c != null )
  //          {
  //            prodIds.add( pol.AcctSeedERP__Product__c );
  //            idString = pol.AcctSeedERP__Product__c;
  //
  //            if( pol.GMBLASERP__Lot__c != null )
  //              idString += ( '-' + pol.GMBLASERP__Lot__c );
  //            System.debug('idString = ' + idString );
  //            pl_q_map.put( idString, Integer.valueOf( oldPol.Reserved__c - pol.Reserved__c ) );
  //          }
  //          if( pol.deliverDate__c != oldPol.deliverDate__c ||
  //              pol.AcctSeedERP__Project__c != oldPol.AcctSeedERP__Project__c )
  //          {
  //            hasDeliverDateChanges.add(pol.Id);
  //          }
  //        }
  //        if( pl_q_map.size() > 0 )
  //          updateProductLotReservation( pl_q_map, prodIds );
  //        if( hasDeliverDateChanges.size() > 0 )
  //        {
  //          PurchaseOrderLine_Service.propagateDeliveryDate( hasDeliverDateChanges );
  //        }
  //
  //      }
  //      if(boolIsDelete)
  //      {
  //
  //      }
  //    }
  //
  //  }
  //
  //  private static void updateProductLotReservation( Map<String, Integer> pl_q_map, Set<Id> prodIds )
  //  {
  //    System.debug('prodIds = ' + prodIds);
  //    List<ProductLotReservation__c> plrs = [SELECT Id,
  //                                                  Product__c,
  //                                                  Lot__c,
  //                                                  Reserved_For_Retail_Sale__c
  //                                           FROM ProductLotReservation__c
  //                                           WHERE Product__c IN :prodIds ];
  //    for( ProductLotReservation__c plr : plrs )
  //    {
  //      String idString = plr.Product__c;
  //      if( plr.Lot__c != null )
  //        idString += ('-' + plr.Lot__c);
  //      if( pl_q_map.containsKey( idString ) )
  //      {
  //        if( plr.Reserved_For_Retail_Sale__c == null )
  //          plr.Reserved_For_Retail_Sale__c = 0;
  //        plr.Reserved_For_Retail_Sale__c += pl_q_map.get( idString );
  //      }
  //    }
  //    update plrs;
  //  }
  //
  //    public static void coverage(){
  //    integer i;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //    i=1;
  //  }
}
