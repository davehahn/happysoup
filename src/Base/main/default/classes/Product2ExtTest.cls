@isTest  (seeAllData=true)
private class Product2ExtTest {

  static InventoryTestFactory factory;
  static Product2 boat;
  static ApexPages.StandardController stdCtrl;
  static Product2Ext p2e;
   static {
     /* disable the Gimbal Trigger handler gtProduct.trigger
       until Gimbals code gets deployed, this needs to be commented out for production */
    //gcProduct.disableTrigger = true;
  }

  private static void init() {
    factory = new InventoryTestFactory();
    boat = factory.buildTestBoat();
    insert boat;
    stdCtrl = new ApexPages.StandardController(boat);
    p2e = new Product2Ext(stdCtrl);
  }

	//testMethod static void getBoatTypesTest() {
 //   init();
 //   Test.startTest();
 //   List<Schema.PicklistEntry> values = Product2.Boat_Type__c.getDescribe().getPickListValues();
 //   List<SelectOption> selectOpts = p2e.getBoatTypes();
 //   Test.stopTest();
 //   System.assertEquals( selectOpts.size(), (values.size() +1) );
	//}

  testMethod static void saveTest() {
    BoatTestFactory f = new BoatTestFactory();
    Pricebook2 spb = [Select Id, Name, IsActive From Pricebook2 where IsStandard = true LIMIT 1];
    Product2 oBoat = f.insertFullTestBoats(1, spb)[0];
    PageReference pageRef;
    pageRef = Page.BoatForm;
    pageRef.getParameters().put('cloneId', oBoat.Id);
    pageRef.getParameters().put('Id', null);
    Test.setCurrentPage(pageRef);
    Test.startTest();
    ApexPages.StandardController sController = new ApexPages.StandardController(oBoat);
    Product2Ext p2Ext = new Product2Ext(sController);
    p2Ext.product.Name = 'I am a cloned Boat';
    p2Ext.save();
    Test.stopTest();

    Product2 newBoat = [SELECT Id, Name, Family FROM Product2 WHERE Id = :sController.getId()];

    System.assertEquals(oBoat.Family, newBoat.Family);
  }

  testMethod static void cloningTest() {
    BoatTestFactory f = new BoatTestFactory();
    Pricebook2 spb = [Select Id, Name, IsActive From Pricebook2 where IsStandard = true LIMIT 1];
    Product2 oBoat = f.insertFullTestBoats(1, spb)[0];
    List<Feature__c> features = f.buildAllFeatures(5);
    insert features;
    List<Product_Feature_Map__C> pFeatureMaps = new List<Product_Feature_Map__c>();
    for(Integer i=0; i<features.size(); i++){
      pFeatureMaps.add( new Product_Feature_Map__c(
        Rank__c = i,
        Product_Id__c = oBoat.Id,
        Feature_Id__c = features[i].Id
        )
      );
    }
    insert pFeatureMaps;
    //create 3 Fee Products
    //get record type Id for fees product record type
    Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.Product2;
    Map<String,Schema.RecordTypeInfo> Product2RecordTypeInfo = cfrSchema.getRecordTypeInfosByName();
    Id feeRecordTypeId = Product2RecordTypeInfo.get('Fees').getRecordTypeId();
    List<Product2> feeProducts = new List<Product2>();
    List<PricebookEntry> feePricebookEntries = new List<PricebookEntry>();
    List<Product_Fee_Map__c> productFeeMaps = new List<Product_Fee_Map__c>();
    for(String t : new Set<String>{'Bank Registration PPSA Fee', 'Documentation Fee','Freight'}){
        feeProducts.add( new Product2(
            Name = t,
            Family = t,
            RecordTypeId = feeRecordTypeId,
            isActive = true
            )
        );
    }
    insert feeProducts;
    for( Product2 fp : feeProducts ){
      feePricebookEntries.add( new PricebookEntry(
          Pricebook2Id = spb.Id,
          Product2Id = fp.Id,
          UnitPrice = 100.00,
          isActive = true
        ) );
    }
    insert feePricebookEntries;
    List<Product_Fee_Map__c> pFeeMaps = new List<Product_Fee_Map__c>();
    for(Integer i=0; i<feeProducts.size(); i++){
      pFeeMaps.add( new Product_Fee_Map__c(
        Rank__c = i,
        Parent_Product__c = oBoat.Id,
        Fee_Product__c = feeProducts[i].Id
        )
      );
    }
    insert pFeeMaps;

    PageReference pageRef;
    pageRef = Page.BoatForm;
    pageRef.getParameters().put('cloneId', oBoat.Id);
    pageRef.getParameters().put('Id', null);
    Test.setCurrentPage(pageRef);
    Test.startTest();
    ApexPages.StandardController sController = new ApexPages.StandardController(oBoat);
    Product2Ext p2Ext = new Product2Ext(sController);
    p2Ext.product.Name = 'I am a cloned Boat';
    p2Ext.saveWithOptions();
    Test.stopTest();

    List<Product_Option__c> origOptions = [Select Id FROM Product_Option__c
                                                    WHERE To_Product__c = :oBoat.Id ];
    List<Product_Option__c> newOptions = [Select Id FROM Product_Option__c
                                                    WHERE To_Product__c = :sController.getId() ];
    List<Product_Feature_Map__c> origFeatureMaps = [SELECT Id
                                                   FROM Product_Feature_Map__c
                                                   WHERE Product_Id__c = :oBoat.Id ];
    List<Product_Feature_Map__c> newFeatureMaps = [SELECT Id
                                                   FROM Product_Feature_Map__c
                                                   WHERE Product_Id__c = :sController.getId() ];
    List<Product_Fee_Map__c> origFeeMaps = [SELECT Id
                                            FROM Product_Fee_Map__c
                                            WHERE Parent_Product__c = :oBoat.Id ];
    List<Product_Fee_Map__c> newFeeMaps = [SELECT Id
                                                   FROM Product_Fee_Map__c
                                                   WHERE Parent_Product__c = :sController.getId() ];
    System.assertEquals( newOptions.size(), origOptions.size() );
    System.assertEquals( newFeatureMaps.size(), origFeatureMaps.size() );
    System.assertEquals( newFeeMaps.size(), origFeeMaps.size() );

  }

}