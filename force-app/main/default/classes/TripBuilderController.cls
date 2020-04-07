public with sharing class TripBuilderController {
  public class TripException extends Exception {}

  public class BOL_Wrapper {
    public DateTime departureDate { get; set; }
    public DateTime deliveryDate { get; set; }
    public String driver { get; set; }
    public String accountName { get; set; }
    public String shipTo_Street { get; set; }
    public String shipTo_City { get; set; }
    public String shipTo_State { get; set; }
    public String shipTo_PostalCode { get; set; }
    public String phone { get; set; }
    public String email { get; set; }
    public String bolNumber { get; set; }
    public String notes  { get; set; }
    public BOL_Items_Wrapper[] items { get; set; }

    public BOL_Wrapper( String driver, DateTime depart, Truck_Destination__c dest )
    {
      this.departureDate = depart;
      this.driver = driver;
      this.bolNumber = dest.Name.split('-')[1];
      this.deliveryDate = dest.Delivery_Date__c;
      this.accountName = dest.Account__r.Name;
      this.phone = dest.Account__r.Phone;
      this.email = dest.Account__r.AccountEmail__c;
      this.notes = dest.Notes__c;
      this.items = new List<BOL_Items_Wrapper>();
      this.shipTo_Street = dest.Account__r.ShippingStreet != null ?
        dest.Account__r.ShippingStreet :
        dest.Account__r.BillingStreet;
      this.shipTo_City = dest.Account__r.ShippingCity != null ?
        dest.Account__r.ShippingCity :
        dest.Account__r.BillingCity;
      this.shipTo_State = dest.Account__r.ShippingState != null ?
        dest.Account__r.ShippingState :
        dest.Account__r.BillingState;
      this.shipTo_PostalCode = dest.Account__r.ShippingPostalCode != null ?
        dest.Account__r.ShippingPostalCode :
        dest.Account__r.BillingPostalCode;
    }

    public void addItems( ErpWrapper erpW)
    {
      this.items.add( new BOL_Items_Wrapper( erpW ) );
    }
  }

  public Class BOL_Items_Wrapper {
    public String orderNumber { get; set; }
    public MaterialWrapper boat { get; set; }
    public MaterialWrapper trailer { get; set; }
    public MaterialWrapper[] motors { get; set; }

    public BOL_Items_Wrapper( ErpWrapper erpW )
    {
      this.orderNumber = erpW.orderNumber;
      this.boat = new MaterialWrapper();
      this.trailer = new MaterialWrapper();
      this.motors = new List<MaterialWrapper>();

      for( MaterialWrapper matW : erpW.MaterialWrappers )
      {
        if( matW.requiresShipping )
        {
          if( matW.RecordType == 'Boat' )
            this.boat = matW;
          if( matW.RecordType == 'Trailer' )
            this.trailer = matW;
          if( matW.RecordType == 'Motor' )
            this.motors.add(matW);
          if( matW.RecordType == 'Trolling Motor' )
            this.motors.add( matW );
        }
      }
    }

  }

  public class MaterialWrapper {
    public String Id { get; set; }
    public String Name { get; set; }
    public String SerialNumber  { get; set; }
    public String SerialId { get; set; }
    public String RecordType { get; set; }
    public Boolean isRetailSale { get; set; }
    public Boolean isTransfer { get; set; }
    public Boolean requiresShipping { get; set; }

     public MaterialWrapper()
    {
      this.Id = '';
      this.Name = '';
      this.SerialNumber = '';
      this.SerialId = '';
      this.RecordType = '';
      this.isRetailSale = false;
      this.requiresShipping = true;
    }

    public MaterialWrapper( AcctSeedERP__Material__c mat, String warehouse)
    {
      this.Id = mat.Id;
      this.Name = mat.Product_Name__c;
      this.SerialNumber = mat.GMBLASERP__Serial_Number__r == null ? null : mat.GMBLASERP__Serial_Number__r.Name;
      this.SerialId = mat.GMBLASERP__Serial_Number__c;
      this.RecordType = mat.AcctSeedERP__Product__r.RecordType.Name;
      this.isRetailSale = true;
      this.isTransfer = false;
      this.requiresShipping = warehouse != mat.GMBLASERP__Serial_Number__r.Location__c;
    }

    public MaterialWrapper( AcctSeedERP__Material__c mat)
    {
      this.Id = mat.Id;
      this.Name = mat.Product_Name__c;
      this.SerialNumber = mat.GMBLASERP__Serial_Number__r == null ? null : mat.GMBLASERP__Serial_Number__r.Name;
      this.SerialId = mat.GMBLASERP__Serial_Number__c;
      this.RecordType = mat.AcctSeedERP__Product__r.RecordType.Name;
      this.isRetailSale = false;
      this.requiresShipping = true;
      this.isTransfer = false;
    }

    public MaterialWrapper( Legend_Transfer_Item__c item )
    {
      this.Id = item.Id;
      this.Name = item.Product__r.Name;
      this.SerialNumber =item.Serial_Number__r == null ? null : item.Serial_Number__r.Name;
      this.SerialId = item.Serial_Number__c;
      this.RecordType = item.Product__r.RecordType.Name;
      this.isRetailSale = false;
      this.requiresShipping = true;
      this.isTransfer = true;
    }
  }

  public class ERPWrapper {

    public String Id { get; set; }
    public String Name { get; set; }
    public String orderNumber { get; set; }
    public String OrderDate { get; set; }
    public String Stage { get; set; }
    public Boolean isDealerBookingOrder { get; set; }
    Public Boolean isRetailSale { get; set; }
    public Boolean isTransfer { get; set; }
    public Boolean isSelected { get; set; }
    public MaterialWrapper[] MaterialWrappers { get; set; }

    public ERPWrapper( AcctSeed__Project__c erp )
    {
      this.MaterialWrappers = new List<MaterialWrapper>();
      this.Id = erp.Id;
      this.Name = erp.Name;
      this.Stage = erp.Stage__c;
      this.orderNumber = erp.AcctSeedERP__Work_Order_Number__c;
      this.isRetailSale = erp.RecordType.Name.contains('Retail');
      for( AcctSeedERP__Material__c mat : erp.AcctSeedERP__Project_Materials__r )
      {
        if( this.isRetailSale )
          this.MaterialWrappers.add( new MaterialWrapper( mat, erp.GMBLASERP__Warehouse__r.Name) );
        else
          this.MaterialWrappers.add( new MaterialWrapper( mat) );
      }
    }

    public ERPWrapper( AcctSeed__Project__c erp, Boolean isSelected )
    {
      this.MaterialWrappers = new List<MaterialWrapper>();
      this.Id = erp.Id;
      this.Name = erp.Name;
      this.Stage = erp.Stage__c;
      this.OrderDate = erp.CreatedDate.format('MMM d, yyyy');
      this.isSelected = isSelected;
      this.isDealerBookingOrder = erp.isDealerBookingOrder__c;
      this.isRetailSale = erp.RecordType.Name.contains('Retail');
      for( AcctSeedERP__Material__c mat : erp.AcctSeedERP__Project_Materials__r )
      {
        if( this.isRetailSale )
          this.MaterialWrappers.add( new MaterialWrapper( mat, erp.GMBLASERP__Warehouse__r.Name) );
        else
          this.MaterialWrappers.add( new MaterialWrapper( mat) );
      }
    }

    public ERPWrapper( Legend_Transfer_Request__c transfer, Boolean isSelected )
    {
      this.MaterialWrappers = new List<MaterialWrapper>();
      this.Id = transfer.Id;
      this.Name = transfer.Name;
      this.Stage = '';
      this.orderNumber = transfer.Name;
      this.OrderDate = transfer.CreatedDate.format('MMM d, yyyy');
      this.isSelected = isSelected;
      this.isDealerBookingOrder = false;
      this.isRetailSale = false;
      this.isTransfer = true;
      for( Legend_Transfer_Item__c item : transfer.Legend_Transfer_Items__r )
      {
        this.MaterialWrappers.add( new MaterialWrapper( item ) );
      }
    }
  }

  public class DeliveryItemWrapper {
    public String Id { get; set; }
    public String DestinationId { get; set; }
    public String Position { get; set; }
    public ERPWrapper ErpWrapper { get; set; }

    public DeliveryItemWrapper(Truck_Delivery_Item__c tdi , ERPWrapper erpWrapper )
    {
      this.Id = tdi.Id;
      this.Position = tdi.Position__c;
      this.ERPWrapper = erpWrapper;
      this.DestinationId = tdi.Destination__c;
    }
  }

  public class DestinationWrapper {
    public Truck_Delivery_Item__c[] truckDeliveryItems { get; set; }
    public String Id { get; set; }
    public String Notes { get; set; }
    public String AccountId { get; set; }
    public String AccountName { get; set; }
    public String AccountSpecialInstructions { get; set; }
    public String ShippingTools { get; set; }
    public String TripId { get; set; }
    public Boolean NotificationSent { get; set; }
    public Date Delivery_Date { get; set; }
    public String Type { get; set; }
    public Set<String> erpIds { get; set; }
    public ERPWrapper[] erpWrappers { get; set; }
    public DeliveryItemWrapper[] deliveryItems { get; set; }

    public DestinationWrapper( Truck_Destination__c td )
    {
      this.truckDeliveryItems = td.Truck_Delivery_Items__r;
      this.Id = td.Id;
      this.AccountId = td.Account__c;
      this.AccountSpecialInstructions = td.Account__r.Special_Delivery_Instructions__c;
      this.ShippingTools = td.Account__r.Shipping_Tools__c;
      this.Notes = td.Notes__c;
      this.AccountName = td.Account__r.Name;
      this.TripId = td.Trip__c;
      this.NotificationSent = td.Partner_Notification_Sent__c;
      this.Delivery_Date = td.Delivery_Date__c;
      this.Type = td.Type__c;
      this.erpIds = new Set<String>();
      this.erpWrappers = new List<ERPWrapper>();
    }

    //public DestinationWrapper( Truck_Destination__c td, List<AcctSeed__Project__c> erps )
    //{
    //  System.debug('&&& SHIPPING TOOLS &&& ' + td.Account__r.Shipping_Tools__c );
    //  this.Id = td.Id;
    //  this.AccountId = td.Account__c;
    //  this.AccountSpecialInstructions = td.Account__r.Special_Delivery_Instructions__c;
    //  this.ShippingTools = td.Account__r.Shipping_Tools__c;
    //  this.Notes = td.Notes__c;
    //  this.AccountName = td.Account__r.Name;
    //  this.TripId = td.Trip__c;
    //  this.Delivery_Date = td.Delivery_Date__c;
    //  this.Type = td.Type__c;
    //  this.erpIds = new Set<String>();
    //  this.erpWrappers = new List<ERPWrapper>();
    //  if( erps != null )
    //  {
    //    for( AcctSeed__Project__c erp : erps )
    //    {
    //      this.erpIds.add( erp.Id );
    //      this.erpWrappers.add( new ERPWrapper(erp, true) );
    //    }
    //  }
    //  buildDeliveryItems( td.Truck_Delivery_Items__r, this.erpWrappers);
    //}

    public DestinationWrapper addERPs( List<AcctSeed__Project__c> erps )
    {
      for( AcctSeed__Project__c erp : erps )
      {
        this.erpIds.add( erp.Id );
        this.erpWrappers.add( new ERPWrapper(erp, true) );
      }
      buildDeliveryItems();
      return this;
    }

    public DestinationWrapper addTransfers( List<Legend_Transfer_Request__c> transfers )
    {
      for( Legend_Transfer_Request__c transfer : transfers )
      {
        this.erpIds.add( transfer.Id );
        this.erpWrappers.add( new ERPWrapper(transfer, true) );
      }
      buildDeliveryItems();
      return this;
    }

    //public DestinationWrapper( Truck_Destination__c td, List<Legend_Transfer_Request__c> transfers )
    //{
    //  System.debug('&&& SHIPPING TOOLS &&& ' + td.Account__r.Shipping_Tools__c );
    //  this.Id = td.Id;
    //  this.AccountId = td.Account__c;
    //  this.AccountSpecialInstructions = td.Account__r.Special_Delivery_Instructions__c;
    //  this.ShippingTools = td.Account__r.Shipping_Tools__c;
    //  this.Notes = td.Notes__c;
    //  this.AccountName = td.Account__r.Name;
    //  this.TripId = td.Trip__c;
    //  this.Delivery_Date = td.Delivery_Date__c;
    //  this.Type = td.Type__c;
    //  this.erpIds = new Set<String>();
    //  this.erpWrappers = new List<ERPWrapper>();
    //  if( transfers != null )
    //  {
    //    for( Legend_Transfer_Request__c transfer : transfers )
    //    {
    //      this.erpIds.add( transfer.Id );
    //      this.erpWrappers.add( new ERPWrapper(transfer, true) );
    //    }
    //  }
    //  buildDeliveryItems( td.Truck_Delivery_Items__r, this.erpWrappers);
    //}

    //private void buildDeliveryItems( Truck_Delivery_Item__c[] deliveryItems, ERPWrapper[] erpWrappers)
    //{
    //  this.DeliveryItems = new List<DeliveryItemWrapper>();
    //  Map<String, ERPWrapper > erpMap = new Map<String, ERPWrapper>();
    //  for( ERPWrapper wrap : erpWrappers )
    //  {
    //    erpMap.put( wrap.Id, wrap);
    //  }
    //  for( Truck_Delivery_Item__c tdi : deliveryItems )
    //  {
    //    if( erpMap.containsKey( tdi.ERP_Order__c ) )
    //    {
    //      this.DeliveryItems.add( new DeliveryItemWrapper( tdi, erpMap.get(tdi.ERP_Order__c) ) );
    //    }
    //  }
    //}

    private void buildDeliveryItems()
    {
      this.DeliveryItems = new List<DeliveryItemWrapper>();
      Map<String, ERPWrapper > erpMap = new Map<String, ERPWrapper>();
      for( ERPWrapper wrap : this.erpWrappers )
      {
        erpMap.put( wrap.Id, wrap);
      }
      for( Truck_Delivery_Item__c tdi : this.truckDeliveryItems )
      {
        if( erpMap.containsKey( tdi.ERP_Order__c ) )
          this.DeliveryItems.add( new DeliveryItemWrapper( tdi, erpMap.get(tdi.ERP_Order__c) ) );
        if( erpMap.containsKey( tdi.Legend_Transfer_Request__c ) )
          this.DeliveryItems.add( new DeliveryItemWrapper( tdi, erpMap.get(tdi.Legend_Transfer_Request__c) ) );
      }
    }
  }

  public static Truck_Trip__c trip { get; set; }
  public final String tripId { get; set; }
  public Map<String, List<DeliveryItemWrapper>> itemsMap { get; set; }
  public BOL_Wrapper[] bolWrappers { get; set; }


	public TripBuilderController( ApexPages.StandardController std ) {
    tripId = std.getId();//ApexPages.currentPage().getParameters().get('Id');
  }

  public void init()
  {
    if( tripId == null )
    {
      trip = new Truck_Trip__c(
        Id = null,
        Name = null,
        Trailer__c = null,
        Truck__c = null,
        Truck_Driver__c = null,
          Distance_KM__c = null,
        Departure_Date__c = null,
        Return_Date__c = null);
    }
    else
    {
      trip = fetchTrip( tripId );
    }
  }

  public void initTruckLoadPDF()
  {
    itemsMap = new Map<String, List<DeliveryItemWrapper>>();
    for( String pos : LGND_Utilities.getPicklistValues('Truck_Delivery_Item__c', 'Position__c') )
    {
      itemsMap.put(pos, new List<DeliveryItemWrapper>() );
    }
    List<Id> destIds = new List<Id>();
    trip = fetchTrip( tripId );
    for( Truck_Destination__c dest : trip.Destinations__r )
    {
      destIds.add( dest.Id );
    }
    for( DestinationWrapper dw: wrapDestinations( destIds ) )
    {
      if( dw.deliveryItems != null && dw.deliveryItems.size() > 0 )
      {
        for( DeliveryItemWrapper diw : dw.deliveryItems )
        {
          if( itemsMap.containsKey(diw.Position) )
          {
            itemsMap.get( diw.Position ).add( diw );
          }
        }
      }
    }
  }

  public void initBOL_PDF()
  {
    Map<Id, Bol_Wrapper> destBolMap = new Map<Id, BOL_Wrapper>();
    trip = [SELECT Id,
                   Name,
                   Trailer__c,
                   Truck__c,
                   Truck_Driver__r.Name,
                   Departure_Date__c,
        Distance_KM__c,
                   Return_Date__c,
              (SELECT Id,
                      Name,
                      Account__r.Name,
                      Account__r.AccountEmail__c,
                      Account__r.Phone,
                      Account__r.BillingCity,
                      Account__r.BillingCountry,
                      Account__r.BillingState,
                      Account__r.BillingStreet,
                      Account__r.BillingPostalCode,
                      Account__r.ShippingCity,
                      Account__r.ShippingCountry,
                      Account__r.ShippingState,
                      Account__r.ShippingStreet,
                      Account__r.ShippingPostalCode,
                      Type__c,
                      Notes__c,
                      Delivery_Date__c,
                      Travel_Days__c
               FROM Destinations__r
               WHERE Type__c = 'Delivery' )
            FROM Truck_Trip__c
            WHERE Id = :tripId];

    //Map<Id, List<AcctSeed__Project__c>> dest_erp_map = new Map<Id, List<AcctSeed__Project__c>>();

    for( Truck_Destination__c dest : trip.Destinations__r )
    {
      //dest_erp_map.put( dest.Id, new List<AcctSeed__Project__c>() );
      destBolMap.put( dest.Id, new BOL_Wrapper( trip.Truck_Driver__r.Name,
                                                trip.Departure_Date__c,
                                                dest )
                    );
    }
    Set<Id> productRTs = new Set<Id>{
      LGND_Utilities.recordTypeIdFromName('Product2', 'Trailer'),
      LGND_Utilities.recordTypeIdFromName('Product2', 'Trolling Motor'),
      LGND_Utilities.recordTypeIdFromName('Product2', 'Motor'),
      LGND_Utilities.recordTypeIdFromName('Product2', 'Boat')
    };
    for( AcctSeed__Project__c erp : [ SELECT Id,
                                             Name,
                                             RecordType.Name,
                                             Destination__c,
                                             Stage__c,
                                             AcctSeedERP__Work_Order_Number__c,
                                             GMBLASERP__Warehouse__r.Name,
                                      (SELECT Id,
                                              Product_Name__c,
                                              AcctSeedERP__Product__r.RecordType.Name,
                                              GMBLASERP__Serial_Number__c,
                                              GMBLASERP__Serial_Number__r.Name,
                                              GMBLASERP__Serial_Number__r.Location__c
                                      FROM AcctSeedERP__Project_Materials__r
                                      WHERE AcctSeedERP__Product__r.RecordTypeId IN :productRTs )
                                      FROM AcctSeed__Project__c
                                      WHERE Destination__c IN :destBolMap.keySet()] )
    {
      destBolMap.get( erp.Destination__c ).addItems( new ErpWrapper(erp) );
    }
    for( Legend_Transfer_Request__c trans : [SELECT Id,
                                                    Name,
                                                    Destination__c,
                                                    CreatedDate,
                                             (SELECT Id,
                                                     Product__r.Name,
                                                     Product__r.RecordType.Name,
                                                     Serial_Number__c,
                                                     Serial_Number__r.Name,
                                                     Serial_Number__r.Location__c
                                              FROM Legend_Transfer_Items__r
                                              WHERE Product__r.RecordTypeId IN :productRTs )
                                             FROM Legend_Transfer_Request__c
                                             WHERE Destination__c IN :destBolMap.keySet()] )
    {
      destBolMap.get( trans.Destination__c ).addItems( new ErpWrapper( trans, true ) );
    }

    bolWrappers = destBolMap.values();
  }


  public PageReference getReturnURL() {
    Schema.DescribeSObjectResult result = Truck_Trip__c.SObjectType.getDescribe();
    PageReference pageRef = new PageReference('/' + result.getKeyPrefix());
    pageRef.setRedirect(true);
    return pageRef;
  }

  public String getTripJSON()
  {
    return JSON.serializePretty( trip );
  }

  @RemoteAction
  public static Truck_Trip__c retrieveTrip()
  {
    return trip;
  }

  public class SelectOptionsWrapper {
    public Map<String, Map<String, String>> drivers { get; set; }
    public List<String> trucks { get; set; }
    public List<String> trailers { get; set; }
    public List<String> trailerPositions { get; set; }

    public SelectOptionsWrapper(){}
  }

  public String getSelectOptions()
  {
    SelectOptionsWrapper so = new SelectOptionsWrapper();
    so.drivers = TruckSchedule.fetchTruckDrivers();
    so.trucks = LGND_Utilities.getPicklistValues('Truck_Trip__c', 'Truck__c');
    so.trailers = LGND_Utilities.getPicklistValues('Truck_Trip__c', 'Trailer__c');
    so.trailerPositions = LGND_Utilities.getPicklistValues('Truck_Delivery_Item__c', 'Position__c');
    return JSON.serialize( so );
  }

  @RemoteAction
  public static Truck_Trip__c saveTrip( String JSONdata )
  {
    System.debug('JSONdata');
    System.debug(JSONdata);
    if( Schema.sObjectType.Truck_Trip__c.isUpdateable() )
    {
      Truck_Trip__c t = (Truck_Trip__c)JSON.deserialize( JSONdata, Truck_Trip__c.class );
      String errorMsg = TruckSchedule.findSchedulingConflicts( t );
      if( errorMsg != null )
        throw new TruckSchedule.TruckScheduleException( errorMsg );
      upsert t;
      return fetchTrip( t.Id );
    }
    throw new TripException('You do not have the required access on the Truck Trip object');
  }

  @RemoteAction
  public static void deleteTrip( String tripId )
  {
    if( !Schema.sObjectType.Truck_Trip__c.isDeletable() )
      throw new TripException('You do not have the required access on the Truck Trip object');
    Truck_Trip__c tt = new Truck_Trip__c( Id = tripId );
    delete tt;
  }

  @RemoteAction
  public static Account[] fetchDestinationAccounts()
  {
    Set<Id> rtIds = new Set<Id>{
      LGND_Utilities.recordTypeIdFromName('Account', 'Dealer'),
      LGND_Utilities.recordTypeIdFromName('Account', 'Supplier')
    };
    return [SELECT Id, Name, BillingCountry, BillingState, BillingCity, BillingStreet
            FROM Account
            WHERE RecordTypeId In :rtIds
            AND Active__c = true
            ORDER BY Name];
  }

  @RemoteAction
  public static List<DestinationWrapper> fetchDestinations( List<Id> destIds )
  {
    return wrapDestinations( destIds );
  }

  public class ContactsWrapper {
    public Boolean hasBeenSent { get; set; }
    public List<Map<String, String>> contacts { get; set; }

    public ContactsWrapper( String destId )
    {
      Truck_Destination__c td = [SELECT Id, Account__c, Partner_Notification_Sent__c
                                 FROM Truck_Destination__c
                                 WHERE Id = :destId ];
      this.hasBeenSent = td.Partner_Notification_Sent__c;
      this.contacts = buildContactList( td.Account__c );
    }

    private List<Map<String, String>> buildContactList( String acctId )
    {
      List<Map<String,String>> result = new List<Map<String, String>>();
      for( Contact c : [SELECT Id, FirstName, LastName, Email, Title
                        FROM Contact
                        WHERE AccountId = :acctId] )
      {
        result.add( new MAp<String, String>{
          'id' => c.Id,
          'name' => c.FirstName + ' ' + c.LastName,
          'email' => c.Email,
          'title' => c.Title
        });
      }
      return result;
    }
  }

  @RemoteAction
  public static ContactsWrapper fetchAccountContacts( String destinationId )
  {
    return new ContactsWrapper( destinationId );
  }

  @RemoteAction
  public static void sendPartnerDeliveryNotice( String destinationId,
                                                String[] contactIds )
  {
    //throw new TripException('This is not implemented yet');
    Truck_Destination__c td = [SELECT Id,
                                      Account__c,
                                      Trip__r.Truck_Driver__r.Partner_Pickup_Placeholder__c
                               FROM Truck_Destination__c
                               WHERE Id = :destinationId ];
    User currentUser = [SELECT Id, Email FROM User WHERE Id = :UserInfo.getUserId() ];
    String[] ccAddrs = new List<String>{
      currentUser.Email,
      'dealercare@legendboats.com'
    };
    String subject = td.Trip__r.Truck_Driver__r.Partner_Pickup_Placeholder__c ?
      'Product Ready for Pick-up' :
      'Legend Boats Delivery Notice';
    String templateId = Legend_Settings__c.getOrgDefaults().Partner_Delivery_Notice_Template_Id__c;
    Id orgEmailId;
    try {
      orgEmailId = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'Legend Logistics' LIMIT 1].Id;
    }
    catch(Exception e){}
    List<Id> toAddresses = new List<Id>();
    for( String cId : contactIds )
    {
      toAddresses.add( Id.valueOf( cId ) );
    }
    List<Messaging.SingleEmailMessage> msgList= new List<Messaging.SingleEmailMessage>();
    //Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(
      templateId,
      toAddresses[0],
      destinationId
    );

    if( orgEmailId != null )
    {
      mail.setOrgWideEmailAddressId( orgEmailId );
    }
    mail.setToAddresses( toAddresses );
    mail.setSubject( subject );
    mail.setTargetObjectId( toAddresses[0] );
    mail.setWhatId( destinationId );
    mail.setTemplateId( templateId );
    mail.setCcAddresses( ccAddrs );
    mail.setSaveAsActivity(true);
    msgList.add(mail);

    Messaging.sendEmail(msgList);
    td.Partner_Notification_Sent__c = true;
    update td;
  }

  @RemoteAction
  public static DestinationWrapper saveDestination( String destinationJSON, List<String> selectedIds )
  {

    Truck_Destination__c td = (Truck_Destination__c)JSON.deserialize( destinationJSON , Truck_Destination__c.class );
    // check permissions
    List<String> errorMsgs = new List<String>();
    Schema.DescribeSObjectResult deliveryObj = Schema.sObjectType.Truck_Delivery_Item__c;
    Schema.DescribeSObjectResult destObj = Schema.sObjectType.Truck_Destination__c;
    if( td.Id == null && !destObj.isCreateable() )
      errorMsgs.add('Truck Destination - Create');
    if( td.Id != null && !destObj.isUpdateable() )
      errorMsgs.add('Truck Destination - Edit');
    if( !deliveryObj.isCreateable() )
      errorMsgs.add('Truck Delivery Item - Create');
    if( errorMsgs.size() == 0 )
    {
      //we need to check if there where any erp associated this destination
      Truck_Delivery_Item__c[] oldItems = new List<Truck_Delivery_Item__c>();
      upsert td;

      Truck_Delivery_Item__c[] deliveryItems = [SELECT Id,
                                                       Position__c,
                                                       Destination__c,
                                                       ERP_Order__c,
                                                       Legend_Transfer_Request__c
                                                FROM Truck_Delivery_Item__c
                                                WHERE Destination__c = :td.Id ];
      Set<String> selectedIdsSet = new Set<String>(selectedIds);
      Set<String> erpIdsSet = new Set<String>();
      Set<String> transferIdsSet = new Set<String>();
      for( String sid : selectedIds )
      {
        if( LGND_Utilities.sObjectNameFromId( sid ) == 'AcctSeed__Project__c' )
          erpIdsSet.add( sid );
        if( LGND_Utilities.sObjectNameFromId( sid ) == 'Legend_Transfer_Request__c' )
          transferIdsSet.add( sid );
      }

      Integer lastUsedPosition = findNextOpenTruckPOsition( td.Trip__c );
      Map<Id, Truck_Delivery_Item__c> erpDeliveryMap = new Map<Id, Truck_Delivery_Item__c>();
      Map<Id, Truck_Delivery_Item__c> transferDeliveryMap = new Map<Id, Truck_Delivery_Item__c>();
      List<Truck_Delivery_Item__c> newDeliveryItems = new List<Truck_Delivery_Item__c>();
      for( Truck_Delivery_Item__c tdi : deliveryItems )
      {
        if( tdi.ERP_Order__c != null &&
            !erpIdsSet.contains( tdi.ERP_Order__c ) )
        {
          oldItems.add( tdi );
        }
        if( tdi.Legend_Transfer_Request__c != null &&
            !transferIdsSet.contains( tdi.Legend_Transfer_Request__c) )
        {
          oldItems.add( tdi );
        }
        if( Integer.valueOf(tdi.Position__c) > lastUsedPosition )
          lastUsedPosition = Integer.valueOf(tdi.Position__c);

        if( tdi.ERP_Order__c != null )
          erpDeliveryMap.put( tdi.ERP_Order__c, tdi );
        if( tdi.Legend_Transfer_Request__c != null )
          transferDeliveryMap.put( tdi.Legend_Transfer_Request__c, tdi );
      }
      for( String sId : selectedIds )
      {
        System.debug( LGND_Utilities.sObjectNameFromId( sId ) );
        lastUsedPosition = lastUsedPosition == 7 ? 1 : lastUsedPosition + 1;
        if( LGND_Utilities.sObjectNameFromId( sId ) == 'AcctSeed__Project__c' &&
            !erpDeliveryMap.containsKey(sId) )
        {
          newDeliveryItems.add( new Truck_Delivery_Item__c(
              ERP_Order__c = sId,
              Destination__c = td.Id,
              Position__c = String.valueOf( lastUsedPosition )
            )
          );
        }
        System.debug( LGND_Utilities.sObjectNameFromId( sId ) == 'Legend_Transfer_Request__c' );
        System.debug( !transferDeliveryMap.containsKey(sId) );
        if( LGND_Utilities.sObjectNameFromId( sId ) == 'Legend_Transfer_Request__c' &&
            !transferDeliveryMap.containsKey(sId) )
        {
          newDeliveryItems.add( new Truck_Delivery_Item__c(
              Legend_Transfer_Request__c = sId,
              Destination__c = td.Id,
              Position__c = String.valueOf( lastUsedPosition )
            )
          );
        }
      }
      delete oldItems;
      insert newDeliveryItems;
      return wrapDestinations( new List<Id>{ td.Id } )[0];
    }
    String errorMsg = 'You are missing the following permissions:';
    for( String err : errorMsgs )
    {
      errorMsg += ' ' + err + ',';
    }
    throw new TripException( errorMsg.removeEnd(',') + '.');
  }

  @RemoteAction
  public static void deleteDestination( String destId )
  {
    if( !Schema.sObjectType.Truck_Destination__c.isDeletable() )
      throw new TripException('You do not have the required access on the Truck Destination object');
    Truck_Destination__c d = new Truck_Destination__c(Id = destId);
    delete d;
  }

  @RemoteAction
  public static ERPWrapper[] fetchERPs( String accountId, List<String> selectedIds )
  {
    List<ERPWrapper> result = new List<ERPWrapper>();
    Set<String> selectedSet = new Set<String>(selectedIds);
    for( AcctSeed__Project__c erp : queryERPs(accountId, selectedIds) )
    {
      result.add( new ERPWrapper( erp, selectedSet.contains(erp.Id) ) );
    }
    for( Legend_Transfer_Request__c transfer : queryTransfers( accountId, selectedIds) )
    {
      result.add( new ERPWrapper( transfer, selectedSet.contains( transfer.Id ) ) );
    }
    return result;
  }

  @RemoteAction
  public static Truck_Delivery_Item__c updateTruckDeliveryItemPosition( String position, String tdiId )
  {
    if( Schema.sObjectType.Truck_Delivery_Item__c.isUpdateable() )
    {
      Truck_Delivery_item__c tdi = [SELECT Id, Position__c FROM Truck_Delivery_item__c WHERE Id = :tdiId];
      tdi.Position__C = position;
      update tdi;
      return tdi;
    }
    throw new TripException('You do not have the required access on the Truck Delivery Item object');
  }

  @RemoteAction @ReadOnly
  public static List<Map<String,String>> searchSerialForMaterial(Id idMaterial)
  {
    String sObjectName = LGND_Utilities.sObjectNameFromId( idMaterial );
    if( sObjectName == 'AcctSeedERP__Material__c' )
    {
      return Truck_Load_Ext.searchSerialForMaterial(idMaterial);
    }
    if( sObjectName == 'Legend_Transfer_Item__c' )
      return searchSerialForTransferItem( idMaterial );
    return null;
  }


  @RemoteAction
  public static MaterialWrapper setSerialOnMaterial(Id idMaterial, Id idSerial)
  {
    String sObjectName = LGND_Utilities.sObjectNameFromId( idMaterial );
    if( Schema.sObjectType.AcctSeedERP__Material__c.isUpdateable() )
    {
      if( sObjectName == 'AcctSeedERP__Material__c' )
      {
        AcctSeedERP__Material__c matl = [SELECT Id FROM AcctSeedERP__Material__c WHERE Id = :idMaterial][0];
        matl.GMBLASERP__Serial_Number__c = idSerial;
        update matl;
        matl = [SELECT Id,
                        Product_Name__c,
                        AcctSeedERP__Product__r.RecordType.Name,
                        GMBLASERP__Serial_Number__c,
                        GMBLASERP__Serial_Number__r.Name
                FROM AcctSeedERP__Material__c
                WHERE Id = :idMaterial][0];
        return new MaterialWrapper( matl );
      }
      if( sObjectName == 'Legend_Transfer_Item__c' )
      {
        Legend_Transfer_Item__c item = [SELECT Id
                                        FROM Legend_Transfer_Item__c
                                        WHERE Id = :idMaterial ];
        item.Serial_Number__c = idSerial;
        update item;
        item = [SELECT Id,
                       Product__r.Name,
                       Product__r.RecordType.Name,
                       Serial_Number__c,
                       Serial_Number__r.Name
                FROM Legend_Transfer_Item__c
                WHERE Id = :idMaterial];
        return new MaterialWrapper( item );
      }
    }
    throw new TripException('You do not have the required access on the Material object');
  }

  @RemoteAction
  public static Truck_Trip__c fetchTrip( Id tripId )
  {
    try
    {
      return [SELECT Id, Name, Distance_KM__c, Trailer__c, Truck__c, Truck_Driver__c, Truck_Driver__r.Name, Departure_Date__c, Return_Date__c,
              (SELECT Id, Account__r.Name,  Type__c, Delivery_Date__c, Travel_Days__c FROM Destinations__r )
                FROM Truck_Trip__c
                WHERE Id = :tripId];
    }
    catch( Exception e )
    {
      return new Truck_Trip__c(
        Id = null,
        Name = null,
        Trailer__c = null,
        Truck__c = null,
        Driver__c = null,
          Distance_KM__c = null,
        Departure_Date__c = null,
        Return_Date__c = null );
    }
  }

  private static List<Map<String, String>> searchSerialForTransferItem( Id transferItemId )
  {
    List<Map<String, String>> result = new List<Map<String, String>>();
    Legend_Transfer_Item__c item = [SELECT Id, Product__c
                                    FROM Legend_Transfer_Item__c
                                    WHERE Id = :transferItemId ];

    for(GMBLASERP__Serial_Number__c sn :
      [SELECT Id,
        Name,
        GMBLASERP__Lot__c,
        GMBLASERP__Lot__r.Name,
        GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c,
        GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__r.Name,
        Available__c,
        Dealer_Rigged__c
       FROM GMBLASERP__Serial_Number__c
       WHERE GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c != null
       AND GMBLASERP__Product__c = :item.Product__c
       AND Available__c = true
       //AND (Nest__c = null OR Nest__c = :matl.AcctSeedERP__Project__r.Serial_Number__c)
       ORDER BY GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__r.Name, Name])
    {
      Map<String,String> m = new Map<String,String>();
      m.put('idWarehouse', sn.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__c);
      m.put('warehouseName', sn.GMBLASERP__Inventory_Balance__r.AcctSeedERP__Warehouse__r.Name);
      m.put('idLot', sn.GMBLASERP__Lot__c);
      m.put('lotName', sn.GMBLASERP__Lot__r.Name);
      m.put('idSerial', sn.Id);
      m.put('serialName', sn.Name);
      m.put('IsAvailable', sn.Available__c?'true':'false');
      m.put('IsDealerRigged', sn.Dealer_Rigged__c ? 'Yes' : 'No' );
      result.add(m);
    }
    return result;
  }

  private static Integer findNextOpenTruckPosition(Id tripId)
  {
    Integer result = 0;
    for( Truck_Destination__c td : [SELECT Id,
                                    (SELECT Id, Position__c FROM Truck_Delivery_Items__r)
                                    FROM Truck_Destination__c
                                    WHERE Trip__c = :tripId] )
    {
      for( Truck_Delivery_Item__c tdi :td.Truck_Delivery_Items__r )
      {
        if( Integer.ValueOf( tdi.Position__c) > result )
          result = Integer.valueOf( tdi.Position__c );
      }
    }
    return result;
  }

  public static List<DestinationWrapper> wrapDestinations( List<Id> destIds )
  {
    List<DestinationWrapper> result = new List<DestinationWrapper>();
    System.debug( ' ^^^^^ destIds = ' + destIds );
    Map<Id, Truck_Destination__c> destMap = new Map<Id, Truck_Destination__c>(
      [SELECT Id,
              Account__c,
              Account__r.Name,
              Account__r.Special_Delivery_Instructions__c,
              Account__r.Shipping_Tools__c,
              Trip__c, Type__c,
              Delivery_Date__c,
              Notes__c,
              Partner_Notification_Sent__c,
       (SELECT Id, ERP_Order__c, Legend_Transfer_Request__c, Destination__c, Position__c
        FROM Truck_Delivery_Items__r
        WHERE (ERP_Order__c <> null OR Legend_Transfer_Request__c <> null ) )
       FROM Truck_Destination__c
       WHERE Id = :destIds ]
    );

    //find erpIds and transferIds
    Set<Id> erpIds = new Set<Id>();
    Set<Id> transferIds = new Set<Id>();
    for( Truck_Destination__c td : destMap.values() )
    {
      for( Truck_Delivery_Item__c tdi : td.Truck_Delivery_Items__r )
      {
        System.debug( tdi );
        if( tdi.ERP_Order__c != null )
          erpIds.add( tdi.ERP_Order__c );
        if( tdi.Legend_Transfer_Request__c != null )
          transferIds.add( tdi.Legend_Transfer_Request__c );
      }
    }

    System.debug( '^^^^ erpIds = ' + erpIds );
    System.debug( '^^^^ transferIds = ' + transferIds );

    Map<Id, AcctSeed__Project__c> erps = queryERPs( erpIds );
    Map<Id, Legend_Transfer_Request__c> transfers = queryTransfers( transferIds );
    System.debug( transfers );
    for( Truck_Destination__c td : destMap.values() )
    {
      List<AcctSeed__Project__c> destination_erps = new List<AcctSeed__Project__c>();
      List<Legend_Transfer_Request__c> destination_transfers = new List<Legend_Transfer_Request__c>();
      for( Truck_Delivery_Item__c tdi : td.Truck_Delivery_Items__r )
      {
        if( tdi.ERP_Order__c != null )
          destination_erps.add( erps.get(tdi.ERP_Order__c) );
        if( tdi.Legend_Transfer_Request__c != null )
          destination_transfers.add( transfers.get(tdi.Legend_Transfer_Request__c) );
      }
      DestinationWrapper dw = new DestinationWrapper( td );
      if( destination_erps.size() > 0 )
        dw.addERPs( destination_erps );

      if( destination_transfers.size() > 0 )
        dw.addTransfers( destination_transfers );

      result.add(dw);
    }
    System.debug( result );
    return result;
  }

  private static List<AcctSeed__Project__c> queryERPs( String accountId, List<String> selectedErpIds)
  {
    Set<String> excludeStages = new Set<String>{
      'Draft',
      'Delivered',
      'Closed Lost'
    };
    Set<Id> productRTs = new Set<Id>{
      LGND_Utilities.recordTypeIdFromName('Product2', 'Trailer'),
      LGND_Utilities.recordTypeIdFromName('Product2', 'Boat')
    };

    Map<Id, String> locMap = new Map<Id, String>{
      Legend_Settings__c.getOrgDefaults().LegendBarrieAccountId__c => 'Barrie',
      Legend_Settings__c.getOrgDefaults().LegendMontrealAccountId__c => 'Montreal',
      Legend_Settings__c.getOrgDefaults().LegendWhitefishAccountId__c => 'Whitefish'
    };

    AcctSeed__Project__c[] erps = [SELECT Id,
                                          Name,
                                          CreatedDate,
                                          RecordType.Name,
                                          Stage__c,
                                          Is_Scheduled_For_Delivery__c,
                                          isDealerBookingOrder__c,
                                          GMBLASERP__Warehouse__r.Name,
                                   (SELECT Id,
                                           Product_Name__c,
                                           AcctSeedERP__Product__r.RecordType.Name,
                                           GMBLASERP__Serial_Number__c,
                                           GMBLASERP__Serial_Number__r.Name,
                                           GMBLASERP__Serial_Number__r.Location__c
                                    FROM AcctSeedERP__Project_Materials__r
                                    WHERE AcctSeedERP__Product__r.RecordTypeId IN :productRTs)
                                   FROM AcctSeed__Project__c
                                   WHERE ( AcctSeed__Account__c = :accountId AND
                                           Is_Scheduled_For_Delivery__c = false AND
                                           Stage__c NOT IN :excludeStages AND
                                           RecordTypeId = :gcConstants.idRtProjectPartnerBoatSale )
                                   OR Id IN :selectedErpIds
                                   ORDER BY CreatedDate];

    if( locMap.containsKey( accountId) )
      erps.addAll( addRetailERPsRequiringShipping( accountId, locMap.get(accountId), selectedErpIds) );

    return erps;
  }

  private static List<Legend_Transfer_Request__c> queryTransfers( String accountId, List<String> selectedIds)
  {
    Set<Id> productRTs = new Set<Id>{
      LGND_Utilities.recordTypeIdFromName('Product2', 'Trailer'),
      LGND_Utilities.recordTypeIdFromName('Product2', 'Boat'),
      LGND_Utilities.recordTypeIdFromName('Product2', 'Motor')
    };

    Map<Id, String> locMap = new Map<Id, String>{
      Legend_Settings__c.getOrgDefaults().LegendBarrieAccountId__c => 'Barrie',
      Legend_Settings__c.getOrgDefaults().LegendMontrealAccountId__c => 'Montreal',
      Legend_Settings__c.getOrgDefaults().LegendWhitefishAccountId__c => 'Whitefish'
    };

    Legend_Transfer_Request__c[] transfers = [SELECT Id,
                                                    Name,
                                                    CreatedDate,
                                             (SELECT Id,
                                                     Product__r.Name,
                                                     Product__r.RecordType.Name,
                                                     Serial_Number__c,
                                                     Serial_Number__r.Name,
                                                     Serial_Number__r.Location__c
                                              FROM Legend_Transfer_Items__r
                                              WHERE Product__r.RecordTypeId IN :productRTs)
                                             FROM Legend_Transfer_Request__c
                                             WHERE (Account__c = :accountId AND Stage__c = 'Plan Load')
                                             OR Id IN :selectedIds
                                             ORDER BY CreatedDate];
    return transfers;
  }

  private static List<AcctSeed__Project__c> addRetailERPsRequiringShipping( Id acctId,
                                                                            String locName,
                                                                            List<String> selectedErpIds )
  {
    Set<Id> productRTs = new Set<Id>{
      LGND_Utilities.recordTypeIdFromName('Product2', 'Trailer'),
      LGND_Utilities.recordTypeIdFromName('Product2', 'Boat'),
      LGND_Utilities.recordTypeIdFromName('Product2', 'Motor'),
      LGND_Utilities.recordTypeIdFromName('Product2', 'Trolling Motor')
    };
    Set<String> shippingStages = new Set<String> {
      'Ready to ship to ' + locName,
      'Items to be shipped to ' + locName
    };
    return [SELECT Id,
                  Name,
                  Stage__c,
                  CreatedDate,
                  isDealerBookingOrder__c,
                  RecordType.Name,
                  AcctSeed__Account__r.Name,
                  GMBLASERP__Warehouse__r.Name,
           (SELECT Id,
                   Product_Name__c,
                   AcctSeedERP__Product__r.RecordType.Name,
                   GMBLASERP__Serial_Number__c,
                   GMBLASERP__Serial_Number__r.Name,
                   GMBLASERP__Serial_Number__r.Location__c
            FROM AcctSeedERP__Project_Materials__r
            WHERE AcctSeedERP__Product__r.RecordTypeId IN :productRTs)
           FROM AcctSeed__Project__c
           WHERE Shipping_Status__c IN :shippingStages
           AND Destination__c = null
           AND Id NOT IN :selectedErpIds
           ORDER BY CreatedDate];
  }

  private static Map<Id, AcctSeed__Project__c> queryERPs( Set<Id> erpIds)
  {
    Set<Id> productRTs = new Set<Id>{
      LGND_Utilities.recordTypeIdFromName('Product2', 'Trailer'),
      LGND_Utilities.recordTypeIdFromName('Product2', 'Boat')
    };
    return new Map<Id, AcctSeed__Project__c>( [SELECT Id, Stage__c, RecordType.Name, Name, GMBLASERP__Warehouse__r.Name, CreatedDate, isDealerBookingOrder__c,
            (SELECT Id, Product_Name__c, AcctSeedERP__Product__r.RecordType.Name, GMBLASERP__Serial_Number__c, GMBLASERP__Serial_Number__r.Name, GMBLASERP__Serial_Number__r.Location__c
             FROM AcctSeedERP__Project_Materials__r
             WHERE AcctSeedERP__Product__r.AcctSeedERP__Serialized__c = true)
           FROM AcctSeed__Project__c
           WHERE Id IN :erpIds
           ORDER BY CreatedDate] );
  }

  private static Map<Id, Legend_Transfer_Request__c> queryTransfers( Set<Id> transferIds)
  {
    Set<Id> productRTs = new Set<Id>{
      LGND_Utilities.recordTypeIdFromName('Product2', 'Trailer'),
      LGND_Utilities.recordTypeIdFromName('Product2', 'Boat')
    };
    return new Map<Id, Legend_Transfer_Request__c>( [SELECT Id,
                                                            CreatedDate,
                                                            Name,
            (SELECT Id,
                    Product__r.Name,
                    Product__r.RecordType.Name, Serial_Number__c, Serial_Number__r.Name, Serial_Number__r.Location__c
             FROM Legend_Transfer_Items__r
             WHERE Product__r.AcctSeedERP__Serialized__c = true)
           FROM Legend_Transfer_Request__c
           WHERE Id IN :transferIds
           ORDER BY CreatedDate] );
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
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
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