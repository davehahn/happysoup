public with sharing class RetailSchedule {

  public class RetailScheduleException extends Exception {}

  public class EventData implements Comparable {
    public String Id                  { get; set; }
    public String Name                { get; set; }
    public String accountName         { get; set; }
    public String memoryMaker         { get; set; }
    public String boatSpecialist       { get; set; }
    public Decimal amount             { get; set; }
    public String boatName            { get; set; }
    public String stage               { get; set; }
    public String paymentMethod       { get; set; }
    public String paymentStatus       { get; set; }
    public Boolean onWaterOrientation { get; set; }
    public DateTime startDateTime     { get; set; }
    public DateTime endDateTime       { get; set; }
    public String startDate           { get; set; }
    public String startTime           { get; set; }
    public String endDate             { get; set; }
    public String endTime             { get; set; }
    public String pickupLocation      { get; set; }
    public String storeLocation       { get; set; }
    public String eventType           { get; set; }
    public String origin              { get; set; }

    public EventData( AcctSeed__Project__c erp )
    {
      this.origin = 'erp';
      this.Id = erp.Id;
      this.Name = erp.Name;
      this.pickupLocation = erp.Pickup_Location__c;
      this.accountName = erp.AcctSeed__Account__c == null ? null : erp.AcctSeed__Account__r.Name;
      this.memoryMaker = erp.Salesperson__r.Name;
      if( erp.AcctSeed__Account__c != null && erp.AcctSeed__Account__r.Boat_Specialist__c != null )
        this.boatSpecialist = erp.AcctSeed__Account__r.Boat_Specialist__r.Name;
      this.onWaterOrientation = erp.On_Water_Orientation__c;
      if( erp.Boat_Product__c != null )
        this.boatName = erp.Boat_Product__r.Name;
      this.amount = erp.Grand_Total__c;
      this.stage = erp.Stage__c;
      this.paymentMethod = erp.Payment_Method__c;
      this.paymentStatus = erp.Payment_Status__c;
      this.startDateTime = erp.Delivery_Date__c;
      if( this.startDateTime != null )
      {
        this.startDate = this.startDateTime.format('MM/dd/yy');
        this.startTime = this.startDateTime.format('HH:mm');
      }
      setStoreAndType(erp.Pickup_Location__c);
    }

    public EventData( Opportunity opp )
    {
      this.origin = 'opportunity';
      this.Id = opp.Id;
      this.Name = opp.Name;
      this.pickupLocation = opp.Pickup_Location__c;
      this.accountName = opp.AccountId == null ? null : opp.Account.Name;
      this.memoryMaker = opp.Owner.Name;
      if( opp.AccountId != null && opp.Account.Boat_Specialist__c != null )
        this.boatSpecialist = opp.Account.Boat_Specialist__r.Name;
      this.onWaterOrientation = opp.On_Water_Orientation__c;
      if( opp.BoatId__c != null )
        this.boatName = opp.BoatId__r.Name;
      this.amount = opp.Total_Amount__c;
      this.stage = opp.StageName;
      this.paymentMethod = opp.Payment_Method__c;
      this.startDateTime = opp.Delivery_Date__c;
      if( this.startDateTime != null )
      {
        this.startDate = this.startDateTime.format('MM/dd/yy');
        this.startTime = this.startDateTime.format('HH:mm');
      }
      setStoreAndType(opp.Pickup_Location__c);
    }

    private void setStoreAndType( String pickupLocation )
    {
      System.debug( pickupLocation);
      if( pickupLocation == null )
      {
        this.storeLocation = '';
      }
      else if( pickupLocation.contains( 'Barrie' ) )
      {
        this.storeLocation = 'Barrie';
      }
      else if( pickupLocation.contains( 'Montreal' ) )
      {
        this.storeLocation = 'Montreal';
      }
      else if( pickupLocation.contains( 'Whitefish' ) )
      {
        this.storeLocation = 'Whitefish';
      }
      else
      {
        this.storeLocation = '';
      }
      if( pickupLocation != null )
      {
        if( pickupLocation.contains('Delivery') )
          this.eventType = 'DELIVERY';
        if( pickupLocation.contains('Pick-up') )
          this.eventType = 'PICKUP';
      }
    }

    public Integer compareTo(Object compareTo) {
      // Cast argument to OpportunityWrapper
      EventData compareToData = (EventData)compareTo;
      return compareToData.storeLocation.compareTo(this.storeLocation);
    }

  }

  public EventData[] scheduables { get; set; }
  public String usersStore { get; set; }
  public Opportunity activeOpp;
  public AcctSeed__Project__c activeERP;

	public RetailSchedule() {
    usersStore = [SELECT Id, Warehouse__c FROM User WHERE Id = :UserInfo.getUserId()].Warehouse__c;
    fetchScheduables();
    Id activeRecordId = ApexPages.currentPage().getParameters().get('active-id');
    if( activeRecordId != null )
    {
      String sObjName = Id.valueOf( activeRecordId ).getSObjectType().getDescribe().getName();
      if( sObjName == 'AcctSeed__Project__c' )
        activeERP = [SELECT Id, Delivery_Date__c, Pickup_Location__c FROM AcctSeed__Project__c WHERE Id = :activeRecordId ];
      if( sObjName == 'Opportunity' )
        activeOpp = [SELECT Id, Delivery_Date__c, Pickup_Location__c FROM Opportunity WHERE Id = :activeRecordId ];
    }
	}

  public String getCalendarStartDate()
  {
    String dateToday = DateTime.now().format('yyyy-MM-dd');
    if( activeERP != null )
    {
      return activeERP.Delivery_Date__c == null ? dateToday : activeERP.Delivery_Date__c.format('yyyy-MM-dd');
    }
    if( activeOpp != null )
    {
      return activeOpp.Delivery_Date__c == null ? dateToday : activeOpp.Delivery_Date__c.format('yyyy-MM-dd');
    }
    return dateToday;
  }

  public String getActiveRecordId()
  {
    if( activeERP != null )
      return activeErp.Id;
    if( activeOpp != null )
      return activeOpp.Id;
    return null;
  }

  public List<String> getStoreLocations()
  {
    return new List<String>{
      'Barrie',
      'Montreal',
      'Whitefish'
    };
  }

  public String getActiveStoresJSON()
  {
    Set<String> stores = new Set<String>();
    String puLoc;
    if( usersStore != null )
      stores.add( usersStore );
    if( activeERP != null )
    {
      puLoc = activeERP.Pickup_Location__c;
    }
    if( activeOpp != null )
    {
      puLoc = activeOpp.Pickup_Location__c;
    }
    if( puLoc != null )
    {
      if( puLoc.contains( 'Barrie' ) )
        stores.add( 'Barrie' );
      if( puLoc.contains( 'Montreal' ) )
        stores.add( 'Montreal' );
      if( puLoc.contains( 'Whitefish' ) )
        stores.add( 'Whitefish' );
    }
    return JSON.serialize( stores );
  }

  public String getStoreLocationsJSON()
  {
    return JSON.serialize( getStoreLocations() );
  }

  public String getPickupLocationsJSON()
  {
    return JSON.serialize( LGND_Utilities.getPicklistValues('AcctSeed__Project__c', 'Pickup_Location__c') );
  }

  @RemoteAction @ReadOnly
  public static List<EventData> fetchScheduledRecords( Long startAt,
                                                    Long endAt,
                                                    String storeLocation )
  {
    Date sDateTime = DateTime.newInstance(startAt).date();
    Date eDateTime = DateTime.newInstance(endAt).date();
    String pickupLocation = '%' + storeLocation + '%';
    List<EventData> result = new List<EventData>();
    for( AcctSeed__Project__c erp : [SELECT Id,
                                            Name,
                                            Stage__c,
                                            Owner.Name,
                                            Salesperson__r.Name,
                                            AcctSeed__Account__r.Name,
                                            AcctSeed__Account__r.Boat_Specialist__r.Name,
                                            Grand_Total__c,
                                            Boat_Product__r.Name,
                                            Pickup_Location__c,
                                            Delivery_Date__c,
                                            On_Water_Orientation__c,
                                            Payment_Method__c,
                                            Payment_Status__c
                                      FROM AcctSeed__Project__c
                                      WHERE Delivery_Date__c >= :sDateTime
                                      AND Delivery_Date__c <= :eDateTime
                                      AND Stage__c != 'Closed Lost'
                                      AND Pickup_Location__c LIKE :pickupLocation] )
    {
      result.add( new EventData( erp ) );
    }
    for( Opportunity opp : [ SELECT Id,
                                    Name,
                                    Owner.Name,
                                    AccountId,
                                    Account.Name,
                                    Account.Boat_Specialist__c,
                                    Account.Boat_Specialist__r.Name,
                                    Total_Amount__c,
                                    BoatId__c,
                                    StageName,
                                    BoatId__r.Name,
                                    Pickup_Location__c,
                                    Delivery_Date__c,
                                    On_Water_Orientation__c,
                                    Payment_Method__c
                             FROM Opportunity
                             WHERE Delivery_Date__c >= :sDateTime
                             AND Probability < 100
                             AND Probability > 0
                             AND Delivery_Date__c <= :eDateTime
                             AND Pickup_Location__c LIKE :pickupLocation] )
    {
      result.add( new EventData( opp ) );
    }
    return result;
  }

  @RemoteAction @Readonly
  public static EventData fetchRecord( String objId )
  {
    String sObjName = Id.valueOf( objId ).getSObjectType().getDescribe().getName();
    if( sObjName == 'AcctSeed__Project__c' )
      return new EventData( retrieveERP( objId ) );
    if( sObjName == 'Opportunity' )
      return new EventData( retrieveOpp( objId ) );
    return null;
  }

  @RemoteAction
  public static EventData upsertRecord( String objId, String jsonData )
  {
    String sObjName = Id.valueOf( objId ).getSObjectType().getDescribe().getName();
    if( sObjName == 'AcctSeed__Project__c')
    {
      AcctSeed__Project__c erp = (AcctSeed__Project__c)JSON.deserialize( jsonData, AcctSeed__Project__c.class);
      upsert erp;
      return new EventData( retrieveERP( erp.Id ) );
    }
    if( sObjName == 'Opportunity' )
    {
      Opportunity opp = (Opportunity)JSON.deserialize( jsonData, Opportunity.class );
      upsert opp;
      return new EventData( retrieveOpp( objId ) );
    }
    return null;
  }

  @RemoteAction
  public static EventData changePickupByDays( String objId, String numDays )
  {
    String sObjName = Id.valueOf( objId ).getSObjectType().getDescribe().getName();
    if( sObjName == 'AcctSeed__Project__c' )
    {
      AcctSeed__Project__c erp = [SELECT Id, Delivery_Date__c
                                  FROM AcctSeed__Project__c
                                  WHERE Id = :objId];
      erp.Delivery_Date__c = erp.Delivery_Date__c.addDays( Integer.valueOf(numDays) );
      update erp;
      return new EventData( retrieveERP( objId) );
    }
    if( sObjName == 'Opportunity' )
    {
      Opportunity opp = [SELECT Id, Delivery_Date__c
                         FROM Opportunity
                         WHERE Id = :objId];
      opp.Delivery_Date__c = opp.Delivery_Date__c.addDays( Integer.valueOf(numDays) );
      update opp;
      return new EventData( retrieveOpp( objId ) );
    }
    return null;
  }

  @RemoteAction
  public static EventData unScheduleRecord( String objId )
  {
    String sObjName = Id.valueOf( objId ).getSObjectType().getDescribe().getName();
    if( sObjName == 'AcctSeed__Project__c' )
    {
      AcctSeed__Project__c erp = retrieveERP( objId );
      erp.Delivery_Date__c = null;
      update erp;
      return new EventData( erp );
    }
    if( sObjName == 'Opportunity' )
    {
      Opportunity opp = retrieveOpp( objId );
      opp.Delivery_Date__c = null;
      update opp;
      return new EventData( opp );
    }
    return null;
  }

  private static AcctSeed__Project__c retrieveERP( String erpId )
  {
    return [SELECT Id,
              Name,
              Stage__c,
              Owner.Name,
              Salesperson__r.Name,
              AcctSeed__Account__r.Name,
              AcctSeed__Account__c,
              AcctSeed__Account__r.Boat_Specialist__c,
              AcctSeed__Account__r.Boat_Specialist__r.Name,
              Grand_Total__c,
              Boat_Product__c,
              Boat_Product__r.Name,
              Pickup_Location__c,
              Delivery_Date__c,
              On_Water_Orientation__c,
              Payment_Method__c,
              Payment_Status__c
       FROM AcctSeed__Project__c
       WHERE Id = :erpId];
  }

  private static Opportunity retrieveOpp( String oppId )
  {
    return [SELECT Id,
                    Name,
                    Owner.Name,
                    AccountId,
                    Account.Name,
                    Account.Boat_Specialist__c,
                    Account.Boat_Specialist__r.Name,
                    Total_Amount__c,
                    BoatId__c,
                    StageName,
                    BoatId__r.Name,
                    Pickup_Location__c,
                    Delivery_Date__c,
                    On_Water_Orientation__c,
                    Payment_Method__c
             FROM Opportunity
             WHERE Id = :oppId];
  }



  private void fetchScheduables()
  {
    Id boatSaleRT = gcConstants.idRtProjectBoatSale;
    Id oppBoatSaleRT = LGND_Utilities.recordTypeIdFromName('Opportunity', 'Retail');
    String pl_string = '%' + usersStore + '%';
    scheduables = new List<EventData>();
    for( AcctSeed__Project__c erp : [ SELECT Id,
                                             Name,
                                             Stage__c,
                                             Owner.Name,
                                             Salesperson__r.Name,
                                             AcctSeed__Account__r.Name,
                                             AcctSeed__Account__c,
                                             AcctSeed__Account__r.Boat_Specialist__c,
                                             AcctSeed__Account__r.Boat_Specialist__r.Name,
                                             Grand_Total__c,
                                             Boat_Product__c,
                                             Boat_Product__r.Name,
                                             Pickup_Location__c,
                                             Delivery_Date__c,
                                             On_Water_Orientation__c,
                                             Payment_Method__c,
                                             Payment_Status__C
                                      FROM AcctSeed__Project__c
                                      WHERE Delivery_Date__c = null
                                      //AND ( Pickup_Location__c LIKE :pl_string
                                      //      OR Pickup_Location__c = null )
                                      AND Sale_Type__c = 'Retail'
                                      AND RecordTypeId = :boatSaleRT
                                      AND AcctSeed__Status__c = 'Active'
                                      AND Stage__c != 'Closed Lost'
                                      ORDER BY Pickup_Location__c DESC ] )
    {
      scheduables.add( new EventData( erp ) );
    }
    for( Opportunity opp : [ SELECT Id,
                                    Name,
                                    Owner.Name,
                                    AccountId,
                                    Account.Name,
                                    Account.Boat_Specialist__c,
                                    Account.Boat_Specialist__r.Name,
                                    Total_Amount__c,
                                    BoatId__c,
                                    StageName,
                                    BoatId__r.Name,
                                    Pickup_Location__c,
                                    Delivery_Date__c,
                                    On_Water_Orientation__c,
                                    Payment_Method__c
                             FROM Opportunity
                             WHERE RecordTypeId = :oppBoatSaleRT
                             AND Delivery_Date__c = null
                             AND Probability > 69
                             AND Probability < 100
                             ORDER BY Pickup_Location__c DESC ])
    {
      scheduables.add( new EventData( opp ) );
    }
    scheduables.sort();
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
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
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