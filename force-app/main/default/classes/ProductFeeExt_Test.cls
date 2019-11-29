@isTest (seeAllData=true)
private class ProductFeeExt_Test {

  static Pricebook2 standard_pb2;
  static BoatTestFactory factory;
  static Product2 parentProduct;
  static Set<String> feeTypes = new Set<String>{'Bank Registration PPSA Fee',
                                           'Documentation Fee',
                                           'Freight',
                                           'License Fee',
                                           'Rigging and Preparation',
                                           'Tire Stewardship Fee'};
  static List<Product2> feeProducts;


  static {
    factory = new BoatTestFactory();
    standard_pb2 = [Select Id, Name, IsActive From Pricebook2 where IsStandard = true LIMIT 1];
    if (!standard_pb2.isActive) {
        standard_pb2.isActive = true;
        update standard_pb2;
    }
    parentProduct = factory.insertFullTestBoats(1, standard_pb2, 'Pontoon')[0];
    feeProducts = new List<Product2>();
    List<PricebookEntry> feePricebookEntries = new List<PricebookEntry>();
    //get record type Id for fees product record type
    Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.Product2;
    Map<String,Schema.RecordTypeInfo> Product2RecordTypeInfo = cfrSchema.getRecordTypeInfosByName();
    Id feeRecordTypeId = Product2RecordTypeInfo.get('Fees').getRecordTypeId();
    for(Integer i=0; i<4; i++){
      for(String t : feeTypes){
        feeProducts.add( new Product2(
            Name = t + ' - ' + String.valueOf(i),
            Family = t,
            RecordTypeId = feeRecordTypeId,
            isActive = true
          ) );
      }
    }
    insert feeProducts;
    for( Product2 f : feeProducts ){
      feePricebookEntries.add( new PricebookEntry(
          Pricebook2Id = standard_pb2.Id,
          Product2Id = f.Id,
          UnitPrice = 200.00,
          isActive = true
        ) );
    }
    //insert feePricebookEntries;
  }

	@isTest static void constructorViewTest() {
    ApexPages.StandardController sc = new ApexPages.StandardController(parentProduct);
    ProductFeeExt pfe = new ProductFeeExt(sc);
    System.assertEquals(pfe.getFeeProducts().size(), 12);
	}

	@isTest static void constructorFormTest() {
    PageReference pageRef = Page.ProductFeeForm;
    pageRef.getParameters().put('productId', parentProduct.Id);
    Test.setCurrentPageReference(pageRef);
    ApexPages.StandardController sc = new ApexPages.StandardController( new Product_Fee_Map__c() );
    ProductFeeExt pfe = new ProductFeeExt(sc);

    System.assertEquals( 2, pfe.selectedBank.size());
    System.assertEquals( 2, pfe.selectedDoc.size());
    System.assertEquals( 2, pfe.selectedFreight.size());
    System.assertEquals( 2, pfe.selectedLicense.size());
    System.assertEquals( 2, pfe.selectedRigging.size());
    System.assertEquals( 2, pfe.selectedTire.size());
	}

  @isTest static void saveTest() {
    PageReference pageRef = Page.ProductFeeForm;
    pageRef.getParameters().put('productId', parentProduct.Id);
    Test.setCurrentPageReference(pageRef);
    ApexPages.StandardController sc = new ApexPages.StandardController( new Product_Fee_Map__c() );
    ProductFeeExt pfe = new ProductFeeExt(sc);

    pfe.selectedBank.add( pfe.availBank[1] );
    pfe.selectedBank.add( pfe.availBank[3] );
    pfe.selectedDoc.add( pfe.availDoc[0] );
    pfe.selectedDoc.add( pfe.availFreight[0] );
    pfe.selectedLicense.add( pfe.availLicense[2] );
    pfe.selectedDoc.add( pfe.availRigging[1] );
    pfe.selectedDoc.add( pfe.availTire[0] );

    pfe.save();

    List<Product_Fee_Map__c> newPFMs = [SELECT Id FROM Product_Fee_Map__c WHERE Parent_Product__c = : parentProduct.Id];

    System.assertEquals(19, newPFMs.size() );

    Test.setCurrentPageReference(pageRef);
    ProductFeeExt pfe2 = new ProductFeeExt(sc);

    System.assertEquals( 4, pfe2.selectedBank.size());
    System.assertEquals( 3, pfe2.selectedDoc.size());
    System.assertEquals( 3, pfe2.selectedFreight.size());
    System.assertEquals( 3, pfe2.selectedLicense.size());
    System.assertEquals( 3, pfe2.selectedRigging.size());
    System.assertEquals( 3, pfe2.selectedTire.size());

    System.assertEquals(19, pfe2.getFeeProducts().size() );
  }

}