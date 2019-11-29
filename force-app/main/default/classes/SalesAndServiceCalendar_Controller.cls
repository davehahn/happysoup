public with sharing class SalesAndServiceCalendar_Controller {

  public class EventData implements Comparable {
    public String Id                  { get; set; }
    public String Name                { get; set; }
    public String woNumber            { get; set; }
    public String accountName         { get; set; }
    public String boatName            { get; set; }
    public Boolean onWaterOrientation { get; set; }
    public DateTime startDateTime     { get; set; }
    public DateTime endDateTime       { get; set; }
    //public String startDate           { get; set; }
    //public String startTime           { get; set; }
    //public String endDate             { get; set; }
    //public String endTime             { get; set; }
    public String pickupLocation      { get; set; }
    public String storeLocation       { get; set; }
    public String parkingSpot         { get; set; }
    public String warehouseId         { get; set; }
    public String serialNumberId      { get; set; }
    public String eventType           { get; set; }
    public String origin              { get; set; }
    public String iconName            { get; set; }
    public String calId               { get; set; }
    public Decimal estimatedDuration  { get; set; }
    public String stage               { get; set; }
    public String jobStatus           { get; set; }

    public EventData( AcctSeed__Project__c erp )
    {
      Id service = gcConstants.idRtProjectService;
      Id boatSale = gcConstants.idRtProjectBoatSale;
      if( erp.RecordTypeId == boatSale )
        buildBoatSaleEvent( erp );
      if( erp.RecordTypeId == service )
        buildServiceEvent( erp );
    }

    public EventData( Opportunity opp )
    {
      this.origin = 'opportunity';
      this.iconName = 'standard:opportunity';
      this.Id = opp.Id;
      this.Name = opp.Name;
      this.woNumber = opp.InvoiceNumber__c;
      this.pickupLocation = opp.Pickup_Location__c;
      this.accountName = opp.AccountId == null ? null : opp.Account.Name;
      this.onWaterOrientation = opp.On_Water_Orientation__c;
      if( opp.BoatId__c != null )
        this.boatName = opp.BoatId__r.Name;
      this.startDateTime = opp.Delivery_Date__c;
      //if( this.startDateTime != null )
      //{
      //  this.startDate = this.startDateTime.format('MM/dd/yy');
      //  this.startTime = this.startDateTime.format('HH:mm');
      //}
      setStoreAndType(opp.Pickup_Location__c, null);
    }

    private void buildServiceEvent( AcctSeed__Project__c erp )
    {
      this.origin = 'erp';
      this.Name = erp.Name;
      this.iconName = 'custom:custom19';
      this.Id = erp.Id;
      this.woNumber = erp.AcctSeedERP__Work_Order_Number__c;
      this.accountName = erp.AcctSeed__Account__c == null ? null : erp.AcctSeed__Account__r.Name;
      this.startDateTime = erp.Service_Date__c;
      this.estimatedDuration = erp.Estimated_Service_Duration__c;
      this.warehouseId = erp.GMBLASERP__Warehouse__c == null ? null : erp.GMBLASERP__Warehouse__c;
      this.serialNumberId = erp.Serial_Number__c;
      this.stage = erp.Stage__c;
      this.parkingSpot = erp.Parking_Spot__c;
      this.jobStatus = erp.Job_Status__c;
      if( this.startDateTime != null )
      {
        //this.startDate = this.startDateTime.format('MM/dd/yy');
        //this.startTime = this.startDateTime.format('HH:mm');
        if( this.estimatedDuration != null )
        {
          this.endDateTime = this.startDateTime.addMinutes( Integer.valueOf( this.estimatedDuration * 60 ) );
        }
      }
      this.boatName = erp.Serial_Product__c;
      this.storeLocation = erp.WarehouseName__c;
      this.calId = this.storeLocation.toLowerCase() + ':service';
      this.eventType = 'SERVICE';
    }

    private void buildBoatSaleEvent( AcctSeed__Project__c erp )
    {
      this.origin = 'erp';
      this.iconName = 'custom:custom68';
      this.Id = erp.Id;
      this.Name = erp.Name;
      this.woNumber = erp.AcctSeedERP__Work_Order_Number__c;
      this.pickupLocation = erp.Pickup_Location__c == null ? '' : erp.Pickup_Location__c;
      this.accountName = erp.AcctSeed__Account__c == null ? null : erp.AcctSeed__Account__r.Name;
      this.onWaterOrientation = erp.On_Water_Orientation__c;
      if( erp.Boat_Product__c != null )
        this.boatName = erp.Boat_Product__r.Name;
      this.startDateTime = erp.Delivery_Date__c;
      this.stage = erp.Stage__c;
      this.jobStatus = erp.Job_Status__c;
      //if( this.startDateTime != null )
      //{
      //  this.startDate = this.startDateTime.format('MM/dd/yy');
      //  this.startTime = this.startDateTime.format('HH:mm');
      //}
      setStoreAndType(erp.Pickup_Location__c, erp.RecordTypeId );
    }

    private void setStoreAndType( String pickupLocation, Id recordTypeId )
    {
      if( pickupLocation == null ||
          pickupLocation == '' )
        this.storeLocation = '';
      else if( pickupLocation.contains( 'Barrie' ) )
      {
        this.storeLocation = 'Barrie';
        this.calId = 'barrie:';
      }
      else if( pickupLocation.contains( 'Montreal' ) )
      {
        this.storeLocation = 'Montreal';
        this.calId = 'montreal:';
      }
      else if( pickupLocation.contains( 'Whitefish' ) )
      {
        this.storeLocation = 'Whitefish';
        this.calId = 'whitefish:';
      }
      else
      {
        this.storeLocation = '';
      }

      if( pickupLocation != null )
      {
        this.calId += 'retail';
        if( pickupLocation.contains('Delivery') )
          this.eventType = 'DELIVERY';
        else if( pickupLocation.contains('Pick-up') )
          this.eventType = 'PICKUP';
        else
          this.eventType ='';
      }
      else {
        if(this.calId == null)
          this.calId = 'retail';
        else
          this.calId += 'retail';
      }
    }

    public Integer compareTo(Object compareTo) {
      // Cast argument to OpportunityWrapper
      EventData compareToData = (EventData)compareTo;
      return compareToData.storeLocation.compareTo(this.storeLocation);
    }

    //public void updateRecord()
    //{

    //}

  }

  @AuraEnabled
  public static String fetchUserDetailsAndPermissions()
  {
    Map<String, String> result = new Map<String, String>();
    String wh = [SELECT Id, Warehouse__c FROM User WHERE Id = :UserInfo.getUserId()].Warehouse__c;
    result.put('warehouse', wh);
    result.put('canCreateERP', String.valueOf( Schema.sObjectType.AcctSeed__Project__c.isCreateable() ) );
    result.put('editPickupDate', String.valueOf( Schema.sObjectType.AcctSeed__Project__c.fields.Delivery_Date__c.isUpdateable() ) );
    result.put('editServiceDate', String.valueOf( Schema.sObjectType.AcctSeed__Project__c.fields.Service_Date__c.isUpdateable() ) );
    return JSON.serialize( result );
  }

  @AuraEnabled
  public static String fetchScheduledRecords( String startAt,
                                              String endAt,
                                              String storeLocation,
                                              String calendarType )
  {
    if( calendarType.toLowerCase() == 'retail')
      return fetchRetailEvents( startAt, endAt, storeLocation );
    if( calendarType.toLowerCase() == 'service' )
      return fetchServiceEvents( startAt, endAt, storeLocation );

    String errorMessage = 'Unrecoginized Calendar Specified';
    AuraHandledException err = new AuraHandledException(errorMessage);
    err.setMessage(errorMessage);
    throw err;
  }

  public class RetailDetailsWrapper {
    public Boolean canEditPickupDate;
    public Boolean canEditPickupLocation;
    public Boolean canEditOnWaterOrientation;
    public String[] pickupLocations;
    public RetailDetailsWrapper(){}
  }

  @AuraEnabled
  public static String initDetailsForm()
  {
    RetailDetailsWrapper result = new RetailDetailsWrapper();
    result.pickupLocations = LGND_Utilities.getPicklistValues('AcctSeed__Project__c', 'Pickup_Location__c');
    result.canEditPickupDate = Schema.sObjectType.AcctSeed__Project__c.fields.Delivery_Date__c.isUpdateable();
    result.canEditPickupLocation = Schema.sObjectType.AcctSeed__Project__c.fields.Pickup_Location__c.isUpdateable();
    result.canEditOnWaterOrientation = Schema.sObjectType.AcctSeed__Project__c.fields.On_Water_Orientation__c.isUpdateable();
    return JSON.serialize( result );
  }

  @AuraEnabled
  public static String fetchRecord( String recordId )
  {
    String sObjName = Id.valueOf( recordId ).getSObjectType().getDescribe().getName();
    if( sObjName == 'AcctSeed__Project__c' )
      return JSON.serialize( new EventData( retrieveERP( recordId ) ) );
    if( sObjName == 'Opportunity' )
      return JSON.serialize( new EventData( retrieveOpp( recordId ) ) );
    return null;
  }

  @AuraEnabled
  public static void updateRetailRecord( String jsonEventData )
  {
    EventData ed = (EventData)JSON.deserialize( jsonEventData, EventData.class );
    SObject obj = Id.valueOf( ed.Id ).getSObjectType().newSObject( ed.Id );
    if( ed.pickupLocation != null )
      obj.put('Pickup_Location__c', ed.pickupLocation);
    if( ed.onWaterOrientation != null )
      obj.put('On_Water_Orientation__c', ed.onWaterOrientation);
    obj.put('Delivery_Date__c', ed.startDateTime );
    try {
      update obj;
    }
    catch(Exception e)
    {
      throw new AuraHandledException( e.getMessage() );
    }
  }

  @AuraEnabled
  public static void updateServiceRecord( String jsonEventData )
  {
    EventData ed = (EventData)JSON.deserialize( jsonEventData, EventData.class );
    SObject obj = Id.valueOf( ed.Id ).getSObjectType().newSObject( ed.Id );
    obj.put('Service_Date__c', ed.startDateTime );
    obj.put('Parking_Spot__c', ed.parkingSpot );
    if( ed.warehouseId != null )
      obj.put('GMBLASERP__Warehouse__c', ed.warehouseId );
    try {
      update obj;
    }
    catch(Exception e)
    {
      throw new AuraHandledException( e.getMessage() );
    }
  }

  @AuraEnabled
  public static String fetchSchedulables()
  {
    Id boatSaleRT = gcConstants.idRtProjectBoatSale;
    Id serviceRT = gcConstants.idRtProjectService;
    Id oppBoatSaleRT = LGND_Utilities.recordTypeIdFromName('Opportunity', 'Retail');
    String usersStore = [SELECT Id, Warehouse__c FROM User WHERE Id = :UserInfo.getUserId()].Warehouse__c;
    String pl_string = '%' + usersStore + '%';
    List<EventData> scheduables = new List<EventData>();
    /** RETAIL ERPS **/
    for( AcctSeed__Project__c erp : [ SELECT Id,
                                             RecordTypeId,
                                             Name,
                                             Job_Status__c,
                                             Parking_Spot__c,
                                             AcctSeedERP__Work_Order_Number__c,
                                             Estimated_Service_Duration__c,
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
                                             Serial_Number__c,
                                             Pickup_Location__c,
                                             Delivery_Date__c,
                                             On_Water_Orientation__c,
                                             Payment_Method__c,
                                             Payment_Status__C
                                      FROM AcctSeed__Project__c
                                      WHERE Delivery_Date__c = null
                                      //AND ( Pickup_Location__c LIKE :pl_string
                                      //      OR Pickup_Location__c = null )
                                      AND RecordTypeId = :boatSaleRT
                                      AND AcctSeed__Status__c = 'Active'
                                      AND Stage__c != 'Closed Lost'
                                      ORDER BY Pickup_Location__c DESC ] )
    {
      scheduables.add( new EventData( erp ) );
    }
    /** SERVICE ERPS **/
    for( AcctSeed__Project__c erp : [ SELECT Id,
                                             RecordTypeId,
                                             Name,
                                             Job_Status__c,
                                             Parking_Spot__c,
                                             AcctSeedERP__Work_Order_Number__c,
                                             GMBLASERP__Warehouse__c,
                                             Estimated_Service_Duration__c,
                                             Stage__c,
                                             AcctSeed__Account__r.Name,
                                             AcctSeed__Account__c,
                                             AcctSeed__Account__r.Boat_Specialist__c,
                                             AcctSeed__Account__r.Boat_Specialist__r.Name,
                                             Grand_Total__c,
                                             Serial_Number__c,
                                             Serial_Product__c,
                                             WarehouseName__c,
                                             Service_Date__c
                                      FROM AcctSeed__Project__c
                                      WHERE Service_Date__c = null
                                      AND RecordTypeId = :serviceRT
                                      AND AcctSeed__Status__c = 'Active'
                                      AND Stage__c != 'Repair Completed'
                                      AND Stage__c != 'Delivered'
                                      ORDER BY WarehouseName__c DESC ] )
    {
      scheduables.add( new EventData( erp ) );
    }
    for( Opportunity opp : [ SELECT Id,
                                    Name,
                                    RecordTypeId,
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
                                    Payment_Method__c,
                                    InvoiceNumber__c
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
    return JSON.serialize( scheduables );
  }

  public class ServiceInitWrapper {
    public String[] taskNames { get; set; }
    public Id userWarehouse { get; set; }
    public AcctSeedERP__Warehouse__c[] warehouses { get; set; }
    public Map<String, Boolean> permissions { get; set; }
    public Employee__c[] riggers { get; set; }
    public String[] parkingSpots { get; set; }

    public ServiceInitWrapper()
    {
      this.permissions = setPermissions();
      this.taskNames = createTaskNames();
      String userWarehouseName = [SELECT Id, Warehouse__c
                                  FROM User
                                  WHERE Id = :UserInfo.getUserId()].Warehouse__c;
      this.warehouses = fetchWarehouses();
      for( AcctSeedERP__Warehouse__c wh : this.warehouses )
      {
        if( wh.Name == userWarehouseName )
          this.userWarehouse = wh.Id;
      }
      this.riggers = fetchRiggers(userWarehouseName);
      this.parkingSpots = LGND_Utilities.getPicklistValues( 'AcctSeed__Project__c',
                                                            'Parking_Spot__c' );
    }

    private Map<String, Boolean> setPermissions()
    {
      Map<String, Boolean> perms = new Map<String, Boolean>();
      perms.put('canEditServiceDate', Schema.sObjectType.AcctSeed__Project__c.fields.Service_Date__c.isUpdateable() );
      perms.put('canEditWarehouse', Schema.sObjectType.AcctSeed__Project__c.fields.GMBLASERP__Warehouse__c.isUpdateable() );
      return perms;
    }

    private String[] createTaskNames()
    {
      List<String> tNames = new List<String>();
      for( ERPOrderTaskNames__c tn : ERPOrderTaskNames__c.getAll().values() )
      {
        tNames.add( tn.Name );
      }
      tNames.sort();
      return tNames;
    }

    private AcctSeedERP__Warehouse__c[] fetchWarehouses()
    {
      Set<String> wareHouseNames = new Set<String>{'Barrie', 'Montreal', 'Whitefish'};
      return [SELECT Id, Name
              FROM AcctSeedERP__Warehouse__c
              WHERE Name IN :wareHouseNames ];
    }

    private Employee__c[] fetchRiggers(String warehouseName) {
      Employee__c[] riggers = [SELECT Id,
                                      Name,
                                      Employee_City__c,
                                      User__r.Warehouse__c,
                                      User__r.FirstName,
                                      User__r.LastName,
                                      Team__c
                                 FROM Employee__c
                                WHERE Is_Rigger__c = true
                                  AND Active__c = true
                                  AND User__r.Warehouse__c = :warehouseName
                             ORDER BY Name ASC];
      return riggers;
    }
  }

  @AuraEnabled
  public static String getRiggers(String warehouseId) {
    AcctSeedERP__Warehouse__c warehouse = [SELECT Id, Name
                                             FROM AcctSeedERP__Warehouse__c
                                            WHERE Id = :warehouseId];
    Employee__c[] riggers = [SELECT Id,
                                      Name,
                                      Employee_City__c,
                                      User__r.Warehouse__c,
                                      User__r.FirstName,
                                      User__r.LastName,
                                      Team__c
                                 FROM Employee__c
                                WHERE Is_Rigger__c = true
                                  AND Active__c = true
                                  AND User__r.Warehouse__c = :warehouse.Name
                             ORDER BY Name ASC];
    return JSON.serialize( riggers );
  }

  @AuraEnabled
  public static String initNewService()
  {
    return JSON.serialize( new ServiceInitWrapper() );
  }

  @AuraEnabled
  public static void createServiceERP( AcctSeed__Project__c erp,
                                       AcctSeed__Project_Task__c[] tasks,
                                       String prepaids,
                                       Id riggerId
                                      )
  {

    if( erp.AcctSeed__Account__c != null )
    {
       Account a = [SELECT Id, Name FROM Account WHERE Id = :erp.AcctSeed__Account__c ];
       erp.Name = a.Name.trim();
    }
    erp.RecordTypeId = gcConstants.idRtProjectService;

    // MP: Disable Rigger Schedule trigger
    Boolean disableTrigger = gcProject.disableJob;
    gcProject.disableJob = true;
    insert erp;
    gcProject.disableJob = disableTrigger;
    // MP

    for( AcctSeed__Project_Task__c t : tasks )
    {
      t.AcctSeed__Project__c = erp.Id;
    }
    Map<String, Boolean> displayOnInvoiceMap = new Map<String, Boolean>();
    for( ERPOrderTaskNames__c tn : ERPOrderTaskNames__c.getAll().values() )
    {
      displayOnInvoiceMap.put( tn.Name, tn.Show_In_Invoice__c );
    }
    for( AcctSeed__Project_Task__c pt : tasks )
    {
      if( displayOnInvoiceMap.containsKey( pt.Name ) )
        pt.DisplayOnCustomerInvoice__c = displayOnInvoiceMap.get( pt.Name );
    }
    insert tasks;

    // MP: Now create the Rigger Schedule job.
    Set<Id> erpIds = new Set<Id>();
    erpIds.add(erp.Id);
    Rigger_Schedule_mp.createJobFromERP(erpIds);
    Rigger_Job__c job = [SELECT Id FROM Rigger_Job__c WHERE ERP_Order__c = :erp.Id];
    Rigger_Schedule_mp.assignJob(riggerId, job.Id);
    // MP

    // MP: Redeem any prepaids
    if( erp.AcctSeed__Account__c != null && prepaids != null) {
      Prepaid_Services_mp.redeemPrepaids(prepaids, erp.AcctSeed__Account__c, erp.Id, tasks);
    }
    // MP
  }

  @AuraEnabled
  public static String fetchSerialNumbersByAccount( String accountId )
  {
    return JSON.serialize( gcProject_Override_Create.searchSerial( '', accountId ) );
  }

  @AuraEnabled
  public static GMBLASERP__Serial_Number__c fetchSerialDetails( String serialId )
  {
    try {
      return [ SELECT Id,
                      Name,
                      GMBLASERP__Lot__r.Name,
                      GMBLASERP__Product__r.Name,
                      ( SELECT Id,
                               Name,
                               GMBLASERP__Lot__r.Name,
                               GMBLASERP__Product__r.Name
                        FROM Nested_Serial_Numbers__r )
               FROM GMBLASERP__Serial_Number__c
               WHERE ID = :serialId ];
    }
    catch( Exception e )
    {
      return new GMBLASERP__Serial_Number__c();
    }
  }

  @AuraEnabled
  public static AcctSeed__Project_Task__c[] fetchOrderTasks( String erpId )
  {
    return [SELECT Id, Name, Complaint_dh__c, Estimated_Duration__c
            FROM AcctSeed__Project_Task__c
            WHERE AcctSeed__Project__c = :erpId ];
  }

  @AuraEnabled
  public static void updateRiggerJob(String erpId, String riggerId)
  {
    System.debug(erpId + ' - ' + riggerId);
    Rigger_Job__c job = [SELECT Id, Employee__c FROM Rigger_Job__c WHERE ERP_Order__c = :erpId];
    if (job != null) {
      if (riggerId == '') {
        job.Employee__c = null;
      } else {
        job.Employee__c = riggerId;
      }
      update job;
    }
  }

  @AuraEnabled
  public static String getRiggerId(String erpId)
  {
    try {
      Rigger_Job__c job = [SELECT Id, Employee__c FROM Rigger_Job__c WHERE ERP_Order__c = :erpId];
      return job.Employee__c;
    }
    catch( Exception e ) {
      return null;
    }
  }

  @AuraEnabled
  public static string getPrepaidsOnAccount( Id accountId ) {
    return Prepaid_Services_mp.getPrepaidsOnAccount( accountId );
  }

  /***** PRIVATE *****/

  private static String fetchRetailEvents ( String startAt,
                                            String endAt,
                                            String storeLocation )
  {
    Date sDateTime = DateTime.newInstance( Long.valueOf(startAt) ).date();
    Date eDateTime = DateTime.newInstance( Long.valueOf(endAt) ).date();
    System.debug( 'start = ' + sDateTime );
    System.debug( 'end = ' + eDateTime );
    String pickupLocation = '%' + storeLocation + '%';
    List<EventData> result = new List<EventData>();
    Id erpRT = gcConstants.idRtProjectBoatSale;
    for( AcctSeed__Project__c erp : [SELECT Id,
                                            Name,
                                            AcctSeedERP__Work_Order_Number__c,
                                            Stage__c,
                                            Job_Status__c,
                                            Owner.Name,
                                            Salesperson__r.Name,
                                            AcctSeed__Account__r.Name,
                                            AcctSeed__Account__r.Boat_Specialist__r.Name,
                                            Grand_Total__c,
                                            Boat_Product__r.Name,
                                            Pickup_Location__c,
                                            Delivery_Date__c,
                                            Serial_Number__c,
                                            On_Water_Orientation__c,
                                            Payment_Method__c,
                                            Payment_Status__c,
                                            RecordTypeId
                                      FROM AcctSeed__Project__c
                                      WHERE Delivery_Date__c >= :sDateTime
                                      AND Delivery_Date__c <= :eDateTime
                                      AND Stage__c != 'Closed Lost'
                                      AND Pickup_Location__c LIKE :pickupLocation
                                      AND RecordTypeId = :erpRT ] )
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
                                    Payment_Method__c,
                                    InvoiceNumber__c
                             FROM Opportunity
                             WHERE Delivery_Date__c >= :sDateTime
                             AND Probability < 100
                             AND Probability > 0
                             AND Delivery_Date__c <= :eDateTime
                             AND Pickup_Location__c LIKE :pickupLocation] )
    {
      result.add( new EventData( opp ) );
    }
    System.debug( result );
    return JSON.serialize( result );
  }

  private static String fetchServiceEvents( String startAt,
                                            String endAt,
                                            String storeLocation )
  {
    Date sDateTime = DateTime.newInstance( Long.valueOf(startAt) ).date();
    Date eDateTime = DateTime.newInstance( Long.valueOf(endAt) ).date();
    System.debug( 'start = ' + sDateTime );
    System.debug( 'end = ' + eDateTime );
    AcctSeedERP__Warehouse__c wh = [SELECT Id
                                    FROM AcctSeedERP__Warehouse__c
                                    WHERE Name = :storeLocation ];
    List<EventData> result = new List<EventData>();
    Id erpRT = gcConstants.idRtProjectService;
    for( AcctSeed__Project__c erp : [SELECT Id,
                                            Name,
                                            AcctSeedERP__Work_Order_Number__c,
                                            Stage__c,
                                            Owner.Name,
                                            Job_Status__c,
                                            Salesperson__r.Name,
                                            AcctSeed__Account__r.Name,
                                            AcctSeed__Account__r.Boat_Specialist__r.Name,
                                            Grand_Total__c,
                                            Serial_Number__c,
                                            Serial_Product__c,
                                            Pickup_Location__c,
                                            Service_Date__c,
                                            Estimated_Service_Duration__c,
                                            WarehouseName__c,
                                            GMBLASERP__Warehouse__c,
                                            Payment_Method__c,
                                            Payment_Status__c,
                                            RecordTypeId,
                                            Parking_Spot__c
                                      FROM AcctSeed__Project__c
                                      WHERE Service_Date__c >= :sDateTime
                                      AND Service_Date__c <= :eDateTime
                                      AND Stage__c != 'Closed Lost'
                                      AND GMBLASERP__Warehouse__c = :wh.Id
                                      AND RecordTypeId = :erpRT ] )
    {
      result.add( new EventData( erp ) );
    }
    return JSON.serialize( result );
  }

  private static AcctSeed__Project__c retrieveERP( String erpId )
  {
    return [SELECT Id,
              Name,
              AcctSeedERP__Work_Order_Number__c,
              Parking_Spot__c,
              Job_Status__c,
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
              Service_Date__c,
              Estimated_Service_Duration__c,
              Serial_Product__c,
              Serial_Number__c,
              WarehouseName__c,
              GMBLASERP__Warehouse__c,
              On_Water_Orientation__c,
              Payment_Method__c,
              Payment_Status__c,
              RecordTypeId
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
                    Payment_Method__c,
                    InvoiceNumber__c
             FROM Opportunity
             WHERE Id = :oppId];
  }

}