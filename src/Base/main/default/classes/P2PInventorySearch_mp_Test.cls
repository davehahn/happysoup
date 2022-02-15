@isTest
private class P2PInventorySearch_mp_Test {

  private static Account[] dealers;
  private static Product2 boat;
  private static Product2 boat2;


	@testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void init()
  {
    dealers = Factory_Account.insertDealerAccounts(5);
    boat = Factory_Product.createSerializedProduct('Boat', 'Pontoon');
    boat2 = Factory_Product.createSerializedProduct('Boat', 'Utility');
  }

  /*
    This ends up creating
    - 4 serial numbers for boat
    - 4 serial numbers for boat2
    - one registration for each boat to dealers[1,2,3,4] by dealer[0]
      ie reg0 to=dealer[1], by=dealer[0] boatSerial[0]
         reg1 to=dealer[2], by=dealer[0] boatSerial[1]
          .
          .
         reg7 to=dealer[5], by=dealer[0] boat2Serial[3]
       for 8 TOTAL registration, 4 per Boat Type
  */

  private static void initRegistrations()
  {
    Date today = Date.today();
    GMBLASERP__Lot__c lot = new GMBLASERP__Lot__c(
      GMBLASERP__Product__c = boat.Id,
      Name = String.valueOf( today.year() ),
      GMBLASERP__Uniquefier__c = boat.Id + '-' + String.valueOf(today.year())
    );
    GMBLASERP__Lot__c lot2 = new GMBLASERP__Lot__c(
      GMBLASERP__Product__c = boat2.Id,
      Name = String.valueOf( today.year() ),
      GMBLASERP__Uniquefier__c = boat2.Id + '-' + String.valueOf(today.year())
    );
    insert lot;
    insert lot2;
    Integer count=0;
    GMBLASERP__Serial_Number__c[] serials = new List<GMBLASERP__Serial_Number__c>();
    GMBLASERP__Serial_Number__c[] serials2 = new List<GMBLASERP__Serial_Number__c>();
    while(count < 4 )
    {
      String serNo = '1000' + String.valueOf(count);
      String serNo2 = '2000' + String.valueOf(count);
      serials.add( Factory_SerialNumber.buildSerial( boat.Id, lot.Id, serNo ) );
      serials2.add( Factory_SerialNumber.buildSerial( boat2.Id, lot2.Id, serNo2 ) );
      count++;
    }
    insert serials;
    insert serials2;
    //GMBLASERP__Serial_Number__c[] serials = Factory_SerialNumber.insertFullSerials( 4, 'Boat', 'Pontoon' );
    Registration__c[] regs = new List<Registration__c>();
    for( Integer i=0; i<serials.size(); i++ )
    {
      regs.add( new Registration__c(
        RegisteredByAccount__c = dealers[0].Id,
        Account__c = dealers[i+1].Id,
        SerialNumber__c = serials[i].Id,
        Delivery_Date__c = DateTime.now()
      ));
    }
    for( Integer i=0; i<serials2.size(); i++ )
    {
      regs.add( new Registration__c(
        RegisteredByAccount__c = dealers[0].Id,
        Account__c = dealers[i+1].Id,
        SerialNumber__c = serials2[i].Id,
        Delivery_Date__c = DateTime.now()
      ));
    }
    insert regs;
  }

  /*
    This ends up creating
    - 1 Dealer Order for dealers[1]
      with 2 Dealer Order Lines, 1 for boat, 1 for boat2
      as well as the ERPs

  */
  private static void initDealerOrders()
  {
    List<String> erpStages = new List<String>{'Tagging Pending'};
    Dealer_Order__c order = Factory_DealerOrder.createDealerOrder( dealers[1] );
    AcctSeed__Project__c erp1 = Factory_ERPOrder.createPartnerBoatSales(
      dealers[1],
      new List<Product2>{boat},
      erpStages
    )[0];
    AcctSeed__Project__c erp2 = Factory_ERPOrder.createPartnerBoatSales(
      dealers[1],
      new List<Product2>{boat2},
      erpStages
    )[0];
    List<Dealer_Order_Line__c> dols = new List<Dealer_Order_Line__c>();
    dols.add(
      Factory_DealerOrder.buildDealerOrderLine(
        erp1,
        order,
        boat
      )
    );
    dols.add(
      Factory_DealerOrder.buildDealerOrderLine(
        erp2,
        order,
        boat2
      )
    );
    MetadataTriggerHandler.bypass('TA_DealerOrderLine_HandlePartnerPro');
    insert dols;
    MetadataTriggerHandler.clearBypass('TA_DealerOrderLine_HandlePartnerPro');
  }

  @isTest
  static void searchPartnerInventories_onlyInStock_Test()
  {
    init();
    initRegistrations();
    String jsonResult = P2PInventorySearch_mp.searchPartnerInventories( true );
    P2PInventorySearch_mp.ResultWrapper result =
      (P2PInventorySearch_mp.ResultWrapper)JSON.deserialize(
        jsonResult,
        P2PInventorySearch_mp.ResultWrapper.class
      );
    System.assertEquals( 2, result.boatSelectOptions.size() );
    System.assertEquals( 2, result.inventory.keySet().size() );
    P2PInventorySearch_mp.AccountWrapper aWrapper =
      result.inventory.get(boat.Name)[0];
    System.assertEquals( 4, result.inventory.get(boat.Name).size() );
    System.assert( aWrapper.inStock );
    System.assert( !aWrapper.onOrder );
  }

  @isTest
  static void searchPartnerInventories_onlyOnOrder_Test()
  {
    init();
    initDealerOrders();
    String jsonResult = P2PInventorySearch_mp.searchPartnerInventories( true );
    P2PInventorySearch_mp.ResultWrapper result =
      (P2PInventorySearch_mp.ResultWrapper)JSON.deserialize(
        jsonResult,
        P2PInventorySearch_mp.ResultWrapper.class
      );
    System.assertEquals( 2, result.boatSelectOptions.size() );
    System.assertEquals( 2, result.inventory.keySet().size() );
    String boatModel = new List<String>( result.inventory.keySet() )[0];
    P2PInventorySearch_mp.AccountWrapper aWrapper =
      result.inventory.get(boat.Name)[0];
    System.debug( aWrapper );
    System.assertEquals( 1, result.inventory.get(boat.Name).size() );
    System.assert( !aWrapper.inStock );
    System.assert( aWrapper.onOrder );
  }

  @isTest
  static void searchPartnerInventories_inStockAndOnOrder_Test()
  {
    init();
    initRegistrations();
    initDealerOrders();
    Test.startTest();
    String jsonResult = P2PInventorySearch_mp.searchPartnerInventories( true );
    Test.stopTest();
    P2PInventorySearch_mp.ResultWrapper result =
      (P2PInventorySearch_mp.ResultWrapper)JSON.deserialize(
        jsonResult,
        P2PInventorySearch_mp.ResultWrapper.class
      );
    System.assertEquals( 2, result.boatSelectOptions.size() );
    System.assertEquals( 2, result.inventory.keySet().size() );
    P2PInventorySearch_mp.AccountWrapper[] wrappers =
      result.inventory.get(boat.Name);
    P2PInventorySearch_mp.AccountWrapper dealer1Wrapper;
    P2PInventorySearch_mp.AccountWrapper dealer2Wrapper;
    for( P2PInventorySearch_mp.AccountWrapper wrapper : wrappers )
    {
      if( wrapper.id == dealers[1].Id )
      {
        dealer1Wrapper = wrapper;
      }
      if( wrapper.id == dealers[2].Id )
      {
        dealer2Wrapper = wrapper;
      }
    }
    System.assertEquals( 4, result.inventory.get(boat.Name).size() );
    System.assert( dealer1Wrapper.inStock );
    System.assert( dealer1Wrapper.onOrder );
    System.assert( dealer2Wrapper.inStock );
    System.assert( !dealer2Wrapper.onOrder );
  }

  @isTest
  static void searchPartnerInventories_AsPartner_Test()
  {
    init();
    initRegistrations();
    Contact pContact = Factory_Contact.buildContact( dealers[2].Id,
                                                     'PartnerFN',
                                                     'PartnerLN',
                                                     'partner@dealer.com');
    User pUser = [SELECT Id, Name FROM User WHERE ContactId = :pContact.Id ];
    System.runAs( pUser )
    {
      String jsonResult = P2PInventorySearch_mp.searchPartnerInventories( true );
      P2PInventorySearch_mp.ResultWrapper result =
        (P2PInventorySearch_mp.ResultWrapper)JSON.deserialize( jsonResult,
                                                               P2PInventorySearch_mp.ResultWrapper.class);
      System.assertEquals( 2, result.boatSelectOptions.size() );
      System.assertEquals( 2, result.inventory.keySet().size() );
      System.assertEquals( 3, result.inventory.get(boat.Name).size() );
    }
  }

}