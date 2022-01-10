@isTest
private class Product_Controller_Test {

	private static Product2[] boats;
  private static Product2[] parts4All;
  private static Product2[] partsRetailOnly;
  private static User partnerUser;
  private static Account partnerAcct;
  private static GMBLASERP__Serial_Number__c[] serials;
  private static Product2 p;

  @testSetup static void dataSetup()
  {
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void init2()
  {
    Product2[] prods = new List<Product2>();
    parts4All = Factory_Product.buildNonserializedProducts('Part', 'Hardware', 20 );
    partsRetailOnly = Factory_Product.buildNonserializedProducts('Part', 'Hardware', 20 );
    prods.addAll( parts4All );
    prods.addAll( partsRetailOnly );
    insert prods;
    Factory_PricebookEntry.createStandardEntries( prods, 10.00);
    PricebookEntry[] pbes = new List<PricebookEntry>();
    pbes.addAll( Factory_PricebookEntry.buildEntries( parts4All, gcConstants.idPricebookRetail, 15.00 ) );
    pbes.addAll( Factory_PricebookEntry.buildEntries( parts4All, gcConstants.idPricebookPartner, 5.00 ) );
    pbes.addAll( Factory_PricebookEntry.buildEntries( partsRetailOnly, gcConstants.idPricebookRetail, 20.00 ) );
    insert pbes;
  }

	@isTest static void findProductsAndPrice_StandardUser() {
		init2();
    User legendUser = Factory_User.buildUser('Testy', 'McTestFace', 'Legend Standard User - New');
    System.runAs( legendUser )
    {
		  String jsonResult = Product_Controller_mp.findProductsAndPrice('InventoryTest', null);
      Product_Controller_mp.PricedProduct[] result =
        (List<Product_Controller_mp.PricedProduct>)JSON.deserialize(jsonResult,
                                                                    List<Product_Controller_mp.PricedProduct>.class);
      System.assertEquals( result.size(), ( parts4All.size() + partsRetailOnly.size() ) );
    }
	}

  @isTest static void findProductsAndPrice_PartnerUser() {
    init2();
    User partnerUser = createPartnerUser();
    System.runAs( partnerUser )
    {
      String jsonResult = Product_Controller_mp.findProductsAndPrice('InventoryTest', null);
      Product_Controller_mp.PricedProduct[] result =
        (List<Product_Controller_mp.PricedProduct>)JSON.deserialize(jsonResult,
                                                                    List<Product_Controller_mp.PricedProduct>.class);
      System.assertEquals( result.size(), parts4All.size() );
    }
  }

  @isTest static void findProductsAndPrice_ForcedPartnerUser() {
    init2();
    User legendUser = Factory_User.buildUser('Testy', 'McTestFace', 'Legend Standard User - New');
    System.runAs( legendUser )
    {
      String jsonResult = Product_Controller_mp.findProductsAndPrice('InventoryTest', 'PowerPartner');
      Product_Controller_mp.PricedProduct[] result =
        (List<Product_Controller_mp.PricedProduct>)JSON.deserialize(jsonResult,
                                                                    List<Product_Controller_mp.PricedProduct>.class);
      System.assertEquals( result.size(), parts4All.size() );
    }
  }

  private static User createPartnerUser()
  {
    Account dealer = Factory_Account.insertDealerAccounts(1)[0];
    Contact partnerContact = Factory_Contact.buildContact( dealer.Id,
                                                   'PartnerFN',
                                                   'PartnerLN',
                                                   'partner@dealer.com ');
    return [SELECT Id, Name FROM User WHERE ContactId = :partnerContact.Id ];
  }

	@isTest static void getProduct() {
		init2();
		Product2 result = Product_Controller_mp.getProduct(parts4All[0].Id);
    System.assertEquals( parts4All[0].Name, result.Name );
	}

//	private static void createSerials( Product2[] prods, Integer count ) {
//    serials = new List<GMBLASERP__Serial_Number__c>();
//    for( Product2 p : prods )
//    {
//      for( Integer i=0; i<count; i++ )
//      {
//        serials.add( new GMBLASERP__Serial_Number__c(
//          GMBLASERP__Product__c = p.Id,
//          Name = 'TESTYMCTESTER'+i
//        ));
//      }
//    }
//    insert serials;
//  }

//  private static void createRegistrations( GMBLASERP__Serial_Number__c[] serials, Id acctId ) {
//    Registration__c[] regs = new List<Registration__c>();
//    for( GMBLASERP__Serial_Number__c sn : serials )
//    {
//      regs.add( new Registration__c(
//          Account__c = acctId,
//          SerialNumber__c = sn.Id
//        )
//      );
//    }
//    insert regs;
//  }

//  private static PricebookEntry createPricebookEntry( Id partId, String pbType, Decimal price )
//  {
//    Id pbId;
//    System.debug([SELECT count(Id) FROM Pricebook2]);
//    if( pbType == 'standard' )
//      pbId = Test.getStandardPricebookId();
//    if( pbType == 'retail' )
//      pbId = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
//    if( pbType == 'partner' )
//      pbId = Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c;

//    return new PricebookEntry(
//      Pricebook2Id = pbId,
//      Product2Id = partId,
//      isActive = true,
//      UnitPrice = price,
//      UseStandardPrice = false
//    );
//  }
}