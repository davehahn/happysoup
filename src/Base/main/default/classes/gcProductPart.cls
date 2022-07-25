public without sharing class gcProductPart {
  public static Boolean disableTrigger {
    get {
      if (disableTrigger == null)
        return false;
      else
        return disableTrigger;
    }
    set {
      if (value == null)
        disableTrigger = false;
      else
        disableTrigger = value;
    }
  }

  public static void triggerHandler(
    map<Id, AcctSeed__Product_Part__c> oldMap,
    map<Id, AcctSeed__Product_Part__c> newMap,
    list<AcctSeed__Product_Part__c> listNew,
    Boolean boolIsBefore,
    Boolean boolIsInsert,
    Boolean boolIsUpdate,
    Boolean boolIsDelete
  ) {
    if (oldMap == null)
      oldMap = new Map<Id, AcctSeed__Product_Part__c>();
    if (newMap == null)
      newMap = new Map<Id, AcctSeed__Product_Part__c>();
    if (listNew == null)
      listNew = new List<AcctSeed__Product_Part__c>();

    updateAndValidate(oldMap, newMap, listNew, boolIsBefore, boolIsInsert, boolIsUpdate, boolIsDelete);

    if (boolIsBefore) {
      if (boolIsInsert) {
      }
      if (boolIsUpdate) {
      }
      if (boolIsDelete) {
      }
    } else //i.e. trigger.isAfter
    {
      if (boolIsInsert) {
        rollUpProduct(listNew);
      }
      if (boolIsUpdate) {
        List<AcctSeed__Product_Part__c> listAll = new List<AcctSeed__Product_Part__c>();
        listAll.addAll(listNew);
        listAll.addAll(oldMap.values());
        rollUpProduct(listAll);
      }
      if (boolIsDelete) {
        rollUpProduct(oldMap.values());
      }
    }
  }

  private static void updateAndValidate(
    map<Id, AcctSeed__Product_Part__c> oldMap,
    map<Id, AcctSeed__Product_Part__c> newMap,
    list<AcctSeed__Product_Part__c> listNew,
    Boolean boolIsBefore,
    Boolean boolIsInsert,
    Boolean boolIsUpdate,
    Boolean boolIsDelete
  ) {
    if (boolIsBefore && (boolIsInsert || boolIsUpdate)) {
      for (AcctSeed__Product_Part__c part : listNew) {
        if (part.AcctSeed__Product__c == part.AcctSeed__Product_Part__c)
          part.AcctSeed__Product_Part__c.addError('The Product Part may not be the same as the Product.');
      }
      retrieveStatics(listNew);
      for (AcctSeed__Product_Part__c part : listNew) {
        Product2 parentProduct = mapProduct.get(part.AcctSeed__Product__c);
        Product2 partProduct = mapProduct.get(part.AcctSeed__Product_Part__c);
        /// Check to see if the Product Part is already used as a Kit Part for some other Kit
        if (!parentProduct.AcctSeed__Inventory_Product__c)
          for (AcctSeed__Product_Part__c pcx : parentProduct.AcctSeed__Product_Parts1__r) {
            if (!pcx.AcctSeed__Product__r.AcctSeed__Inventory_Product__c)
              part.addError(
                'This product ' +
                parentProduct.Name +
                ' has been used as a Part for another Kit. It cannot be a Kit itself.'
              );
          }

        //check for duplicate parts
        set<Id> setIdComponentItem = new Set<Id>();
        for (AcctSeed__Product_Part__c sibling : partProduct.AcctSeed__Product_Parts__r) {
          if (sibling.AcctSeed__Product__c != part.AcctSeed__Product__c)
            continue;

          if (setIdComponentItem.contains(sibling.AcctSeed__Product__c)) {
            part.addError(
              'A Product may not have more than one Part of the same product.  The action may not be completed because [' +
              partProduct.Name +
              '] would have more than one part of [' +
              sibling.AcctSeed__Product__r.Name +
              '].'
            );
          } else
            setIdComponentItem.add(sibling.AcctSeed__Product__c);
        }

        Boolean productIsKit = false;
        Boolean partIsKit = false;
        Boolean partIsKitComponent = false;

        if (
          partProduct != null &&
          !partProduct.AcctSeed__Inventory_Product__c &&
          !partProduct.AcctSeed__Product_Parts__r.isEmpty()
        ) {
          partIsKit = true;
          for (AcctSeed__Product_Part__c cx : partProduct.AcctSeed__Product_Parts1__r) {
            if (!cx.AcctSeed__Product_Part__r.AcctSeed__Inventory_Product__c)
              partIsKitComponent = true;
          }
        }

        if (
          parentProduct != null &&
          !parentProduct.AcctSeed__Inventory_Product__c &&
          !parentProduct.AcctSeed__Product_Parts__r.isEmpty()
        )
          productIsKit = true;

        /// Check to see if a product part of a kit is already a kit, which is not allowed
        if ((productIsKit && partIsKit) || partIsKitComponent)
          part.addError('A Kit may not have parts that are themselves Kits.');
      }
    }
  }

  private static map<Id, Product2> mapProduct;

  private static void retrieveStatics(list<AcctSeed__Product_Part__c> listNew) {
    if (mapProduct == null) {
      mapProduct = new Map<Id, Product2>();
    }

    set<Id> setIdProduct = new Set<Id>();

    for (AcctSeed__Product_Part__c part : listNew) {
      if (!mapProduct.containsKey(part.AcctSeed__Product__c))
        setIdProduct.add(part.AcctSeed__Product__c);
      if (!mapProduct.containsKey(part.AcctSeed__Product_Part__c))
        setIdProduct.add(part.AcctSeed__Product_Part__c);
    }
    setIdProduct.remove(null);

    if (!setIdProduct.isEmpty()) {
      for (Product2 p : [
        SELECT
          Id,
          Name,
          GMBLASERP__Lot_Tracked__c,
          AcctSeedERP__Serialized__c,
          AcctSeed__Inventory_Product__c,
          (
            SELECT
              Id,
              AcctSeed__Product_Part__c,
              AcctSeed__Product_Part__r.Name,
              AcctSeed__Product_Part__r.AcctSeed__Inventory_Product__c,
              AcctSeed__Product__r.Name,
              AcctSeed__Product__r.AcctSeed__Inventory_Product__c
            FROM AcctSeed__Product_Parts1__r
          ),
          (
            SELECT
              Id,
              AcctSeed__Product__c,
              AcctSeed__Product__r.Name,
              AcctSeed__Product__r.AcctSeed__Inventory_Product__c
            FROM AcctSeed__Product_Parts__r
          )
        FROM Product2
        WHERE Id IN :setIdProduct
      ]) {
        mapProduct.put(p.Id, p);
      }
    }
  }

  public static void rollUpProduct(List<AcctSeed__Product_Part__c> listParts) {
    if (listParts.isEmpty())
      return;
    Map<Id, Decimal> mapIdProductParts = new Map<Id, Decimal>();
    for (AcctSeed__Product_Part__c part : listParts)
      mapIdProductParts.put(part.AcctSeed__Product__c, 0);

    /// Total count of parts
    for (sObject p : [
      SELECT AcctSeed__Product__c idProduct, count(Id) countParts
      FROM AcctSeed__Product_Part__c
      WHERE AcctSeed__Product__c IN :mapIdProductParts.keySet()
      GROUP BY AcctSeed__Product__c
    ]) {
      mapIdProductParts.put((Id) p.get('idProduct'), (Decimal) p.get('countParts'));
    }
    /// Generate the products list to update
    List<Product2> listUpdateProducts = new List<Product2>();
    for (Product2 p : [SELECT Id, Parts_Count__c FROM Product2 WHERE Id IN :mapIdProductParts.keySet()]) {
      p.Parts_Count__c = mapIdProductParts.get(p.Id);
      listUpdateProducts.add(p);
    }
    /// Update the count
    if (!listUpdateProducts.isEmpty()) {
      Boolean boolOld = gcProduct.disableTrigger;
      gcProduct.disableTrigger = true;
      update listUpdateProducts;
      gcProduct.disableTrigger = boolOld;
    }
  }
}
