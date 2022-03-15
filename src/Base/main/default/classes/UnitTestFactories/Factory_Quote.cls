@isTest
public with sharing class Factory_Quote {

  public static Quote insertQuote( Opportunity opp )
  {
    Quote q = new Quote(
      OpportunityId = opp.Id,
      Pricebook2Id = opp.Pricebook2Id,
      Name = 'Test Quote'
    );
    insert q;
    return q;
  }

  public static Quote insertQuoteForBoat( Opportunity opp )
  {
    Quote quot = insertQuote( opp );
    Product2[] prods = new List<Product2>();
    Product2 boat = Factory_Product.buildSerializedProduct( 'Boat', 'Pontoon' );
    prods.add( boat );
    Product2 motor = Factory_Product.buildSerializedProduct( 'Motor', 'Remote' );
    prods.add( motor );
    Product2 trailer = Factory_Product.buildSerializedProduct( 'Trailer', 'Pontoon Trailer' );
    prods.add( trailer );
    Product2 trollingMotor = Factory_Product.buildSerializedProduct( 'Trolling Motor', '');
    prods.add( trollingMotor );
    Product2[] parts = Factory_Product.buildNonSerializedProducts( 'Part', 'Hardware', 5 );
    prods.addAll( parts );
    Boolean orig = gcProduct.disableTrigger;
    gcProduct.disableTrigger = true;
    insert prods;
    gcProduct.disableTrigger = orig;
    Factory_PricebookEntry.insertStandardEntries( prods, 0.00 );
    PricebookEntry[] pbes = new List<PricebookEntry>();
    PricebookEntry boatPBE = Factory_PricebookEntry.buildEntry( boat.Id, opp.Pricebook2Id, 10000 );
    pbes.add( boatPBE );
    PricebookEntry motorPBE = Factory_PricebookEntry.buildEntry( motor.Id, opp.Pricebook2Id, 1000 );
    pbes.add( motorPBE );
    PricebookEntry trailerPBE = Factory_PricebookEntry.buildEntry( trailer.Id, opp.Pricebook2Id, 1000 );
    pbes.add( trailerPBE );
    PricebookEntry trollingMotorPBE = Factory_PricebookEntry.buildEntry( trollingMotor.Id, opp.Pricebook2Id, 1000 );
    pbes.add( trollingMotorPBE );
    PricebookEntry[] partPBEs = Factory_PricebookEntry.buildEntries( parts, opp.Pricebook2Id, 100 );
    pbes.addAll( partPBEs );
    insert pbes;
    QuoteLineItem[] qlis = new List<QuoteLineItem>();
    qlis.add( Factory_QuoteLineItem.buildLineItem( boatPBE, quot.Id, 1, null ) );
    qlis.add( Factory_QuoteLineItem.buildLineItem( motorPBE, quot.Id, 1, null ) );
    qlis.add( Factory_QuoteLineItem.buildLineItem( trailerPBE, quot.Id, 1, null ) );
    qlis.add( Factory_QuoteLineItem.buildLineItem( trollingMotorPBE, quot.Id, 1, null ) );
    for( PricebookEntry pbe : partPBEs )
    {
      qlis.add( Factory_QuoteLineItem.buildLineItem( pbe, quot.Id, 1, boat.Id ) );
    }
    insert qlis;
    return quot;
  }
}