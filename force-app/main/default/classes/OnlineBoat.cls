/**
 * Created by dave on 2020-04-29.
 */

public virtual class OnlineBoat extends Online_Product
{
  @AuraEnabled public Online_Product.Standard standardMotor;
  @AuraEnabled public List<Online_Product.Upgrade> motorUpgrades;
  @AuraEnabled public Online_Product.Standard standardTrailer;
  @AuraEnabled public List<Online_Product.Upgrade> trailerUpgrades;
  @AuraEnabled public Online_Product.Standard standardTrollingMotor;
  @AuraEnabled public List<Online_Product.Upgrade> trollingMotorUpgrades;
  @AuraEnabled public Online_Product.PremiumPackage premiumPackage;
  
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

  public OnlineBoat( Product2 boat )
  {
    super( boat );
    this.allProductIds = new Set<Id>();
    this.allProductOptionIds = new Set<Id>();
    this.marketingContentMap = new Map<Id, List<Marketing_Content__c>>();
    this.product_optionMap = new Map<Id, Product_Option__c>();
    this.optionOwnerMap = new Map<Id, List<Product_Option__c>>();
    this.product_upgradeMap = new Map<Id, List<Product_Upgrade__c>>();
    this.productFee_Map = new Map<Id, List<Product_Fee_Amount__c>>();
    this.optionalUpgradeIds = new Set<Id>();

    init();
  }

  private void init()
  {
    this.allProductIds.add( this.sfProduct.Id );
    this.standardProductIds = new Set<Id>();
    if( this.sfProduct.Standard_Motor__c != null )
      this.standardProductIds.add( this.sfProduct.Standard_Motor__c );
    if( this.sfProduct.Standard_Trailer__c != null )
      this.standardProductIds.add( this.sfProduct.Standard_Trailer__c );
    if( this.sfProduct.Standard_Trolling_Motor__c != null )
      this.standardProductIds.add( this.sfProduct.Standard_Trolling_Motor__c );

    this.allProductIds.addAll( this.standardProductIds );
    this.productPartMap = new Map<Id, List<AcctSeed__Product_Part__c>>();

    this.motorUpgrades = new List<Online_Product.Upgrade>();
    this.trailerUpgrades = new List<Online_Product.Upgrade>();
    this.trollingMotorUpgrades = new List<Online_Product.Upgrade>();

    getOptionsForStandardProductsAndBoatOptions();
    buildUpgradeMap();

    fetchAllMarketingContent();
    fetchAllProductParts();
    fetchAllFees();
    fetchAllProductDetails();
    fetchAllPrices();
    setBoatDetails();
  }

  private void setBoatDetails()
  {

    if( this.pricebookEntryMap.containsKey( this.Id ) )
    {
      PricebookEntry pbe = this.pricebookEntryMap.get( this.id );
      this.pricebookEntryId = pbe.id;
      this.retailPrice = pbe.UnitPrice;
    }

    this.standardMotor = setStandardProduct( this.sfProduct.Standard_Motor__c );
    this.standardTrailer = setStandardProduct( this.sfProduct.Standard_Trailer__c );
    this.standardTrollingMotor = setStandardProduct( this.sfProduct.Standard_Trolling_Motor__c );

    buildUpgrades();

    populate( this );
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
            this.sfProduct.Standard_Motor__c != null ) ||
          ( opt.From_Product__r.RecordTypeId == LGND_Constants.productRtId_Trailer &&
            this.sfProduct.Standard_Trailer__c != null ) ||
          ( opt.From_Product__r.RecordTypeId == LGND_Constants.productRtId_TrollingMotor &&
            this.sfProduct.Standard_Trolling_Motor__c != null ) )
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
    if( parentIds.size() > 0 )
    {
      List<Product_Option__c> childOptions =
        ProductOption_Selector.allChildOptions_AvailableOnline(parentIds);
      if (childOptions.size() > 0)
        buildOptionMap(childOptions);
    }
  }

  private void buildUpgradeMap()
  {
    Set<Id> ids = new Set<Id>();
    if( this.standardProductIds.size() > 0 && this.optionalUpgradeIds.size() > 0 )
    {
      for (Product_Upgrade__c pu :
        ProductUpgrade_Selector.allUpgradesByStandardIdsWithRetailCost(this.standardProductIds, this.optionalUpgradeIds))
      {
        if (pu.Product_Upgrade_Costs__r.size() > 0)
        {
          if (!this.product_upgradeMap.containsKey(pu.From_Product__c))
            this.product_upgradeMap.put(pu.From_Product__c, new List<Product_Upgrade__c>());
          this.product_upgradeMap.get(pu.From_Product__c).add(pu);
          this.allProductIds.add(pu.To_Product__c);
          ids.add(pu.To_Product__c);
        }
      }
      if (ids.size() > 0)
        buildOptionMap(ProductOption_Selector.allChildOptions_AvailableOnline(ids));
    }
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
    for( AcctSeed__Product_Part__c pp : ProductPart_Selector.allForPartKitsByParentIds( this.allProductIds ) )
    {
      if( !this.productPartMap.containsKey( pp.AcctSeed__Product__c ) )
        this.productPartMap.put( pp.AcctSeed__Product__c, new List<AcctSeed__Product_Part__c>() );
      this.productPartMap.get( pp.AcctSeed__Product__c ).add( pp );
      this.allProductIds.add( pp.AcctSeed__Product_Part__c );
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
      this.allProductIds.add( pfa.Fee_Product__c );
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

  private Online_Product.Standard setStandardProduct( Id standardId )
  {
    if( standardId != null &&
      this.allProductsMap.containsKey( standardId ) &&
      this.pricebookEntryMap.containsKey( standardId ) )
    {
      Online_Product.Standard result = new Online_Product.Standard(
        this.allProductsMap.get( standardId ),
        this.pricebookEntryMap.get( standardId )
      );
      populate( result );
      return result;
    }
    return null;
  }

  private void buildUpgrades()
  {
    for( Id standardId : this.product_upgradeMap.keySet() )
    {
      List<Online_Product.Upgrade> upgrades = new List<Online_Product.Upgrade>();
      for( Product_Upgrade__c pu : this.product_upgradeMap.get( standardId ) )
      {
        if( this.allProductsMap.containsKey( pu.To_Product__c ) )
        {
          Online_Product.Upgrade upgrade = new Online_Product.Upgrade(
            this.allProductsMap.get( pu.To_Product__c ),
            pu,
            this.pricebookEntryMap.get( this.Id ).UnitPrice
          );
          populate( upgrade );
          upgrades.add( upgrade );
        }
      }
      if( standardId == this.sfProduct.Standard_Motor__c )
        this.motorUpgrades.addAll( upgrades );
      if( standardId == this.sfProduct.Standard_Trailer__c )
        this.trailerUpgrades.addAll( upgrades );
      if( standardId == this.sfProduct.Standard_Trolling_Motor__c )
        this.trollingMotorUpgrades.addAll( upgrades );
    }
  }

  private Map<String, List<Online_Product.Option>> buildOptions( List<Product_Option__c> options )
  {
    Set<Id> prodRts = new Set<Id>{
      LGND_Constants.productRtId_Motor,
      LGND_Constants.productRtId_Trailer,
      LGND_Constants.productRtId_TrollingMotor
    };
    Map<String, List<Online_Product.Option>> result = new Map<String, List<Online_Product.Option>>();
    for( Product_Option__c opt : options )
    {
      Product2 prod = this.allProductsMap.get( opt.From_Product__c );
      PricebookEntry pbe = this.pricebookEntryMap.get( opt.From_Product__c );
      if( opt.To_Product__c == this.id && prod.Family == 'Premium Package' )
      {
        this.premiumPackage = new Online_Product.PremiumPackage( prod, pbe );
        if( this.marketingContentMap.containsKey( prod.Id ) )
          this.premiumPackage.addMarketingContent( this.marketingContentMap.get( prod.Id ) );
      }
      else
      {
        Online_Product.Option oop = new Online_Product.Option(prod, opt, pbe);
        populate( oop );

        String label;
        if( prodRts.contains( prod.RecordType.Id ) )
          label = prod.RecordType.Name;
        else
          label = prod.Family;

        label = LGND_Utilities.toCamelCase( label );
        if (!result.containsKey(label))
          result.put(label, new List<Online_Product.Option>());
        result.get(label).add( oop );
      }
    }
    return result;
  }

  private void populate( Online_Product op)
  {
    if( this.optionOwnerMap.containsKey( op.id ) )
    {
      op.optionalProducts = buildOptions( this.optionOwnerMap.get( op.id ) );
    }

    if( this.marketingContentMap.containsKey( op.id ) )
    {
      op.addMarketingContent( this.marketingContentMap.get( op.id ) );
    }

    if( this.product_optionMap.containsKey( op.id ) )
    {
      Product_Option__c opt = this.product_optionMap.get( op.id );
      if( this.marketingContentMap.containsKey( opt.Id ) )
      {
        op.addMarketingContent( this.marketingContentMap.get( opt.Id ) );
      }
    }

    if( this.productFee_Map.containsKey( op.id ) )
    {
      for( Product_Fee_Amount__c pfa : this.productFee_Map.get( op.id ) )
      {
        Product2 prod = this.allProductsMap.get( pfa.Fee_Product__c );
        PricebookEntry pbe = this.pricebookEntryMap.containsKey( pfa.Fee_Product__c ) ?
          this.pricebookEntryMap.get( pfa.Fee_Product__c ) : null;
        op.addAdditionalFee( prod, pbe, pfa );
      }
    }

    if( this.productPartMap.containsKey( op.id ) )
    {
      for( AcctSeed__Product_Part__c pp : this.productPartMap.get( op.id ) )
      {
        Product2 prod = this.allProductsMap.get( pp.AcctSeed__Product_Part__c );
        PricebookEntry pbe = this.pricebookEntryMap.containsKey( pp.AcctSeed__Product_Part__c ) ?
          this.pricebookEntryMap.get( pp.AcctSeed__Product_Part__c ) : null;
        op.addKitComponent( prod, pbe, pp );
      }
    }

  }

}



