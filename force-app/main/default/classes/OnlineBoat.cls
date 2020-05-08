/**
 * Created by dave on 2020-04-29.
 */

public without sharing class OnlineBoat
{
  @AuraEnabled public String id;
  @AuraEnabled public String name;
  @AuraEnabled public String details;
  @AuraEnabled public String imageURL;
  @AuraEnabled public String pricebookEntryId;
  @AuraEnabled public Decimal retailPrice;
  @AuraEnabled public OnlineStandardProduct standardMotor;
  @AuraEnabled public List<OnlineProductUpgrade> motorUpgrades;
  @AuraEnabled public OnlineStandardProduct standardTrailer;
  @AuraEnabled public List<OnlineProductUpgrade> trailerUpgrades;
  @AuraEnabled public OnlineStandardProduct standardTrollingMotor;
  @AuraEnabled public Map<String, List<OnlineOptionalProduct>> optionalProducts;
  @AuraEnabled public List<OnlineProductUpgrade> trollingMotorUpgrades;
  @AuraEnabled public OnlinePremiumPackage premiumPackage;
  @AuraEnabled public List<OnlineMarketingContent> marketingContent;
  @AuraEnabled public Map<String, List<OnlineProvincialFee>> additionalFees;

  private Product2 boatProduct;
  private Set<Id> allProductIds;
  private Set<Id> allProductOptionIds;
  private Map<Id, Product2> allProductsMap;
  private Map<Id, PricebookEntry> pricebookEntryMap;
  private Set<Id> standardProductIds;
  private Set<Id> optionalUpgradeIds;
  private Map<Id, List<Marketing_Content__c>> marketingContentMap;
  private Map<Id, List<AcctSeed__Product_Part__c>> productPartMap;
  private Map<Id, List<Product_Fee_Amount__c>> productFee_Map;
  private Map<Id, Product_Option__c> product_optionMap; // optionalProductId => Option
  private Map<Id, List<Product_Option__c>> optionOwnerMap;// parentProductId => List<Options>
  private Map<Id, List<Product_Upgrade__c>> product_upgradeMap;// standardId => List<Upgrades>

  public OnlineBoat( Id boatId )
  {
    this.allProductIds = new Set<Id>();
    this.allProductOptionIds = new Set<Id>();
    this.marketingContentMap = new Map<Id, List<Marketing_Content__c>>();
    this.product_optionMap = new Map<Id, Product_Option__c>();
    this.optionOwnerMap = new Map<Id, List<Product_Option__c>>();
    this.product_upgradeMap = new Map<Id, List<Product_Upgrade__c>>();
    this.productFee_Map = new Map<Id, List<Product_Fee_Amount__c>>();
    this.optionalUpgradeIds = new Set<Id>();
    this.id = boatId;
    init();
  }

  private void init()
  {
    this.boatProduct = Product_Selector.getOnlineBoat( this.id );
    this.allProductIds.add( this.boatProduct.Id );
    this.standardProductIds = new Set<Id>();
    if( this.boatProduct.Standard_Motor__c != null )
      this.standardProductIds.add( this.boatProduct.Standard_Motor__c );
    if( this.boatProduct.Standard_Trailer__c != null )
      this.standardProductIds.add( this.boatProduct.Standard_Trailer__c );
    if( this.boatProduct.Standard_Trolling_Motor__c != null )
      this.standardProductIds.add( this.boatProduct.Standard_Trolling_Motor__c );

    this.allProductIds.addAll( this.standardProductIds );
    this.optionalProducts = new Map<String, List<OnlineOptionalProduct>>();
    this.marketingContent = new List<OnlineMarketingContent>();
    this.additionalFees = new Map<String, List<OnlineProvincialFee>>();
    this.productPartMap = new Map<Id, List<AcctSeed__Product_Part__c>>();

    this.motorUpgrades = new List<OnlineProductUpgrade>();
    this.trailerUpgrades = new List<OnlineProductUpgrade>();
    this.trollingMotorUpgrades = new List<OnlineProductUpgrade>();

    getOptionsForStandardProductsAndBoatOptions();
    buildUpgradeMap();

    fetchAllProductDetails();
    fetchAllMarketingContent();
    fetchAllProductParts();
    fetchAllFees();
    fetchAllPrices();
    setBoatDetails();
  }

  private void setBoatDetails()
  {
    this.name = this.boatProduct.Name;
    this.imageURL = this.boatProduct.Default_Gallery_Image_Original__c;

    if( this.pricebookEntryMap.containsKey( this.Id ) )
    {
      PricebookEntry pbe = this.pricebookEntryMap.get( this.id );
      this.pricebookEntryId = pbe.id;
      this.retailPrice = pbe.UnitPrice;
    }

    this.standardMotor = setStandardProduct( this.boatProduct.Standard_Motor__c );
    this.standardTrailer = setStandardProduct( this.boatProduct.Standard_Trailer__c );
    this.standardTrollingMotor = setStandardProduct( this.boatProduct.Standard_Trolling_Motor__c );

    buildUpgrades();

    if( this.optionOwnerMap.containsKey( this.id ) )
    {
      this.optionalProducts = buildOptions( this.optionOwnerMap.get( this.id ) );
    }

    if( this.marketingContentMap.containsKey( this.id ) )
    {
      for( Marketing_Content__c mc : this.marketingContentMap.get( this.id ) )
      {
        this.marketingContent.add( new OnlineMarketingContent( mc ) );
      }
    }

    if( this.productFee_Map.containsKey( this.id ) )
    {
      for( Product_Fee_Amount__c pfa : this.productFee_Map.get( this.id ) )
      {
        if( !this.additionalFees.containsKey( pfa.Province__c ) && pfa.Province__c != null )
          this.additionalFees.put( pfa.Province__c, new List<OnlineProvincialFee>() );
        this.additionalFees.get( pfa.Province__c ).add( new OnlineProvincialFee( pfa ) );
      }
    }

  }

  private OnlineStandardProduct setStandardProduct( Id standardId )
  {
    if( standardId != null &&
        this.allProductsMap.containsKey( standardId ) &&
        this.pricebookEntryMap.containsKey( standardId ) )
    {
       OnlineStandardProduct result = new OnlineStandardProduct(
        this.allProductsMap.get( standardId ),
        this.pricebookEntryMap.get( standardId )
      );
      if( this.optionOwnerMap.containsKey( standardId ) )
      {
        result.optionalProducts = buildOptions(
          this.optionOwnerMap.get( standardId )
        );
      }
      if( this.marketingContentMap.containsKey( standardId ) )
      {
        result.addMarketingContent( this.marketingContentMap.get( standardId ) );
      }
      if( this.product_optionMap.containsKey( standardId ) )
      {
        Product_Option__c opt = this.product_optionMap.get( standardId );
        if( this.marketingContentMap.containsKey( opt.Id ) )
        {
          result.addMarketingContent( this.marketingContentMap.get( opt.Id ) );
        }
      }
      if( this.productFee_Map.containsKey( standardId ) )
      {
        result.addProvincialFees( this.productFee_Map.get( standardId ) );
      }
      return result;
    }
    return null;
  }

  private void buildOptionMap( List<Product_Option__c> options )
  {
    Set<Id> parentIds = new Set<Id>();
    for( Product_Option__c opt : options )
    {
      this.allProductIds.add( opt.From_Product__c );
      this.allProductOptionIds.add( opt.Id );
      this.product_optionMap.put( opt.From_Product__c , opt );

      if( ( opt.From_Product__r.RecordTypeId == LGND_Constants.productRtId_Motor &&
            this.boatProduct.Standard_Motor__c != null ) ||
          ( opt.From_Product__r.RecordTypeId == LGND_Constants.productRtId_Trailer &&
            this.boatProduct.Standard_Trailer__c != null ) ||
          ( opt.From_Product__r.RecordTypeId == LGND_Constants.productRtId_TrollingMotor &&
            this.boatProduct.Standard_Trolling_Motor__c != null ) )
      {
        this.optionalUpgradeIds.add(opt.From_Product__c);
      }
      else
      {
        parentIds.add( opt.From_Product__c );
        if (!this.optionOwnerMap.containsKey(opt.To_Product__c))
        {
          this.optionOwnerMap.put(opt.To_Product__c, new List<Product_Option__c>());
        }
        this.optionOwnerMap.get(opt.To_Product__c).add(opt);
      }
    }
    List<Product_Option__c> childOptions =
      ProductOption_Selector.allChildOptions_AvailableOnline( parentIds );
    if( childOptions.size() > 0 )
      buildOptionMap( childOptions );
  }

  private void buildUpgradeMap()
  {
    Set<Id> ids = new Set<Id>();
    for( Product_Upgrade__c pu :
         ProductUpgrade_Selector.allUpgradesByStandardIdsWithRetailCost( this.standardProductIds, this.optionalUpgradeIds ) )
    {
      if( pu.Product_Upgrade_Costs__r.size() > 0 )
      {
        if( !this.product_upgradeMap.containsKey(pu.From_Product__c) )
          this.product_upgradeMap.put( pu.From_Product__c, new List<Product_Upgrade__c>() );
        this.product_upgradeMap.get( pu.From_Product__c ).add( pu );
        this.allProductIds.add( pu.To_Product__c );
        ids.add( pu.To_Product__c );
      }
    }
    buildOptionMap( ProductOption_Selector.allChildOptions_AvailableOnline( ids ) );
  }

  private void getOptionsForStandardProductsAndBoatOptions()
  {
    Set<Id> prodIds = new Set<Id>{ this.id };
    prodIds.addAll( this.standardProductIds );
    buildOptionMap( ProductOption_Selector.allChildOptions_AvailableOnline( prodIds ) );
  }

  private void fetchAllProductDetails()
  {
    this.allProductsMap = new Map<Id, Product2>();
    for( Product2 p : Product_Selector.allWithFullDetailsById( this.allProductIds ) )
    {
      this.allProductsMap.put( p.Id, p );
    }
  }

  private void fetchAllProductParts()
  {
    System.debug( ProductPart_Selector.allForPartKitsByParentIds( this.allProductIds ) );
    for( AcctSeed__Product_Part__c pp : ProductPart_Selector.allForPartKitsByParentIds( this.allProductIds ) )
    {
      if( !this.productPartMap.containsKey( pp.AcctSeed__Product__c ) )
        this.productPartMap.put( pp.AcctSeed__Product__c, new List<AcctSeed__Product_Part__c>() );
      this.productPartMap.get( pp.AcctSeed__Product__c ).add( pp );
    }
  }

  private void fetchAllMarketingContent()
  {
    Set<Id> allIds = new Set<Id>();
    allIds.addAll( this.allProductIds );
    allIds.addAll( this.allProductOptionIds );
    for( Marketing_Content__c mc : MarketingContent_Selector.allByProductAndProductOption( allIds ) )
    {
      if( mc.Product__c != null )
      {
        if( !this.marketingContentMap.containsKey( mc.Product__c ) )
        {
          this.marketingContentMap.put( mc.Product__c, new List<Marketing_Content__c>() );
        }
        this.marketingContentMap.get( mc.Product__c ).add( mc );
      }
      if( mc.Product_Option__c != null )
      {
        if( !this.marketingContentMap.containsKey( mc.Product_Option__c ) )
        {
          this.marketingContentMap.put( mc.Product_Option__c, new List<Marketing_Content__c>() );
        }
        this.marketingContentMap.get( mc.Product_Option__c ).add( mc );
      }
    }
  }

  private void fetchAllFees()
  {
    Id retailPbId = LGND_Constants.retailPricebookId;
    Map<Id, Id> fee_parent_map = new Map<Id, Id>();
    for( Product_Fee_Map__c pfm : ProductFeeMap_Selector.allProductFeeMapsByParentProductId( this.allProductIds ) )
    {

      if( !this.productFee_Map.containsKey( pfm.Parent_Product__c ) )
        this.productFee_Map.put( pfm.Parent_Product__c, new List<Product_Fee_Amount__c>() );
      fee_parent_map.put( pfm.Fee_Product__c, pfm.Parent_Product__c );
    }

    for( Product_Fee_Amount__c pfa : [ SELECT Id, Province__c, Amount__c, Fee_Product__c, Fee_Product__r.Name FROM Product_Fee_Amount__c WHERE Fee_Product__c IN :fee_parent_map.keySet() AND Price_Book__c = :retailPbId ])
    {
      this.productFee_Map.get( fee_parent_map.get( pfa.Fee_Product__c ) ).add( pfa );
    }
  }

  private void fetchAllPrices()
  {
    this.pricebookEntryMap = new Map<Id, PricebookEntry>();
    for( PricebookEntry pbe : PricebookEntry_Selector.allRetailEntriesByProductId( this.allProductIds ) )
    {
      this.pricebookEntryMap.put( pbe.Product2Id, pbe );
    }
  }

  private void buildUpgrades()
  {
    for( Id standardId : this.product_upgradeMap.keySet() )
    {
      List<OnlineProductUpgrade> upgrades = new List<OnlineProductUpgrade>();
      for( Product_Upgrade__c pu : this.product_upgradeMap.get( standardId ) )
      {
        if( this.allProductsMap.containsKey( pu.To_Product__c ) )
        {
          OnlineProductUpgrade upgrade = new OnlineProductUpgrade(
            this.allProductsMap.get( pu.To_Product__c ),
            pu,
            this.pricebookEntryMap.get( this.Id ).UnitPrice
          );
          if( this.optionOwnerMap.containsKey( pu.To_Product__c ) )
          {
            upgrade.optionalProducts = buildOptions( this.optionOwnerMap.get( pu.To_Product__c ) );
          }
          if( this.marketingContentMap.containsKey( upgrade.id ) )
          {
            upgrade.addMarketingContent( this.marketingContentMap.get( upgrade.id ) );
          }
          if( this.product_optionMap.containsKey( upgrade.id ) )
          {
            Product_Option__c opt = this.product_optionMap.get( upgrade.id );
            if( this.marketingContentMap.containsKey( opt.Id ) )
            {
              upgrade.addMarketingContent( this.marketingContentMap.get( opt.Id ) );
            }
          }
          if( this.productFee_Map.containsKey( upgrade.id ) )
          {
            upgrade.addProvincialFees( this.productFee_Map.get( upgrade.Id ) );
          }
          upgrades.add( upgrade );
        }
      }
      if( standardId == this.boatProduct.Standard_Motor__c )
        this.motorUpgrades.addAll( upgrades );
      if( standardId == this.boatProduct.Standard_Trailer__c )
        this.trailerUpgrades.addAll( upgrades );
      if( standardId == this.boatProduct.Standard_Trolling_Motor__c )
        this.trollingMotorUpgrades.addAll( upgrades );
    }
  }

  private Map<String, List<OnlineOptionalProduct>> buildOptions( List<Product_Option__c> options )
  {
    Set<Id> prodRts = new Set<Id>{
      LGND_Constants.productRtId_Motor,
      LGND_Constants.productRtId_Trailer,
      LGND_Constants.productRtId_TrollingMotor
    };
    Map<String, List<OnlineOptionalProduct>> result = new Map<String, List<OnlineOptionalProduct>>();
    for( Product_Option__c opt : options )
    {
      Product2 prod = this.allProductsMap.get( opt.From_Product__c );
      PricebookEntry pbe = this.pricebookEntryMap.get( opt.From_Product__c );
      if( opt.To_Product__c == this.id && prod.Family == 'Premium Package' )
      {
        this.premiumPackage = new OnlinePremiumPackage( prod, pbe );
        if( this.marketingContentMap.containsKey( prod.Id ) )
          this.premiumPackage.addMarketingContent( this.marketingContentMap.get( prod.Id ) );
      }
      else
      {
        OnlineOptionalProduct oop = new OnlineOptionalProduct(prod, opt, pbe);
        if( this.optionOwnerMap.containsKey( oop.id ) )
        {
          oop.optionalProducts = buildOptions( this.optionOwnerMap.get( oop.id ) );
        }

        if( this.marketingContentMap.containsKey( prod.Id ) )
          oop.addMarketingContent( this.marketingContentMap.get( prod.Id ) );
        if( this.marketingContentMap.containsKey( opt.Id ) )
          oop.addMarketingContent( this.marketingContentMap.get( opt.Id ) );

        if( this.productPartMap.containsKey( prod.Id ) )
        {
          oop.addKitContents( this.productPartMap.get( prod.Id ) );
        }

        if( this.productFee_Map.containsKey( prod.Id ) )
        {
          oop.addProvincialFees( this.productFee_Map.get( prod.Id ) );
        }

        String label;
        if( prodRts.contains( prod.RecordType.Id ) )
          label = prod.RecordType.Name;
        else
          label = prod.Family;

        label = LGND_Utilities.toCamelCase( label );
        if (!result.containsKey(label))
          result.put(label, new List<OnlineOptionalProduct>());
        result.get(label).add( oop );
      }
    }
    return result;
  }

  public virtual class OnlineProduct
  {
    @AuraEnabled public String id;
    @AuraEnabled public String name;
    @AuraEnabled public String details;
    @AuraEnabled public Decimal retailPrice;
    @AuraEnabled public String pricebookEntryId;
    @AuraEnabled public String imageURL;
    @AuraEnabled public Map<String, List<OnlineOptionalProduct>> optionalProducts;
    @AuraEnabled public List<OnlineKitContent> kitContents;
    @AuraEnabled public List<OnlineMarketingContent> marketingContent;
    @AuraEnabled public Map<String, List<OnlineProvincialFee>> additionalFees;

    public OnlineProduct( Product2 prod )
    {
      this.id = prod.Id;
      this.name = prod.Name;
      this.imageURL = prod.Default_Gallery_Image_Original__c;
      this.optionalProducts = new Map<String, List<OnlineOptionalProduct>>();
      this.marketingContent = new List<OnlineMarketingContent>();
      this.additionalFees = new Map<String, List<OnlineProvincialFee>>();
    }

    public OnlineProduct( Product2 prod, PricebookEntry pbe )
    {
      this.id = prod.Id;
      this.name = prod.Name;
      this.imageURL = prod.Default_Gallery_Image_Original__c;
      this.optionalProducts = new Map<String, List<OnlineOptionalProduct>>();
      this.pricebookEntryId = pbe.Id;
      this.retailPrice = pbe.UnitPrice;
      this.marketingContent = new List<OnlineMarketingContent>();
      this.additionalFees = new Map<String, List<OnlineProvincialFee>>();
    }

    public void addMarketingContent( List<Marketing_Content__c> marketingContent )
    {
      for( Marketing_Content__c mc : marketingContent )
      {
        this.marketingContent.add( new OnlineMarketingContent( mc ) );
      }
    }

    public void addKitContents( List<AcctSeed__Product_Part__c> productParts )
    {
      if( this.kitContents == null )
        this.kitContents = new List<OnlineKitContent>();
      for( AcctSeed__Product_Part__c pp : productParts )
      {
        this.kitContents.add( new OnlineKitContent( pp ) );
      }
    }

    public void addProvincialFees( List<Product_Fee_Amount__c> feeAmounts )
    {
      for( Product_Fee_Amount__c pfa : feeAmounts )
      {
        if( pfa.Province__c != null && !this.additionalFees.containsKey( pfa.Province__c ) )
          this.additionalFees.put( pfa.Province__c, new List<OnlineProvincialFee>() );
        this.additionalFees.get( pfa.Province__c ).add( new OnlineProvincialFee( pfa ) );
      }
    }
  }

  public virtual class OnlineStandardProduct extends OnlineProduct
  {
    public OnlineStandardProduct( Product2 prod, PricebookEntry pbe )
    {
      super( prod, pbe );
      this.retailPrice = 0.00;
    }
  }

  public virtual class OnlineProductUpgrade extends OnlineProduct
  {
    @AuraEnabled public Decimal RetailUpgradeCost;
    @AuraEnabled public Decimal WeeklyUpgradeCost;

    public OnlineProductUpgrade( Product2 prod, Product_Upgrade__c upgrade, Decimal boatPrice )
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

  public virtual class OnlineOptionalProduct extends OnlineProduct
  {
    @AuraEnabled public Decimal standard;
    @AuraEnabled public Decimal maximum;

    public OnlineOptionalProduct( Product2 prod, Product_Option__c opt, PricebookEntry pbe )
    {
      super( prod, pbe );
      this.standard = opt.Standard__c;
      this.maximum = opt.Maximum__c;
    }
  }

  public virtual class OnlinePremiumPackage extends OnlineProduct
  {
    @AuraEnabled public  Decimal value;
    @AuraEnabled public Map<String, List<String>> contents;

    public OnlinePremiumPackage( Product2 prod, PricebookEntry pbe )
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

  public virtual class OnlineMarketingContent
  {
    @AuraEnabled public String label;
    @AuraEnabled public String content;

    public OnlineMarketingContent( Marketing_Content__c mc )
    {
      this.label = mc.Label__c;
      this.content = mc.Content__c;
    }
  }

  public virtual class OnlineKitContent
  {
    @AuraEnabled public String name;
    @AuraEnabled public Decimal quantity;

    public OnlineKitContent( AcctSeed__Product_Part__c pp )
    {
      this.name = pp.AcctSeed__Product_Part__r.Name;
      this.quantity = pp.AcctSeed__Quantity__c;
    }
  }

  public virtual class OnlineProvincialFee
  {
    @AuraEnabled public String province;
    @AuraEnabled public String feeProductId;
    @AuraEnabled public String name;
    @AuraEnabled public Decimal amount;

    public OnlineProvincialFee( Product_Fee_Amount__c feeAmount )
    {
      this.province = feeAmount.Province__c;
      this.feeProductId = feeAmount.Fee_Product__c;
      this.name = feeAmount.Fee_Product__r.Name;
      this.amount = feeAmount.Amount__c;
    }
  }
}



