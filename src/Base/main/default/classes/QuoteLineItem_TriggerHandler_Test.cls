@isTest
private class QuoteLineItem_TriggerHandler_Test {

	static Opportunity opp;
  static Quote quot;
  static Id pbId = Test.getStandardPricebookId();
  static QuoteLineItem[] qlis;
  static Decimal price = 100;

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void init()
  {
    Account cust = Factory_Account.insertCustomerAccounts(1)[0];
    opp = Factory_Opportunity.insertOpportunity( cust, pbId );
    quot = Factory_Quote.insertQuote( opp );
    createLineItems();
  }

  private static void createLineItems()
  {
    qlis = new List<QuoteLineItem>();
    Product2[] prods = new List<Product2>();
    for( Product2 p : Factory_Product.buildNonSerializedProducts('Part', 'Electronics', 5) )
    {
      p.Taxable__c = true;
      prods.add( p );
    }
    prods[0].Family = 'Discount';
    insert prods;
    Map<Id, Product2> prodMap = new Map<Id, Product2>(prods);
    PricebookEntry[] pbes = Factory_PricebookEntry.createEntries( prods, pbId, price );
    for( PricebookEntry pbe : pbes )
    {
      Integer q = prodMap.get(pbe.Product2Id).Family == 'Discount' ? 1 : 2;
      qlis.add( Factory_QuoteLineItem.buildLineItem( pbe.Id, quot.Id, price, q, null ));
    }
    insert qlis;
  }

  @isTest
  static void trigger_beforeInsert_Test()
  {
    init();
    for( QuoteLineItem qli : [SELECT Id,
                                     Quantity,
                                     UnitPrice,
                                     Taxable_Federal__c,
                                     Taxable_Provincial__c,
                                     isDiscount__c,
                                     PricebookEntry.Product2.Family,
                                     Total_Amount__c
                              FROM QuoteLineItem
                              WHERE QuoteId = :quot.Id] )
    {
      System.assertEquals( true, qli.Taxable_Federal__c );
      System.assertEquals( true, qli.Taxable_Provincial__c );
      System.assertEquals( qli.Total_Amount__c, qli.Quantity * price );
      System.assertEquals( qli.IsDiscount__c, qli.PricebookEntry.Product2.Family == 'Discount' );
    }
  }

  @isTest
  static void trigger_beforeUpdate_Test()
  {
    init();
    Decimal newQuantity = 10;
    QuoteLineItem qli = [SELECT Id, UnitPrice, Quantity
                         FROM QuoteLineItem
                         WHERE QuoteId = :quot.Id
                         AND PricebookEntry.Product2.Family <> 'Discount'
                         LIMIT 1];
    qli.Quantity = newQuantity;
    update qli;
    qli = [SELECT Id, UnitPrice, Quantity, Total_Amount__c
           FROM QuoteLineItem
           WHERE Id = :qli.Id ];
    System.assertEquals( qli.Total_Amount__c, newQuantity * price );
  }

}