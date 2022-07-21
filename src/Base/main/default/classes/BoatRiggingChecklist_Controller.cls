public with sharing class BoatRiggingChecklist_Controller {
  public Map<String, String> categories { get; set; }
  public Map<String, List<Boat_Rigging_Checklist_Map__c>> activeItems { get; set; }
  public Map<String, List<Boat_Rigging_Checklist_Item__c>> availableItems { get; set; }
  private Set<Id> activeItemIds = new Set<Id>();
  public Id productId { get; set; }

  public BoatRiggingChecklist_Controller(ApexPages.StandardController ctlr) {
    this.productId = ctlr.getId();
    this.categories = findCategories();
    initializeItems();
    findActiveItems();
    findAvailableItems();
  }

  public static Map<String, String> findCategories() {
    Map<String, String> result = new Map<String, String>();
    Schema.DescribeFieldResult category = Boat_Rigging_Checklist_Item__c.Category__c.getDescribe();
    for (Schema.PickListEntry ple : category.getPicklistValues()) {
      result.put(ple.getLabel().toLowerCase().replace(' ', '_'), ple.getLabel());
    }
    return result;
  }

  @RemoteAction
  public static List<Boat_Rigging_Checklist_Map__c> updateItemOrder(String jsonData) {
    List<Boat_Rigging_Checklist_Map__c> listMaps = (List<Boat_Rigging_Checklist_Map__c>) JSON.deserialize(
      jsonData,
      List<Boat_Rigging_Checklist_Map__c>.class
    );
    update listMaps;
    return listMaps;
  }

  @RemoteAction
  public static Boat_Rigging_Checklist_Map__c createChecklistMap(String jsonData) {
    Boat_Rigging_Checklist_Map__c riggingMap = (Boat_Rigging_Checklist_Map__c) JSON.deserialize(
      jsonData,
      Boat_Rigging_Checklist_Map__c.class
    );
    insert riggingMap;
    return [
      SELECT Id, Rank__c, Checklist_Item__c, Checklist_Item__r.Category__c, Checklist_Item__r.Description__c
      FROM Boat_Rigging_Checklist_Map__c
      WHERE Id = :riggingMap.Id
    ];
  }

  @RemoteAction
  public static Map<String, String> createItem(String jsonItemData, String jsonMapData) {
    Map<String, String> result = new Map<String, String>();
    Boat_Rigging_Checklist_Item__c item = (Boat_Rigging_Checklist_Item__c) JSON.deserialize(
      jsonItemData,
      Boat_Rigging_Checklist_Item__c.class
    );
    Boat_Rigging_Checklist_Map__c checklistMap = (Boat_Rigging_Checklist_Map__c) JSON.deserialize(
      jsonMapData,
      Boat_Rigging_Checklist_Map__c.class
    );
    insert item;
    checklistMap.Checklist_Item__c = item.Id;
    insert checklistMap;
    result.put('item_id', item.Id);
    result.put('map_id', checklistMap.Id);
    return result;
  }

  @RemoteAction
  public static Boat_Rigging_Checklist_Item__c updateItem(String jsonData) {
    Boat_Rigging_Checklist_Item__c item = (Boat_Rigging_Checklist_Item__c) JSON.deserialize(
      jsonData,
      Boat_Rigging_Checklist_Item__c.class
    );
    update item;
    return item;
  }

  @RemoteAction
  public static void removeChecklistMap(String deleteId) {
    Boat_Rigging_Checklist_Map__c toDelete = new Boat_Rigging_Checklist_Map__c(Id = deleteId);
    delete toDelete;
  }

  private void initializeItems() {
    activeItems = new Map<String, List<Boat_Rigging_Checklist_Map__c>>();
    availableItems = new Map<String, List<Boat_Rigging_Checklist_Item__c>>();
    for (String cat : categories.values()) {
      activeItems.put(cat, new List<Boat_Rigging_Checklist_Map__c>());
      availableItems.put(cat, new List<Boat_Rigging_Checklist_Item__c>());
    }
  }

  private void findActiveItems() {
    Map<Id, Boat_Rigging_Checklist_Map__c> maps = new Map<Id, Boat_Rigging_Checklist_Map__c>(
      [
        SELECT Id, Rank__c, Checklist_Item__c, Checklist_Item__r.Category__c, Checklist_Item__r.Description__c
        FROM Boat_Rigging_Checklist_Map__c
        WHERE Product__c = :productId
        ORDER BY Rank__c
      ]
    );
    if (maps.size() > 0) {
      for (Boat_Rigging_Checklist_Map__c itemMap : maps.values()) {
        activeItemIds.add(itemMap.Checklist_Item__c);
      }
      activeItems = catagorizeItems(activeItems, maps.values());
    }
  }

  private void findAvailableItems() {
    List<Boat_Rigging_Checklist_Item__c> items = [
      SELECT Id, Category__c, Description__c
      FROM Boat_Rigging_Checklist_Item__c
      WHERE Id NOT IN :activeItemIds
    ];
    if (items.size() > 0) {
      for (Boat_Rigging_Checklist_Item__c item : items) {
        if (availableItems.containsKey(item.Category__c)) {
          availableItems.get(item.Category__c).add(item);
        }
      }
    }
  }

  private static Map<String, List<Boat_Rigging_Checklist_Map__c>> catagorizeItems(
    Map<String, List<Boat_Rigging_Checklist_Map__c>> itemMap,
    List<Boat_Rigging_Checklist_Map__c> maps
  ) {
    for (Boat_Rigging_Checklist_Map__c m : maps) {
      if (itemMap.containsKey(m.Checklist_Item__r.Category__c)) {
        itemMap.get(m.Checklist_Item__r.Category__c).add(m);
      }
    }
    return itemMap;
  }
}
