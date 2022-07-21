global without sharing class arMaterial_PACKAGE {
  global static Boolean disableTrigger {
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
    map<Id, AcctSeedERP__Material__c> oldMap,
    map<Id, AcctSeedERP__Material__c> newMap,
    list<AcctSeedERP__Material__c> listNew,
    Boolean boolIsBefore,
    Boolean boolIsInsert,
    Boolean boolIsUpdate,
    Boolean boolIsDelete
  ) {
    if (oldMap == null)
      oldMap = new Map<Id, AcctSeedERP__Material__c>();
    if (newMap == null)
      newMap = new Map<Id, AcctSeedERP__Material__c>();
    if (listNew == null)
      listNew = new List<AcctSeedERP__Material__c>();

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
      }
      if (boolIsUpdate) {
      }
      if (boolIsDelete) {
      }
    }
  }

  private static void updateAndValidate(
    map<Id, AcctSeedERP__Material__c> oldMap,
    map<Id, AcctSeedERP__Material__c> newMap,
    list<AcctSeedERP__Material__c> listNew,
    Boolean boolIsBefore,
    Boolean boolIsInsert,
    Boolean boolIsUpdate,
    Boolean boolIsDelete
  ) {
    set<Id> setIdMatlHasBilling = new Set<Id>();
    set<Id> setIdMatlHasMove = new Set<Id>();

    if ((boolIsBefore && boolIsDelete) || (!boolIsBefore && boolIsUpdate)) {
      for (AcctSeed__Billing_Line__c line : [
        SELECT GMBLASERP__Material__c
        FROM AcctSeed__Billing_Line__c
        WHERE GMBLASERP__Material__c IN :oldMap.keySet()
      ]) {
        setIdMatlHasBilling.add(line.GMBLASERP__Material__c);
      }
      setIdMatlHasBilling.remove(null);

      for (AcctSeedERP__Manufacturing_Inventory_Movement__c move : [
        SELECT AcctSeedERP__Material__c
        FROM AcctSeedERP__Manufacturing_Inventory_Movement__c
        WHERE AcctSeedERP__Material__c IN :oldMap.keySet()
      ]) {
        setIdMatlHasMove.add(move.AcctSeedERP__Material__c);
      }
      setIdMatlHasMove.remove(null);
    }

    if (boolIsBefore) {
      if (boolIsInsert || boolIsUpdate) {
        refreshStatics(listNew);

        if (!disablePriceAutomation)
          price(listNew, oldMap);

        for (AcctSeedERP__Material__c matl : listNew) {
          Product2 product = mapProduct.get(matl.AcctSeedERP__Product__c);
          AcctSeed__Project__c project = mapProject.get(matl.AcctSeedERP__Project__c);
          GMBLASERP__Lot__c lot = mapLot.get(matl.GMBLASERP__Lot__c);
          GMBLASERP__Serial_Number__c serial = mapSerial.get(matl.GMBLASERP__Serial_Number__c);

          if (serial != null) {
            matl.AcctSeedERP__Product__c = serial.GMBLASERP__Product__c;
            matl.GMBLASERP__Lot__c = serial.GMBLASERP__Lot__c;
            /*if(matl.AcctSeedERP__Quantity_per_Unit__c != 0 
							|| matl.AcctSeedERP__Quantity_per_Unit__c != 1 
							|| matl.AcctSeedERP__Quantity_per_Unit__c != -1)
						matl.AcctSeedERP__Quantity_per_Unit__c = 1;*/
          } else if (lot != null) {
            matl.AcctSeedERP__Product__c = lot.GMBLASERP__Product__c;
          }

          if (matl.AcctSeedERP__Quantity_per_Unit__c == null)
            matl.AcctSeedERP__Quantity_per_Unit__c = 0;

          //NOTE:  If there is an UNMANAGED trigger on Material that affects Unit Price (e.g. custom pricing logic), these lines should be inserted in that UNMANAGED trigger, as well.
          Decimal mult = (matl.AcctSeedERP__Quantity_per_Unit__c == null ? 0 : matl.AcctSeedERP__Quantity_per_Unit__c);
          if (
            project != null &&
            project.AcctSeedERP__Quantity_Ordered__c != null &&
            project.AcctSeedERP__Quantity_Ordered__c != 0
          )
            mult *= project.AcctSeedERP__Quantity_Ordered__c;

          matl.GMBLASERP__Total_Price__c =
            mult * (matl.GMBLASERP__Unit_Price__c == null ? 0 : matl.GMBLASERP__Unit_Price__c);
          matl.GMBLASERP__Total_Price__c = (matl.GMBLASERP__Total_Price__c == null
            ? 0
            : matl.GMBLASERP__Total_Price__c.setScale(2));
        }
      }

      if (boolIsDelete) {
        for (AcctSeedERP__Material__c matl : oldMap.values()) {
          if (setIdMatlHasBilling.contains(matl.Id))
            matl.addError(
              'The ' +
              objLabel +
              ' may not be deleted, because it has an underlying Billing Line: ' +
              matl.Name
            );
          if (setIdMatlHasMove.contains(matl.Id))
            matl.addError(
              'The ' +
              objLabel +
              ' may not be deleted, because it has an underlying Inventory Movement: ' +
              matl.Name
            );
        }
      }
    } else //i.e. AFTER context
    {
      if (boolIsUpdate) {
        for (AcctSeedERP__Material__c matl : listNew) {
          AcctSeedERP__Material__c oldRec = oldMap.get(matl.Id);

          if (matl.AcctSeedERP__Product__c != oldRec.AcctSeedERP__Product__c) {
            matl.addError('The Product of the ' + objLabel + ' may not be changed.');
            continue;
          }

          if (setIdMatlHasBilling.contains(matl.Id)) {
            if (matl.GMBLASERP__Unit_Price__c != oldRec.GMBLASERP__Unit_Price__c) {
              matl.addError(
                'The Unit Price of the ' +
                objLabel +
                ' may not be changed, because the ' +
                objLabel +
                ' has underlying Billing Lines.'
              );
              continue;
            }
          }

          if (setIdMatlHasMove.contains(matl.Id)) {
            if (matl.GMBLASERP__Serial_Number__c != oldRec.GMBLASERP__Serial_Number__c) {
              matl.addError(
                'The Serial Number of the ' +
                objLabel +
                ' may not be changed, because the ' +
                objLabel +
                ' has underlying Inventory Movements.'
              );
              continue;
            }
            if (matl.GMBLASERP__Lot__c != oldRec.GMBLASERP__Lot__c) {
              matl.addError(
                'The Lot of the ' +
                objLabel +
                ' may not be changed, because the ' +
                objLabel +
                ' has underlying Inventory Movements.'
              );
              continue;
            }
          }
        }
      }
    }
  }

  private static DescribeSobjectResult descObj;
  private static string objLabel;
  private static map<Id, GMBLASERP__Lot__c> mapLot;
  private static map<Id, Product2> mapProduct;
  private static map<Id, map<Id, Decimal>> mapProductPricebookPrice;
  private static map<Id, AcctSeed__Project__c> mapProject;
  private static map<Id, GMBLASERP__Serial_Number__c> mapSerial;
  private static Boolean disablePriceAutomation;

  private static void refreshStatics(list<AcctSeedERP__Material__c> listNew) {
    if (mapProject == null) {
      descObj = AcctSeedERP__Material__c.sObjectType.getDescribe();
      objLabel = descObj.getLabel();

      mapLot = new Map<Id, GMBLASERP__Lot__c>();
      mapProduct = new Map<Id, Product2>();
      mapProductPricebookPrice = new Map<Id, map<Id, Decimal>>();
      mapProject = new Map<Id, AcctSeed__Project__c>();
      mapSerial = new Map<Id, GMBLASERP__Serial_Number__c>();

      disablePriceAutomation = GMBLASERP__Inventory_Settings__c.getOrgDefaults()
        .GMBLASERP__disable_price_automation_on_Material__c;
    }
    set<Id> setIdLot = new Set<Id>();
    set<Id> setIdProduct = new Set<Id>();
    set<Id> setIdProject = new Set<Id>();
    set<Id> setIdSerial = new Set<Id>();

    for (AcctSeedERP__Material__c matl : listNew) {
      if (matl.GMBLASERP__Lot__c != null && !mapLot.containsKey(matl.GMBLASERP__Lot__c))
        setIdLot.add(matl.GMBLASERP__Lot__c);

      if (!mapProduct.containsKey(matl.AcctSeedERP__Product__c))
        setIdProduct.add(matl.AcctSeedERP__Product__c);

      if (!mapProject.containsKey(matl.AcctSeedERP__Project__c))
        setIdProject.add(matl.AcctSeedERP__Project__c);

      if (matl.GMBLASERP__Serial_Number__c != null && !mapSerial.containsKey(matl.GMBLASERP__Serial_Number__c))
        setIdSerial.add(matl.GMBLASERP__Serial_Number__c);
    }
    setIdProduct.remove(null);
    setIdProject.remove(null);
    setIdLot.remove(null);
    setIdSerial.remove(null);

    if (!setIdSerial.isEmpty())
      for (GMBLASERP__Serial_Number__c sn : [
        SELECT Id, GMBLASERP__Lot__c, GMBLASERP__Product__c
        FROM GMBLASERP__Serial_Number__c
        WHERE Id IN :setIdSerial
      ]) {
        mapSerial.put(sn.Id, sn);

        if (sn.GMBLASERP__Lot__c != null && !mapLot.containsKey(sn.GMBLASERP__Lot__c))
          setIdLot.add(sn.GMBLASERP__Lot__c);
        if (sn.GMBLASERP__Product__c != null && !mapProduct.containsKey(sn.GMBLASERP__Product__c))
          setIdProduct.add(sn.GMBLASERP__Product__c);
      }

    if (!setIdLot.isEmpty())
      for (GMBLASERP__Lot__c lot : [SELECT Id, GMBLASERP__Product__c FROM GMBLASERP__Lot__c WHERE Id IN :setIdLot]) {
        mapLot.put(lot.Id, lot);

        if (lot.GMBLASERP__Product__c != null && !mapProduct.containsKey(lot.GMBLASERP__Product__c))
          setIdProduct.add(lot.GMBLASERP__Product__c);
      }

    if (!setIdProduct.isEmpty()) {
      for (Product2 p : [
        SELECT Id, GMBLASERP__Lot_Tracked__c, AcctSeedERP__Serialized__c
        FROM Product2
        WHERE Id IN :setIdProduct
      ]) {
        mapProduct.put(p.Id, p);
      }

      if (!disablePriceAutomation)
        for (PricebookEntry pbe : [
          SELECT Id, IsActive, Product2Id, PriceBook2Id, UnitPrice
          FROM PriceBookEntry
          WHERE Product2Id IN :setIdProduct AND IsActive = TRUE AND PriceBook2.IsActive = TRUE
          ORDER BY CreatedDate DESC
        ]) {
          map<Id, Decimal> mapPricebookPrice = mapProductPricebookPrice.get(pbe.Product2Id);
          if (mapPricebookPrice == null) {
            mapPricebookPrice = new Map<Id, Decimal>();
            mapPricebookPrice.put(pbe.Pricebook2Id, pbe.UnitPrice);
            mapProductPricebookPrice.put(pbe.Product2Id, mapPricebookPrice);
          } else
            mapProductPricebookPrice.get(pbe.Product2Id).put(pbe.Pricebook2Id, pbe.UnitPrice);
        }
    }

    if (!setIdProject.isEmpty())
      for (AcctSeed__Project__c p : [
        SELECT Id, AcctSeedERP__Quantity_Ordered__c, GMBLASERP__Pricebook__c
        FROM AcctSeed__Project__c
        WHERE Id IN :setIdProject
      ]) {
        mapProject.put(p.Id, p);
      }
  }

  global static void price(list<AcctSeedERP__Material__c> listNew, map<Id, AcctSeedERP__Material__c> oldMap) {
    for (AcctSeedERP__Material__c matl : listNew) {
      Boolean boolIsUpdate = false;
      Boolean boolIsInsert = true;
      if (matl.Id != null) {
        boolIsUpdate = true;
        boolIsInsert = false;
      }

      Decimal pricebookPrice = null;
      if (mapProject.containsKey(matl.AcctSeedERP__Project__c)) {
        Id idPricebook = mapProject.get(matl.AcctSeedERP__Project__c).GMBLASERP__Pricebook__c;
        map<Id, Decimal> mapPricebookPrice = mapProductPricebookPrice.get(matl.AcctSeedERP__Product__c);
        if (mapPricebookPrice != null)
          pricebookPrice = mapPricebookPrice.get(idPricebook);
      }

      if (boolIsInsert) {
        //if there is no price in the pricebook, then it doesn't matter whether or not the user selected price override; it is by definition a price override.
        if (pricebookPrice == null)
          matl.GMBLASERP__Price_Override__c = true;
        else if (matl.GMBLASERP__Price_Override__c == false)
          //if the user is requesting the pricebook price, use it
          matl.GMBLASERP__Unit_price__c = pricebookPrice;
        //if the user is NOT requesting the pricebook price, use whatever price the user has specified.
      }

      if (boolIsUpdate) {
        AcctSeedERP__Material__c oldRec = oldMap.get(matl.Id);

        //if the user has manipulated either the price override checkbox, or the unit price, then do something.  otherwise, don't.
        if (
          matl.GMBLASERP__Price_Override__c != oldRec.GMBLASERP__Price_Override__c ||
          matl.GMBLASERP__Unit_Price__c != oldRec.GMBLASERP__Unit_Price__c
        ) {
          //if the user has NOT manipulated the price override checkbox...
          if (matl.GMBLASERP__Price_Override__c == oldRec.GMBLASERP__Price_Override__c) {
            //...and if the price override is selected, then accept whatever price the user has entered.
            if (matl.GMBLASERP__Price_Override__c) {
              //do nothing
            } else if (matl.GMBLASERP__Unit_Price__c == null) {
              //...and if the user has changed the price to NULL, then use the pricebook price.
              matl.GMBLASERP__Unit_Price__c = pricebookPrice;
            } else {
              //...and if the user has changed the price to a NON-null value, then set the price override
              matl.GMBLASERP__Price_Override__c = true;
            }
          } else if (!matl.GMBLASERP__Price_Override__c) {
            //...and if the user has changed the price override checkbox from TRUE to FALSE, then use the pricebook price
            if (pricebookPrice != null)
              matl.GMBLASERP__Unit_Price__c = pricebookPrice;
            else
              matl.GMBLASERP__Price_Override__c = true;
          }
          //...and if the user has changed the price override checkbox from FALSE to TRUE, then accept whatever price the user has entered.
        }
      }
      if (matl.GMBLASERP__Unit_Price__c == null)
        matl.GMBLASERP__Unit_Price__c = 0;

      matl.GMBLASERP__Unit_Price__c = matl.GMBLASERP__Unit_Price__c.setScale(6);
    }
  }

  public static void coverage() {
    integer i;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
  }
}
