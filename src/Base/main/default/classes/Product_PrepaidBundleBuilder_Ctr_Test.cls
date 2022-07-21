@isTest
private class Product_PrepaidBundleBuilder_Ctr_Test {
  static Product2 theBundle;
  static Product2[] packages;
  static Prepaid_Package_Item__c[] packageItems;

  private static void init() {
    packages = Factory_Product.buildNonSerializedProducts('Protection and Services', 'Maintenance Package', 10);
    insert packages;
    theBundle = Factory_Product.buildNonSerializedProduct('Package Bundle', 'Maintenance Package');
    theBundle.isPrepayable__c = true;
    insert theBundle;

    packageItems = new List<Prepaid_Package_Item__c>();

    for (Integer i = 0; i < 4; i++) {
      packageItems.add(
        new Prepaid_Package_Item__c(Item__c = packages[i].Id, Package__c = theBundle.Id, Quantity__c = 2)
      );
    }

    insert packageItems;
  }

  @isTest
  static void BundleWrapper_Test() {
    init();
    Product_PrepaidBundleBuilder_Controller.BundleWrapper bw = new Product_PrepaidBundleBuilder_Controller.BundleWrapper(
      null
    );
    System.assertEquals(bw.id, null);
    System.assert(bw.selectedPackages.isEmpty());
    System.assertEquals(10, bw.availablePackages.size());
  }

  @isTest
  static void initComponent_Test() {
    init();
    String resultJSON = Product_PrepaidBundleBuilder_Controller.initComponent(theBundle.Id);
    Product_PrepaidBundleBuilder_Controller.BundleWrapper result = (Product_PrepaidBundleBuilder_Controller.BundleWrapper) JSON.deserialize(
      resultJSON,
      Product_PrepaidBundleBuilder_Controller.BundleWrapper.class
    );

    System.assertEquals(4, result.selectedPackages.size());
    System.assertEquals(6, result.availablePackages.size());
  }

  @isTest
  static void addNewPackageToBundle_Test() {
    init();
    Prepaid_Package_Item__c pppi = new Prepaid_Package_Item__c(
      Item__c = packages[4].Id,
      Package__c = theBundle.Id,
      Quantity__c = 2
    );
    Product_PrepaidBundleBuilder_Controller.addNewPackageToBundle(pppi);

    Prepaid_Package_Item__c[] items = [SELECT Id FROM Prepaid_Package_Item__c WHERE Package__c = :theBundle.Id];

    System.assertEquals(5, items.size());
  }

  @isTest
  static void removePackageFromBundle_Test() {
    init();
    Product_PrepaidBundleBuilder_Controller.removePackageFromBundle(theBundle.Id, packageItems[0].Id);
    Prepaid_Package_Item__c[] items = [SELECT Id FROM Prepaid_Package_Item__c WHERE Package__c = :theBundle.Id];
    System.assertEquals(3, items.size());
  }

  @isTest
  static void updatePackages_Test() {
    init();
    packageItems[0].Quantity__c = 10;
    Product_PrepaidBundleBuilder_Controller.updatePackages(theBundle.Id, packageItems);
    Prepaid_Package_Item__c item = [SELECT Id, Quantity__c FROM Prepaid_Package_Item__c WHERE Id = :packageItems[0].Id];
    System.assertEquals(10, item.Quantity__c);
  }
}
