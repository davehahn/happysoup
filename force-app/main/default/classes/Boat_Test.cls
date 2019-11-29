@isTest (seeAllData=true)
private class Boat_Test {

  //private static String partTypesString = Legend_Settings__c.getOrgDefaults().BB_Product_Families__c;
  //private static List<String> partTypes = partTypesString.split(',');

  @isTest static void testWithId()
  {
    BoatTestFactory factory = new BoatTestFactory();
    Pricebook2 pb = [SELECT Id
                     FROM Pricebook2
                     WHERE Id = :Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c];
    List<Product2> boats = factory.insertFullTestBoats(10, pb, 'Pontoon');

    System.assert( boats.size() > 0 );

    Boat b = new Boat( boats[0].Id );

    System.assert(b.StandardMotor != null);
    System.assert(b.StandardTrailer != null);
    System.assert(b.StandardTrollingMotor != null);
     //5 part type defined in BoatTestFactory
    System.assertEquals(5, b.OptionalProducts.keySet().size() );
    System.assert(b.MotorUpgrades.size() == 9);
    System.assert(b.TrailerUpgrades.size() == 9);
    System.assert(b.TrollingMotorUpgrades.size() == 9);
    System.assert(b.MarketingImages.size() == 5);
    System.assert(b.DefaultImage != null );
    System.assert(b.Features.size() > 0);
    System.assert(b.SampleRetailSale != null);
     //6 fee type defined in BoatTestFactory
    System.assertEquals(6, b.Fees.keySet().size() );
  }

  @isTest static void retailTest()
  {
    BoatTestFactory factory = new BoatTestFactory();
    Set<Id> pbIds = new Set<Id>{Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c,
                                Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c};
    List<Pricebook2> pbs = [SELECT Id
                     FROM Pricebook2
                     WHERE Id IN :pbIds];
    List<Product2> boats = factory.insertFullTestBoats(10, pbs, 'Pontoon');

    System.assert( boats.size() > 0 );

    Boat b = new Boat( boats[0].Id, 'retail' );

    System.assert(b.StandardMotor != null);
    System.assert(b.StandardTrailer != null);
    System.assert(b.StandardTrollingMotor != null);
     //5 part type defined in BoatTestFactory
    System.assertEquals(5, b.OptionalProducts.keySet().size() );
    System.assert(b.MotorUpgrades.size() == 9);
    System.assert(b.TrailerUpgrades.size() == 9);
    System.assert(b.TrollingMotorUpgrades.size() == 9);
    System.assert(b.MarketingImages.size() == 5);
    System.assert(b.DefaultImage != null );
    System.assert(b.Features.size() > 0);
    System.assert(b.SampleRetailSale != null);
     //6 fee type defined in BoatTestFactory
    System.assertEquals(6, b.Fees.keySet().size() );
  }

  @isTest static void findByStyle_Test()
  {
    PricebookEntry[] boatsFound = Boat.findByStyle('Pontoon');
  }

  //@isTest(seeAllData=true) static void partnerTest()
  //{
  //  BoatTestFactory factory = new BoatTestFactory();
  //  Pricebook2 pb = [SELECT Id
  //                   FROM Pricebook2
  //                   WHERE Id = :Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c];
  //  List<Product2> boats = factory.insertFullTestBoats(10, pb, 'Pontoon');

  //  System.assert( boats.size() > 0 );

  //  Boat b = new Boat( boats[0].Id, 'partner' );

  //  System.assert(b.StandardMotor != null);
  //  System.assert(b.StandardTrailer != null);
  //  System.assert(b.StandardTrollingMotor != null);
  //   //7 part type defined in BoatTestFactory
  //  System.assertEquals(7, b.OptionalProducts.keySet().size() );
  //  System.assert(b.MotorUpgrades.size() == 9);
  //  System.assert(b.TrailerUpgrades.size() == 9);
  //  System.assert(b.TrollingMotorUpgrades.size() == 9);
  //  System.assert(b.MarketingImages.size() == 5);
  //  System.assert(b.DefaultImage != null );
  //  System.assert(b.Features.size() > 0);
  //  System.assert(b.SampleRetailSale != null);
  //   //6 fee type defined in BoatTestFactory
  //  System.assertEquals(6, b.Fees.keySet().size() );
  //}



}