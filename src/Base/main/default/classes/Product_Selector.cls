/**
 * Created by dave on 2020-04-23.
 */

public with sharing class Product_Selector extends Application_Selector
{

  private static List<String> boatFields = new List<String>{
    'Standard_Motor__c',
    'Standard_Trailer__c',
    'Standard_Trolling_Motor__c'
  };

  private static List<String> boatListingFields = new List<String>{
    'Standard_Motor__c',
    'Standard_Motor__r.Name',
    'Standard_Trailer__c',
    'Standard_Trailer__r.Name',
    'Standard_Trolling_Motor__c',
    'Model_Year_Start__c',
    'Centerline_Length__c',
    'Package_Length__c',
    'Towing_Weight__c',
    'Beam__c',
    'Length__c',
    'Series__c'
  };

  public Product_Selector()
  {
    this.sObjectName = 'Product2';
    this.fields = new List<String>{
      'Id',
      'Name',
      'Family',
      'RecordTypeId',
      'RecordType.Name',
      'ProductCode',
      'Description',
      'Default_Gallery_Image_Original__c',
      'Rigging_Time__c',
      'Composite_Type__c'
    };
  }

  public static List<Product2> allBoatsAvailableForOnlineSale()
  {
    Id boatRtId = LGND_Constants.productRtId_Boat;
    Product_Selector selector = new Product_Selector();
    selector.addWhere('RecordTypeId = \'' + boatRtId + '\'')
      .addWhere('Available_Online__c = true');
    return (List<Product2>)selector.query();
  }

  public static List<Product2> allWithFullDetailsById( Set<Id> productIds )
  {
    return new Product_Selector()
      .addWhereIdIn( productIds )
      .query();
  }

  public static Product2 getOnlineBoat( String recordId )
  {
    Product_Selector selector = new Product_Selector();
    selector
      .addFields( boatFields )
      .addWhere('Id = \'' + recordId + '\'')
      .addWhere( 'Available_online__c = true', 'AND');
    List<Sobject> results = selector.query();
    if( results.size() > 0 )
      return (Product2)results[0];
    return null;
  }

  public static List<Product2> allKitsWithKitPartsById( Set<Id> prodIds )
  {
    return new Product_Selector()
      .addChildQuery( new ProductPart_Selector(), 'AcctSeed__Product_Parts__r' )
      .addWhereIdIn( prodIds )
      .addWhere('Composite_Type__c = \'Kit\'', 'AND')
      .query();
  }

  public static List<Product2> allBoatsInSeries( String series )
  {
    Product_Selector selector = new Product_Selector();
    selector
            .addFields( boatListingFields )
            .addWhere('Series__c = \'' + series + '\'')
            .addWhere('Available_on_Factory_Store_Sites__c = true', 'AND');
    return (List<Product2>)selector.query();
  }
}
