@isTest
private class BoatRiggingChecklistController_Test {
  static Product2 boat;
  static List<Boat_Rigging_Checklist_Map__c> checklistItems;

  static {
    InventoryTestFactory factory = new InventoryTestFactory();
    boat = factory.buildTestBoat();
    boat.AcctSeedERP__Serialized__c = true;
    boat.AcctSeed__Inventory_Product__c = true;
    Boolean orig = gcProduct.disableTrigger;
    gcProduct.disableTrigger = true;
    System.debug(boat);
    insert boat;
    gcProduct.disableTrigger = orig;
    checklistItems = factory.insertFullRiggingChecklistForBoat(boat.Id, 5);
  }

  @isTest
  static void buildChecklistFromProduct_Test() {
    Test.startTest();
    PageReference pageRef = Page.BoatRiggingChecklist_View;
    pageRef.getParameters().put('Id', boat.Id);
    Test.setCurrentPage(pageRef);
    BoatRiggingChecklistController ctr = new BoatRiggingChecklistController();
    String[] categories = LGND_Utilities.getPicklistValues('Boat_Rigging_Checklist_Item__c', 'Category__c');
    Test.stopTest();

    System.assert(ctr.getHasRiggingChecklistItems());
    System.assertEquals(categories.size(), ctr.riggingChecklistItems.keySet().size());
    System.assertEquals(5, ctr.riggingChecklistItems.get(categories[0]).size());
    System.assertEquals('', ctr.boatSerialNumber);
    System.assertEquals('', ctr.trailerSerialNumber);
    System.assertEquals('', ctr.trollingMotorSerialNumber);
  }

  @isTest
  static void buildChecklistFromSerialNumber_Test() {
    Test.startTest();
    Map<Id, GMBLASERP__Lot__c> lotMap = buildLotMap(boat);
    Map<Id, GMBLASERP__Serial_Number__c> serialMap = new Map<Id, GMBLASERP__Serial_Number__c>();
    for (Id prodId : lotMap.keySet()) {
      String serNum = '123';
      if (prodId == boat.Id)
        serNum += 'BOAT';
      if (prodId == boat.Standard_Motor__c)
        serNum += 'MOTOR';
      if (prodId == boat.Standard_Trailer__c)
        serNum += 'TRAILER';
      if (prodId == boat.Standard_Trolling_Motor__c)
        serNum += 'TROLLINGMOTOR';

      GMBLASERP__Serial_Number__c ser = Factory_SerialNumber.buildSerial(prodId, lotMap.get(prodId).Id, serNum);
      serialMap.put(prodId, ser);
    }
    insert serialMap.values();
    for (Id prodId : serialMap.keySet()) {
      if (prodId != boat.Id)
        serialMap.get(prodId).Nest__c = serialMap.get(boat.Id).Id;
    }
    update serialMap.values();
    PageReference pageRef = Page.BoatRiggingChecklist_View;
    pageRef.getParameters().put('Id', serialMap.get(boat.Id).Id);
    Test.setCurrentPage(pageRef);
    BoatRiggingChecklistController ctr = new BoatRiggingChecklistController();
    String[] categories = LGND_Utilities.getPicklistValues('Boat_Rigging_Checklist_Item__c', 'Category__c');
    Test.stopTest();

    System.assertEquals(categories.size(), ctr.riggingChecklistItems.keySet().size());
    System.assertEquals(5, ctr.riggingChecklistItems.get(categories[0]).size());
    System.assertEquals('123BOAT', ctr.boatSerialNumber);
    System.assertEquals('123TRAILER', ctr.trailerSerialNumber);
    System.assertEquals('123TROLLINGMOTOR', ctr.trollingMotorSerialNumber);
    System.assertEquals('', ctr.ignitionKeyNumber);
    System.assertEquals('', ctr.compartmentKeyNumber);
  }

  private static Map<Id, GMBLASERP__Lot__c> buildLotMap(Product2 boat) {
    Map<Id, GMBLASERP__Lot__c> lotMap = new Map<Id, GMBLASERP__Lot__c>();
    Date today = Date.today();
    lotMap.put(
      boat.Id,
      new GMBLASERP__Lot__c(
        GMBLASERP__Product__c = boat.Id,
        Name = String.valueOf(today.year()),
        GMBLASERP__Uniquefier__c = boat.Id + '-' + String.valueOf(today.year())
      )
    );
    lotMap.put(
      boat.Standard_Motor__c,
      new GMBLASERP__Lot__c(
        GMBLASERP__Product__c = boat.Standard_Motor__c,
        Name = String.valueOf(today.year()),
        GMBLASERP__Uniquefier__c = boat.Standard_Motor__c + '-' + String.valueOf(today.year())
      )
    );
    lotMap.put(
      boat.Standard_Trailer__c,
      new GMBLASERP__Lot__c(
        GMBLASERP__Product__c = boat.Standard_Trailer__c,
        Name = String.valueOf(today.year()),
        GMBLASERP__Uniquefier__c = boat.Standard_Trailer__c + '-' + String.valueOf(today.year())
      )
    );
    lotMap.put(
      boat.Standard_Trolling_Motor__c,
      new GMBLASERP__Lot__c(
        GMBLASERP__Product__c = boat.Standard_Trolling_Motor__c,
        Name = String.valueOf(today.year()),
        GMBLASERP__Uniquefier__c = boat.Standard_Trolling_Motor__c + '-' + String.valueOf(today.year())
      )
    );
    insert lotMap.values();
    return lotMap;
  }
}
