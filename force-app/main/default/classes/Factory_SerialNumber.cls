@isTest
public class Factory_SerialNumber {

  public static GMBLASERP__Serial_Number__c insertSerialNumber( Product2 prod,
    String serialNumber )
  {
    GMBLASERP__Lot__c lot = insertLot( prod );
    GMBLASERP__Serial_Number__c serial = buildSerial( prod.Id, lot.Id, serialNumber );
    insert serial;
    return serial;
  }

  public static GMBLASERP__Serial_Number__c insertSerialNumber( Product2 prod,
                                                                String serialNumber,
                                                                String lotId )
  {
    GMBLASERP__Serial_Number__c serial = buildSerial( prod.Id, lotId, serialNumber );
    insert serial;
    return serial;
  }

  public static GMBLASERP__Serial_Number__c insertFullSerial( String productRecordTypeName,
                                                              String productFamily,
                                                              String serialNumber )
  {
    InventoryTestFactory factory = new InventoryTestFactory();
    Product2 p = factory.buildTestProducts(1, productRecordTypeName, productFamily)[0];
    p.AcctSeedERP__Serialized__c = true;
    p.GMBLASERP__Lot_Tracked__c = true;
    Boolean origTriggerState = gcProduct.disableTrigger;
    gcProduct.disableTrigger = true;
    insert p;
    gcProduct.disableTrigger = origTriggerState;
    GMBLASERP__Lot__c lot = insertLot( p );
    GMBLASERP__Serial_Number__c serial = buildSerial( p.Id, lot.Id, serialNumber );
    insert serial;
    return serial;
  }

  public static GMBLASERP__Serial_Number__c insertFullSerialWithProduct( String productRecordTypeName,
                                                                         String productFamily,
                                                                         String serialNumber,
                                                                         Product2 p )
  {
    InventoryTestFactory factory = new InventoryTestFactory();
    p.AcctSeedERP__Serialized__c = true;
    p.GMBLASERP__Lot_Tracked__c = true;
    Boolean origTriggerState = gcProduct.disableTrigger;
    gcProduct.disableTrigger = true;
    update p;
    gcProduct.disableTrigger = origTriggerState;
    GMBLASERP__Lot__c lot = insertLot( p );
    GMBLASERP__Serial_Number__c serial = buildSerial( p.Id, lot.Id, serialNumber );
    insert serial;
    return serial;
  }

  public static GMBLASERP__Serial_Number__c[] insertFullSerials( Integer count,
                                                                 String productRecordTypeName,
                                                                 String productFamily )
  {
    //Products
    Product2[] prods = new List<Product2>();
    for( Integer i=0; i < count; i++ )
    {
      prods.add( Factory_Product.buildSerializedProduct( productRecordTypeName, productFamily ) );
    }
    Boolean origTriggerState = gcProduct.disableTrigger;
    gcProduct.disableTrigger = true;
    insert prods;
    gcProduct.disableTrigger = origTriggerState;

    //Lots
    Map<Id, GMBLASERP__Lot__c> lots = new Map<Id, GMBLASERP__Lot__c>();
    for( Product2 p : prods )
    {
      lots.put(p.Id, buildLot(p) );
    }
    insert lots.values();

    //Serial Numbers
    GMBLASERP__Serial_Number__c[] serials = new List<GMBLASERP__Serial_Number__c>();
    for( Product2 p : prods )
    {
      serials.add( buildSerial( p.Id, lots.get(p.Id).Id, String.valueOf( Crypto.getRandomLong() ) ) );
    }
    insert serials;
    return serials;
  }


  public static GMBLASERP__Serial_Number__c buildSerial( Id prodId, Id lotId, String serNum )
  {
    return new GMBLASERP__Serial_Number__c(
      Available__c = true,
      GMBLASERP__Lot__c = lotId,
      GMBLASERP__Product__c = prodId,
      Name = serNum
    );
  }

  public static GMBLASERP__Lot__c buildLot( Product2 p )
  {
    Date today = Date.today();
    return new GMBLASERP__Lot__c(
      GMBLASERP__Product__c = p.Id,
      Name = String.valueOf( today.year() ),
      GMBLASERP__Uniquefier__c = p.Id + '-' + String.valueOf(today.year())
    );
  }

  public static GMBLASERP__Lot__c insertLot( Product2 p )
  {
    GMBLASERP__Lot__c lot = buildLot( p );
    insert lot;
    return lot;
  }

}