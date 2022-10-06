/**
 * Created by dave on 2020-01-29.
 */

public inherited sharing class Pricebook2_Service {
  public class Pricebook2_Service_Exception extends Exception {}

  private static Pricebook2_Service instance;
  private Map<Id, Id> retail2FactoryMap {
    get {
      if( retail2FactoryMap == null){
        retail2FactoryMap = Pricebook2_Service.getRetailToFactory_Map();
      }
      return retail2FactoryMap;
    }
    set{}
  }
  private Map<Id, Id> dealer2RetailMap {
    get {
      if( dealer2RetailMap == null ){
        dealer2RetailMap = getDealerToRetail_Map();
      }
      return dealer2RetailMap;
    }
    set {}
  }

  public Id getMatchingRetailIdFromDealerId( Id dealerPbId ){
    if( !this.dealer2RetailMap.containsKey( dealerPbId ) ){
      throw new Pricebook2_Service_Exception('No matching Retail Pricebook found');
    }
    return this.dealer2RetailMap.get(dealerPbId);
  }


  public static Pricebook2_Service getInstance(){
    if( instance == null ){
      instance = new Pricebook2_Service();
    }
    return instance;
  }

  public static Map<Id, Id> getRetailToFactory_Map() {
    Application_RecordType.PriceBookRTs rts = Application_RecordType.getInstance().getPricebookRecordTypes();
    return mapPriceBooks( rts.getSalesId(), rts.getFactoryId() );
  }

  public static Map<Id, Id> getDealerToRetail_Map() {
    Application_RecordType.PriceBookRTs rts = Application_RecordType.getInstance().getPricebookRecordTypes();
    return mapPriceBooks( rts.getDealerId(), rts.getSalesId() );
  }

  private static Map<Id, Id> mapPriceBooks( Id keyRtId, Id valueRtId ){
    Map<Id, Id> result_Map = new Map<Id, Id>();
    Map<String, Id> value_pbId2Year_Map = new Map<String, Id>();
    Map<String, Id> key_pbId2Year_Map = new Map<String, Id>();
    Set<Id> pbs = new Set<Id>{ keyRtId, valueRtId };
    for (Pricebook2 pb : Pricebook_Selector.allByRecordTypeIds(pbs)) {
      if (pb.RecordTypeId == keyRtId) {
        key_pbId2Year_Map.put((pb.Sales_Year__c + '-' + pb.Version__c), pb.Id);
      }
      if (pb.RecordTypeId == valueRtId) {
        value_pbId2Year_Map.put((pb.Sales_Year__c + '-' + pb.Version__c), pb.Id);
      }
    }
    for (String year_version : key_pbId2Year_Map.keySet()) {
      if (value_pbId2Year_Map.containsKey(year_version)) {
        result_Map.put(key_pbId2Year_Map.get(year_version), value_pbId2Year_Map.get(year_version));
      }
    }
    return result_Map;
  }
}
