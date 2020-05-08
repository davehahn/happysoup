/**
 * Created by dave on 2020-05-08.
 */

public virtual class Online_Product
{
  @AuraEnabled public String id;
  @AuraEnabled public String name;
  @AuraEnabled public String details;
  @AuraEnabled public Decimal retailPrice;
  @AuraEnabled public String pricebookEntryId;
  @AuraEnabled public String imageURL;
  @AuraEnabled public Map<String, List<Option>> optionalProducts;
  @AuraEnabled public List<KitComponent> kitComponents;
  @AuraEnabled public List<MarketingContent> marketingContent;
  @AuraEnabled public Map<String, List<ProvincialFee>> additionalFees;

  protected Product2 sfProduct;

  public Online_Product( Product2 prod )
  {
    this.sfProduct = prod;
    this.id = prod.Id;
    this.name = prod.Name;
    this.imageURL = prod.Default_Gallery_Image_Original__c;
    this.optionalProducts = new Map<String, List<Option>>();
    this.marketingContent = new List<MarketingContent>();
    this.additionalFees = new Map<String, List<ProvincialFee>>();
  }

  public Online_Product( Product2 prod, PricebookEntry pbe )
  {
    this.sfProduct = prod;
    this.id = prod.Id;
    this.name = prod.Name;
    this.imageURL = prod.Default_Gallery_Image_Original__c;
    this.optionalProducts = new Map<String, List<Option>>();
    this.pricebookEntryId = pbe.Id;
    this.retailPrice = pbe.UnitPrice;
    this.marketingContent = new List<MarketingContent>();
    this.additionalFees = new Map<String, List<ProvincialFee>>();
  }

  public void addMarketingContent( List<Marketing_Content__c> marketingContent )
  {
    for( Marketing_Content__c mc : marketingContent )
    {
      this.marketingContent.add( new MarketingContent( mc ) );
    }
  }

  public void addKitComponent( Product2 prod, PricebookEntry pbe, AcctSeed__Product_Part__c pp )
  {
    if (this.kitComponents == null)
      this.kitComponents = new List<KitComponent>();
    this.kitComponents.add( new KitComponent( prod, pbe, pp ) );
  }

  public void addAdditionalFee( Product2 prod, PricebookEntry pbe, Product_Fee_Amount__c pfa )
  {
    if( this.additionalFees == null )
      this.additionalFees = new Map<String, List<ProvincialFee>>();
    if( pfa.Province__c != null && !this.additionalFees.containsKey( pfa.Province__c ) )
      this.additionalFees.put( pfa.Province__c, new List<ProvincialFee>() );
    this.additionalFees.get( pfa.Province__c ).add( new ProvincialFee( prod, pbe, pfa ) );
  }

  public virtual class Standard extends Online_Product
  {
    public Standard( Product2 prod, PricebookEntry pbe )
    {
      super( prod, pbe );
      this.retailPrice = 0.00;
    }
  }

  public virtual class Option extends Online_Product
  {
    @AuraEnabled public Decimal standard;
    @AuraEnabled public Decimal maximum;

    public Option( Product2 prod, Product_Option__c opt, PricebookEntry pbe )
    {
      super( prod, pbe );
      this.standard = opt.Standard__c;
      this.maximum = opt.Maximum__c;
    }
  }

  public virtual class Upgrade extends Online_Product
  {
    @AuraEnabled public Decimal RetailUpgradeCost;
    @AuraEnabled public Decimal WeeklyUpgradeCost;

    public Upgrade( Product2 prod, Product_Upgrade__c upgrade, Decimal boatPrice )
    {
      super( prod );
      this.RetailUpgradeCost = upgrade.Product_Upgrade_Costs__r[0].Cost__c;
      this.WeeklyUpgradeCost = calcWeeklyCost( boatPrice );
    }

    private Decimal calcWeeklyCost( Decimal boatPrice )
    {
      /* calculate using this.RetailUpgradeCost and ParentRetailPrice */
      if( this.RetailUpgradeCost != null )
      {
        PaymentCalculator pc = new PaymentCalculator( this.RetailUpgradeCost + boatPrice );
        return pc.calculateWeeklyPayment( this.RetailUpgradeCost );
      }
      return null;
    }
  }

  public virtual class PremiumPackage extends Online_Product
  {
    @AuraEnabled public  Decimal value;
    @AuraEnabled public Map<String, List<String>> contents;

    public PremiumPackage( Product2 prod, PricebookEntry pbe )
    {
      super( prod, pbe );
      this.retailPrice = 0;
      this.value = pbe.UnitPrice;
      this.contents = new Map<String, List<String>>();
      processContents();
    }

    private void processContents()
    {
      for( Product_Feature_Map__c pfmap : [
        SELECT
          Id,
          Feature_Id__r.description__c,
          Feature_Id__r.description_fr__c,
          Feature_Id__r.Category__c
        FROM Product_Feature_Map__c
        WHERE Product_Id__c = :this.id ] )
      {
        if( !this.contents.containsKey( pfmap.Feature_Id__r.Category__c) )
          this.contents.put(  pfmap.Feature_Id__r.Category__c, new List<String>() );
        this.contents.get(  pfmap.Feature_Id__r.Category__c ).add( pfmap.Feature_Id__r.description__c );
      }
    }
  }

  public virtual class MarketingContent
  {
    @AuraEnabled public String label;
    @AuraEnabled public String content;

    public MarketingContent( Marketing_Content__c mc )
    {
      this.label = mc.Label__c;
      this.content = mc.Content__c;
    }
  }

  public virtual class KitComponent extends Online_Product
  {
    @AuraEnabled public Decimal quantity;

    public KitComponent( Product2 prod, PricebookEntry pbe, AcctSeed__Product_Part__c pp )
    {
      super( prod );
      this.quantity = pp.AcctSeed__Quantity__c;
      this.pricebookEntryId = pbe == null ? null : pbe.Id;
    }
  }

  public virtual class ProvincialFee extends Online_Product
  {
    @AuraEnabled public String province;


    public ProvincialFee( Product2 prod,
                          PricebookEntry pbe,
                          Product_Fee_Amount__c feeAmount )
    {
      super( prod );
      this.province = feeAmount.Province__c;
      this.retailPrice = feeAmount.Amount__c;
      this.pricebookEntryId = pbe == null ? null : pbe.Id;
    }

//    public ProvincialFee( Product_Fee_Amount__c feeAmount )
//    {
//      this.province = feeAmount.Province__c;
//      this.feeProductId = feeAmount.Fee_Product__c;
//      this.name = feeAmount.Fee_Product__r.Name;
//      this.amount = feeAmount.Amount__c;
//    }
  }
}