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
  @AuraEnabled public List<OnlineOptionalProduct> optionalProducts;

  private Product2 boat;
  private Set<Id> allProductIds;

  public OnlineBoat( Id boatId )
  {
    this.allProductIds = new Set<Id>();
    this.id = boatId;
    init();
  }

  private void init()
  {
    this.boat = Product_Selector.getOnlineBoat( this.id );
    this.allProductIds.add( this.boat.Id );
    setBoatDetails();
    this.optionalProducts = buildOptions( this.boat.To_Product_Options__r );
    setAllPrices();
  }

  private void setBoatDetails()
  {
    this.name = this.boat.Name;
  }

  private List<OnlineOptionalProduct> buildOptions( List<Product_Option__c> options )
  {
    List<OnlineOptionalProduct> result = new List<OnlineOptionalProduct>();
    Map<Id, Product_Option__c> prodId_optionMap = new Map<Id, Product_Option__c>();
    for( Product_Option__c opt : options )
    {
      prodId_optionMap.put( opt.From_Product__c , opt );
    }
    for( Product2 p : Product_Selector.allWithFullDetailsById( prodId_optionMap.keySet() ) )
    {
      this.allProductIds.add( p.Id );
      result.add( new OnlineOptionalProduct( p, prodId_optionMap.get( p.Id ) ) );
    }
    return result;
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

    public OnlineProduct( Product2 prod )
    {
      this.id = prod.Id;
      this.name = prod.Name;
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



