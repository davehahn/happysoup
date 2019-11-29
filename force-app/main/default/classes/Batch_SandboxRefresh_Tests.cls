@isTest
private class Batch_SandboxRefresh_Tests {

	@isTest static void Products_Test()
  {
		Product2[] parts = new List<Product2>();
    for( Integer i=0; i<200; i++ )
    {
      parts.add( Factory_Product.buildNonSerializedProduct('Part', 'Electronics') );
    }
    insert parts;

    Test.startTest();
    Database.executeBatch( new Batch_SandboxRefresh_Products() );
    Test.stopTest();

    Product2[] prods = [SELECT Id FROM PRoduct2 WHERE Dump_Id__c = null];
    System.assertEquals( 0, prods.size() );
	}

  @isTest static void Pricebook_Test()
  {
    Pricebook2[] pbs = new List<Pricebook2>();
    for( Integer i=0; i<200; i++ )
    {
      pbs.add( new Pricebook2(Name = 'Test book' + String.valueOf(i) ) );
    }
    insert pbs;

    Test.startTest();
    Database.executeBatch( new Batch_SandboxRefresh_Pricebooks() );
    Test.stopTest();

    Pricebook2[] pricebooks = [SELECT Id FROM Pricebook2 WHERE Dump_Id__c = null];
    System.assertEquals( 0, pricebooks.size() );
  }

  @isTest
  static void createPricebookEntries_Test()
  {
    Product2[] parts = Factory_Product.buildNonSerializedProducts( 'Part', 'Electronics', 20 );
    insert parts;
    Factory_PricebookEntry.createStandardEntries( parts, 10.00 );

    Test.startTest();
    Database.executeBatch( new Batch_SandboxRefresh_PricebookEntries() );
    Test.stopTest();

    PricebookEntry[] pbes = [SELECT Id FROM PricebookEntry WHERE Dump_Id__c = null];
    System.assertEquals( 0, pbes.size() );
  }

}