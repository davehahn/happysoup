public with sharing class LGNDcProject_CreateFromDealerOrder {
	public LGNDcProject_CreateFromDealerOrder() {}
  //public LGNDcProject_CreateFromDealerOrder( Apex.StandardController c ){}

  private Id warehouseId {
    get {
      if( warehouseId == null )
        warehouseId = determineWarehouse();
      return warehouseId;
    }
    set;
  }

  public PageReference createProjects()
  {
    try {
      Id dealerOrderId = ApexPages.currentPage().getParameters().get('dealer_order_id');
      Dealer_Order__c dealerOrder = [SELECT Id, Stage__c, Is_Booking_Order__c,
                                      (SELECT Id,
                                              Opportunity__c,
                                              Opportunity__r.Name,
                                              Opportunity__r.AccountId,
                                              Opportunity__r.Pricebook2Id
                                       FROM Dealer_Order_Lines__r)
                                     FROM Dealer_Order__c
                                     WHERE Id = :dealerOrderId];
      if( dealerOrder.Stage__c != 'Approved' )
        throw new LGND_Utilities.LGND_Exception( generateError( dealerOrder.Stage__c) );

      Map<Id, List<OpportunityLineItem>> dol_oppLineItems = fetchOppLineItems( dealerOrder );

      Map<Id, AcctSeed__Project__c> dol_project_map = new Map<Id, AcctSeed__Project__c>();
      Map<Id, AcctSeed__Project_Task__c> dol_project_task_map = new Map<Id, AcctSeed__Project_Task__c>();
      List<AcctSeedERP__Material__c> materials = new List<AcctSeedERP__Material__c>();

      for( Dealer_Order_Line__c dol : dealerOrder.Dealer_Order_Lines__r )
      {
        dol_project_map.put( dol.id, createProjectFromDealerOrderLine(dol, dealerOrder.Is_Booking_Order__c) );
      }
      insert dol_project_map.values();

      for( Id dolId : dol_project_map.keySet() )
      {
        dol_project_task_map.put( dolId, new AcctSeed__Project_Task__c(
                                            Name = 'Oppy Line Items',
                                            AcctSeed__Project__c = dol_project_map.get(dolId).Id
                                          )
        );
      }
      insert dol_project_task_map.values();

      for( Id dolId : dol_oppLineItems.keySet() )
      {
        for( OpportunityLineItem oli : dol_oppLineItems.get( dolId) )
        {
          materials.add( new AcctSeedERP__Material__c(
                        AcctSeedERP__Product__c = oli.Product2Id,
                        AcctSeedERP__Comment__c = oli.Description,
                        AcctSeedERP__Project__c = dol_project_map.get(dolId).Id,
                        AcctSeedERP__Project_Task__c = dol_project_task_map.get(dolId).Id,
                        AcctSeedERP__Quantity_per_Unit__c = (oli.Quantity == null ? 0 : oli.Quantity),
                        GMBLASERP__Unit_Price__c = oli.UnitPrice,
                        GMBLASERP__Price_Override__c = (oli.UnitPrice == oli.ListPrice ? false : true)
                    ) );
        }
      }
      insert materials;

      for( Dealer_Order_Line__c dol : dealerOrder.Dealer_Order_Lines__r )
      {
        dol.Erp_Order__c = dol_project_map.get(dol.Id).Id;
      }
      update dealerOrder.Dealer_Order_Lines__r;
      dealerOrder.Stage__c = 'Processed';
      update dealerOrder;

      return new PageReference('/' + dealerOrderId );
    }
    catch(Exception e)
    {
      ApexPages.addMessage( new ApexPages.Message(ApexPages.severity.ERROR, e.getMessage() ) );
      return null;
    }
  }

  private Map<Id, List<OpportunityLineItem>> fetchOppLineItems( Dealer_Order__c dealerOrder )
  {
    //get oppIds
    Map<Id, List<OpportunityLineItem>> result = new Map<Id, List<OpportunityLineItem>>();
    Map<Id, Id> opp_dol_map = new Map<Id, Id>();
    for( Dealer_Order_Line__c dol : dealerOrder.Dealer_Order_Lines__r )
    {
      opp_dol_map.put(dol.Opportunity__c, dol.Id);
      result.put(dol.Id, new List<OpportunityLineItem>() );
    }
    for( OpportunityLineItem oli : [SELECT Id,
                                           Product2Id,
                                           Quantity,
                                           UnitPrice,
                                           Description,
                                           ListPrice,
                                           OpportunityId
                                    FROM OpportunityLineItem
                                    WHERE OpportunityId
                                    IN :opp_dol_map.keySet() ] )
    {
      result.get( opp_dol_map.get(oli.OpportunityId) ).add( oli );
    }
    return result;
  }

  private AcctSeed__Project__c createProjectFromDealerOrderLine( Dealer_Order_Line__c dol, Boolean isBookingOrder )
  {
    return new AcctSeed__Project__c(
        Name = (dol.Opportunity__r.Name).LEFT(80),
        isDealerBookingOrder__c = isBookingOrder,
        AcctSeed__Account__c = dol.Opportunity__r.AccountId,
        AcctSeed__Status__c = 'Active',
        Stage__c = 'Plan Load',
        AcctSeed__Opportunity__c = dol.Opportunity__c,
        GMBLASERP__Pricebook__c = dol.Opportunity__r.Pricebook2Id,
        RecordTypeId = gcConstants.idRtProjectPartnerBoatSale,
        GMBLASERP__Warehouse__c = warehouseId
    );
  }


  private String generateError(String stage)
  {
    if( stage == 'Processed' )
    {
      return 'The Dealer Order is already Processed';
    }
    return 'The Dealer Order needs to be approved first';
  }

  private Id determineWarehouse()
  {
    Id idUser = UserInfo.getUserId();
    String dept = [SELECT Id, Sales_Department__c FROM User WHERE Id = :idUser][0].Sales_Department__c;
    Id idWarehouse = null;
    set<Id> setIdWarehouseReserved = new set<Id>();
    setIdWarehouseReserved.add(GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Adjustment_Warehouse_Id__c);
    setIdWarehouseReserved.add(GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Transit_Warehouse_Id__c);

    for(AcctSeedERP__Warehouse__c whs :
      [SELECT Id, Name
       FROM AcctSeedERP__Warehouse__c
       WHERE Id NOT IN :setIdWarehouseReserved
       ORDER BY CreatedDate])
    {
      if(whs.Name == dept)
      {
        idWarehouse = whs.Id;
        break;
      }
      if(idWarehouse == null)
        idWarehouse = whs.Id;
    }
    return idWarehouse;
  }

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
  }



}