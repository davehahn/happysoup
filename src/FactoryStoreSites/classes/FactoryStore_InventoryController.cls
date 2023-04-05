/**
 * Created by Tim on 2021-03-23.
 */

public with sharing class FactoryStore_InventoryController {
  @AuraEnabled(Cacheable=true)
  public static LGND_APIv2_Product fetchBoat(String boatId) {
    LGND_APIv2_Product api = new LGND_APIv2_Product(boatId, 'retail', 'Boat');
    //System.debug( api );
    return api;
  }

  @AuraEnabled(Cacheable=true)
  public static List<Product2> fetchBoatsBySeries(String seriesName) {
    Set<String> series = new Set<String>();
    series.add(seriesName);
    if (seriesName == 'R') {
      series.add('WideBody');
      series.add('ProSport');
      series.add('Angler');
      series.add('AllSport');
      series.add('Ultralite');
      series.add('ProSport TL');
      series.add('ProSport SC');
    }
    return Product_Selector.allBoatsInSeries(series);
  }

  @AuraEnabled(Cacheable=true)
  public static FSBoatDetails_Service fetchFullBoatDetails(Id modelId) {
    FSBoatDetails_Service boat = new FSBoatDetails_Service(modelId);
    return boat;
  }

  @AuraEnabled(Cacheable=true)
  public static FSInventory_Service fetchNewInStockInventory(String location, Integer year, String modelId) {
    FSInventory_Service inventory = new FSInventory_Service(location, year, modelId);

    System.debug('Returned Inventory: ' + inventory);
    return inventory;
  }

  @AuraEnabled(Cacheable=true)
  public static GMBLASERP__Serial_Number__c fetchSerialNumber(String serialId) {
    return SerialNumber_Selector.getSerialNumber(serialId);
  }

  //    @AuraEnabled(Cacheable=true)
  //    public static FSImage_Processor fetchImages( GMBLASERP__Serial_Number__c serialNumber )
  //    {
  //        FSImage_Processor images = new FSImage_Processor( serialNumber );
  //        System.debug('Processed Images: ' + images);
  //
  //        return images;
  //    }
}