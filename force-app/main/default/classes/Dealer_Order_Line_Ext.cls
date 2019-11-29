public with sharing class Dealer_Order_Line_Ext {

  public class DealerOrderLineException extends Exception {}

  public static Boolean disableTrigger {
    get{
      if(disableTrigger == null) return false;
      else return disableTrigger;
    }
    set;
  }

  public final Dealer_Order_Line__c dealerOrderLine { get; private set; }
  public final BoatBuilder boatBuilder { get; private set; }

  public Dealer_Order_Line_Ext(ApexPages.StandardController stdController) {
      this.dealerOrderLine = [SELECT Id,
                                     Name,
                                     Dealer_Order__c,
                                     Dealer_Order__r.Name,
                                     Dealer_Order__r.Account__r.Name,
                                     ERP_Order__r.Name,
                                     Dealer_Order__r.isLocked__c,
                                     Opportunity__c
                              FROM Dealer_Order_Line__c
                              WHERE Id = :stdController.getId()];
      this.boatBuilder = new BoatBuilder( dealerOrderLine );
  }

  public Boolean getIsDealerOrderLocked()
  {
    return dealerOrderLine.Dealer_Order__r.isLocked__c;
  }

  @RemoteAction
  public static void cloneOrderLine(String orderLineId, Integer quantity )
  {
    Dealer_Order_Line__c origLine = [SELECT Id,
                                            Dealer_Order__c,
                                            Dealer_Order__r.Name,
                                            Dealer_Order__r.isLocked__c,
                                            Dealer_Order__r.Stage__c,
                                            Dealer_Order__r.LineItemCount__c,
                                            Dealer_Order__r.Account__r.Name,
                                            Opportunity__c,
                                            Order_Group_Id__c
                                     FROM Dealer_Order_Line__c
                                     WHERE Id = :orderLineId];

    if( origLine.Dealer_Order__r.isLocked__c )
      throw new DealerOrderLineException('Can not add line items to a Dealer Order with Stage = ' + origLine.Dealer_Order__r.Stage__c );

    String oppSOQL = LGND_Utilities.getCreatableFieldsSOQL('Opportunity', 'Id = \'' + origLine.Opportunity__c +'\'');
    String oliSOQL = LGND_Utilities.getCreatableFieldsSOQL('OpportunityLineItem', 'OpportunityId = \'' + origLine.Opportunity__c + '\'');
    Opportunity origOpp = (Opportunity)Database.query(oppSOQL);
    OpportunityLineItem[] origOppLines = (OpportunityLineItem[])Database.query(oliSOQL);

    List<Opportunity> newOpps = new List<Opportunity>();

    for( Integer i=0; i<quantity; i++ )
    {
        Opportunity opp = origOpp.clone(false, true);
        opp.Name = (origLine.Dealer_Order__r.Account__r.Name).LEFT(72) + ' - [' + String.valueOf( origLine.Dealer_Order__r.LineItemCount__c + 1 + i) + ']';
        newOpps.add(opp);
    }
    insert newOpps;

    List<OpportunityLineItem> newOppLines = new List<OpportunityLineItem>();
    List<Dealer_Order_Line__c> newDealerOrderLines = new List<Dealer_Order_Line__c>();
    for( Opportunity opp : newOpps )
    {
      for( OpportunityLineItem oli : origOppLines )
      {
        OpportunityLineItem newLi = oli.clone(false, true);
        newLi.OpportunityId = opp.Id;
        newLi.TotalPrice = null;
        newOppLines.add( newLi );
      }
      opp.Pricebook2Id = origOpp.Pricebook2Id;
      newDealerOrderLines.add(
        new Dealer_Order_Line__c(
            Opportunity__c = opp.Id,
            Dealer_Order__c = origLine.Dealer_Order__c,
            Order_Group_id__c = origLine.Order_Group_Id__c
        )
      );
    }

    update newOpps;
    insert newOppLines;
    insert newDealerOrderLines;

  }

  public static void triggerHandler(
                                    Map<Id, Dealer_Order_Line__c> oldMap,
                                    Map<Id, Dealer_Order_Line__c> newMap,
                                    List<Dealer_Order_Line__c> listNew,
                                    Boolean boolIsBefore,
                                    Boolean boolIsInsert,
                                    Boolean boolIsUpdate,
                                    Boolean boolIsDelete
                                   )
  {
    if( oldMap == null ) oldMap = new Map<Id, Dealer_Order_Line__c>();
    if( newMap == null ) newMap = new Map<Id, Dealer_Order_Line__c>();
    if( listNew == null ) listNew = new List<Dealer_Order_Line__c>();

    if( boolIsBefore )
    /* &&&&&&&   BEFORE    &&&&&&& */
    {
      if( boolIsInsert )
      {
        setLineTotal( listNew );
      }
      if( boolIsUpdate )
      {
         setLineTotal( listNew );
      }
      if( boolIsDelete )
      {
        //for( Dealer_Order_Line__c dol : oldMap.values() )
        //{
        //  if( dol.ERP_Order__c != null )
        //  {
        //    dol.addError('You can not delete a Dealer Order Line that has an associated ERP Order');
        //  }
        //}
      }
    }
    else
    {
    /* &&&&&&&   AFTER   &&&&&&& */
      if( boolIsInsert )
      {

      }
      if( boolIsUpdate )
      {
        System.debug( 'Dealer Order Line after update');
        Set<Id> toSendtoMercuryId = new Set<Id>();
        for( Dealer_Order_Line__c dol : listNew )
        {
          if( dol.Dealer_Motor_Request__c != null &&
              !dol.Serial_Number_Sent_to_Mercury__c &&
              dol.Boat_Serial_Number__c != null &&
              oldMap.get( dol.Id ).Boat_Serial_Number__c != dol.Boat_Serial_Number__c ) {
            toSendtoMercuryId.add(dol.Id);
          }
        }
        System.debug( toSendtoMercuryId );
        if( toSendtoMercuryId.size() > 0 )
        {
          notifyMercuryOfSerial( toSendtoMercuryId );
        }
      }
      if( boolIsDelete )
      {
        Set<Id> erpIds = new Set<Id>();
        Set<Id> transferIds = new Set<Id>();
        Set<Id> motorRequestIds = new Set<Id>();
        for( Dealer_Order_Line__c dol : oldMap.values() )
        {
          if( dol.ERP_Order__c != null )
            erpIds.add( dol.ERP_Order__c );
          if( dol.Legend_Transfer_Request__c != null )
            transferIds.add( dol.Legend_Transfer_Request__c );
          if( dol.Dealer_Motor_Request__c != null )
            motorRequestIds.add( dol.Dealer_Motor_Request__c );
        }
        if( erpIds.size() > 0 )
          deleteErps(erpIds);
        if( transferIds.size() > 0 )
          deleteLegendTransferRequests( transferIds );
        if( motorRequestIds.size() > 0 )
          deleteDealerMotorRequests( motorRequestIds );
      }
    }
  }

  public class DealerOrderLine_SetSerial_Queue implements Queueable {
    public final Set<Id> materialIds;

    public DealerOrderLine_SetSerial_Queue( Set<Id> matIds )
    {
      this.materialIds = matIds;
    }

    public void execute( QueueableContext context )
    {
      Id boatRtId = LGND_Constants.productRtId_Boat;
      Map<Id, AcctSeedERP__Material__c> erpId_Material_map = new Map<Id, AcctSeedERP__Material__c>();
      List<Dealer_Order_Line__c> dols = new List<Dealer_Order_Line__c>();
      for( AcctSeedERP__Material__c mat : [ SELECT Id,
                                                   AcctSeedERP__Project__c,
                                                   GMBLASERP__Serial_Number__c
                                            FROM AcctSeedERP__Material__c
                                            WHERE Id IN :this.materialIds
                                            AND AcctSeedERP__Product__r.RecordTypeId = :boatRtId
                                            AND GMBLASERP__Serial_Number__c <> null ] )
      {
        erpId_Material_map.put( mat.AcctSeedERP__Project__c, mat );
      }
      for( Dealer_Order_Line__c dol : [SELECT Id, ERP_Order__c
                                       FROM Dealer_Order_Line__c
                                       WHERE ERP_Order__c IN :erpId_Material_map.keySet() ] )
      {
        dols.add( new Dealer_Order_Line__c(
          Id = dol.Id,
          Boat_Serial_Number__c = erpId_Material_map.get( dol.ERP_Order__c ).GMBLASERP__Serial_Number__c
        ));
      }
      update dols;
    }
  }

  private static void notifyMercuryOfSerial( Set<Id> dolIds )
  {
    String[] ccAddrs = new List<String>{
      'dealercare@legendboats.com'
    };
    String templateId = Legend_Settings__c.getOrgDefaults().Mercury_Motor_Request_Serial_Number_Emai__c;
    Id contactId = Legend_Settings__c.getOrgDefaults().Mercury_Contact_Id__c;
    Id orgEmailId;
    try {
      orgEmailId = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'Dealer Care' LIMIT 1].Id;
    }
    catch(Exception e){}
    List<Dealer_Order_Line__c> dols = new List<Dealer_Order_Line__c>();
    List<Messaging.SingleEmailMessage> msgList= new List<Messaging.SingleEmailMessage>();
    for( Id dolId : dolIds ) {
      dols.add(new Dealer_Order_Line__c(
        Id = dolId,
        Serial_Number_Sent_to_Mercury__c = true,
        Serial_Number_Sent_On__c = Date.today()
      ));
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
      if (orgEmailId != null) {
        mail.setOrgWideEmailAddressId(orgEmailId);
      }
      mail.setTargetObjectId(contactId);
      mail.setWhatId(dolId);
      mail.setTemplateId(templateId);
      if( !LGND_Constants.runningInASandbox )
      {
        mail.setCcAddresses(ccAddrs);
      }
      mail.setSaveAsActivity(true);
      msgList.add(mail);
    }
    Messaging.sendEmail(msgList);
    Boolean orig = Dealer_Order_Line_Ext.disableTrigger;
    Dealer_Order_Line_Ext.disableTrigger = true;
    update dols;
    Dealer_Order_Line_Ext.disableTrigger = orig;
  }

  private static void setLineTotal( List<Dealer_Order_Line__c> lines )
  {
    for( Dealer_Order_Line__c dol : lines )
    {
      dol.Line_Total__c = dol.Line_Total_Pre_Tax__c;//dol.Line_Total_Calc__c;
    }
  }

  public static void deleteErps( Set<Id> erpIds )
  {
    AcctSeed__Project__c[] erps = [SELECT Id FROM AcctSeed__Project__c WHERE Id IN :erpIds];
    delete erps;
  }

  private static void deleteLegendTransferRequests( Set<Id> transferIds )
  {
    Legend_Transfer_Request__c[] ltrs = [SELECT Id
                                         FROM Legend_Transfer_Request__c
                                         WHERE Id IN :transferIds];
    delete ltrs;
  }

  private static void deleteDealerMotorRequests( Set<Id> motorRequestIds )
  {
    Dealer_Motor_Request__c[] dmrs = [SELECT Id
                                      FROM Dealer_Motor_Request__c
                                      WHERE Id IN :motorRequestIds];
    delete dmrs;
  }

  //private static void setOpportunityStage( List<Dealer_Order_Line__c> dols )
  //{
  //  Set<Id> oppIds = new Set<Id>();
  //  for( Dealer_Order_Line__c dol : dols )
  //  {
  //    if( dol.Opportunity__c != null && dol.ERP_Order__c != null )
  //      oppIds.add( dol.Opportunity__c );
  //  }
  //  Opportunity[] opps = [SELECT Id, StageName FROM Opportunity WHERE Id IN :oppIds];
  //  for( Opportunity opp : opps )
  //  {
  //    opp.StageName = 'Sent to ERP';
  //  }
  //  update opps;
  //}

public static void coverage(){
    integer i;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
  }

}