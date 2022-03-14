/**
 * Created by dave on 2020-08-07.
 */
/* TODO: DELETE ME */
public without sharing class DealerOrder_TriggerHandler extends TriggerHandler
{
//  public static Boolean disableStagePropagation
//  {
//    get
//    {
//      if (disableStagePropagation == null) return false; else return disableStagePropagation;
//    }
//    set
//    {
//      if (value == null) disableStagePropagation = false; else disableStagePropagation = value;
//    }
//  }
//
////  protected override void bulkBefore()
////  {
////    system.debug('[DealerOrder_TriggerHandler] bulk before');
////  }
//
////  protected override void bulkAfter()
////  {
////    system.debug('[DealerOrder_TriggerHandler] bulk after');
////  }
//
//  protected override void beforeInsert()
//  {
//    for (Dealer_Order__c dealerOrder : (List<Dealer_Order__c>) Trigger.new)
//    {
//      if (dealerOrder.Stage__c == 'Pending Review')
//        dealerOrder.Date_Submitted__c = DateTime.now();
//    }
//  }
//
//  protected override void beforeUpdate()
//  {
//    Map<Id, Dealer_Order__c> oldMap = (Map<Id, Dealer_Order__c>) Trigger.oldMap;
//    for (Dealer_Order__c dealerOrder : (List<Dealer_Order__c>) Trigger.new)
//    {
//      Dealer_Order__c oldOrder = oldMap.get(dealerOrder.Id);
//      if (dealerOrder.Stage__c == 'Pending Review' &&
//        oldOrder.Stage__c == 'Draft')
//        dealerOrder.Date_Submitted__c = DateTime.now();
//      if (dealerOrder.Stage__c == 'Draft')
//        dealerOrder.Date_Submitted__c = null;
//    }
//  }
//
//  protected override void beforeDelete()
//  {
//    Map<Id, Dealer_Order__c> oldMap = (Map<Id, Dealer_Order__c>) Trigger.oldMap;
//    Map<Id, List<Dealer_Order_Line__c>> dealerOrderLinesByDealerOrderId = new Map<id, List<Dealer_Order_Line__c>>();
//    Set<Id> erpIdsToDelete = new Set<Id>();
//    for( Dealer_Order_Line__c dol : DealerOrderLine_Selector.allBYDealerOrder( oldMap.keySet() ) )
//    {
//      if( !dealerOrderLinesByDealerOrderId.containsKey( dol.Dealer_Order__c) )
//      {
//        dealerOrderLinesByDealerOrderId.put( dol.Dealer_Order__c, new List<Dealer_Order_Line__c>() );
//      }
//      dealerOrderLinesByDealerOrderId.get( dol.Dealer_Order__c ).add( dol );
//    }
//    for( Dealer_Order__c dOrder : (List<Dealer_Order__c>)Trigger.old )
//    {
//      if (dOrder.Stage__c != 'Draft')
//      {
//        dOrder.addError('You can not delete a Dealer Order with stage "' + dOrder.Stage__c + '"');
//      }
//      else
//      {
//        if( dealerOrderLinesByDealerOrderId.containsKey( dOrder.Id ) )
//        {
//          for (Dealer_Order_Line__c dol : dealerOrderLinesByDealerOrderId.get(dOrder.Id))
//          {
//            if( dol.ERP_Order__r.Reserved_For_Customer_Account__c != null )
//            {
//              String err = 'You can not delete this Dealer Order.  One of the Line items is currently reserved for ' +
//                dol.ERP_Order__r.Reserved_For_Customer_Account__r.Name;
//              dOrder.addError( err );
//            }
//            else
//            {
//              erpIdsToDelete.add(dol.ERP_Order__c);
//            }
//          }
//        }
//      }
//    }
//    DealerOrderLine_TriggerHandler.deleteERPs(erpIdsToDelete);
//  }
//
//  protected override void afterInsert()
//  {
//    createRequiredPartnerBookingOrders((List<Dealer_Order__c>) Trigger.new);
//  }
//
//  protected override void afterUpdate()
//  {
//    Map<Id, Dealer_Order__c> oldMap = (Map<Id, Dealer_Order__c>)Trigger.oldMap;
//    Map<Id, Dealer_Order__c> stageChangeMap = new Map<Id, Dealer_Order__c>();
//    Map<Id, Id> ownerChanged = new Map<Id, Id>();
//    for( Dealer_Order__c newOrder : (List<Dealer_Order__c>)Trigger.new )
//    {
//      Dealer_Order__c oldOrder = oldMap.get( newOrder.Id );
//      if (!disableStagePropagation)
//      {
//        if( oldOrder.Stage__c != newOrder.Stage__c )
//          stageChangeMap.put( newOrder.Id, newOrder );
//      }
//      if( oldOrder.OwnerId != newOrder.OwnerId )
//      {
//        ownerChanged.put( newOrder.Id, newOrder.OwnerId );
//      }
//    }
//    propagateOwner( ownerChanged );
//    setErpStage( stageChangeMap );
//  }
//
////  protected override void afterDelete()
////  {
////    system.debug('[DealerOrder_TriggerHandler] after delete');
////  }
//
////  protected override void afterUndelete()
////  {
////    system.debug('[DealerOrder_TriggerHandler] after undelete');
////  }
//
////  protected override void finalActions()
////  {
////    system.debug('[DealerOrder_TriggerHandler] final actions');
////  }
//
//  private static void propagateOwner( Map<Id, Id> ownerChanged )
//  {
//    if( ownerChanged.size() == 0 ) return;
//
//    Map<Id, Id> erpDOrderMap = new Map<Id, Id>();
//    for (Dealer_Order_Line__c dol : [
//      SELECT ERP_Order__c, Dealer_Order__c
//      FROM Dealer_Order_Line__c
//      WHERE Dealer_Order__c IN :ownerChanged.keySet()
//    ])
//    {
//      erpDOrderMap.put(dol.ERP_Order__c, dol.Dealer_Order__c);
//    }
//    AcctSeed__Project__c[] erps = [
//      SELECT Id, (
//        SELECT Id
//        FROM AcctSeedERP__Project_Materials__r
//      )
//      FROM AcctSeed__Project__c
//      WHERE Id IN :erpDOrderMap.keySet()
//    ];
//    AcctSeedERP__Material__c[] updateMats = new List<AcctSeedERP__Material__c>();
//    for (AcctSeed__Project__c erp : erps)
//    {
//      Id doId = erpDOrderMap.get(erp.Id);
//      erp.OwnerId = ownerChanged.get(doId);
//      for (AcctSeedERP__Material__c m : erp.AcctSeedERP__Project_Materials__r)
//      {
//        m.OwnerId = ownerChanged.get(doId);
//        updateMats.add(m);
//      }
//    }
//    Boolean origProgTrig = gcProject.disableTrigger;
//    Boolean origMatTrig = gcMaterial.disableTrigger;
//    gcProject.disableTrigger = true;
//    gcMaterial.disableTrigger = true;
//    update erps;
//    update updateMats;
//    gcProject.disableTrigger = origProgTrig;
//    gcMaterial.disableTrigger = origMatTrig;
//  }
//
//  private static void createRequiredPartnerBookingOrders( List<Dealer_Order__c> listNew )
//  {
//    List<Partner_Booking_Order__c> orders = new List<Partner_Booking_Order__c>();
//    for( Dealer_Order__c dOrder : listNew )
//    {
//      if( dOrder.Is_Booking_Order__c )
//      {
//        orders.add( new Partner_Booking_Order__c(
//          Dealer_Order__c = dOrder.Id,
//          Name = dOrder.Program_Year__c,
//          Account__c = dOrder.Account__c
//        ));
//      }
//    }
//    if( orders.size() > 0 )
//      insert orders;
//  }
//
//  private static void setErpStage( Map<Id, Dealer_Order__c> newMap )
//  {
//    if( newMap.size() == 0 ) return;
//    //Stages that are greater than (passed) Plan Load
//    Set<String> highStages = new Set<String>{
//      //'Tagging Pending',
//      'Ready to Ship',
//      'Delivered',
//      'Closed Lost'
//    };
//    AcctSeed__Project__c[] erps = new List<AcctSeed__Project__c>();
//    Set<Id> dealerOrdeIds_WithMotorTransferRequests = new Set<Id>();
//    Legend_Transfer_Request__c[] transfers = new List<Legend_Transfer_Request__c>();
//    Dealer_Order_Line__c[] dols = [SELECT Id,
//      Dealer_Order__c,
//      Dealer_Order__r.Merc_Order_Sent__c,
//      ERP_Order__c,
//      ERP_Order__r.Stage__c,
//      Legend_Transfer_Request__c,
//      Dealer_Motor_Request__c
//    FROM Dealer_Order_Line__c
//    WHERE Dealer_Order__c IN :newMap.keySet() ];
//    for( Dealer_Order_Line__c dol : dols )
//    {
//      /*
//        Draft
//      */
//      if( newMap.get( dol.Dealer_Order__c ).Stage__c == 'Draft' )
//      {
//        if( dol.ERP_Order__c != null && !highStages.contains( dol.Erp_Order__r.Stage__c ) )
//        {
//          AcctSeed__Project__c erp = new AcctSeed__Project__c(
//            Id = dol.ERP_Order__c,
//            Stage__c = 'Draft'
//          );
//          erps.add( erp );
//        }
////        if( dol.Legend_Transfer_Request__c != null )
////        {
////          transfers.add( new Legend_Transfer_Request__c(
////            Id = dol.Legend_Transfer_Request__c,
////            Stage__c = 'Draft'
////          )
////          );
////        }
//      }
//      /*
//        "Pending Review"
//      */
//      if( newMap.get( dol.Dealer_Order__c ).Stage__c == 'Pending Review' )
//      {
//        if( dol.ERP_Order__c != null && !highStages.contains( dol.Erp_Order__r.Stage__c ) )
//        {
//          AcctSeed__Project__c erp = new AcctSeed__Project__c(
//            Id = dol.ERP_Order__c,
//            Stage__c = 'Pending Review'
//          );
//          erps.add( erp );
//        }
////        if( dol.Legend_Transfer_Request__c != null )
////        {
////          transfers.add( new Legend_Transfer_Request__c(
////            Id = dol.Legend_Transfer_Request__c,
////            Stage__c = 'Plan Load'
////          )
////          );
////        }
//      }
//      /*
//       "Pending Financing"
//     */
//      if( newMap.get( dol.Dealer_Order__c ).Stage__c == 'Pending Financing' )
//      {
//        if( dol.ERP_Order__c != null && !highStages.contains( dol.Erp_Order__r.Stage__c ) )
//        {
//          AcctSeed__Project__c erp = new AcctSeed__Project__c(
//            Id = dol.ERP_Order__c,
//            Stage__c = 'Pending Financing'
//          );
//          erps.add( erp );
//        }
//        if( dol.Dealer_Motor_Request__c != null &&
//          !dol.Dealer_Order__r.Merc_Order_Sent__c)
//          dealerOrdeIds_WithMotorTransferRequests.add( dol.Dealer_Order__c);
//      }
//      /*
//        "Approved"
//      */
//      if( newMap.get( dol.Dealer_Order__c ).Stage__c == 'Approved' )
//      {
//        if( dol.ERP_Order__c != null && !highStages.contains( dol.Erp_Order__r.Stage__c ) )
//        {
//          AcctSeed__Project__c erp = new AcctSeed__Project__c(
//            Id = dol.ERP_Order__c,
//            Stage__c = 'Tagging Pending'
//          );
//          erps.add( erp );
//        }
//        if( dol.Dealer_Motor_Request__c != null &&
//          !dol.Dealer_Order__r.Merc_Order_Sent__c)
//          dealerOrdeIds_WithMotorTransferRequests.add( dol.Dealer_Order__c);
//      }
//    }
//
//    if( erps.size() > 0 )
//      update erps;
//
//    if( transfers.size() > 0 )
//      update transfers;
//
//    if( dealerOrdeIds_WithMotorTransferRequests.size() > 0 )
//      sendMercuryMotorOrderEmail( dealerOrdeIds_WithMotorTransferRequests );
//  }
//
//  @Future
//  private static void sendMercuryMotorOrderEmail( Set<Id> dealerOrderIds )
//  {
//
//    String[] ccAddrs = new List<String>{
//      'dealercare@legendboats.com'
//    };
//    String templateId = Legend_Settings__c.getOrgDefaults().Mercury_Order_Email_Template_Id__c;
//    Id contactId = Legend_Settings__c.getOrgDefaults().Mercury_Contact_Id__c;
//    Id orgEmailId;
//    try {
//      orgEmailId = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'Dealer Care' LIMIT 1].Id;
//    }
//    catch(Exception e){}
//    List<Dealer_Order__c> dealerOrders = new List<Dealer_Order__c>();
//    List<Messaging.SingleEmailMessage> msgList= new List<Messaging.SingleEmailMessage>();
//    for( Id doId : dealerOrderIds )
//    {
//      dealerOrders.add( new Dealer_Order__c(
//        Id = doId,
//        Merc_Order_Sent__c = true
//      )
//      );
//      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
//      if( orgEmailId != null )
//      {
//        mail.setOrgWideEmailAddressId( orgEmailId );
//      }
//      mail.setTargetObjectId(contactId);
//      mail.setWhatId( doId );
//      mail.setTemplateId( templateId );
//      mail.setCcAddresses( ccAddrs );
//      mail.setSaveAsActivity(true);
//      msgList.add(mail);
//    }
//    if( !Test.isRunningTest() )
//    {
//      Messaging.sendEmail(msgList);
//    }
//    TriggerBase.bypass('Dealer_Order__c');
//    update dealerOrders;
//    TriggerBase.clearBypass('Dealer_Order__c');
//  }

}