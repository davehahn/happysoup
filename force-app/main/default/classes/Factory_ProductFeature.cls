@isTest
public class Factory_ProductFeature {

  public static Product_Feature_Map__c[] createAllFeatures( Id prodId, Integer count )
  {
    Product_Feature_Map__c[] result = new List<Product_Feature_Map__c>();
    Feature__c[] features = buildAllFeatures( count );
    insert features;
    for( Feature__c f : features )
    {
      result.add( new Product_Feature_Map__c(
        Product_Id__c = prodId,
        Feature_Id__c = f.Id
      ));
    }
    insert result;
    return result;
  }


  private static List<Feature__c> buildAllFeatures(Integer count) {
    Set<String> categories = new Set<String>();
    Schema.DescribeFieldResult featureCategory = Feature__c.Category__c.getDescribe();
    for( Schema.PickListEntry ple : featureCategory.getPicklistValues() ){
      String cat = ple.getLabel();
      categories.add( cat );
    }
    List<Feature__c> features = new List<Feature__c> ();
    for( String cat : categories ){
      features.addAll( buildFeatures(count, cat) );
    }
    return features;
  }

   /*
  builds and returns a List of features
  count = number of features to create
  */
  private static List<Feature__c> buildFeatures(Integer count, String category) {
    List<Feature__c> features = new List<Feature__c>();
    for(Integer i = 0; i < count; i++){
      Feature__c f = new Feature__c(description__c = 'This is number ' + Crypto.getRandomLong() + ' test description', Category__c = category);
      features.add(f);
    }
    return features;
  }

}