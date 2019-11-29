@isTest
private class BoatRiggingChecklist_Controller_Test {

  static InventoryTestFactory factory;
  static Product2 boat;
  static List<Schema.PickListEntry> categories;
  static List<Boat_Rigging_Checklist_Item__c> availableChecklistItems;
  static Integer categoryCount;

  public static void init()
  {
    gcProduct.disableTrigger = true;
    factory = new InventoryTestFactory();
    boat = factory.buildTestBoat();
    insert boat;
    factory.insertFullRiggingChecklistForBoat(boat.Id, 5);
    categories =  Boat_Rigging_Checklist_Item__c.Category__c.getDescribe().getPickListValues();
    categoryCount = categories.size();
    availableChecklistItems = factory.buildAllRiggingChecklistItems(5);
    insert availableChecklistItems;
  }

  @isTest
  public static void constructor_Test()
  {
    init();
    BoatRiggingChecklist_Controller ctrl = new BoatRiggingChecklist_Controller( new ApexPages.StandardController(boat) );

    System.assertEquals(boat.Id, ctrl.productId );
    System.assertEquals( categoryCount, ctrl.categories.size() );
    System.assertEquals( categoryCount, ctrl.activeItems.size() );
    System.assertEquals( categoryCount, ctrl.availableItems.size() );
    for( Schema.PickListEntry cat : categories )
    {
      System.assertEquals( 5, ctrl.activeItems.get( cat.getLabel() ).size() );
      System.assertEquals( 1, ctrl.activeItems.get( cat.getLabel() )[0].Rank__c );
      System.assertEquals( 2, ctrl.activeItems.get( cat.getLabel() )[1].Rank__c );
      System.assertEquals( 3, ctrl.activeItems.get( cat.getLabel() )[2].Rank__c );
      System.assertEquals( 4, ctrl.activeItems.get( cat.getLabel() )[3].Rank__c );
      System.assertEquals( 5, ctrl.activeItems.get( cat.getLabel() )[4].Rank__c );
      System.assertEquals( 5, ctrl.availableItems.get(cat.getLabel() ).size()  );
    }
  }

  @isTest
  public static void updateItemOrder_Test()
  {
    init();
    BoatRiggingChecklist_Controller ctrl = new BoatRiggingChecklist_Controller( new ApexPages.StandardController(boat) );
    //Lets just deal with the first category of activeItems
    List<Boat_Rigging_Checklist_Map__c> activeItems = ctrl.activeItems.get( categories[0].getLabel() );
    Id origRankOneItem = activeItems[0].Id;
    for( Integer i=0; i<activeItems.size(); i++ )
    {
     activeItems[i].Rank__c = activeItems.size() - i;
    }
    BoatRiggingChecklist_Controller.updateItemOrder( JSON.serialize(activeItems) );
    Boat_Rigging_Checklist_Map__c rMap = [SELECT Id, Rank__c FROM Boat_Rigging_Checklist_Map__c WHERE Id = :origRankOneItem];

    System.assertEquals( activeItems.size(), rMap.Rank__c );
  }

  @isTest
  public static void createChecklistMap_Test()
  {
    init();
    String cat = availableChecklistItems[0].Category__c;
    BoatRiggingChecklist_Controller beforeCtrl = new BoatRiggingChecklist_Controller( new ApexPages.StandardController(boat) );

    Boat_Rigging_Checklist_Map__c newMap = new Boat_Rigging_Checklist_Map__c( Product__c = boat.Id, Checklist_Item__c = availableChecklistItems[0].Id, Rank__c = 6 );
    BoatRiggingChecklist_Controller.createChecklistMap( JSON.serialize( newMap ) );

    BoatRiggingChecklist_Controller afterCtrl = new BoatRiggingChecklist_Controller( new ApexPages.StandardController(boat) );

    System.assertEquals( 5, beforeCtrl.activeItems.get(cat).size() );
    System.assertEquals( 6, afterCtrl.activeItems.get(cat).size() );

  }

  @isTest
  public static void createItem()
  {
    init();
    String cat = categories[0].getLabel();
    BoatRiggingChecklist_Controller beforeCtrl = new BoatRiggingChecklist_Controller( new ApexPages.StandardController(boat) );
    Boat_Rigging_Checklist_Item__c item = new Boat_Rigging_Checklist_Item__c( Description__c = 'This was added by a test', Category__c = cat);
    Boat_Rigging_Checklist_Map__c newMap = new Boat_Rigging_Checklist_Map__c( Product__c = boat.Id, Rank__c = 6 );

    BoatRiggingChecklist_Controller.createItem( JSON.serialize(item), JSON.serialize(newMap) );

    BoatRiggingChecklist_Controller afterCtrl = new BoatRiggingChecklist_Controller( new ApexPages.StandardController(boat) );

    System.assertEquals( 5, beforeCtrl.activeItems.get(cat).size() );
    System.assertEquals( 6, afterCtrl.activeItems.get(cat).size() );
  }

  @isTest
  public static void updateItem_Test()
  {
    init();
    String cat = categories[0].getLabel();
    BoatRiggingChecklist_Controller beforeCtrl = new BoatRiggingChecklist_Controller( new ApexPages.StandardController(boat) );
    Boat_Rigging_Checklist_Map__c rMap = beforeCtrl.activeItems.get( cat )[0];
    Boat_Rigging_Checklist_Item__c item = new Boat_Rigging_Checklist_Item__c( Id = rMap.Checklist_Item__c, Description__c = 'This was updated through a test');

    BoatRiggingChecklist_Controller.updateItem( JSON.serialize(item) );
    Boat_Rigging_Checklist_Item__c updatedItem = [SELECT Id, Description__c
                                                  FROM Boat_Rigging_Checklist_Item__c
                                                  WHERE Id = : item.Id];

    System.assertEquals( 'This was updated through a test', updatedItem.Description__c );
  }

  @isTest
  private static void removeChecklistMap_Test()
  {
    init();
    String cat = categories[0].getLabel();
    BoatRiggingChecklist_Controller beforeCtrl = new BoatRiggingChecklist_Controller( new ApexPages.StandardController(boat) );
    Boat_Rigging_Checklist_Map__c rMap = beforeCtrl.activeItems.get( cat )[0];

    BoatRiggingChecklist_Controller.removeChecklistMap(rMap.Id);

    BoatRiggingChecklist_Controller afterCtrl = new BoatRiggingChecklist_Controller( new ApexPages.StandardController(boat) );

    System.assertEquals( 5, beforeCtrl.activeItems.get(cat).size() );
    System.assertEquals( 4, afterCtrl.activeItems.get(cat).size() );
  }

}