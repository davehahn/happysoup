@isTest
public with sharing class Factory_ProductOption {

  public static Product_Option__c[] buildProductOptions( Id parentId,
                                                         Product2[] optionalProducts,
                                                         Integer standard,
                                                         Integer maximum )
  {
    Product_Option__c[] opts = new List<Product_Option__c>();
    for( Product2 p : optionalProducts )
    {
      opts.add( buildProductOption( parentId, p.Id, standard, maximum ) );
    }
    return opts;
  }

  public static void createProductOptions( Id parentId,
                                           Product2[] optionalProducts,
                                           Integer standard,
                                           Integer maximum )
  {
    insert buildProductOptions( parentId,
                                optionalProducts,
                                standard,
                                maximum );
  }


  public static Product_Option__c buildProductOption( Id parentId,
                                                      Id childId,
                                                      Integer standard,
                                                      Integer maximum )
  {
    return new Product_Option__c(
      To_Product__c = parentId,
      From_Product__c = childId,
      Maximum__c = maximum,
      Standard__c = standard
    );
  }

  public static Product_Option__c buildProductOption(
    Id parentId,
    Id childId,
    Integer standard,
    Integer maximum,
    Boolean availableOnline)
  {
    return new Product_Option__c(
      To_Product__c = parentId,
      From_Product__c = childId,
      Maximum__c = maximum,
      Standard__c = standard,
      Available_Online__c = availableOnline
    );
  }

}