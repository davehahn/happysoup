@isTest
private class EmailComponentController_Test {

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  static Account acct;
  static Truck_Driver__c driver;
  static Truck_Destination__c destination;
  static AcctSeed__Project__c[] erps;

  static {
    acct = AccountFactory.buildDealerAccount('Test Dealer');
    acct.BillingStreet = '666 Test Drive';
    acct.BillingState = 'Ontario';
    acct.BillingCity = 'Lovely Place';
    acct.BillingCountry = 'Canada';
    acct.BillingPostalCode = 'A1B2C3';
    insert acct;
  }

  private static void initTruckTrip( String destinationType,
                                     String notes)
  {
    driver = new Truck_Driver__c( Name='Bob' );
    insert driver;
    Truck_Trip__c trip = new Truck_Trip__c(
      Truck_Driver__c = driver.Id,
      Name = 'Test Trip'
    );
    insert trip;
    destination = new Truck_Destination__c(
      Account__c = acct.Id,
      Delivery_Date__c = Date.today(),
      Trip__c = trip.Id,
      Type__c = destinationType
    );
    if( notes != null )
      destination.Notes__c = notes;
    insert destination;
  }

  private static void initERPs()
  {
    Product2[] prods = new List<Product2>();
    prods.add( Factory_Product.createSerializedProduct('Boat', 'Pontoon') );
    prods.add( Factory_Product.createSerializedProduct('Trailer','' ) );

    erps = Factory_ERPOrder.createPartnerBoatSales( acct,
                                                     prods,
                                                     new List<String>{'Pending Review', 'Pending Review', 'Pending Review'} );
    initTruckTrip('Delivery', null);
    Truck_Delivery_Item__c[] items = new List<Truck_Delivery_Item__c>();
    for( AcctSeed__Project__c erp : erps )
    {
      items.add( new Truck_Delivery_Item__c(
        Destination__c = destination.Id,
        ERP_Order__c = erp.Id
      ));
    }
    insert items;
  }

  @isTest
  static void getIsPickup_Test()
  {
    initTruckTrip('Delivery', null);
    driver.Partner_Pickup_Placeholder__c = true;
    update driver;
    EmailComponentController ecc = new EmailComponentController();
    ecc.recordId = destination.Id;
    System.assertEquals( true, ecc.getIsPickup() );
  }

  @isTest
  static void getNotes_Test()
  {
    String notes = 'These are the Notes';
    initTruckTrip( 'Pickup', notes );
    EmailComponentController ecc = new EmailComponentController();
    ecc.recordId = destination.Id;
    System.assertEquals( notes, ecc.getNotes() );
  }

  @isTest
  static void getDeliveryDate_Test()
  {
    initTruckTrip('Delivery', null);
    Date tday = Date.today();
    DateTime dt = DateTime.newInstance(tday.year(), tday.month(), tday.day() );
    String expected = dt.format( 'EEE MMM dd, yyyy' );
    EmailComponentController ecc = new EmailComponentController();
    ecc.recordId = destination.Id;
    System.assertEquals( expected, ecc.getDeliveryDate() );
  }

  @isTest
  static void getDeliveryItems_Test()
  {
    initERPs();
    EmailComponentController ecc = new EmailComponentController();
    ecc.recordId = destination.Id;
    EmailComponentController.PartnerDeliveryItem[] items =
      ecc.getDeliveryItems();

    System.assertEquals( erps.size(), items.size() );
  }

	@isTest static void getAccountDetails_Test() {
		Test.startTest();
    EmailComponentController ecc = new EmailComponentController();
    ecc.acctId = acct.Id;
    Account acct2 = ecc.getAccountDetails();
    Test.stopTest();

    System.assertEquals(acct.Name, acct2.Name);
    System.assertEquals(acct.BillingCity, acct2.BillingCity);
    System.assertEquals(acct.BillingStreet, acct2.BillingStreet);

	}

  @isTest
  static void getDomain_Test()
  {
    EmailComponentController ecc = new EmailComponentController();
    String actual = URL.getSalesforceBaseUrl().toExternalForm();
    System.assertEquals( actual, ecc.getDomain() );
  }

  @isTest
  static void getImages_Test()
  {
    EmailComponentController ecc = new EmailComponentController();
    //Set in Factory CustomSettings
    System.assertEquals( 'theEnglishId', ecc.getEnglishImage() );
    System.assertEquals( 'theFrenchId', ecc.getFrenchImage() );
  }

  @isTest
  static void getIsFrench_Ontario_Test()
  {
    EmailComponentController ecc = new EmailComponentController();
    ecc.acctId = acct.Id;
    System.assertEquals( false, ecc.getIsFrench() );
  }

  @isTest
  static void getIsFrench_Quebec_Test()
  {
    acct.BillingState = 'Quebec';
    acct.Language__c = null;
    update acct;
    EmailComponentController ecc = new EmailComponentController();
    ecc.acctId = acct.Id;
    System.assertEquals( true, ecc.getIsFrench() );
  }

  @isTest
  static void getIsFrench_French_Test()
  {
    acct.Language__c = 'French';
    update acct;
    EmailComponentController ecc = new EmailComponentController();
    ecc.acctId = acct.Id;
    System.assertEquals( true, ecc.getIsFrench() );
  }

  @isTest static void getAccountDetails_Fail_Test() {
    EmailComponentController ecc = new EmailComponentController();
    ecc.acctId = '1234567890123456';
    Account acct = ecc.getAccountDetails();

    System.assert(acct.Id == null);
  }

  @isTest static void getDealerMotorRequests_Test()
  {
    Test.startTest();
    gcProduct.disableTrigger = true;
    Dealer_Order__c dOrder = new Dealer_Order__c(
      Account__c = acct.Id,
      Model_Year__c = String.valueOf( Date.today().year() )
    );
    insert dOrder;
    InventoryTestFactory factory = new InventoryTestFactory();
    Product2 motor = factory.buildTestProducts(1, 'Motor')[0];
    motor.AcctSeedERP__Serialized__c = true;
    insert motor;
    Dealer_Motor_Request__c dmr = new Dealer_Motor_Request__c(
      Motor__c = motor.Id,
      Quantity__c = 3
    );
    insert dmr;
    List<Dealer_Order_Line__c> dols = new List<Dealer_Order_Line__c>();
    for( Integer i=0; i<3; i++ )
    {
      dols.add( new Dealer_Order_Line__c(
        Dealer_Motor_Request__c = dmr.Id,
        Dealer_Order__c = dOrder.Id,
        Product__c = motor.Id,
        Order_Group_Id__c = LGND_Utilities.generateRandomString( 16 )
      ));
    }
    insert dols;
    Test.stopTest();

    EmailComponentController ecc = new EmailComponentController();
    ecc.recordId = dOrder.Id;
    EmailComponentController.MotorRequestWrapper[] reqs = ecc.getDealerMotorRequests();

    System.assert( reqs.size() == 3 );
    System.assertEquals( motor.Name, reqs[0].motorModel);
  }

  @isTest static void getDealerMotorRequests_Fail_Test()
  {
    EmailComponentController ecc = new EmailComponentController();
    ecc.recordId = '1234567';
    EmailComponentController.MotorRequestWrapper[] reqs = ecc.getDealerMotorRequests();

    System.assert( reqs.size() == 0 );
  }

  @isTest
  static void getCaseEmailDetails_Test() {
    gcMaterial.disableTrigger = true;
    Account toAcct = AccountFactory.buildDealerAccount('Test Dealer');
    Account byAcct = AccountFactory.buildDealerAccount('Test Factory');
    Account supplier = AccountFactory.buildSupplierAccount('Test Supplier');
    toAcct.BillingCity = 'Wallaceburg';
    toAcct.BillingStreet = '139 Fittons Rd West';
    toAcct.BillingState = 'Ontario';
    toAcct.BillingCountry = 'Canada';
    toAcct.BillingPostalCode = 'L3V3V3';
    List<Account> accts = new List<Account>{ toAcct, byAcct, supplier };
    insert accts;
    Case c = Factory_Case.createWarrantyCaseWithErp( toAcct );

    TriggerHandler.bypass('Registration_TriggerHandler');
    Registration__c reg = new Registration__c(
      Registered_Date__c = Date.today(),
      SerialNumber__c = c.Serial_Number__c,
      RegisteredByAccount__c = byAcct.Id,
      Account__c = toAcct.Id,
      isCurrent__c = true
    );
    insert reg;
    TriggerHandler.clearBypass('Registration_TriggerHandler');

    String projectName = 'Recoverable-' + supplier.Name.trim();
    AcctSeed__Project__c recoverable = new AcctSeed__Project__c (
      Name = projectName,
      RecordTypeId = gcConstants.idRtProjectWarranty,
      AcctSeed__Account__c = supplier.Id,
      Serial_Number__c = c.Serial_Number__c,
      Warranty_Case__c = c.Id,
      Customer_Notes__c = ''
    );
    Boolean orig = gcProject.disableTrigger;
    gcProject.disableTrigger = true;
    insert recoverable;
    gcProject.disableTrigger = orig;

    AcctSeed__Project_Task__c task = new AcctSeed__Project_Task__c(
      Name = 'Warranty Recoverable Task',
      AcctSeed__Project__c = recoverable.Id
    );
    orig = gcProjectTask.disableTrigger;
    gcProjectTask.disableTrigger = true;
    insert task;
    gcProjectTask.disableTrigger = orig;

    List<AcctSeedERP__Material__c> mats = new List<AcctSeedERP__Material__c>();
    for( Product2 p : Factory_Product.createNonSerializedProducts( 'Part', 'Electronics', 3 ) )
    {
      AcctSeedERP__Material__c mat = Factory_ERPOrder.buildMaterial( recoverable.Id, task.Id, p.Id );
      mat.GMBLASERP__Price_Override__c = true;
      mat.Supplier_Credit_Requested__c = true;
      mats.add( mat );
    }
    orig = gcMaterial.disableTrigger;
    gcMaterial.disableTrigger = true;
    insert mats;
    gcMaterial.disableTrigger = orig;

    c.Recoverable_ERP__c = recoverable.Id;
    update c;

    c = [SELECT Id, CaseNumber, Recoverable_ERP__c FROM Case WHERE Id = : c.Id];
    Test.startTest();
    EmailComponentController ecc = new EmailComponentController();
    ecc.recordId = recoverable.Id;
    EmailComponentController.warrantyRecoverable wr = ecc.getCaseEmailDetails();
    Test.stopTest();

    System.assertEquals( toAcct.BillingCity, wr.customerCity );
    System.assertEquals( c.CaseNumber, wr.claimNumber );
    System.assertEquals( 30, wr.total );
  }

}