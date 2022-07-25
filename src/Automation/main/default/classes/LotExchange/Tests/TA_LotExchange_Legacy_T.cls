@isTest
public class TA_LotExchange_Legacy_T {
  static List<Lot_Exchange__c> lotExchange;
  private static List<Lot_Exchange__c> getData() {
    return [SELECT id, Exchange_Date__c, Exchange_Type__c, Lot_From__c, Lot_To__c FROM Lot_Exchange__c];
  }
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Product2 boat = Factory_Product.createSerializedProduct('Boat', 'Pontoon');
    Integer year = Date.today().year();
    Map<String, GMBLASERP__Lot__c> lotMap = new Map<String, GMBLASERP__Lot__c>();
    lotMap.put(
      'from_lot',
      new GMBLASERP__Lot__c(
        GMBLASERP__Product__c = boat.Id,
        Name = String.valueOf(year - 1),
        GMBLASERP__Uniquefier__c = boat.Id + '-' + String.valueOf(year - 1)
      )
    );

    lotMap.put(
      'to_lot',
      new GMBLASERP__Lot__c(
        GMBLASERP__Product__c = boat.Id,
        Name = String.valueOf(year),
        GMBLASERP__Uniquefier__c = boat.Id + '-' + String.valueOf(year)
      )
    );
    insert lotMap.values();
    insert new Lot_Exchange__c(
      Exchange_Date__c = Date.today(),
      Exchange_Type__c = 'Lot',
      Lot_From__c = lotMap.get('from_lot').Id,
      Lot_To__c = lotMap.get('to_lot').Id
    );
  }

  @IsTest
  static void beforeInsertTest() {
    Test.startTest();
    lotExchange = getData();
    new TA_LotExchange_Legacy().beforeInsert(lotExchange);
    Test.stopTest();
  }
  @IsTest
  static void afterInsertTest() {
    Test.startTest();
    new TA_LotExchange_Legacy().afterInsert(getData());
    Test.stopTest();
  }
  @IsTest
  static void afterUpdateTest() {
    Test.startTest();
    lotExchange = getData();
    Lot_Exchange__c lotExClone = lotExchange[0].clone(true, true, true, true);
    new TA_LotExchange_Legacy()
      .afterUpdate(new List<Lot_Exchange__c>{ lotExchange[0] }, new List<Lot_Exchange__c>{ lotExClone });
    Test.stopTest();
  }
  @IsTest
  static void beforeUpdateTest() {
    Test.startTest();
    lotExchange = getData();
    Lot_Exchange__c lotExClone = lotExchange[0].clone(true, true, true, true);
    new TA_LotExchange_Legacy()
      .beforeUpdate(new List<Lot_Exchange__c>{ lotExchange[0] }, new List<Lot_Exchange__c>{ lotExClone });
    Test.stopTest();
  }
  @IsTest
  static void beforeDeleteTest() {
    Test.startTest();
    new TA_LotExchange_Legacy().beforeDelete(getData());
    Test.stopTest();
  }
  @IsTest
  static void afterDeleteTest() {
    Test.startTest();
    new TA_LotExchange_Legacy().afterDelete(getData());
    Test.stopTest();
  }
}
