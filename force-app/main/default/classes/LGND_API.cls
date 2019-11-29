public with sharing class LGND_API {

  public class ProductWrapper {
    public String Id { get; set; }
    public String Name { get; set; }
    public Decimal RetailPrice { get; set; }
    public Decimal PartnerPrice { get; set; }
    public Map<String, Decimal> Prices { get; set; }
    public Map<String, String> DefaultImages { get; set; }
    public List<Boat.MarketingImage> AllImages { get; set; }

    public ProductWrapper(Product2 p, Boolean includePrice)
    {
      this.Id = p.Id;
      this.Name = p.Name;
      this.DefaultImages = buildDefaultImageObject(p);
      if( includePrice )
      {
        handlePrices(p);
      }
    }

    public ProductWrapper handlePrices(Product2 p)
    {
      for(PricebookEntry pbe : p.PricebookEntries )
      {
        if( pricebookMap.containsKey(pbe.Pricebook2Id) )
        {
          if( pricebookMap.get(pbe.Pricebook2Id) == 'retail')
          {
            this.RetailPrice = pbe.UnitPrice;
          }
          if( pricebookMap.get(pbe.Pricebook2Id) == 'partner')
          {
            this.PartnerPrice = pbe.UnitPrice;
          }
        }
      }
      return this;
    }

    public Map<String,String> buildDefaultImageObject(Product2 p)
    {
      Map<String, String> imageMap = new Map<String,String>();
      if( p.Legend_Gallery_Image__r != null )
      {

        imageMap.put('500x500', p.Legend_Gallery_Image__r.Active_S3_Object__r.URL_500x500__c);
        imageMap.put('700w', p.Legend_Gallery_Image__r.Active_S3_Object__r.URL_700w__c);
        imageMap.put('1280w', p.Legend_Gallery_Image__r.Active_S3_Object__r.URL_1280w__c);
        imageMap.put('Original', p.Legend_Gallery_Image__r.Active_S3_Object__r.URL_Original__c);
      }
      return imageMap;
    }
  }

  static Id retailPricebookId;
  static Id partnerPricebookId;
  static Id devRetailPricebookId;
  static Map<Id, String> pricebookMap;
  static Map<String, Id> pricebookNameMap;
  static {
    retailPricebookId = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
    partnerPricebookId = Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c;
    devRetailPricebookId = Legend_Settings__c.getOrgDefaults().Dev_Retail_Pricebook__c;
    pricebookMap = new Map<Id, String>();
    pricebookNameMap = new Map<String, Id>();
    pricebookMap.put(retailPricebookId, 'retail');
    pricebookNameMap.put('retail', retailPricebookId);
    pricebookNameMap.put('media-vault', retailPricebookId);
    pricebookMap.put(devRetailPricebookId, 'dev-retail');
    pricebookNameMap.put('dev-retail', devRetailPricebookId);
    pricebookMap.put(partnerPricebookId, 'partner');
    pricebookNameMap.put('partner', partnerPricebookId);
  }

  public static String productsJSON( String recordTypeName, String apiType)
  {
    List<Product2> prods = fetchProducts(pricebookNameMap.get(apiType), recordTypeName);
    Map<String, List<ProductWrapper>> groupedProds = groupProductsByFamily(prods, false);
    return buildJSONString( groupedProds);
  }

  public static Product2[] fetchProducts(Id pricebookId, String recordTypeName)
  {
    //Get all Items with RecordType.Name == 'boat' these are selectedBoats (duh)
    Set<Id> productIdsInPricebook = new Set<Id>();
    PricebookEntry[] pbes = [SELECT Product2Id, Pricebook2Id
                             FROM PricebookEntry
                             WHERE Pricebook2Id = :pricebookId
                             AND isActive = true
                             AND Pricebook2.isActive = true
                             AND Product2.RecordType.Name = :recordTypeName];
    for( PricebookEntry pbe :pbes )
    {
      productIdsInPricebook.add(pbe.Product2Id);
    }
    return [SELECT Id,
                   Name,
                   Family,
                   Legend_Gallery_Image__r.Active_S3_Object__r.URL_Original__c,
                   Legend_Gallery_Image__r.Active_S3_Object__r.URL_500x500__c,
                   Legend_Gallery_Image__r.Active_S3_Object__r.URL_700w__c,
                   Legend_Gallery_Image__r.Active_S3_Object__r.URL_1280w__c,
             (SELECT UnitPrice, Pricebook2.Name, CreatedDate, Pricebook2Id
              FROM PricebookEntries
              WHERE Pricebook2.isActive = true
              AND isActive = true
              AND Pricebook2Id IN :pricebookMap.keySet()
              ORDER BY CreatedDate DESC
             )
             FROM Product2
             WHERE RecordType.Name = :recordTypeName
             AND IsActive = True
             AND Id IN :productIdsInPricebook
             ORDER BY Name];
  }

  public  static Map<String, List<ProductWrapper>> groupProductsByFamily(Product2[] products, Boolean includePrice)
  {
    // sort the selectedBoats and group them by selectedBoat type
    Map<String, List<ProductWrapper>> groupedProducts = new Map<String, List<ProductWrapper>>();
    Schema.DescribeFieldResult productTypes = Product2.Family.getDescribe();

    for( Schema.PickListEntry pt : productTypes.getPicklistValues() )
    {
        groupedProducts.put( pt.getLabel(), new List<ProductWrapper>() );
    }
    for( Product2 p :products)
    {
        if( groupedProducts.keySet().contains( p.Family) )
        {
            groupedProducts.get( p.Family ).add( new ProductWrapper(p, includePrice) );
        }
    }
    return groupedProducts;
  }

  private static String buildJSONString(Map<String, List<ProductWrapper>> groupedProducts)
  {
    JSONGenerator json_gen = JSON.createGenerator(true);
    //start JSON object
    json_gen.writeStartObject();
    for( String pFam :groupedProducts.keySet() )
    {
      if( !groupedProducts.get(pFam).isEmpty() )
      {
        json_gen.writeFieldName(pFam);
        json_gen.writeStartArray();
        // this will return everything we queried and null for other fields
        //Or we can customize to show just what we want
        for( ProductWrapper pw : groupedProducts.get(pFam) )
        {
          json_gen.writeStartObject();
          json_gen.writeStringField('id', pw.Id);
          json_gen.writeStringField('name', pw.Name);
          if(pw.RetailPrice != null)
          {
            json_gen.writeNumberField('retail_price', pw.RetailPrice);
          }
          if(pw.PartnerPrice != null)
          {
            json_gen.writeNumberField('partner_price', pw.PartnerPrice);
          }
          if( pw.DefaultImages != null )
          {
            json_gen.writeObjectField('Default Images', pw.DefaultImages);
          }
          if( pw.AllImages != null )
          {
            json_gen.writeObjectField('All Images', pw.AllImages);
          }
          if( pw.Prices != null )
          {
            json_gen.writeObjectField('Prices', pw.Prices);
          }
          json_gen.writeEndObject(); //parent item object
        }
        json_gen.writeEndArray();
      }
    }
    json_gen.writeEndObject(); //END JSON OBJECT
    return json_gen.getAsString();
  }


}