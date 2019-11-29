@isTest
public class Factory_Opportunity {

  static Id stdPB2Id = Test.getStandardPricebookId();

  public static Opportunity[] insertBasic( Integer count,
                                           Account acct,
                                           String stageName,
                                           AcctSeedERP__Warehouse__c warehouse,
                                           DateTime deliveryDate )
  {
    Opportunity[] opps = new List<Opportunity>();
    Id retailRT = LGND_Utilities.recordTypeIdFromName('Opportunity', 'Retail');
    String puLoc = findPickupLocationFromWarehouse( warehouse.Name );
    for( Integer i=0; i<count; i++ )
    {
      opps.add( new Opportunity(
        RecordTypeId = retailRT,
        Name= 'Test Retail Opp',
        AccountId = acct.Id,
        CloseDate=Date.today(),
        Delivery_Date__c = deliveryDate,
        Pickup_Location__C = puLoc,
        Pricebook2Id = stdPB2Id,
        StageName = stageName
      ) );
    }
    insert opps;
    return opps;
  }

  public static Opportunity insertOpportunity( Account acct,
                                               Id pbId )
  {
    Opportunity opp = new Opportunity(
      Name = 'Test Opp',
      AccountId = acct.Id,
      Pricebook2Id = pbId,
      StageName = 'Quoting',
      CloseDate = Date.today().addDays(10)
    );
    insert opp;
    return opp;
  }

  public static Opportunity insertOpportunityForBoatSale( Id pbId, Account acct )
  {
    Opportunity opp = insertOpportunity( acct, pbId );
    Product2[] prods = new List<Product2>();
    Product2 boat = Factory_Product.buildSerializedProduct( 'Boat', 'Pontoon' );
    prods.add( boat );
    Product2 motor = Factory_Product.buildSerializedProduct( 'Motor', 'Remote' );
    prods.add( motor );
    Product2 trailer = Factory_Product.buildSerializedProduct( 'Trailer', 'Pontoon Trailer' );
    prods.add( trailer );
    Product2 trollingMotor = Factory_Product.buildSerializedProduct( 'Trolling Motor', '');
    prods.add( trollingMotor );
    Product2[] parts = Factory_Product.buildNonSerializedProducts( 'Part', 'Electronic', 5 );
    prods.addAll( parts );
    Boolean orig = gcProduct.disableTrigger;
    gcProduct.disableTrigger = true;
    insert prods;
    gcProduct.disableTrigger = orig;
    Factory_PricebookEntry.insertStandardEntries( prods, 0.00 );
    PricebookEntry[] pbes = new List<PricebookEntry>();
    PricebookEntry boatPBE = Factory_PricebookEntry.buildEntry( boat.Id, pbId, 10000 );
    pbes.add( boatPBE );
    PricebookEntry motorPBE = Factory_PricebookEntry.buildEntry( motor.Id, pbId, 1000 );
    pbes.add( motorPBE );
    PricebookEntry trailerPBE = Factory_PricebookEntry.buildEntry( trailer.Id, pbId, 1000 );
    pbes.add( trailerPBE );
    PricebookEntry trollingMotorPBE = Factory_PricebookEntry.buildEntry( trollingMotor.Id, pbId, 1000 );
    pbes.add( trollingMotorPBE );
    PricebookEntry[] partPBEs = Factory_PricebookEntry.buildEntries( parts, pbId, 100 );
    pbes.addAll( partPBEs );
    insert pbes;
    OpportunityLineItem[] olis = new List<OpportunityLineItem>();
    olis.add( Factory_OpportunityLineItem.buildLineItem( boatPBE, opp.Id, 1, null ) );
    olis.add( Factory_OpportunityLineItem.buildLineItem( motorPBE, opp.Id, 1, null ) );
    olis.add( Factory_OpportunityLineItem.buildLineItem( trailerPBE, opp.Id, 1, null ) );
    olis.add( Factory_OpportunityLineItem.buildLineItem( trollingMotorPBE, opp.Id, 1, null ) );
    for( PricebookEntry pbe : partPBEs )
    {
      olis.add( Factory_OpportunityLineItem.buildLineItem( pbe, opp.Id, 1, boat.Id ) );
    }
    insert olis;
    return opp;
  }

  private static String[] pickupLocations;
  private static String findPickupLocationFromWarehouse( String whName )
  {
    String result = '';
    if( pickupLocations == null )
      pickupLocations = LGND_Utilities.getPicklistValues( 'AcctSeed__Project__c', 'Pickup_Location__c');
    for( String pl : pickupLocations )
    {
      if( pl.toLowerCase().contains( whName.toLowerCase() ) )
      {
        result =  pl;
        break;
      }
    }
    return result;
  }




  //private static Map<String, AcctSeed__GL_Account__c> insertGLAccounts()
  //{
  //  Map<String, AcctSeed__GL_Account__c> result = new Map<String, AcctSeed__GL_Account__c>();
  //  result.put('Revenue', new AcctSeed__GL_Account__c(Name='Test Revenue Account',
  //                                                    AcctSeed__Active__c = true,
  //                                                    AcctSeed__Type__c = 'Revenue') );
  //  result.put('Expense', new AcctSeed__GL_Account__c(Name='Test Expense Account',
  //                                                    AcctSeed__Active__c = true,
  //                                                    AcctSeed__Type__c = 'Expense') );
  //  result.put('Inventory', new AcctSeed__GL_Account__c(Name='Test Inventory Account',
  //                                                      AcctSeed__Active__c = true,
  //                                                      AcctSeed__Sub_Type_1__c = 'Assets',
  //                                                      AcctSeed__Type__c = 'Balance Sheet') );
  //  insert results.values();
  //  return results;
  //}
}