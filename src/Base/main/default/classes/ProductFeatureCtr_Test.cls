@isTest
private class ProductFeatureCtr_Test {

	testMethod static void test1() {
     /* disable the Gimbal Trigger handler gtProduct.trigger
     until Gimbals code gets deployed, this needs to be commented out for production */
    gcProduct.disableTrigger = true;

    InventoryTestFactory factory = new InventoryTestFactory();
    Product2 boat = factory.insertTestBoatWithFeatures(7);
    List<Feature__c> features = factory.buildAllFeatures(10);
    insert features;

    PageReference pageRef = Page.ProductFeatureSelect;
    pageRef.getParameters().put('id', boat.Id);
    Test.setCurrentPageReference(pageRef);
    ProductFeatureCtr ctr = new ProductFeatureCtr();

    System.assertEquals(7, ctr.selectedConstructionFeatures.size() );
    System.assertEquals(7, ctr.selectedConsoleFeatures.size() );
    System.assertEquals(7, ctr.selectedLivewellFeatures.size() );
    System.assertEquals(7, ctr.selectedSeatingFeatures.size() );
    System.assertEquals(7, ctr.selectedDeckFeatures.size() );
    System.assertEquals(7, ctr.selectedSafetyFeatures.size() );
    System.assertEquals(7, ctr.selectedAdditionalFeatures.size() );

    System.assertEquals(10, ctr.availableConstructionFeatures.size() );
    System.assertEquals(10, ctr.availableConsoleFeatures.size() );
    System.assertEquals(10, ctr.availableLivewellFeatures.size() );
    System.assertEquals(10, ctr.availableSeatingFeatures.size() );
    System.assertEquals(10, ctr.availableDeckFeatures.size() );
    System.assertEquals(10, ctr.availableSafetyFeatures.size() );
    System.assertEquals(10, ctr.availableAdditionalFeatures.size() );

    /* add the first 2 availableConstructionfeatures to the selectedFeatures List */
    for(Integer i=0; i < 2; i++){
      ctr.selectedConstructionFeatures.add( new SelectOption( ctr.availableConstructionfeatures[i].getValue(), ctr.availableConstructionfeatures[i].getLabel() ) );
    }

    /* add the first 2 availableDeckfeatures to the selectedFeatures List */
    for(Integer i=0; i < 2; i++){
      ctr.selectedDeckFeatures.add( new SelectOption( ctr.availableDeckFeatures[i].getValue(), ctr.availableDeckFeatures[i].getLabel() ) );
    }

    ctr.save();

    boat = [SELECT Id, (SELECT Id, Feature_Id__c FROM Product_Feature_Maps__r)
            FROM Product2 WHERE Id = :boat.Id];

    System.assertEquals( 53, boat.Product_Feature_Maps__r.size() );

  }

}