@isTest
private class lgnd_inventory_test {

  private static Product2[] boats;
  private static User partnerUser;
  private static Account partnerAcct;
  private static GMBLASERP__Serial_Number__c[] serials;

  private static void initData()
  {
    boats = new List<Product2>();
    gcProduct.disableTrigger = true;
    InventoryTestFactory factory = new InventoryTestFactory();
    for( Product2 b: factory.buildTestProducts( 10, 'Boat' ) )
    {
      b.AcctSeedERP__Serialized__c = true;
      b.GMBLASERP__Lot_Tracked__c = false;
      boats.add(b);
    }
    insert boats;
    partnerAcct = AccountFactory.buildDealerAccount('TestingPartnerCo');
    insert partnerAcct;
    partnerUser = User_TestFactory.newPartnerUser('Partner', 'Tester', partnerAcct.Id);
    createSerials( boats, 3 );
    createRegistrations( serials, partnerAcct.Id );
  }

	@isTest static void getDetailedRegistrations_Test() {
    initData();
    System.runAs( partnerUser )
    {
		  String result5JSON = lgnd_inventory.getDetailedRegistrations( 'SerialNumber__c', 'ASC', 5, 1, 'All', null);
      List<lgnd_inventory.wrapProduct> result5 = (List<lgnd_inventory.wrapProduct>)JSON.deserialize( result5JSON, List<lgnd_inventory.wrapProduct>.class);
      String result10JSON = lgnd_inventory.getDetailedRegistrations( 'Product_Record_Type__c', 'ASC', 10, 1, 'All', null);
      List<lgnd_inventory.wrapProduct> result10 = (List<lgnd_inventory.wrapProduct>)JSON.deserialize( result10JSON, List<lgnd_inventory.wrapProduct>.class);
      String result7JSON = lgnd_inventory.getDetailedRegistrations( 'Product_Name__c', 'ASC', 7, 1, 'All', null);
      List<lgnd_inventory.wrapProduct> result7 = (List<lgnd_inventory.wrapProduct>)JSON.deserialize( result7JSON, List<lgnd_inventory.wrapProduct>.class);
      String result15JSON = lgnd_inventory.getDetailedRegistrations( 'Location__c', 'ASC', 15, 1, 'All', null);
      List<lgnd_inventory.wrapProduct> result15 = (List<lgnd_inventory.wrapProduct>)JSON.deserialize( result15JSON, List<lgnd_inventory.wrapProduct>.class);
      System.assertEquals( 5, result5.size() );
      System.assertEquals( 10, result10.size() );
      System.assertEquals( 7, result7.size() );
      System.assertEquals( 15, result15.size() );
    }
	}

	@isTest static void getAccountRegistrations_Test() {
		initData();
    System.runAs( partnerUser )
    {
      String resultJSON = lgnd_inventory.getAccountRegistrations( partnerAcct.Id );
      List<lgnd_inventory.wrapProduct> result = (List<lgnd_inventory.wrapProduct>)JSON.deserialize( resultJSON, List<lgnd_inventory.wrapProduct>.class);
      System.assertEquals( 30, result.size() );
    }
	}

  @isTest static void getUserId_Test()
  {
    partnerAcct = AccountFactory.buildDealerAccount('TestingPartnerCo');
    insert partnerAcct;
    partnerUser = User_TestFactory.newPartnerUser('Partner', 'Tester', partnerAcct.Id);
    System.runAs( partnerUser )
    {
      String uId = lgnd_inventory.getUserId();
      System.assertEquals( partnerUser.Id, uId );
    }
  }

  private static void createSerials( Product2[] prods, Integer count )
  {
    serials = new List<GMBLASERP__Serial_Number__c>();
    for( Product2 p : prods )
    {
      for( Integer i=0; i<count; i++ )
      {
        serials.add( new GMBLASERP__Serial_Number__c(
          GMBLASERP__Product__c = p.Id,
          Name = 'TESTYMCTESTER'+i
        ));
      }
    }
    insert serials;
  }

  private static void createRegistrations( GMBLASERP__Serial_Number__c[] serials, Id acctId )
  {
    Registration__c[] regs = new List<Registration__c>();
    for( GMBLASERP__Serial_Number__c sn : serials )
    {
      regs.add( new Registration__c(
          Account__c = acctId,
          SerialNumber__c = sn.Id
        )
      );
    }
    insert regs;
  }


}