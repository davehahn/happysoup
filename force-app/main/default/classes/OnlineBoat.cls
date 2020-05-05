/**
 * Created by dave on 2020-04-29.
 */

public with sharing class OnlineBoat
{
  @AuraEnabled public String id;
  @AuraEnabled public String name;
  @AuraEnabled public String details;
  @AuraEnabled public String pricebookEntryId;
  @AuraEnabled public Decimal retailPrice;
  @AuraEnabled public OnlineStandardProduct standardMotor;
  @AuraEnabled public List<OnlineProductUpgrade> motorUpgrades;
  @AuraEnabled public OnlineStandardProduct standardTrailer;
  @AuraEnabled public List<OnlineProductUpgrade> trailerUpgrades;
  @AuraEnabled public OnlineStandardProduct standardTrollingMotor;
  @AuraEnabled public List<OnlineOptionalProduct> optionalProducts;
  @AuraEnabled public List<OnlineProductUpgrade> trollingMotorUpgrades;

  private Product2 boatProduct;
  private Set<Id> allProductIds;
  private Map<Id, Product2> allProductsMap;
  private Map<Id, PricebookEntry> pricebookEntryMap;
  private Set<Id> standardProductIds;
  private Map<Id, Product_Option__c> product_optionMap; // optionalProductId => Option
  private Map<Id, List<Product_Option__c>> optionOwnerMap;// parentProductId => List<Options>
  private Map<Id, List<Product_Upgrade__c>> product_upgradeMap;// standardId => List<Upgrades>

  public OnlineBoat( Id boatId )
  {
    this.allProductIds = new Set<Id>();
    this.product_optionMap = new Map<Id, Product_Option__c>();
    this.optionOwnerMap = new Map<Id, List<Product_Option__c>>();
    this.product_upgradeMap = new Map<Id, List<Product_Upgrade__c>>();
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

    setBoatDetails();
    buildOptionMap( this.boatProduct.To_Product_Options__r );
    buildUpgradeMap();

    getOptionsForStandardProductsAndBoatOptions();

    fetchAllProductDetails();
    fetchAllPrices();

    buildUpgrades();

  }

  private void setBoatDetails()
  {
    this.name = this.boatProduct.Name;
    this.motorUpgrades = new List<OnlineProductUpgrade>();
    this.trailerUpgrades = new List<OnlineProductUpgrade>();
    this.trollingMotorUpgrades = new List<OnlineProductUpgrade>();
  }

  private void buildOptionMap( List<Product_Option__c> options )
  {
    for( Product_Option__c opt : options )
    {
      this.allProductIds.add( opt.From_Product__c );
      this.product_optionMap.put( opt.From_Product__c , opt );
      if( !this.optionOwnerMap.containsKey( opt.To_Product__c) )
      {
        this.optionOwnerMap.put( opt.To_Product__c, new List<Product_Option__c>() );
      }
      this.optionOwnerMap.get( opt.To_Product__c ).add( opt );
    }
  }

  private void buildUpgradeMap()
  {
    for( Product_Upgrade__c pu :
         ProductUpgrade_Selector.allUpgradesByStandardIdsWithRetailCost( this.standardProductIds ) )
    {
      if( pu.Product_Upgrade_Costs__r.size() > 0 )
      {
        if( !this.product_upgradeMap.containsKey(pu.From_Product__c) )
          this.product_upgradeMap.put( pu.From_Product__c, new List<Product_Upgrade__c>() );
        this.product_upgradeMap.get( pu.From_Product__c ).add( pu );
        this.allProductIds.add( pu.To_Product__c );
      }
    }
  }

  private void getOptionsForStandardProductsAndBoatOptions()
  {
    Set<Id> prodIds = new Set<Id>();
    prodIds.addAll( this.standardProductIds );
    for( Product_Option__c po : this.product_optionMap.values() )
    {
      prodIds.add( po.From_Product__c );
    }
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
          upgrades.add( new OnlineProductUpgrade(
            this.allProductsMap.get( pu.To_Product__c ),
            pu,
            this.pricebookEntryMap.get( this.Id ).UnitPrice
          ));
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

  private void setAllPrices()
  {
    Map<Id, PricebookEntry> prodId_pbEntry_Map = new Map<Id, PricebookEntry>();
    for( PricebookEntry pbe : PricebookEntry_Selector.allRetailEntriesByProductId( this.allProductIds ) )
    {
      prodId_pbEntry_Map.put( pbe.Product2Id, pbe );
    }
    if( prodId_pbEntry_Map.containsKey( this.id ) )
    {
      this.retailPrice = prodId_pbEntry_Map.get( this.id ).UnitPrice;
      this.pricebookEntryId = prodId_pbEntry_Map.get( this.id ).Id;
    }
    for( OnlineOptionalProduct oop : this.optionalProducts )
    {
      if( prodId_pbEntry_Map.containsKey( oop.id ) )
      {
        oop.pricebookEntryId = prodId_pbEntry_Map.get( oop.id ).Id;
        oop.retailPrice = prodId_pbEntry_Map.get( oop.id ).UnitPrice;
      }
    }
  }

  public virtual class OnlineProduct
  {
    @AuraEnabled public String id;
    @AuraEnabled public String name;
    @AuraEnabled public String details;
    @AuraEnabled public Decimal retailPrice;
    @AuraEnabled public String pricebookEntryId;
    @AuraEnabled public List<OnlineOptionalProduct> optionalProducts;

    public OnlineProduct( Product2 prod )
    {
      this.id = prod.Id;
      this.name = prod.Name;
      this.optionalProducts = new List<OnlineOptionalProduct>();
    }
  }

  public virtual class OnlineStandardProduct extends OnlineProduct
  {
    public OnlineStandardProduct( Product2 prod )
    {
      super( prod );
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


  public virtual class OnlineOptionalProduct extends OnlineProduct{
    @AuraEnabled public Decimal standard;
    @AuraEnabled public Decimal maximum;

    public OnlineOptionalProduct( Product2 prod, Product_Option__c opt )
    {
      super( prod );
      this.standard = opt.Standard__c;
      this.maximum = opt.Maximum__c;
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
}



