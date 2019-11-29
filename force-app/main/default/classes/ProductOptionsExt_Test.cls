@isTest (seeAllData=true)
private class ProductOptionsExt_Test {

  @isTest
  static void coverageTest()
  {
    ProductOptionsExt.coverage();
  }

  ////static String partFamiliesString = Legend_Settings__c.getOrgDefaults().BB_Product_Families__c;
  //static List<String> partFamilies;
  //static Integer familyCount;
  //static InventoryTestFactory factory;
  //static Product2 boat;
  //static Map<String, List<Product2>> productMap;
  //static List<Product_Upgrade__c> upgrades;
  //public static PageReference pageRef;
  //public static ProductOptionsExt pox;
  //public static Integer origSelectedCount;

  //private static void init()
  //{
  //  buildPartFamilies();
  //  familyCount = partFamilies.size();
  //  buildStuff();
  //  pageRef = Page.ProductOptionsForm;
  //  pageRef.getParameters().put('productId', boat.Id);
  //  Test.setCurrentPageReference(pageRef);

  //  /* instantiate a standard controller and the extension */
  //  ApexPages.StandardController sc = new ApexPages.StandardController(boat);
  //  pox = new ProductOptionsExt(sc);
  //}

  //private static void buildPartFamilies()
  //{
  //  List<String> fams = LGND_Utilities.getPicklistValues('Product2', 'Family');
  //  partFamilies = new List<String>();
  //  for( Integer i=0; i<5; i++)
  //  {
  //    partFamilies.add( fams.get(i) );
  //  }
  //}

  //private static void buildStuff() {
  //  factory = new InventoryTestFactory();
  //  boat = factory.buildTestBoat();
  //  insert boat;
  //  productMap = new Map<String, List<Product2>>();
  //  productMap.put('Motor', factory.insertTestProducts(10, 'Motor') );
  //  productMap.put('Trolling Motor', factory.insertTestProducts(5, 'Trolling Motor') );
  //  productMap.put('Trailer', factory.insertTestProducts(5, 'Trailer') );
  //  for(String fam :partFamilies)
  //  {
  //      productMap.put(fam, factory.insertTestProducts(5, 'Part', fam));
  //  }
  //  productMap.put('warranty', factory.insertTestProducts(5, 'Protection and Services', 'Extended Warranty') );
  //  upgrades = new List<Product_Upgrade__c>();
  //  for(Integer i=0; i<3; i++)
  //  {
  //      upgrades.add( new Product_Upgrade__c(
  //          From_Product__c = boat.Standard_Motor__c,
  //          To_Product__c = productMap.get('Motor')[i].Id
  //          )
  //      );
  //      upgrades.add( new Product_Upgrade__c(
  //          From_Product__c = boat.Standard_Trailer__c,
  //          To_Product__c = productMap.get('Trailer')[i].Id
  //          )
  //      );
  //      upgrades.add( new Product_Upgrade__c(
  //          From_Product__c = boat.Standard_Trolling_Motor__c,
  //          To_Product__c = productMap.get('Trolling Motor')[i].Id
  //          )
  //      );
  //  }
  //  insert upgrades;
  //}

  //private static void doOriginalSelect(ProductOptionsExt l_pox)
  //{
  //  origSelectedCount = 0;
  //  /*Select 2 parts from every part Family*/
  //  for(String fam :partFamilies)
  //  {
  //    l_pox.optionsMap.get(fam).selected.add( new SelectOption( productMap.get(fam)[1].Id, productMap.get(fam)[1].Name ) );
  //    l_pox.optionsMap.get(fam).selected.add( new SelectOption( productMap.get(fam)[3].Id, productMap.get(fam)[3].Name ) );
  //    origSelectedCount += 2;
  //  }
  //  /* select 2 warranty and covers */
  //  l_pox.optionsMap.get('Extended Warranty').selected.add( new SelectOption(productMap.get('warranty')[1].Id, productMap.get('warranty')[1].Name) );
  //  l_pox.optionsMap.get('Extended Warranty').selected.add( new SelectOption(productMap.get('warranty')[3].Id, productMap.get('warranty')[3].Name) );
  //  origSelectedCount += 2;

  //  /* select some motors */
  //  l_pox.optionsMap.get('Motors').selected.add( new SelectOption(productMap.get('Motor')[1].Id, productMap.get('Motor')[1].Name) );
  //  l_pox.optionsMap.get('Motors').selected.add( new SelectOption(productMap.get('Motor')[3].Id, productMap.get('Motor')[3].Name) );
  //  l_pox.optionsMap.get('Motors').selected.add( new SelectOption(productMap.get('Motor')[4].Id, productMap.get('Motor')[4].Name) );
  //  l_pox.optionsMap.get('Motors').selected.add( new SelectOption(productMap.get('Motor')[7].Id, productMap.get('Motor')[7].Name) );
  //  l_pox.optionsMap.get('Motors').selected.add( new SelectOption(productMap.get('Motor')[9].Id, productMap.get('Motor')[9].Name) );
  //  origSelectedCount += 5;

  //   /* select some  trolling motors */
  //  l_pox.optionsMap.get('Trolling Motors').selected.add( new SelectOption(productMap.get('Trolling Motor')[0].Id, productMap.get('Trolling Motor')[0].Name) );
  //  l_pox.optionsMap.get('Trolling Motors').selected.add( new SelectOption(productMap.get('Trolling Motor')[1].Id, productMap.get('Trolling Motor')[1].Name) );
  //  origSelectedCount += 2;

  //  /* select a trailer */
  //  l_pox.optionsMap.get('Trailers').selected.add( new SelectOption(productMap.get('Trailer')[1].Id, productMap.get('Trailer')[1].Name) );
  //  origSelectedCount += 1;

  //  l_pox.save();
  //}
  ///*
  // This test will simulate a newly created boat and selecting options for
  // the first time
  //*/
  //testMethod static void constructor_Test() {
  //  Test.startTest();
  //  init();

  //  /* we want to make sure the boat's standardTrailer and standardMotor
  //    are not included in allMotor/allTrailers */
  //  Set<String> motorIds = new Set<String>();
  //  Set<String> trailerIds = new Set<String>();
  //  Set<String> trollingMotorIds = new Set<String>();
  //  for(SelectOption so: pox.optionsMap.get('Motors').available){
  //    motorIds.add( so.getValue() );
  //  }
  //  for(SelectOption so: pox.optionsMap.get('Trailers').available){
  //    trailerIds.add( so.getValue() );
  //  }
  //  for(SelectOption so: pox.optionsMap.get('Trolling Motors').available){
  //    trollingMotorIds.add( so.getValue() );
  //  }
  //  Test.stopTest();

  //  System.assertEquals( boat.Id, pox.getProduct().Id );
  //  System.assert( !motorIds.contains( boat.Standard_Motor__c) );
  //  System.assert( !trailerIds.contains( boat.Standard_Trailer__c) );
  //  System.assert( !trollingMotorIds.contains( boat.Standard_Trolling_Motor__c) );

  //} //constructor_Test

  // /* lets test the search function we will search 'InventoryTestxxx999ddd ' which should
  //     return ( (familyCount * 5) - (familyCount * 2) ) */
  //testmethod static void search_Test()
  //{
  //  Test.startTest();
  //  init();
  //  doOriginalSelect(pox);
  //  pageRef.getParameters().put('search_string', 'InventoryTestxxx999ddd');
  //  Test.setCurrentPageReference(pageRef);
  //  pox.fetchSearchResults();
  //  Integer firstSearchSize = pox.allSearchResults.size();
  //  Integer firstSeslectedSize = pox.selectedSearchResults.size();
  //  pox.selectedSearchResults.add( new SelectOption(pox.allSearchResults[0].getValue(), pox.allSearchResults[0].getLabel()) );
  //  pageRef.getParameters().put('search_string', 'InventoryTestxxx999ddd');
  //  Test.setCurrentPageReference(pageRef);
  //  pox.fetchSearchResults();
  //  Integer secondSearchSize = pox.allSearchResults.size();
  //  Integer secondSeslectedSize = pox.selectedSearchResults.size();
  //  Test.stopTest();

  //  System.assertEquals( 0, firstSeslectedSize );
  //  System.assertEquals( 1 , secondSeslectedSize );
  //  System.assertEquals( (familyCount * 5) , firstSearchSize );
  //  System.assertEquals( (familyCount * 5) - 1, secondSearchSize );
  //}// search_Test



  //testMethod static void selectOptions_Test()
  //{
  //  Test.startTest();
  //  init();
  //  doOriginalSelect(pox);

  //  boat = [SELECT Id, Name, Standard_Trailer__c, Standard_Motor__c, Standard_Trolling_Motor__c,
  //            (SELECT Id, From_Product__c FROM To_Product_Options__r)
  //            FROM Product2 WHERE Id = :boat.Id];
  //  Test.stopTest();
  //  /* our boat should now have the following Product Options associated with it
  //    5 - motors
  //    2 - trolling motors
  //    1 - trailer
  //    2 - extended warranty
  //    (familyCount * 2) - parts
  //  */

  //  System.assertEquals( origSelectedCount, boat.To_Product_Options__r.size() );
  //}//selectOptions_Test

  //testmethod static void changeOptions_Test()
  //{
  //  Test.startTest();
  //  init();
  //  doOriginalSelect(pox);
  //  PageReference pr = Page.ProductOptionsForm;
  //  pr.getParameters().put('productId', boat.Id);
  //  Test.setCurrentPageReference(pr);
  //  ApexPages.StandardController sc = new ApexPages.StandardController(boat);
  //  ProductOptionsExt ext = new ProductOptionsExt(sc);

  //  System.assertEquals( origSelectedCount, ext.selectedIds.size() );
  //  /* remove the first selected motor in the list motors[1] */
  //  ext.optionsMap.get('Motors').selected.remove(0);

  //  ext.save();
  //  /* re-instantiate the controller and extension */
  //  sc = new ApexPages.StandardController(boat);
  //  ext = new ProductOptionsExt(sc);
  //  Test.stopTest();

  //  System.assertEquals( origSelectedCount - 1, ext.selectedIds.size() );
  //  System.assertEquals(1, ext.optionsMap.get('Trailers').selected.size() );
  //  System.assertEquals(4, ext.optionsMap.get('Motors').selected.size() );
  //  System.assertEquals(2, ext.optionsMap.get('Trolling Motors').selected.size() );
  //  for(String fam : partFamilies)
  //  {
  //    System.assertEquals(2, ext.optionsMap.get(fam).selected.size() );
  //  }
  //  System.assertEquals(2, ext.optionsMap.get('Extended Warranty').selected.size() );
  //}//changeOptions_Test



}