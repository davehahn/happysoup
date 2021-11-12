@isTest
private class Product2ExtTest {
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  @IsTest
  static void saveTest() {
    BoatTestFactory f = new BoatTestFactory();
    Product2 oBoat = f.insertFullTestBoats(1, Test.getStandardPricebookId())[0];
    PageReference pageRef;
    pageRef = Page.BoatForm;
    pageRef.getParameters().put('cloneId', oBoat.Id);
    pageRef.getParameters().put('Id', null);
    Test.setCurrentPage(pageRef);
    Test.startTest();
    ApexPages.StandardController sController = new ApexPages.StandardController(
      oBoat
    );
    Product2Ext p2Ext = new Product2Ext(sController);
    p2Ext.product.Name = 'I am a cloned Boat';
    p2Ext.save();
    Test.stopTest();

    Product2 newBoat = [
      SELECT Id, Name, Family
      FROM Product2
      WHERE Id = :sController.getId()
    ];

    System.assertEquals(oBoat.Family, newBoat.Family);
    System.assert( p2Ext.renderDeepCloneButton );
  }

  @IsTest
  static void clone_Test() {
    Set<String> feeFamilies = new Set<String>{
      'Bank Registration PPSA Fee',
      'Documentation Fee',
      'Freight'
    };
    Product2 boat = Factory_Product.createSerializedProduct('Boat', 'Pontoon');
    Product2 clone = boat.clone(false, false, false, false);
    List<Product2> optionalParts = Factory_Product.createNonSerializedProducts(
      'Part',
      'Electronics',
      5
    );
    List<Product2> productPartParts = Factory_Product.createNonSerializedProducts(
      'Part',
      'Electronics',
      5
    );

    List<Product_Option__c> origOptions = new List<Product_Option__c>();
    for (Product2 op : optionalParts) {
      origOptions.add(
        new Product_Option__c(
          From_Product__c = op.Id,
          To_Product__c = boat.Id,
          Standard__c = 0,
          Maximum__c = 1
        )
      );
    }
    insert origOptions;

    List<AcctSeed__Product_Part__c> origProductParts = new List<AcctSeed__Product_Part__c>();
    for (Product2 ppp : productPartParts) {
      origProductParts.add(
        new AcctSeed__Product_Part__c(
          AcctSeed__Product__c = boat.Id,
          AcctSeed__Product_Part__c = ppp.Id,
          AcctSeed__Quantity__c = 1
        )
      );
    }
    insert origProductParts;

    List<Product_Feature_Map__c> origFeatures = Factory_ProductFeature.createAllFeatures(
      boat.Id,
      10
    );

    List<Product2> feeProducts = new List<Product2>();
    for (String familyName : feeFamilies) {
      feeProducts.add(
        Factory_Product.buildNonSerializedProduct('Fees', familyName)
      );
    }
    insert feeProducts;
    List<Product_Fee_Map__c> origProductFeeMaps = new List<Product_Fee_Map__c>();
    for (Integer i = 0; i < feeProducts.size(); i++) {
      origProductFeeMaps.add(
        new Product_Fee_Map__c(
          Rank__c = i,
          Parent_Product__c = boat.Id,
          Fee_Product__c = feeProducts[i].Id
        )
      );
    }
    insert origProductFeeMaps;

    List<Boat_Rigging_Checklist_Map__c> origChecklistMaps = new List<Boat_Rigging_Checklist_Map__c>();
    List<Boat_Rigging_Checklist_Item__c> origChecklistItems = new List<Boat_Rigging_Checklist_Item__c>();
    for (
      Schema.PickListEntry ple : Boat_Rigging_Checklist_Item__c.Category__c.getDescribe()
        .getPicklistValues()
    ) {
      for (Integer i = 0; i < 3; i++) {
        origChecklistItems.add(
          new Boat_Rigging_Checklist_Item__c(
            Category__c = ple.getValue(),
            Description__c = ple.getValue() + '-' + String.valueOf(i)
          )
        );
      }
    }
    insert origChecklistItems;
    for (Boat_Rigging_Checklist_Item__c item : origChecklistItems) {
      origChecklistMaps.add(
        new Boat_Rigging_Checklist_Map__c(
          Product__c = boat.Id,
          Checklist_Item__c = item.Id
        )
      );
    }
    insert origChecklistMaps;

    Id rtId = new Application_RecordType().getProductRecordTypes().getBoatId();
    PageReference pageRef = Page.BoatForm;
    pageRef.getParameters().put('cloneId', boat.Id);
    pageRef.getParameters().put('Id', null);
    pageRef.setRedirect(true);
    Test.startTest();
    Test.setCurrentPage(pageRef);
    ApexPages.StandardController sController = new ApexPages.StandardController(
      clone
    );
    Product2Ext p2Ext = new Product2Ext(sController);
    p2Ext.product.Unique_Product_Code__c = boat.ProductCode + 'Cloned';
    p2Ext.saveWithOptions();
    Test.stopTest();

    Product2[] boats = [SELECT Id FROM Product2 WHERE RecordTypeId = :rtId];

    System.assertEquals(2, boats.size());

    List<Product_Option__c> clonedOptions = [
      SELECT Id
      FROM Product_Option__c
      WHERE To_Product__c = :p2Ext.product.Id
    ];
    List<AcctSeed__Product_Part__c> clonedProductParts = [
      SELECT Id
      FROM AcctSeed__Product_Part__c
      WHERE AcctSeed__Product__c = :p2Ext.product.Id
    ];
    List<Product_Feature_Map__c> clonedFeatureMaps = [
      SELECT Id
      FROM Product_Feature_Map__c
      WHERE Product_Id__c = :p2Ext.product.Id
    ];
    List<Product_Fee_Map__c> clonedFeeMaps = [
      SELECT Id
      FROM Product_Fee_Map__c
      WHERE Parent_Product__c = :p2Ext.product.Id
    ];
    List<Boat_Rigging_Checklist_Map__c> clonedChecklistMap = [
      SELECT Id
      FROM Boat_Rigging_Checklist_Map__c
      WHERE Product__c = :p2Ext.product.Id
    ];

    System.assertEquals(origOptions.size(), clonedOptions.size());
    System.assertEquals(origProductParts.size(), clonedProductParts.size());
    System.assertEquals(origFeatures.size(), clonedFeatureMaps.size());
    System.assertEquals(origProductFeeMaps.size(), clonedFeeMaps.size());
    System.assertEquals(origChecklistMaps.size(), clonedChecklistMap.size());
  }
}
