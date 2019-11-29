@isTest
private class P2PInventorySearch_mp_Test {

  private static Account[] dealers;


	@testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void init()
  {
    dealers = Factory_Account.insertDealerAccounts(5);
    Product2 boat = Factory_Product.createSerializedProduct('Boat', 'Pontoon');
    Product2 boat2 = Factory_Product.createSerializedProduct('Boat', 'Utility');
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

  @isTest
  static void searchPartnerInventories_Test()
  {
    init();
    String jsonResult = P2PInventorySearch_mp.searchPartnerInventories();
    P2PInventorySearch_mp.ResultWrapper result =
      (P2PInventorySearch_mp.ResultWrapper)JSON.deserialize( jsonResult,
                                                             P2PInventorySearch_mp.ResultWrapper.class);
    System.assertEquals( 2, result.boatSelectOptions.size() );
    System.assertEquals( 2, result.inventory.keySet().size() );
    String bm = new List<String>( result.inventory.keySet() )[0];
    System.assertEquals( 4, result.inventory.get(bm).size() );
  }

   @isTest
  static void searchPartnerInventories_AsPartner_Test()
  {
    init();
    Contact pContact = Factory_Contact.buildContact( dealers[2].Id,
                                                     'PartnerFN',
                                                     'PartnerLN',
                                                     'partner@dealer.com');
    User pUser = [SELECT Id, Name FROM User WHERE ContactId = :pContact.Id ];
    System.runAs( pUser )
    {
      String jsonResult = P2PInventorySearch_mp.searchPartnerInventories();
      P2PInventorySearch_mp.ResultWrapper result =
        (P2PInventorySearch_mp.ResultWrapper)JSON.deserialize( jsonResult,
                                                               P2PInventorySearch_mp.ResultWrapper.class);
      System.assertEquals( 2, result.boatSelectOptions.size() );
      System.assertEquals( 2, result.inventory.keySet().size() );
      String bm = new List<String>( result.inventory.keySet() )[0];
      System.assertEquals( 3, result.inventory.get(bm).size() );
    }
  }

}