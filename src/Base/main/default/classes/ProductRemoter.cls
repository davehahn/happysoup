global with sharing class ProductRemoter {

  global class ProductWrapper {
    global String Id { get; set; }
    global String Name { get; set; }
    global String Description { get; set; }
    global String Family { get; set; }
    global String ProductCode { get; set; }
    global String RecordTYpe { get; set; }
    global Decimal UnitPrice { get; set; }

    global ProductWrapper(PricebookEntry pbe)
    {
      this.Id = pbe.Product2.Id;
      this.Name = pbe.Product2.Name;
      this.Description = pbe.Product2.Description;
      this.Family = pbe.Product2.Family;
      this.RecordType = pbe.Product2.RecordType.Name;
      this.ProductCode = pbe.Product2.Unique_Product_Code__c;
      this.UnitPrice = pbe.UnitPrice;
    }
  }

  @RemoteAction
  global static List<ProductWrapper> productSearch( String pricebookId, String searchString )
  {
    return doProductSearch( pricebookId, searchString, null);
  }

  @RemoteAction
  global static List<ProductWrapper> excludedProductSearch( String pricebookId,
                                                           String searchString,
                                                           List<String> excludes )
  {
    return doProductSearch( pricebookId, searchString, excludes);
  }





  private static List<ProductWrapper> doProductSearch( String pricebookId,
                                              String searchString,
                                              List<String> excludedRecordTypes )
  {
    List<ProductWrapper> results = new List<ProductWrapper>();
    Set<Id> excludedRTIDs = new Set<Id>();
    if( excludedRecordTypes != null )
    {
      for( String t :excludedRecordTypes )
      {
        excludedRTIDs.add( LGND_Utilities.recordTypeIdFromName('Product2', t) );
      }
    }
    Id boatRTId = LGND_Utilities.recordTypeIdFromName('Product2', 'Boat');
    String s = '%' + searchString + '%';
    List<PricebookEntry> pbes = [SELECT Id, UnitPrice,
                                        Product2.Id,
                                        Product2.Name,
                                        Product2.Description,
                                        Product2.Family,
                                        Product2.RecordType.Name,
                                        Product2.Unique_Product_Code__c,
                                        Product2.AcctSeed__Accounting_Type__c,
                                        Product2.AcctSeed__Inventory_Type__c
                                   FROM PricebookEntry
                                   WHERE Pricebook2Id = :pricebookId
                                   AND Product2.isActive = true
                                   AND Product2.RecordTypeId NOT IN :excludedRTIDs
                                   AND ( Product2.Name LIKE :s OR
                                         Product2.ProductCode LIKE :s OR
                                         Product2.IEM_Unique_Part_Number__c LIKE :s OR
                                         Product2.Unique_Product_Code__c LIKE :s) ];
    for(PricebookEntry pbe : pbes)
    {
      results.add( new ProductWrapper(pbe) );
    }
    return results;
  }

  @RemoteAction
  global static Product2 selectProduct(String pricebookId, String productId) {
    return [SELECT Id, Name, (SELECT Id, UnitPrice FROM PricebookEntries WHERE PriceBook2Id = :pricebookId LIMIT 1) FROM Product2 WHERE Id= :productId];
  }

}