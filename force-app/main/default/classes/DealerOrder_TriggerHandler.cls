/**
 * Created by dave on 2020-08-07.
 */

public without sharing class DealerOrder_TriggerHandler extends TriggerHandler
{
  public static Boolean disableStagePropagation
  {
    get
    {
      if (disableStagePropagation == null) return false; else return disableStagePropagation;
    }
    set
    {
      if (value == null) disableStagePropagation = false; else disableStagePropagation = value;
    }
  }

//  protected override void bulkBefore()
//  {
//    system.debug('[DealerOrder_TriggerHandler] bulk before');
//  }

//  protected override void bulkAfter()
//  {
//    system.debug('[DealerOrder_TriggerHandler] bulk after');
//  }

  protected override void beforeInsert()
  {
    for (Dealer_Order__c dealerOrder : (List<Dealer_Order__c>) Trigger.new)
    {
      if (dealerOrder.Stage__c == 'Pending Review')
        dealerOrder.Date_Submitted__c = DateTime.now();
    }
  }

  protected override void beforeUpdate()
  {
    Map<Id, Dealer_Order__c> oldMap = (Map<Id, Dealer_Order__c>) Trigger.oldMap;
    for (Dealer_Order__c dealerOrder : (List<Dealer_Order__c>) Trigger.new)
    {
      Dealer_Order__c oldOrder = oldMap.get(dealerOrder.Id);
      if (dealerOrder.Stage__c == 'Pending Review' &&
        oldOrder.Stage__c == 'Draft')
        dealerOrder.Date_Submitted__c = DateTime.now();
      if (dealerOrder.Stage__c == 'Draft')
        dealerOrder.Date_Submitted__c = null;
    }
  }

  protected override void beforeDelete()
  {
    Map<Id, Dealer_Order__c> oldMap = (Map<Id, Dealer_Order__c>) Trigger.oldMap;
    for (Dealer_Order__c dOrder : oldMap.values())
    {
      if (dOrder.Stage__c != 'Draft')
      {
        dOrder.addError('You can not delete a Dealer Order with stage "' + dOrder.Stage__c + '"');
      } else
      {
        Set<Id> erpIds = new Set<Id>();
        for (Dealer_Order_Line__c dol : [
          SELECT ERP_Order__c
          FROM Dealer_Order_Line__c
          WHERE Dealer_Order__c IN :oldMap.keySet()
        ])
        {
          erpIds.add(dol.ERP_Order__c);
        }
        Dealer_Order_Line_Ext.deleteERPs(erpIds);
      }
    }
  }

  protected override void afterInsert()
  {
    createRequiredPartnerBookingOrders((List<Dealer_Order__c>) Trigger.new);
    setErpStage(
      (Map<Id, Dealer_Order__c>) Trigger.oldMap,
      (Map<Id, Dealer_Order__c>) Trigger.newMap
    );
  }

  protected override void afterUpdate()
  {
    if (!disableStagePropagation)
    {
      setErpStage(
        (Map<Id, Dealer_Order__c>) Trigger.oldMap,
        (Map<Id, Dealer_Order__c>) Trigger.newMap
      );
    }
    propagateOwner(
      (Map<Id, Dealer_Order__c>) Trigger.oldMap,
      (Map<Id, Dealer_Order__c>) Trigger.newMap
    );
  }

//  protected override void afterDelete()
//  {
//    system.debug('[DealerOrder_TriggerHandler] after delete');
//  }

//  protected override void afterUndelete()
//  {
//    system.debug('[DealerOrder_TriggerHandler] after undelete');
//  }

//  protected override void finalActions()
//  {
//    system.debug('[DealerOrder_TriggerHandler] final actions');
//  }

  private static void propagateOwner( Map<Id, Dealer_Order__c> oldMap,
                                      Map<Id, Dealer_Order__c> newMap )
  {
    Map<Id, Id> ownerChanged = new Map<Id, Id>();
    for (Dealer_Order__c d : newMap.Values())
    {
      Dealer_Order__c od = oldMap.get(d.Id);
      if (d.OwnerId != od.OwnerId)
      {
        ownerChanged.put(d.Id, d.OwnerId);
      }
    }
    if (ownerChanged.size() > 0)
    {
      Map<Id, Id> erpDOrderMap = new Map<Id, Id>();
      for (Dealer_Order_Line__c dol : [
        SELECT ERP_Order__c, Dealer_Order__c
        FROM Dealer_Order_Line__c
        WHERE Dealer_Order__c IN :ownerChanged.keySet()
      ])
      {
        erpDOrderMap.put(dol.ERP_Order__c, dol.Dealer_Order__c);
      }
      AcctSeed__Project__c[] erps = [
        SELECT Id, (
          SELECT Id
          FROM AcctSeedERP__Project_Materials__r
        )
        FROM AcctSeed__Project__c
        WHERE Id IN :erpDOrderMap.keySet()
      ];
      AcctSeedERP__Material__c[] updateMats = new List<AcctSeedERP__Material__c>();
      for (AcctSeed__Project__c erp : erps)
      {
        Id doId = erpDOrderMap.get(erp.Id);
        erp.OwnerId = ownerChanged.get(doId);
        for (AcctSeedERP__Material__c m : erp.AcctSeedERP__Project_Materials__r)
        {
          m.OwnerId = ownerChanged.get(doId);
          updateMats.add(m);
        }
      }
      Boolean origProgTrig = gcProject.disableTrigger;
      Boolean origMatTrig = gcMaterial.disableTrigger;
      gcProject.disableTrigger = true;
      gcMaterial.disableTrigger = true;
      update erps;
      update updateMats;
      gcProject.disableTrigger = origProgTrig;
      gcMaterial.disableTrigger = origMatTrig;
    }
  }

  private static void createRequiredPartnerBookingOrders( List<Dealer_Order__c> listNew )
  {
    List<Partner_Booking_Order__c> orders = new List<Partner_Booking_Order__c>();
    for( Dealer_Order__c dOrder : listNew )
    {
      if( dOrder.Is_Booking_Order__c )
      {
        orders.add( new Partner_Booking_Order__c(
          Dealer_Order__c = dOrder.Id,
          Name = dOrder.Program_Year__c,
          Account__c = dOrder.Account__c
        ));
      }
    }
    if( orders.size() > 0 )
      insert orders;
  }

  private static void setErpStage( Map<Id, Dealer_Order__c> oldMap,
    Map<Id, Dealer_Order__c> newMap )
  {
    //Stages that are greater than (passed) Plan Load
    Set<String> highStages = new Set<String>{
      //'Tagging Pending',
      'Ready to Ship',
      'Delivered',
      'Closed Lost'
    };
    AcctSeed__Project__c[] erps = new List<AcctSeed__Project__c>();
    Set<Id> dealerOrdeIds_WithMotorTransferRequests = new Set<Id>();
    Legend_Transfer_Request__c[] transfers = new List<Legend_Transfer_Request__c>();
    Dealer_Order_Line__c[] dols = [SELECT Id,
      Dealer_Order__c,
      Dealer_Order__r.Merc_Order_Sent__c,
      ERP_Order__c,
      ERP_Order__r.Stage__c,
      Legend_Transfer_Request__c,
      Dealer_Motor_Request__c
    FROM Dealer_Order_Line__c
    WHERE Dealer_Order__c IN :newMap.keySet() ];
    for( Dealer_Order_Line__c dol : dols )
    {
      /*
        Draft
      */
      if( newMap.get( dol.Dealer_Order__c ).Stage__c == 'Draft' )
      {
        if( dol.ERP_Order__c != null && !highStages.contains( dol.Erp_Order__r.Stage__c ) )
        {
          AcctSeed__Project__c erp = new AcctSeed__Project__c(
            Id = dol.ERP_Order__c,
            Stage__c = 'Draft'
          );
          erps.add( erp );
        }
        if( dol.Legend_Transfer_Request__c != null )
        {
          transfers.add( new Legend_Transfer_Request__c(
            Id = dol.Legend_Transfer_Request__c,
            Stage__c = 'Draft'
          )
          );
        }
      }
      /*
        "Pending Review"
      */
      if( newMap.get( dol.Dealer_Order__c ).Stage__c == 'Pending Review' )
      {
        if( dol.ERP_Order__c != null && !highStages.contains( dol.Erp_Order__r.Stage__c ) )
        {
          AcctSeed__Project__c erp = new AcctSeed__Project__c(
            Id = dol.ERP_Order__c,
            Stage__c = 'Pending Review'
          );
          erps.add( erp );
        }
        if( dol.Legend_Transfer_Request__c != null )
        {
          transfers.add( new Legend_Transfer_Request__c(
            Id = dol.Legend_Transfer_Request__c,
            Stage__c = 'Plan Load'
          )
          );
        }
      }
      /*
       "Pending Financing"
     */
      if( newMap.get( dol.Dealer_Order__c ).Stage__c == 'Pending Financing' )
      {
        if( dol.ERP_Order__c != null && !highStages.contains( dol.Erp_Order__r.Stage__c ) )
        {
          AcctSeed__Project__c erp = new AcctSeed__Project__c(
            Id = dol.ERP_Order__c,
            Stage__c = 'Pending Financing'
          );
          erps.add( erp );
        }
        if( dol.Dealer_Motor_Request__c != null &&
          !dol.Dealer_Order__r.Merc_Order_Sent__c)
          dealerOrdeIds_WithMotorTransferRequests.add( dol.Dealer_Order__c);
      }
      /*
        "Approved"
      */
      if( newMap.get( dol.Dealer_Order__c ).Stage__c == 'Approved' )
      {
        if( dol.ERP_Order__c != null && !highStages.contains( dol.Erp_Order__r.Stage__c ) )
        {
          AcctSeed__Project__c erp = new AcctSeed__Project__c(
            Id = dol.ERP_Order__c,
            Stage__c = 'Tagging Pending'
          );
          erps.add( erp );
        }
        if( dol.Dealer_Motor_Request__c != null &&
          !dol.Dealer_Order__r.Merc_Order_Sent__c)
          dealerOrdeIds_WithMotorTransferRequests.add( dol.Dealer_Order__c);
      }
    }

    if( erps.size() > 0 )
      update erps;

    if( transfers.size() > 0 )
      update transfers;

    if( dealerOrdeIds_WithMotorTransferRequests.size() > 0 )
      sendMercuryMotorOrderEmail( dealerOrdeIds_WithMotorTransferRequests );
  }

  private static void sendMercuryMotorOrderEmail( Set<Id> dealerOrderIds )
  {

    String[] ccAddrs = new List<String>{
      'dealercare@legendboats.com'
    };
    String templateId = Legend_Settings__c.getOrgDefaults().Mercury_Order_Email_Template_Id__c;
    Id contactId = Legend_Settings__c.getOrgDefaults().Mercury_Contact_Id__c;
    Id orgEmailId;
    try {
      orgEmailId = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'Dealer Care' LIMIT 1].Id;
    }
    catch(Exception e){}
    List<Dealer_Order__c> dealerOrders = new List<Dealer_Order__c>();
    List<Messaging.SingleEmailMessage> msgList= new List<Messaging.SingleEmailMessage>();
    for( Id doId : dealerOrderIds )
    {
      dealerOrders.add( new Dealer_Order__c(
        Id = doId,
        Merc_Order_Sent__c = true
      )
      );
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
      if( orgEmailId != null )
      {
        mail.setOrgWideEmailAddressId( orgEmailId );
      }
      mail.setTargetObjectId(contactId);
      mail.setWhatId( doId );
      mail.setTemplateId( templateId );
      mail.setCcAddresses( ccAddrs );
      mail.setSaveAsActivity(true);
      msgList.add(mail);
    }
    Messaging.sendEmail(msgList);
    TriggerHandler.bypass('DealerOrder_TriggerHandler');
    update dealerOrders;
    TriggerHandler.clearBypass('DealerOrder_TriggerHandler');
  }

}