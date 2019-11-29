@isTest
private class lgnd_serno_search_Test {

  private static Product2 boat;

  static {
    gcProduct.disableTrigger = true;
    InventoryTestFactory factory = new InventoryTestFactory();
    boat = factory.buildTestBoat();
    boat.AcctSeedERP__Serialized__c = true;
    boat.GMBLASERP__Lot_Tracked__c = false;
    insert boat;
  }

  @isTest static void findByNumber_Test() {
    GMBLASERP__Serial_Number__c[] serNos = createSerials(3, boat.Id);
    GMBLASERP__Serial_Number__c[] foundSer = lgnd_serno_search.findBySerialNumber( 'TESTY', null, null);
    System.assertEquals( 3, foundSer.size() );
  }

	@isTest static void findByNumber_Limited_Test() {
    GMBLASERP__Serial_Number__c[] serNos = createSerials(3, boat.Id);
    Account acct = AccountFactory.buildDealerAccount('TestingPartnerCo');
    insert acct;
    Registration__c reg = new Registration__c(
      Account__c = acct.Id,
      SerialNumber__c = serNos[0].Id
    );
    insert reg;
    User partner = User_TestFactory.newPartnerUser('Partner', 'Tester', acct.Id);
    insert partner;
    System.runAs( partner )
    {
      GMBLASERP__Serial_Number__c[] foundSer = lgnd_serno_search.findBySerialNumber( 'TESTY', 'limited', null);
      System.assertEquals( 1, foundSer.size() );
    }
	}

	@isTest static void findById_Test() {
    GMBLASERP__Serial_Number__c[] serNos = createSerials(3, boat.Id);
		GMBLASERP__Serial_Number__c[] foundSer = lgnd_serno_search.findBySerialId( serNos[0].Id );
    System.assertEquals( 1, foundSer.size() );
    System.assertEquals(serNos[0].Name, foundSer[0].Name );
	}

  private static GMBLASERP__Serial_Number__c[] createSerials( Integer count, Id productId )
  {
    GMBLASERP__Serial_Number__c[] serials = new List<GMBLASERP__Serial_Number__c>();
    for( Integer i = 0; i<count; i++ )
    {
      serials.add( new GMBLASERP__Serial_Number__c(
        GMBLASERP__Product__c = productId,
        Name = 'TESTYMCTESTER'+i
      ));
    }
    insert serials;
    return serials;
  }

}