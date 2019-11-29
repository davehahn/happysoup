@isTest(seeAllData = true)
public with sharing class BoatSampleRetailSale_Ext_Test {

  static Product2 boat;
  static Boat_Sample_Retail_Sale__c srs;
  static BoatSampleRetailSale_Ext ext;

  static {
    BoatTestFactory factory = new BoatTestFactory();
    Pricebook2 pb =  new Pricebook2( Name = 'Test PB 1', isActive = true);
    insert pb;
    boat = factory.insertFullTestBoats(1, pb, 'Pontoon')[0];
    srs = new Boat_Sample_Retail_Sale__c(Boat__c = boat.Id);
    ext = new BoatSampleRetailSale_Ext( new ApexPages.StandardController(srs) );
  }

  /*
    FROM BoatTestFactory.insertFullTestBoats() we get...
    9 motor upgrades
    9 trailer upgrades
    9 trolling motor upgrades
    15 options > 5 families X 3 options per family
    1 Service Contract Option
    -- 43 total options
  */

  @isTest static void constructor_test()
  {
    System.assertEquals( null, ext.recordId );
    System.assertEquals( srs, ext.record );
    System.assertEquals( 0, ext.exampleProducts.size() );
    System.assertEquals( 0, ext.exampleProductsToDelete.size() );
    System.assertEquals( 43, ext.resultOptionsMap.size() );
    System.assertEquals( 12, ext.fieldList().size() );
  }

  @isTest static void productSearch_test()
  {
    PageReference pageRef = Page.BoatSampleRetailSale_Form;
    //BoatTestFactory uses the first 5 picklist values in family
    List<String> fams = LGND_Utilities.getPicklistValues('Product2', 'Family');
    pageRef.getParameters().put('qString', fams[0]);
    Test.setCurrentPage(pageRef);

    ext.productSearch();

    System.assertEquals( 3, ext.resultOptionsMap.size() );
  }

  @isTest static void getResultOptionsTest()
  {
    System.assertEquals( 43, ext.getResultOptions().size() );
  }

  @isTest static void select_and_remove_Product_test()
  {
    Id poId = ext.getResultOptions()[0].Id;
    PageReference pageRef = Page.BoatSampleRetailSale_Form;
    pageRef.getParameters().put('product_option_id', poId);
    Test.setCurrentPage(pageRef);
    ext.selectProduct();

    System.assertEquals(1, ext.exampleProducts.size() );
    System.assertEquals( 42, ext.getResultOptions().size() );

    ext.removeProduct();

    System.assertEquals(0, ext.exampleProducts.size() );
    System.assertEquals( 43, ext.getResultOptions().size() );
  }

  @isTest static void save_test()
  {
    ext.record.BatteryCost__c = 100;
    ext.record.BoatShowDiscount__c = 100;
    ext.record.MercuryEngineRebate__c = 100;
    ext.record.PropCost__c = 100;
    Id poId = ext.getResultOptions()[0].Id;
    PageReference pageRef = Page.BoatSampleRetailSale_Form;
    pageRef.getParameters().put('product_option_id', poId);
    Test.setCurrentPage(pageRef);
    ext.selectProduct();
    ext.save();
    ext = new BoatSampleRetailSale_Ext( new ApexPages.StandardController(srs) );

    System.assert( ext.record.Id != null);
    System.assertEquals( 100, ext.record.BatteryCost__c );
    System.assertEquals(1, ext.exampleProducts.size() );
    System.assertEquals( 42, ext.getResultOptions().size() );

    ext.removeProduct();

    System.assertEquals(0, ext.exampleProducts.size() );
    System.assertEquals( 43, ext.getResultOptions().size() );
    System.assertEquals( 1, ext.exampleProductsToDelete.size() );

    ext.save();

    ext = new BoatSampleRetailSale_Ext( new ApexPages.StandardController(srs) );

    System.assertEquals(0, ext.exampleProducts.size() );
    System.assertEquals( 43, ext.getResultOptions().size() );
  }


}