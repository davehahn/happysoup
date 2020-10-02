public with sharing class Partner_OutstandingBoatOrders {

  @AuraEnabled
  public static String checkPermission()
  {
    return LGND_Utilities.CustomPermissions.partnerCanViewOutstandingOrders ? 'true' : 'false';
  }

  @AuraEnabled
  public static Boolean isFactoryStore()
  {
    try {
      return [SELECT Id, Account.Is_Internal__c FROM User WHERE Id = :UserInfo.getUserId() ].Account.Is_Internal__c;
    }
    catch( Exception e )
    {
      throw new AuraHandledException('You appear to logged in as a Non Partner User');
    }
  }

  @AuraEnabled
  public static String fetchOutstandingNumbers()
  {
    Id boat = LGND_Constants.productRtId_Boat;
    Id motor = LGND_Constants.productRtId_Motor;
    Id trailer = LGND_Constants.productRtId_Trailer;
    List<String> ignoreStages = new List<String>{'Draft', 'Delivered', 'Closed Lost'};
    Map<String, Integer> result = new Map<String, Integer>{
      'boats' => 0, 'trailers' => 0
    };

    User cu = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId() ];
    if( cu.AccountId == null )
    {
      String msg = 'Current user does not have an Account Id and is likely not a Partner';
      AuraHandledException ex = new AuraHandledException(msg);
      ex.setMessage(msg);
      throw ex;
    }

    for( Dealer_Order_Line__c dol : [SELECT Id, Product__r.RecordTypeId, Erp_Order__r.Stage__c
                                     FROM Dealer_Order_Line__c
                                     WHERE ERP_Order__c <> null
                                     AND ERP_Order__r.Stage__c NOT IN :ignoreStages
                                     AND Dealer_Order__r.Account__c = :cu.AccountId] )
    {
      System.debug( dol.ERP_Order__r.Stage__c );
      if( dol.Product__r.RecordTypeId == boat )
        result.put('boats', result.get('boats') + 1 );
      if( dol.Product__r.RecordTypeId == trailer )
        result.put('trailers', result.get('trailers') + 1 );
    }
    return JSON.serialize( result );
  }

  @AuraEnabled
  public static String fetchOrderTypeDetails( String orderType )
  {
    if( orderType == 'boat' )
      return buildOutstandingBoatOrders();
    if( orderType == 'trailer' )
      return buildOutstandingTrailerOrders();
    return null;
  }

  public class OrderLine implements Comparable
  {
    public String majorItemName;
    public String dealerOrderId;
    public String dealerOrderName;
    public String erpOrderNumber;
    public String erpOrderId;
    public String erpOrderStage;
    public String reservedForCustomerId;
    public String reservedForCustomerName;
    public String retailErpId;
    public String retailErpName;
    public DateTime orderDate;
    public List<String> lineItems;
    public String invoiceId;

    public OrderLine( Dealer_Order_Line__c dol, AcctSeedERP__Material__c[] mats )
    {
      init( dol );
      this.lineItems = new List<String>();
      if( mats != null )
      {
        for( AcctSeedERP__Material__c mat : mats )
        {
          this.lineItems.add( mat.AcctSeedERP__Product__r.Name );
        }
      }
    }

    public OrderLine( Dealer_Order_Line__c dol )
    {
      init( dol );
    }

    private void init( Dealer_Order_Line__c dol )
    {
      this.majorItemName = dol.Product__r.Name;
      this.dealerOrderId = dol.Dealer_Order__c;
      this.dealerOrderName = dol.Dealer_Order__r.Name;
      this.erpOrderStage = dol.ERP_Order__r.Stage__c;
      this.erpOrderId = dol.ERP_Order__c;
      if( dol.ERP_Order__r.Reserved_For_Customer_Account__c != null )
      {
        this.reservedForCustomerId = dol.ERP_Order__r.Reserved_For_Customer_Account__c;
        this.reservedForCustomerName = dol.ERP_Order__r.Reserved_For_Customer_Account__r.Name;
      }
      if( dol.ERP_Order__r.Retail_ERP__c != null )
      {
        this.retailErpId = dol.ERP_Order__r.Retail_ERP__c;
        this.retailErpName = dol.ERP_Order__r.Retail_ERP__r.Name;
      }
      if( dol.ERP_Order__r.LastDocumentID__c != null )
      {
        this.erpOrderNumber = dol.ERP_Order__r.AcctSeedERP__Work_Order_Number__c;
        this.invoiceId = dol.ERP_Order__r.LastDocumentID__c;
      }
      this.orderDate = dol.Dealer_Order__r.Date_Submitted__c;
    }

    public Integer compareTo(Object compareTo) {
      // Cast argument to OpportunityWrapper
      OrderLine compareToData = (OrderLine)compareTo;
      return (compareToData.majorItemName.compareTo(this.majorItemName) * -1);
    }

  }

  private static String buildOutstandingBoatOrders()
  {
    Id boatRtId = LGND_Constants.productRtId_Boat;
    Set<Id> matRecordTypes = new Set<Id>{
      LGND_Constants.productRtId_Trailer,
      LGND_Constants.productRtId_Part,
      LGND_Constants.productRtId_TrollingMotor
    };
    List<String> ignoreStages = new List<String>{'Draft', 'Delivered', 'Closed Lost'};
    User cu = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId() ];
    Map<Id, Dealer_Order_Line__c> erpId_dol_map = new Map<id, Dealer_Order_Line__c>();

    OrderLine[] result = new List<OrderLine>();
    for( Dealer_Order_Line__c dol : [SELECT Id,
                                            Product__r.Name,
                                            Dealer_Order__r.Date_Submitted__c,
                                            Dealer_Order__r.Name,
                                            Dealer_Order__c,
                                            ERP_Order__c,
                                            ERP_Order__r.Stage__c,
                                            ERP_Order__r.AcctSeedERP__Work_Order_Number__c,
                                            ERP_Order__r.LastDocumentID__c,
                                            ERP_Order__r.Retail_ERP__c,
                                            ERP_Order__r.Retail_ERP__r.Name,
                                            ERP_Order__r.Reserved_For_Customer_Account__c,
                                            ERP_Order__r.Reserved_For_Customer_Account__r.Name
                                     FROM Dealer_Order_Line__c
                                     WHERE ERP_Order__c <> null
                                     AND ERP_Order__r.Stage__c NOT IN :ignoreStages
                                     AND Dealer_Order__r.Account__c = :cu.AccountId
                                     AND Product__r.RecordTypeId = :boatRtId ] )
    {
      //System.debug( dol.ERP_Order__c );
      //if( dol.ERP_Order__c != null && dol.ERP_Order__c != '' )
        erpId_dol_map.put( dol.ERP_Order__c, dol );
    }
    Map<Id, List<AcctSeedERP__Material__c>> erpId_Mat_map = new Map<Id, List<AcctSeedERP__Material__c>>();
    for( AcctSeedERP__Material__c mat :  [SELECT Id,
                                                 AcctSeedERP__Project__c,
                                                 AcctSeedERP__Product__r.Name
                                          FROM AcctSeedERP__Material__c
                                          WHERE AcctSeedERP__Product__r.RecordTypeId IN :matRecordTypes
                                          AND AcctSeedERP__Product__r.Family != 'Discount'
                                          AND AcctSeedERP__Project__c IN :erpId_dol_map.keySet() ] )
    {
      if( !erpId_Mat_map.containsKey( mat.AcctSeedERP__Project__c ) )
        erpId_Mat_map.put( mat.AcctSeedERP__Project__c, new List<AcctSeedERP__Material__c>() );
      erpId_Mat_map.get( mat.AcctSeedERP__Project__c ).add( mat );
    }

    for( Id erpId : erpId_dol_map.keySet() )
    {
       result.add( new OrderLine( erpId_dol_map.get( erpId ),
                                  erpId_Mat_map.get( erpId )
                                ) );
    }
    result.sort();
    return JSON.serialize( result );
  }

  private static String buildOutstandingTrailerOrders()
  {
    Id trailerRtId = LGND_Constants.productRtId_Trailer;
    List<String> ignoreStages = new List<String>{'Draft', 'Delivered', 'Closed Lost'};
    User cu = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId() ];
    OrderLine[] result = new List<OrderLine>();
    for( Dealer_Order_Line__c dol : [SELECT Id,
                                            Product__r.Name,
                                            Dealer_Order__r.Date_Submitted__c,
                                            Dealer_Order__r.Name,
                                            Dealer_Order__c,
                                            ERP_Order__c,
                                            ERP_Order__r.Stage__c,
                                            ERP_Order__r.AcctSeedERP__Work_Order_Number__c,
                                            ERP_Order__r.LastDocumentID__c
                                     FROM Dealer_Order_Line__c
                                     WHERE ERP_Order__c <> null
                                     AND ERP_Order__r.Stage__c NOT IN :ignoreStages
                                     AND Dealer_Order__r.Account__c = :cu.AccountId
                                     AND Product__r.RecordTypeId = :trailerRtId ] )
    {
      result.sort();
      result.add( new OrderLine( dol ) );
    }
    return JSON.serialize( result );
  }

}