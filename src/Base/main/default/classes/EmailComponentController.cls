global class EmailComponentController {

  global class EmailComponent_Exception extends Exception{}

  global class ClaimDetail {
    public String description { get; set; }
    public String correction { get; set; }
    public List<PartLine> partLines { get; set; }
    public List<PartLine> labourLines { get; set; }
    public List<PartLine> freightLines { get; set; }
    public List<PartLine> subletLines { get; set; }
    public Decimal grandTotal { get; set; }
    public Decimal partsTotal { get; set; }
    public Decimal labourTotal { get; set; }
    public Decimal freightTotal { get; set; }
    public Decimal subletTotal { get; set; }

    public ClaimDetail ( AcctSeed__Project_Task__c task )
    {
      this.description = task.Complaint_dh__c;
      this.correction = task.Correction_dh__c;
      this.partLines = new List<PartLine>();
      this.labourLines = new List<PartLine>();
      this.freightLines = new List<PartLine>();
      this.subletLines = new List<PartLine>();
      this.grandTotal = 0;
      this.partsTotal = 0;
      this.labourTotal = 0;
      this.freightTotal = 0;
      this.subletTotal = 0;
      buildLines( task.AcctSeedERP__Materials__r );
    }

    private void buildLines( AcctSeedERP__Material__c[] materials )
    {
      for( AcctSeedERP__Material__c mat : materials )
      {
        System.debug('MAT');
        System.debug(mat);
        this.grandTotal += mat.Supplier_Credit_Requested__c ? mat.GMBLASERP__Total_Price__c : 0;
        if( mat.AcctSeedERP__Product__c == Utility_Products__c.getOrgDefaults().Sublet__c )
        {
          this.subletLines.add( new PartLine( mat ) );
          this.subletTotal += mat.Supplier_Credit_Requested__c ? mat.GMBLASERP__Total_Price__c : 0;
        }
        else if( ( mat.Product_Record_Type__c == 'Fees' && mat.AcctSeedERP__Product__r.Family == 'Freight' ) ||
          ( mat.Product_Record_Type__c == 'Part' && mat.AcctSeedERP__Product__r.Family == 'Freight' ) )
        {
          this.freightLines.add( new PartLine( mat ) );
          this.freightTotal += mat.Supplier_Credit_Requested__c ? mat.GMBLASERP__Total_Price__c : 0;
        }
        else if( mat.Product_Record_Type__c == 'Labour' ||
          ( mat.Product_Record_Type__c == 'Part' && mat.AcctSeedERP__Product__r.Family == 'Labour' ) )
        {
          this.labourLines.add( new PartLine( mat ) );
          this.labourTotal += mat.Supplier_Credit_Requested__c ? mat.GMBLASERP__Total_Price__c : 0;
        }
        else
        {
          this.partLines.add( new PartLine( mat ) );
          this.partsTotal += mat.Supplier_Credit_Requested__c ? mat.GMBLASERP__Total_Price__c : 0;
        }
      }
    }
  }

  global class warrantyRecoverable {
    public String claimNumber { get; set; }
    public String serialNumber { get; set; }
    public String supplierClaimNumber { get; set; }
    public String modelName { get; set; }
    public String customerName { get; set; }
    public String customerCity { get; set; }
    public String customerStreet { get; set; }
    public String customerState { get; set; }
    public String customerCountry { get; set; }
    public String customerPostalCode { get; set; }
    public String customerPhone { get; set; }
    public String customerEmail { get; set; }
    public DateTime purchaseDate { get; set; }
    public DateTime failureDate { get; set; }
    public Decimal total { get; set; }
    public Decimal partsTotal { get; set; }
    public Decimal labourTotal { get; set; }
    public Decimal freightTotal { get; set; }
    public Decimal subletTotal { get; set; }
    public List<Map<String, String>> imageURLS { get; set; }
    public List<ClaimDetail> claimDetails { get; set; }

    public warrantyRecoverable( Id erpId )
    {
      this.total = 0;
      this.partsTotal = 0;
      this.labourTotal = 0;
      this.freightTotal = 0;
      this.subletTotal = 0;
      Case c = fetchCase( erpId );
      buildClaimDetails( erpId );
      this.claimNumber = c.CaseNumber;
      this.serialNumber = c.Serial_Number__r.Name;
      this.modelName = c.Serial_Number__r.Product_Name__c;
      this.failureDate = c.CreatedDate;
      this.supplierClaimNumber = findSupplierClaimNumber( erpId );
      //findMaterialLines( erpId, task.Id );
      if( c.Serial_Number__c != null )
        findCustomerDetails( c.Serial_Number__c );
      this.imageURLS = new List<Map<String,String>>();
      findImages( c.Id );
    }

    private String findSupplierClaimNumber( Id erpId )
    {
      try
      {
        return [SELECT Id, Supplier_Claim_Number__c FROM AcctSeed__Project__c WHERE Id = :erpId].Supplier_Claim_Number__c;
      }
      catch( Exception e )
      {
        return '';
      }
    }

    private void buildClaimDetails( Id erpId )
    {
      System.debug( 'IN BUILDCLAIMDETAILS' );
      claimDetails = new List<ClaimDetail>();
      for( AcctSeed__Project_Task__c task : findProjectTasks( erpId ) )
      {
        System.debug( task );
        ClaimDetail cd = new ClaimDetail( task );
        System.debug( 'CLAIM DETAIL  ' + cd);
        total += cd.grandTotal;
        partsTotal += cd.partsTotal;
        labourTotal += cd.labourTotal;
        freightTotal += cd.freightTotal;
        subletTotal += cd.subLetTotal;
        claimDetails.add( cd );
      }
    }

    private AcctSeed__Project_Task__c[] findProjectTasks( Id erpId )
    {
      return [ SELECT Id, Complaint_dh__c, Correction_dh__c,
               ( SELECT Id,
                        Product_Name__c,
                        Supplier_Credit_Requested__c,
                        AcctSeedERP__Product__c,
                        AcctSeedERP__Product__r.Family,
                        AcctSeedERP__Product__r.ProductCode,
                        AcctSeedERP__Quantity_Per_Unit__c,
                        GMBLASERP__Total_Price__c,
                        GMBLASERP__Unit_Price__c,
                        Product_Record_Type__c,
                        AcctSeedERP__Comment__c
                 FROM AcctSeedERP__Materials__r)
               FROM AcctSeed__Project_Task__c
               WHERE AcctSeed__Project__c = :erpId
               AND Name LIKE '%Warranty Recoverable%' ];
    }

    private Case fetchCase( Id erpId )
    {
      try {
        return [SELECT Id,
                       CaseNumber,
                       CreatedDate,
                       Correction__c,
                       Date_Failure__c,
                       Description,
                       Shipping_Company__c,
                       Shipping_Company_Other__c,
                       Sublet_Company__c,
                       Sublet_Price__c,
                       Shipping_Cost__c,
                       Serial_Number__c,
                       Serial_Number__r.Name,
                       Serial_Number__r.Product_Name__c
                FROM Case
                WHERE Recoverable_ERP__c = :erpId];
      }
      catch( Exception e )
      {
        return new Case();
      }
    }

    private void findCustomerDetails( Id serialId )
    {
      try {
        Registration__c reg = [SELECT Id,
                                      Account__r.Name,
                                      Account__r.BillingCity,
                                      Account__r.BillingStreet,
                                      Account__r.BillingState,
                                      Account__r.BillingCountry,
                                      Account__r.BillingPostalCode,
                                      Account__r.Phone,
                                      Account__r.PersonMobilePhone,
                                      Account__r.PersonEmail,
                                      Registered_Date__c,
                                      CreatedDate
                               FROM Registration__c
                               WHERE SerialNumber__c = : serialId
                               AND isCurrent__c = true
                               LIMIT 1];
        this.customerName = reg.Account__r.Name;
        this.customerCity = reg.Account__r.BillingCity;
        this.customerStreet = reg.Account__r.BillingStreet;
        this.customerState = reg.Account__r.BillingState;
        this.customerCountry = reg.Account__r.BillingCountry;
        this.customerPostalCode = reg.Account__r.BillingPostalCode;
        this.customerPhone = reg.Account__r.Phone != null ? reg.Account__r.Phone :
          reg.Account__r.PersonMobilePhone != null ? reg.Account__r.PersonMobilePhone : '';
        this.customerEmail = reg.Account__r.PersonEmail;
        this.purchaseDate = reg.Registered_Date__c == null ? reg.CreatedDate : reg.Registered_Date__c;
      }
      catch( Exception e ){}
    }

    private void findImages( String caseId )
    {
      Set<Id> imageIds = new Set<Id>();
      List<Legend_Gallery_Image_Map__c> maps = [SELECT Id, Legend_Gallery_Image__c
                                               FROM Legend_Gallery_Image_Map__c
                                               WHERE Parent_Object_id__c = :caseId
                                               AND Legend_Gallery_Image__c <> null
                                               ORDER BY CreatedDate ASC];
      for(Legend_Gallery_Image_Map__c m : maps)
      {
        imageIds.add(m.Legend_Gallery_Image__c);
      }
      for( Legend_Gallery_Image__c img : [SELECT Id, Name, Active_S3_object__r.URL_Original__c
                                          FROM Legend_Gallery_Image__c
                                          WHERE Id IN :imageIds] )
      {
        Map<String, String> i = new Map<String, String>();
        i.put('Name', img.Name );
        i.put('URL', img.Active_S3_object__r.URL_Original__c );
        this.imageURLS.add( i );
      }
    }

  }

  global class PartLine {
    global String productName { get; set; }
    global String comment { get; set; }
    global String productCode { get; set; }
    global Decimal quantity { get; set; }
    global Decimal unitCost { get; set; }
    global Decimal total { get; set; }

    global PartLine( AcctSeedERP__Material__c mat )
    {
      this.productName = mat.Product_Name__c;
      this.productCode = mat.AcctSeedERP__Product__r.ProductCode;
      this.quantity = mat.AcctSeedERP__Quantity_Per_Unit__c;
      this.unitCost = mat.Supplier_Credit_Requested__c ? mat.GMBLASERP__Unit_Price__c : 0;
      this.total = mat.Supplier_Credit_Requested__c ? mat.GMBLASERP__Total_Price__c : 0;
      this.comment = mat.AcctSeedERP__Comment__c;
    }
  }

  /* a simple wrapper to hold a item that will be shipped to a dealer
     we try to create Boat with the nested items
     but if it is a single loose item that is not a boat
     it is set alone
  */
  global class PartnerDeliveryItem {
    public String productName {get; set;}
    public List<String> nestedItems {get; set;}

    public PartnerDeliveryItem( TripBuilderController.ErpWrapper erpWrapper )
    {
      this.nestedItems = new List<String>();
      if( erpWrapper.MaterialWrappers.size() == 1 )
      {
        this.productName = erpWrapper.MaterialWrappers[0].Name;
      }
      else
      {
        for( TripBuilderController.MaterialWrapper mw : erpWrapper.MaterialWrappers )
        {
          if( mw.RecordType == 'Boat' )
            this.productName = mw.Name;
          else
            this.nestedItems.add( mw.Name );
        }
      }
    }
  }

  global String recordId { get; set; }
  global String acctId { get; set; }
  global Account acct;
  global Truck_Destination__c destination;

	global EmailComponentController() {}

  global class MotorRequestWrapper {
    public String requestNumber { get; set; }
    public String motorModel { get; set; }
    public String motorProductCode { get; set; }
    public String boatERPSerialNum { get; set; }
    public Decimal quantity { get; set; }

    global MotorRequestWrapper(){}

    global MotorRequestWrapper( Dealer_Order_Line__c dol )
    {
      this.requestNumber =  dol.Motor_Request_Number__c;
      this.motorModel =  dol.Dealer_Motor_Request__r.Motor__r.Name;
      this.motorProductCode =  dol.Dealer_Motor_Request__r.Motor__r.ProductCode ;
      this.boatERPSerialNum = dol.Boat_Serial_Number__r.Name;
      this.quantity = dol.ERP_Order__c == null ? dol.Dealer_Motor_Request__r.Quantity__c : 1;
    }
  }

  global List<MotorRequestWrapper> getDealerMotorRequests()
  {
    List<MotorRequestWrapper> result = new List<MotorRequestWrapper>();
    try {
      Dealer_Order__c order = [ SELECT Id, Account__c, Account__r.Name
                                FROM Dealer_Order__c
                                WHERE Id = :recordId];
      Set<Id> dealerMotorRequestIds = new Set<Id>();
      for( Dealer_Order_Line__c dol : [ SELECT Id,
                                               Motor_Request_Number__c,
                                               ERP_Order__c,
                                               Boat_Serial_Number__r.Name,
                                               Dealer_Motor_Request__c,
                                               Dealer_Motor_Request__r.Quantity__c,
                                               Dealer_Motor_Request__r.Motor__r.Name,
                                               Dealer_Motor_Request__r.Motor__r.ProductCode
                                        FROM Dealer_Order_Line__c
                                        WHERE Dealer_Order__c = :order.Id
                                        AND Dealer_Motor_Request__c <> null] )
      {
        //dealerMotorRequestIds.add( dol.Dealer_Motor_Request__c );
        result.add( new MotorRequestWrapper( dol) );
      }
//      if( dealerMotorRequestIds.size() > 0 )
//        result = [SELECT Id, Motor__r.Name, Motor__r.ProductCode, Quantity__c
//                  FROM Dealer_Motor_Request__c
//                  WHERE Id IN :dealerMotorRequestIds ];
    }
    catch(Exception e){}
    return result;
  }

  global MotorRequestWrapper getOrderLineWithSerial()
  {
    try {
      Dealer_Order_Line__c dol = [ SELECT Id,
                                          ERP_Order__c,
                                          Motor_Request_Number__c,
                                          Boat_Serial_Number__r.Name,
                                          Dealer_Motor_Request__c,
                                          Dealer_Motor_Request__r.Motor__r.Name,
                                          Dealer_Motor_Request__r.Motor__r.ProductCode
                                        FROM Dealer_Order_Line__c
                                        WHERE Id = :recordId ];
      MotorRequestWrapper mrw = new MotorRequestWrapper( dol );
      return mrw;
    }
    catch( Exception e )
    {
      return new MotorRequestWrapper();
    }
  }

  global PartnerDeliveryItem[] getDeliveryItems()
  {
    PartnerDeliveryItem[] result = new List<PartnerDeliveryItem>();
    TripBuilderController.DestinationWrapper dw = TripBuilderController.wrapDestinations( new List<Id>{recordId} )[0];
    for( TripBuilderController.ErpWrapper erpW : dw.erpWrappers )
    {
      result.add( new PartnerDeliveryItem( erpW ) );
    }
    return result;
  }

  global String getDomain()
  {
    return URL.getSalesforceBaseUrl().toExternalForm();
  }

  global String getEnglishImage()
  {
    return Legend_Settings__c.getOrgDefaults().Email_Logo_Id_English__c;
  }

  global String getFrenchImage()
  {
    return Legend_Settings__c.getOrgDefaults().Email_Logo_Id_French__c;
  }

  global Boolean getIsFrench()
  {
    if( acct != null )
    {
      return accountLanguage( acct );
    }
    else
    {
      try {
        acct = [SELECT Id, Language__c, BillingState
               FROM Account
               WHERE Id = :acctId ];
        return accountLanguage( acct );
      }
      catch(Exception e)
      {
        return false;
      }
    }
  }

  global String getDeliveryDate()
  {
    try {
      if( destination == null )
      {
        destination = fetchDestination();
      }
      Date dDate = destination.Delivery_Date__c;
      DateTime dt = DateTime.newInstance(dDate.year(), dDate.month(), dDate.day() );
      return dt.format( 'EEE MMM dd, yyyy' );
    }
    catch( Exception e )
    {
      return '';
    }

  }

  public Boolean getIsPickup()
  {
    if( destination == null )
      destination = fetchDestination();
    return destination.Trip__r.Truck_Driver__r.Partner_Pickup_Placeholder__c;
  }

  public String getNotes()
  {
    if( destination == null )
    {
      destination = fetchDestination();
    }
    return destination.Notes__c;
  }


  private Truck_Destination__c fetchDestination()
  {
    return [SELECT Id,
                   Delivery_Date__c,
                   Notes__c,
                   Trip__r.Truck_Driver__r.Partner_Pickup_Placeholder__c
            FROM Truck_Destination__c
            WHERE Id = :recordId ];
  }


  private Boolean accountLanguage( Account a )
  {
    if( a.Language__c != null )
      return a.Language__c == 'French';
    if( a.BillingState.toLowerCase() == 'quebec' )
      return true;
    return false;
  }

  global Account getAccountDetails()
  {
    return fetchAccount();
  }

  global warrantyRecoverable getCaseEmailDetails()
  {
    return new warrantyRecoverable( recordId );
  }

  private Account fetchAccount()
  {
    if( acct == null )
    {
      try {
        acct = [SELECT Id,
                       Name,
                       BillingStreet,
                       BillingCity,
                       BillingState,
                       BillingCountry,
                       BillingPostalCode
                FROM Account
                WHERE Id = :acctId ];
      }
      catch(Exception e)
      {
        acct = new Account();
      }
    }
    return acct;
  }

}