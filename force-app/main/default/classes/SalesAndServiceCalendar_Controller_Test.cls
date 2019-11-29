@isTest
private class SalesAndServiceCalendar_Controller_Test {

  static AcctSeedERP__Warehouse__c whitefishWarehouse;
  static AcctSeedERP__Warehouse__c barrieWarehouse;
  static AcctSeedERP__Warehouse__c montrealWarehouse;
  static User whitefishUser;
  static User barrieUser;
  static User montrealUser;
  static Account customer;
  static GMBLASERP__Serial_Number__c[] serials;
  static GMBLASERP__Serial_Number__c[] b_serials;
  static GMBLASERP__Serial_Number__c[] wf_serials;
  static GMBLASERP__Serial_Number__c[] m_serials;
  static GMBLASERP__Serial_Number__c[] unscheduled_serials;

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void setup()
  {
    for( AcctSeedERP__Warehouse__c wh : [ SELECT Id, Name, GL_Account_Variable_3__c FROM AcctSeedERP__Warehouse__c ] )
    {
      if( wh.Name == 'Barrie' )
        barrieWarehouse = wh;
      if( wh.Name == 'Whitefish' )
        whitefishWarehouse = wh;
      if( wh.Name == 'Montreal' )
        montrealWarehouse = wh;
    }
    User[] users = new List<User>();
    barrieUser =  Factory_User.newUser('barrie', 'mcTesterson', 'Legend Standard User - New', barrieWarehouse );
    whitefishUser = Factory_User.newUser('whitefish', 'mcTesterson', 'Legend Standard User - New', whitefishWarehouse );
    montrealUser = Factory_User.newUser('montreal', 'mcTesterson', 'Legend Standard User - New', montrealWarehouse );
    users.add( barrieUser );
    users.add( whitefishUser );
    users.add( montrealUser );
    insert users;
    customer = AccountFactory.insertPersonAccount();
  }

  private static void setupSerials()
  {

    serials = Factory_SerialNumber.insertFullSerials( 12, 'Boat', 'Pontoon');
    b_serials = new List<GMBLASERP__Serial_Number__c> { serials[0], serials[1], serials[2] };
    wf_serials = new List<GMBLASERP__Serial_Number__c> { serials[3], serials[4], serials[5], serials[6] };
    m_serials = new List<GMBLASERP__Serial_Number__c> { serials[7] };
    unscheduled_serials = new List<GMBLASERP__Serial_Number__c> { serials[8], serials[9], serials[10], serials[11] };
  }

  private static AcctSeed__Project__c[] unscheduledERPs()
  {
    return Factory_ERPOrder.insertRetailBoatSales( customer,
                                            barrieWarehouse,
                                            null,
                                            unscheduled_serials );
  }

  private static AcctSeed__Project__c[] barrieERPs(String type)
  {
    AcctSeed__Project__c[] result;
    System.runAs( barrieUser )
    {
      if(type == 'retail')
        result = Factory_ERPOrder.insertRetailBoatSales( customer,
                                                       barrieWarehouse,
                                                       DateTime.now(),
                                                       b_serials );
      else if(type == 'service')
        result = Factory_ERPOrder.insertServiceOrders( customer,
                                                     barrieWarehouse,
                                                     DateTime.now(),
                                                     b_serials );
      else
        result = new List<AcctSeed__Project__c>();
    }
    return result;
  }

  private static Opportunity[] barrieOpportunities()
  {
    Opportunity[] result;
    System.runAs( barrieUser )
    {
      result = Factory_Opportunity.insertBasic( 5,
                                              customer,
                                              'Tagging Pending',
                                              barrieWarehouse,
                                              DateTime.now() );
    }
    return result;
  }

  private static void whitefishERPs()
  {
    System.runAs( whitefishUser )
    {
      Factory_ERPOrder.insertRetailBoatSales( customer,
                                              whitefishWarehouse,
                                              DateTime.now(),
                                              wf_serials );
    }
  }

  private static void montrealERPs()
  {
    System.runAs( montrealUser )
    {
      Factory_ERPOrder.insertRetailBoatSales( customer,
                                              montrealWarehouse,
                                              DateTime.now(),
                                              m_serials );
    }
  }

  /**************************** TESTS **************************/

  @isTest
  static void fetchUserDetailsAndPermissions_Test()
  {
    setup();
    System.runAs( whitefishUser )
    {
      String jsonResult = SalesAndServiceCalendar_Controller.fetchUserDetailsAndPermissions();
      Map<String, String> result = (Map<String, String>)JSON.deserialize( jsonResult, Map<String, String>.class);
      System.assertEquals('Whitefish', result.get('warehouse') );
    }
  }

  @isTest
  static void fetchScheduledRecords_fail_Test()
  {
    DateTime sd = DateTime.now();
    DateTime ed = sd.addHours(2);
    try {
      SalesAndServiceCalendar_Controller.fetchScheduledRecords( String.valueOf( sd.getTime() ),
                                                                String.valueOf( ed.getTime() ),
                                                                'Barrie',
                                                                'testFail');
    }
    catch( Exception err )
    {
      System.assertEquals( 'Unrecoginized Calendar Specified', err.getMessage() );
    }
  }

  @isTest
  static void initDetailsForm_Test()
  {
    String jsonResult = SalesAndServiceCalendar_Controller.initDetailsForm();
    SalesAndServiceCalendar_Controller.RetailDetailsWrapper result =
      (SalesAndServiceCalendar_Controller.RetailDetailsWrapper)JSON.deserialize(jsonResult, SalesAndServiceCalendar_Controller.RetailDetailsWrapper.class);
    System.assert( result.pickupLocations.size() > 0 );
  }

  @isTest
  static void fetchScheduledRecords_Retail_Whitefish_Test()
  {
    setup();
    setupSerials();
    whitefishERPs();
    System.runAs( whitefishUser )
    {
      Test.startTest();
      DateTime s = DateTime.now().addDays( -3 );
      DateTime e = s.addDays( 7 );
      System.debug( 'Start.getTime() ' + String.valueOf( s.getTime() ) );
      System.debug( 'Start.formatLong() ' + s.formatLong() );
      String jsonResult = SalesAndServiceCalendar_Controller.fetchScheduledRecords(
        String.valueOf( s.getTime() ),
        String.valueOf( e.getTime() ),
        'Whitefish',
        'Retail'
      );
      List<SalesAndServiceCalendar_Controller.EventData> result =
        (List<SalesAndServiceCalendar_Controller.EventData>)JSON.deserialize( jsonResult,
                                                                              List<SalesAndServiceCalendar_Controller.EventData>.class);
      Test.stopTest();
      System.assertEquals( 4, result.size() );
    }
  }

   @isTest
  static void fetchScheduledRecords_Retail_Montreal_Test()
  {
    setup();
    setupSerials();
    montrealERPs();
    System.runAs( montrealUser )
    {
      Test.startTest();
      DateTime s = DateTime.now().addDays( -3 );
      DateTime e = s.addDays( 7 );
      System.debug( 'Start.getTime() ' + String.valueOf( s.getTime() ) );
      System.debug( 'Start.formatLong() ' + s.formatLong() );
      String jsonResult = SalesAndServiceCalendar_Controller.fetchScheduledRecords(
        String.valueOf( s.getTime() ),
        String.valueOf( e.getTime() ),
        'Montreal',
        'Retail'
      );
      List<SalesAndServiceCalendar_Controller.EventData> result =
        (List<SalesAndServiceCalendar_Controller.EventData>)JSON.deserialize( jsonResult,
                                                                              List<SalesAndServiceCalendar_Controller.EventData>.class);
      Test.stopTest();
      System.assertEquals( 1, result.size() );
    }
  }

  @isTest
  static void fetchScheduledRecords_Retail_Barrie_Test()
  {
    setup();
    setupSerials();
    whitefishERPs();
    AcctSeed__Project__c[] erps = barrieERPs('retail');
    Opportunity[] opps = barrieOpportunities();
    Integer recCount = erps.size() + opps.size();
    System.runAs( barrieUser )
    {
      Test.startTest();
      DateTime s = DateTime.now().addDays( -3 );
      DateTime e = s.addDays( 7 );
      System.debug( 'Start.getTime() ' + String.valueOf( s.getTime() ) );
      System.debug( 'Start.formatLong() ' + s.formatLong() );
      String jsonResult = SalesAndServiceCalendar_Controller.fetchScheduledRecords(
        String.valueOf( s.getTime() ),
        String.valueOf( e.getTime() ),
        'Barrie',
        'Retail'
      );
      List<SalesAndServiceCalendar_Controller.EventData> result =
        (List<SalesAndServiceCalendar_Controller.EventData>)JSON.deserialize( jsonResult,
                                                                              List<SalesAndServiceCalendar_Controller.EventData>.class);
      Test.stopTest();
      System.assertEquals( recCount, result.size() );
    }
  }

  @isTest
  static void fetchScheduledRecords_Service_Barrie_Test()
  {
    setup();
    setupSerials();
    AcctSeed__Project__c[] erps = barrieERPs('service');
    System.debug('*********************** SERVICE ERPS *********************');
    System.debug( erps );
    System.runAs( barrieUser )
    {
      Test.startTest();
      DateTime s = DateTime.now().addDays( -3 );
      DateTime e = s.addDays( 7 );
      System.debug( 'Start.getTime() ' + String.valueOf( s.getTime() ) );
      System.debug( 'Start.formatLong() ' + s.formatLong() );
      String jsonResult = SalesAndServiceCalendar_Controller.fetchScheduledRecords(
        String.valueOf( s.getTime() ),
        String.valueOf( e.getTime() ),
        'Barrie',
        'Service'
      );
      List<SalesAndServiceCalendar_Controller.EventData> result =
        (List<SalesAndServiceCalendar_Controller.EventData>)JSON.deserialize( jsonResult,
                                                                              List<SalesAndServiceCalendar_Controller.EventData>.class);
      Test.stopTest();
      System.assertEquals( erps.size(), result.size() );
    }
  }

  @isTest
  static void fetchRecord_Retail_ERP_Test()
  {
    setup();
    setupSerials();
    AcctSeed__Project__c[] erps = barrieERPs('retail');
    System.runAs( barrieUser )
    {
      Test.startTest();
      String jsonResult = SalesAndServiceCalendar_Controller.fetchRecord( erps[0].Id );
      SalesAndServiceCalendar_Controller.EventData result =
        (SalesAndServiceCalendar_Controller.EventData)JSON.deserialize( jsonResult,
                                                                        SalesAndServiceCalendar_Controller.EventData.class);
      Test.stopTest();
      System.assertEquals( erps[0].Id, result.Id);
    }
  }

  @isTest
  static void fetchRecord_Service_ERP_Test()
  {
    setup();
    setupSerials();
    AcctSeed__Project__c[] erps = barrieERPs('service');
    System.runAs( barrieUser )
    {
      Test.startTest();
      String jsonResult = SalesAndServiceCalendar_Controller.fetchRecord( erps[0].Id );
      SalesAndServiceCalendar_Controller.EventData result =
        (SalesAndServiceCalendar_Controller.EventData)JSON.deserialize( jsonResult,
                                                                        SalesAndServiceCalendar_Controller.EventData.class);
      Test.stopTest();
      System.assertEquals( erps[0].Id, result.Id);
    }
  }

  @isTest
  static void fetchRecord_Retail_OPP_Test()
  {
    setup();
    Opportunity[] opps = barrieOpportunities();
    System.runAs( barrieUser )
    {
      Test.startTest();
      String jsonResult = SalesAndServiceCalendar_Controller.fetchRecord( opps[0].Id );
      SalesAndServiceCalendar_Controller.EventData result =
        (SalesAndServiceCalendar_Controller.EventData)JSON.deserialize( jsonResult,
                                                                        SalesAndServiceCalendar_Controller.EventData.class);
      Test.stopTest();
      System.assertEquals( opps[0].Id, result.Id);
    }
  }

  @isTest
  static void fetchRecord_NULL_Test()
  {
    setup();
    Test.startTest();
    String jsonResult = SalesAndServiceCalendar_Controller.fetchRecord( barrieWarehouse.Id );
    Test.stopTest();
    System.assertEquals( jsonResult, null );
  }

  @isTest
  static void fetchSchedulables_Test()
  {
    setup();
    setupSerials();
    System.runAs( barrieUser )
    {
      AcctSeed__Project__c[] erps = unscheduledERPs();
      Opportunity[] opps = Factory_Opportunity.insertBasic( 5,
                                                            customer,
                                                            'Tagging Pending',
                                                            barrieWarehouse,
                                                            null );
      Integer recCount = erps.size() + opps.size();
      Test.startTest();
      String jsonResult = SalesAndServiceCalendar_Controller.fetchSchedulables();
      List<SalesAndServiceCalendar_Controller.EventData> result =
        (List<SalesAndServiceCalendar_Controller.EventData>)JSON.deserialize( jsonResult,
                                                                              List<SalesAndServiceCalendar_Controller.EventData>.class);
      Test.stopTest();
      System.assertEquals( recCount, result.size() );
    }
  }

  @isTest
  static void updateRetailRecord_Test()
  {
    setup();
    setupSerials();
    AcctSeed__Project__c[] erps = barrieERPs('retail');
    System.runAs( barrieUser )
    {
      Test.startTest();
      SalesAndServiceCalendar_Controller.EventData ed = new SalesAndServiceCalendar_Controller.EventData( erps[0] );
      System.assertEquals( ed.onWaterOrientation, false );
      System.assertEquals( erps[0].Delivery_Date__c, ed.startDateTime );
      DateTime newDT = erps[0].Delivery_Date__c.addDays(3);
      ed.onWaterOrientation = true;
      ed.startDateTime = newDT;
      ed.pickupLocation = 'Barrie - Delivery';
      SalesAndServiceCalendar_Controller.updateRetailRecord(
        JSON.serialize( ed )
      );
      AcctSeed__Project__c result = [SELECT Id,
                                            Pickup_Location__c,
                                            Delivery_Date__c,
                                            On_Water_Orientation__c
                                     FROM AcctSeed__Project__c
                                     WHERE Id = :erps[0].Id];
      Test.stopTest();
      System.assertEquals( true, result.On_Water_Orientation__c );
      System.assertEquals( 'Barrie - Delivery', result.Pickup_Location__c );
      System.assertEquals( newDT, result.Delivery_Date__c );
    }
  }

  @isTest
  static void updateServiceRecord_Test()
  {
    setup();
    setupSerials();
    AcctSeed__Project__c[] erps = barrieERPs('service');
    System.runAs( barrieUser )
    {
      Test.startTest();
      AcctSeed__Project__c erp = [SELECT Id,
                                         Name,
                                         RecordTypeId,
                                         AcctSeedERP__Work_Order_Number__c,
                                         AcctSeed__Account__c,
                                         AcctSeed__Account__r.Name,
                                         Service_Date__c,
                                         Estimated_Service_Duration__c,
                                         GMBLASERP__Warehouse__c,
                                         Serial_Number__c,
                                         Serial_Product__c,
                                         WarehouseName__c,
                                         Stage__c,
                                         Job_status__c,
                                         Parking_Spot__c
                                 FROM AcctSeed__Project__c
                                 WHERE Id = :erps[0].Id ];
      SalesAndServiceCalendar_Controller.EventData ed = new SalesAndServiceCalendar_Controller.EventData( erp );
      System.assertEquals( barrieWarehouse.Id, ed.warehouseId );
      System.assertEquals( erp.Service_Date__c, ed.startDateTime );
      DateTime newDT = erp.Service_Date__c.addDays(3);
      ed.warehouseId = whitefishWarehouse.Id;
      ed.startDateTime = newDT;
      SalesAndServiceCalendar_Controller.updateServiceRecord(
        JSON.serialize( ed )
      );
      AcctSeed__Project__c result = [SELECT Id,
                                            GMBLASERP__Warehouse__c,
                                            Service_Date__c
                                     FROM AcctSeed__Project__c
                                     WHERE Id = :erp.Id];
      Test.stopTest();
      System.assertEquals( whitefishWarehouse.Id, result.GMBLASERP__Warehouse__c );
      System.assertEquals( newDT, result.Service_Date__c );
    }
  }

  @isTest
  static void initNewService_Test()
  {
    setup();
    Factory_CustomSettings.erpOrderTaskNames(5);
    System.runAs( barrieUser )
    {

      String jsonResult = SalesAndServiceCalendar_Controller.initNewService();
      System.debug( jsonResult );
      SalesAndServiceCalendar_Controller.ServiceInitWrapper result =
        (SalesAndServiceCalendar_Controller.ServiceInitWrapper)JSON.deserialize( jsonResult,
                                                                                 SalesAndServiceCalendar_Controller.ServiceInitWrapper.class );

      System.assertEquals( 5, result.taskNames.size() );
      System.assertEquals( barrieWarehouse.Id, result.userWarehouse );
      System.assertEquals( 3, result.warehouses.size() );
    }

  }

  @isTest
  static void fetchSerialNumbersByAccount()
  {
    setup();
    setupSerials();
    AcctSeed__Project__c[] erps = barrieERPs('retail');
    System.runAs( barrieUser )
    {
      String jsonResult = SalesAndServiceCalendar_Controller.fetchSerialNumbersByAccount( customer.Id );
      List<Map<String,String>> result =
        (List<Map<String, String>>)JSON.deserialize( jsonResult, List<Map<String, String>>.class );
      System.assertEquals( erps.size(), result.size() );
    }
  }

  @isTest
  static void fetchSerialDetails_Test()
  {
    setup();
    setupSerials();
    GMBLASERP__Serial_Number__c sn = SalesAndServiceCalendar_Controller.fetchSerialDetails( b_serials[0].Id );
    System.assertEquals( b_serials[0].Id, sn.Id );
  }

  @isTest
  static void createServiceERP_Test()
  {
    setup();
    setupSerials();
    Factory_CustomSettings.erpOrderTaskNames(5);
    System.runAs( barrieUser )
    {
      DateTime sDate = DateTime.newInstance( 2018, 07, 07, 10, 00, 00);
      AcctSeed__Project__c erp = new AcctSeed__Project__c(
        AcctSeed__Account__c = customer.Id,
        Serial_Number__c = b_serials[0].Id,
        GMBLASERP__Warehouse__c = barrieWarehouse.Id,
        Customer_Notes__c = 'Test Customer Notes',
        Service_Date__c = sDate
      );
      AcctSeed__Project_Task__c[] tasks = new List<AcctSeed__Project_Task__c>();
      Integer count = 1;
      for( ERPOrderTaskNames__c tn : ERPOrderTaskNames__c.getAll().values() )
      {
        tasks.add( new AcctSeed__Project_Task__c(
          Name = tn.Name,
          Complaint_dh__c = 'Test Complaint ' + String.valueOf(count),
          Estimated_Duration__c = 1
        ));
      }
      Test.startTest();
      SalesAndServiceCalendar_Controller.createServiceERP( erp, tasks, null, null );
      AcctSeed__Project__c[] erps = [SELECT Id, Serial_Number__c, RecordTypeId,
                                     (SELECT Id FROM AcctSeed__Project_Tasks__r)
                                     FROM AcctSeed__Project__c
                                     WHERE AcctSeed__Account__c = :customer.Id];
      Test.stopTest();
      System.assertEquals( 1, erps.size() );
      System.assertEquals( 5, erps[0].AcctSeed__Project_Tasks__r.size() );
    }
  }

  @isTest
  static void fetchOrderTasks_Test()
  {
    setup();
    setupSerials();
    AcctSeed__Project__c[] erps = barrieERPs('service');
    Factory_CustomSettings.erpOrderTaskNames(5);
    System.runAs( barrieUser )
    {
      AcctSeed__Project_Task__c[] tasks = new List<AcctSeed__Project_Task__c>();
      Integer count = 1;
      for( ERPOrderTaskNames__c tn : ERPOrderTaskNames__c.getAll().values() )
      {
        tasks.add( new AcctSeed__Project_Task__c(
          Name = tn.Name,
          Complaint_dh__c = 'Test Complaint ' + String.valueOf(count),
          Estimated_Duration__c = 1,
          AcctSeed__Project__c = erps[0].Id
        ));
      }
      insert tasks;
      Test.startTest();
      AcctSeed__Project_Task__c[] result1 = SalesAndServiceCalendar_Controller.fetchOrderTasks( erps[0].Id );
      AcctSeed__Project_Task__c[] result2 = SalesAndServiceCalendar_Controller.fetchOrderTasks( erps[1].Id );
      Test.stopTest();
      System.assertEquals( tasks.size(), result1.size() );
      System.assertEquals( 0, result2.size() );
    }

  }

  @isTest
  static void getRiggers_Test() {
    setup();
    String riggers = SalesAndServiceCalendar_Controller.getRiggers(whitefishWarehouse.Id);
    System.assert(riggers.length() > 0);
  }

}