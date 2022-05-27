/**
 * Created by dave on 2022-05-26.
 */

public inherited sharing class Product_ActivePrices_Controller
{

  public class ActivePricesWrapper {
    private Id prodId;
    @AuraEnabled public PriceDetail retail;
    @AuraEnabled public PriceDetail partner;
    @AuraEnabled public PriceDetail factory;

    public ActivePricesWrapper( String prodId ){
      this.prodId = prodId;
      init();
    }

    private void init(){
      List<Pricebook2> pbs = Pricebook_Selector.getDefaultPricebooks();
      Map<Id, PricebookEntry> pricebookEntryByPricebookId = getPricebookEntries();
      for( Pricebook2 pb : pbs ){
        switch on pb.RecordType.Name {
          when 'Sales' {
            if( pricebookEntryByPricebookId.containsKey(pb.Id) ){
              this.retail = new PriceDetail( pricebookEntryByPricebookId.get(pb.Id) );
            }
            else{
              this.retail = new PriceDetail( pb );
            }
          }
          when 'Dealer' {
            if( pricebookEntryByPricebookId.containsKey(pb.Id) ){
              this.partner = new PriceDetail( pricebookEntryByPricebookId.get(pb.Id) );
            }
            else{
              this.partner = new PriceDetail( pb );
            }
          }
          when 'Factory' {
            if( pricebookEntryByPricebookId.containsKey(pb.Id) ){
              this.factory = new PriceDetail( pricebookEntryByPricebookId.get(pb.Id) );
            }
            else{
              this.factory = new PriceDetail( pb );
            }
          }
        }
      }

    }

    private Map<Id, PricebookEntry> getPricebookEntries(){
      Map<Id, PricebookEntry> result = new Map<Id, PricebookEntry>();
      for( PricebookEntry pb : PricebookEntry_Selector.allDefaultEntriesByProductId(this.prodId) ){
        result.put( pb.Pricebook2Id, pb);
      }
      return result;
    }

  }

  public class PriceDetail {
    @AuraEnabled public Id pricebookId;
    @AuraEnabled public String pricebookName;
    @AuraEnabled public String pricebookRecordTypeName;
    @AuraEnabled public Id pricebookRecordTypeId;
    @AuraEnabled public String pricebookSalesYear;
    @AuraEnabled public Decimal pricebookVersion;
    @AuraEnabled public Id pricebookEntryId;
    @AuraEnabled public String priceCssClass;
    @AuraEnabled public Decimal price;

    public PriceDetail( PricebookEntry pbe){
      this.pricebookId = pbe.Pricebook2Id;
      this.pricebookName = pbe.Pricebook2.Name;
      this.pricebookRecordTypeName = pbe.Pricebook2.RecordType.Name;
      this.pricebookRecordTypeId = pbe.Pricebook2.RecordTypeId;
      this.pricebookSalesYear = pbe.Pricebook2.Sales_Year__c;
      this.pricebookVersion = pbe.Pricebook2.Version__c;
      this.pricebookEntryId = pbe.Id;
      this.price = pbe.UnitPrice;
      this.priceCssClass = 'slds-text-heading_medium slds-align_absolute-center';
      if( !pbe.IsActive ){
        this.priceCssClass += ' inactive';
      }
    }

    public PriceDetail( Pricebook2 pb){
      this.pricebookId = pb.Id;
      this.pricebookName = pb.Name;
      this.pricebookRecordTypeName = pb.Name;
      this.pricebookRecordTypeId = pb.RecordTypeId;
      this.pricebookSalesYear = pb.Sales_Year__c;
      this.pricebookVersion = pb.Version__c;
    }

  }

  @AuraEnabled(Cacheable=true)
  public static ActivePricesWrapper getCurrentPricing( String prodId ){
    return new ActivePricesWrapper( prodId );
  }

}