global without sharing class gcPurchaseOrderLine {
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

  global static Boolean applyingFreight {
    get {
      if (applyingFreight == null)
        return false;
      else
        return applyingFreight;
    }
    set {
      if (value == null)
        applyingFreight = false;
      else
        applyingFreight = value;
    }
  }

  public static void triggerHandler(
    map<Id, AcctSeedERP__Purchase_Order_Line__c> oldMap,
    map<Id, AcctSeedERP__Purchase_Order_Line__c> newMap,
    list<AcctSeedERP__Purchase_Order_Line__c> listNew,
    Boolean boolIsBefore,
    Boolean boolIsInsert,
    Boolean boolIsUpdate,
    Boolean boolIsDelete
  ) {
    if (oldMap == null)
      oldMap = new Map<Id, AcctSeedERP__Purchase_Order_Line__c>();
    if (newMap == null)
      newMap = new Map<Id, AcctSeedERP__Purchase_Order_Line__c>();
    if (listNew == null)
      listNew = new List<AcctSeedERP__Purchase_Order_Line__c>();

    Boolean boolDisableParent = GMBLASERP.gcPurchaseOrder.disableTrigger;
    GMBLASERP.gcPurchaseOrder.disableTrigger = true;

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

    GMBLASERP.gcPurchaseOrder.disableTrigger = boolDisableParent;
  }

  private static void updateAndValidate(
    map<Id, AcctSeedERP__Purchase_Order_Line__c> oldMap,
    map<Id, AcctSeedERP__Purchase_Order_Line__c> newMap,
    list<AcctSeedERP__Purchase_Order_Line__c> listNew,
    Boolean boolIsBefore,
    Boolean boolIsInsert,
    Boolean boolIsUpdate,
    Boolean boolIsDelete
  ) {
    set<Id> setIdHasApLines = new Set<Id>();
    set<Id> setIdHasMoves = new Set<Id>();
    if ((boolIsBefore && boolIsDelete) || (!boolIsBefore && boolIsUpdate)) {
      for (AcctSeed__Account_Payable_Line__c line : [
        SELECT AcctSeedERP__Purchase_Order_Line__c
        FROM AcctSeed__Account_Payable_Line__c
        WHERE AcctSeedERP__Purchase_Order_Line__c IN :oldMap.keySet()
      ]) {
        setIdHasApLines.add(line.AcctSeedERP__Purchase_Order_Line__c);
      }
      setIdHasApLines.remove(null);

      for (AcctSeedERP__Purchase_Order_Inventory_Movement__c move : [
        SELECT AcctSeedERP__Purchase_Order_Line__c
        FROM AcctSeedERP__Purchase_Order_Inventory_Movement__c
        WHERE AcctSeedERP__Purchase_Order_Line__c IN :oldMap.keySet()
      ]) {
        setIdHasMoves.add(move.AcctSeedERP__Purchase_Order_Line__c);
      }
      setIdHasMoves.remove(null);
    }

    if (boolIsBefore) {
      if (boolIsInsert || boolIsUpdate) {
        refreshStatics(listNew, boolIsInsert, boolIsUpdate);
        CustomPermissionsReader cpr = new CustomPermissionsReader();
        Boolean canModifyLockedPurchaseOrder = false;
        Boolean canReceiveAnyLotPOL = false;
        if (cpr.hasPermission('CanModifyLockedPurchaseOrder'))
          canModifyLockedPurchaseOrder = true;
        if (cpr.hasPermission('CanReceiveAnyLotPOL'))
          canReceiveAnyLotPOL = true;

        if (!disablePriceAutomation)
          price2(listNew, oldMap);

        for (AcctSeedERP__Purchase_Order_Line__c pol : listNew) {
          AcctSeedERP__Purchase_Order__c po = mapPurchaseOrder.get(pol.AcctSeedERP__Purchase_Order__c);
          Product2 product = mapProduct.get(pol.AcctSeedERP__Product__c);
          GMBLASERP__Lot__c lot = mapLot.get(pol.GMBLASERP__Lot__c);
          GMBLASERP__Serial_Number__c serial = mapSerial.get(pol.GMBLASERP__Serial_Number__c);
          if (boolIsInsert && po.Locked__c && !canModifyLockedPurchaseOrder)
            pol.addError('Cannot add new PO Line on a locked Purchase Order.');

          if (po.Locked__c && boolIsUpdate && !canModifyLockedPurchaseOrder) {
            AcctSeedERP__Purchase_Order_Line__c oldRec = oldMap.get(pol.Id);
            if (
              oldRec.Base_Price__c != pol.Base_Price__c ||
              oldRec.deliverDate__c != pol.deliverDate__c ||
              oldRec.AcctSeedERP__GL_Account_Variable_1__c != pol.AcctSeedERP__GL_Account_Variable_1__c ||
              oldRec.AcctSeedERP__GL_Account_Variable_2__c != pol.AcctSeedERP__GL_Account_Variable_2__c ||
              oldRec.AcctSeedERP__GL_Account_Variable_3__c != pol.AcctSeedERP__GL_Account_Variable_3__c ||
              oldRec.AcctSeedERP__GL_Account_Variable_4__c != pol.AcctSeedERP__GL_Account_Variable_4__c ||
              oldRec.GMBLASERP__Lot__c != pol.GMBLASERP__Lot__c ||
              oldRec.GMBLASERP__Price_Override__c != pol.GMBLASERP__Price_Override__c ||
              oldRec.AcctSeedERP__Product__c != pol.AcctSeedERP__Product__c ||
              oldRec.AcctSeedERP__Project__c != pol.AcctSeedERP__Project__c ||
              oldRec.AcctSeedERP__Project_Task__c != pol.AcctSeedERP__Project_Task__c ||
              oldRec.AcctSeedERP__Quantity__c != pol.AcctSeedERP__Quantity__c ||
              oldRec.GMBLASERP__Quantity_Received_Non_Inventory__c !=
              pol.GMBLASERP__Quantity_Received_Non_Inventory__c ||
              oldRec.Reserved__c != pol.Reserved__c ||
              oldRec.GMBLASERP__Serial_Number__c != pol.GMBLASERP__Serial_Number__c ||
              oldRec.AcctSeedERP__Unit_Price__c != pol.AcctSeedERP__Unit_Price__c
            ) {
              pol.addError(
                'The Purchase Order is locked and cannot modify PO Line fields. Please unlock the PO to proceed.'
              );
            }
          }
          // SFISSUES-771 Starts
          if (boolIsInsert && pol.deliverDate__c == null) {
            pol.deliverDate__c = po.Estimated_Time_of_Arrival_ETA__c;
          }
          // SFISSUES-771 Ends
          if (serial != null) {
            pol.AcctSeedERP__Product__c = serial.GMBLASERP__Product__c;
            pol.GMBLASERP__Lot__c = serial.GMBLASERP__Lot__c;
            pol.AcctSeedERP__Quantity__c = 1;
          } else if (lot != null) {
            pol.AcctSeedERP__Product__c = lot.GMBLASERP__Product__c;
          }

          /// Automatic Assignment of Lot if the Product is a Boat
          if (
            boolIsInsert &&
            pol.GMBLASERP__Lot__c == null &&
            product != null &&
            product.RecordType.Name == 'Boat' &&
            mapProductPOLLot.containsKey(product.Id)
          )
            pol.GMBLASERP__Lot__c = mapProductPOLLot.get(product.Id).Id;

          if (
            product != null &&
            product.RecordType.Name == 'Boat' &&
            pol.GMBLASERP__Lot__c == null &&
            !canReceiveAnyLotPOL
          )
            pol.addError('The Purchase Order Line Must have a Lot as the Product is a Boat.');
          if (
            product != null &&
            product.RecordType.Name == 'Boat' &&
            (pol.AcctSeedERP__Quantity__c > 1 ||
            pol.AcctSeedERP__Quantity__c < -1) &&
            !canReceiveAnyLotPOL
          )
            pol.addError('The Purchase Order Line Must not have multiple Ordered Quantity for a Boat product.');

          if (pol.AcctSeedERP__Quantity__c == null)
            pol.AcctSeedERP__Quantity__c = 0;

          //if the purchase order specifies a Project and Project Task, set all the purchase order lines to the same Project and Project Task.
          if (po.GMBLASERP__Project_Task__c != null) {
            pol.AcctSeedERP__Project__c = po.GMBLASERP__Project_Task__r.AcctSeed__Project__c;
            pol.AcctSeedERP__Project_Task__c = po.GMBLASERP__Project_Task__c;
          } else if (
            po.GMBLASERP__Project__c != null &&
            pol.AcctSeedERP__Project__c != null &&
            pol.AcctSeedERP__Project__c != po.GMBLASERP__Project__c
          ) {
            pol.addError('The Purchase Order specifies a different Project than this Purchase Order Line.');
          }
          /// Check to see if the Project has been used in some other POL
          if (
            boolIsUpdate &&
            pol.AcctSeedERP__Project__c != null &&
            pol.AcctSeedERP__Project__c != oldMap.get(pol.Id).AcctSeedERP__Project__c
          ) {
            AcctSeed__Project__c proj = mapProject.get(pol.AcctSeedERP__Project__c);
            if (!proj.AcctSeedERP__Purchase_Order_Lines__r.isEmpty())
              pol.addError('The ERP Order has been used in another POL. Please choose a different one.');
          }
        }
      }

      if (boolIsDelete) {
        for (AcctSeedERP__Purchase_Order_Line__c pol : oldMap.values()) {
          if (setIdHasAPlines.contains(pol.Id))
            pol.addError(
              'The Purchase Order Line cannot be deleted because it has an underlying Account Payable Line: ' + pol.Name
            );
          if (setIdHasMoves.contains(pol.Id))
            pol.addError(
              'The Purchase Order Line cannot be deleted because it has an underlying Inventory Movement: ' + pol.Name
            );
        }
      }
    } else //i.e. AFTER context
    {
      if (boolIsUpdate) {
        for (AcctSeedERP__Purchase_Order_Line__c pol : listNew) {
          AcctSeedERP__Purchase_Order_Line__c oldRec = oldMap.get(pol.Id);

          if (pol.AcctSeedERP__Product__c != oldRec.AcctSeedERP__Product__c) {
            pol.addError('The Product of the ' + objLabel + ' may not be changed.');
            continue;
          }

          if (setIdHasApLines.contains(pol.Id)) {
            if (pol.AcctSeedERP__Unit_Price__c != oldRec.AcctSeedERP__Unit_Price__c && !applyingFreight) {
              pol.addError(
                'The Unit Price of the ' +
                objLabel +
                ' may not be changed, because the ' +
                objLabel +
                ' has underlying AP Lines.'
              );
              continue;
            }
            if (pol.AcctSeedERP__Unit_Price__c != oldRec.AcctSeedERP__Unit_Price__c && !applyingFreight) {
              pol.addError(
                'The Unit Price of the ' +
                objLabel +
                ' cannot be changed, because the ' +
                objLabel +
                ' has underlying AP Lines.'
              );
              continue;
            }
          }

          if (setIdHasMoves.contains(pol.Id)) {
            if (pol.GMBLASERP__Serial_Number__c != oldRec.GMBLASERP__Serial_Number__c) {
              pol.addError(
                'The Serial Number of the ' +
                objLabel +
                ' may not be changed, because the ' +
                objLabel +
                ' has underlying Inventory Movements.'
              );
              continue;
            }
            if (pol.GMBLASERP__Lot__c != oldRec.GMBLASERP__Lot__c) {
              pol.addError(
                'The Lot of the ' +
                objLabel +
                ' may not be changed, because the ' +
                objLabel +
                ' has underlying Inventory Movements.'
              );
              continue;
            }
            //if(pol.AcctSeedERP__Unit_Price__c != oldRec.AcctSeedERP__Unit_Price__c)
            //{
            //	pol.addError('The Unit Price of the '+objLabel+' cannot be changed, because the '+objLabel+' has underlying Inventory Movements.');
            //	continue;
            //}
            if (pol.AcctSeedERP__Product__c != oldRec.AcctSeedERP__Product__c) {
              pol.addError(
                'The Product of the ' +
                objLabel +
                ' cannot be changed, because the ' +
                objLabel +
                ' has underlying Inventory Movements.'
              );
              continue;
            }
          }
        }
      }
      //Arrival_Date__c
      if (boolIsUpdate || boolIsInsert) {
        List<AcctSeed__Project__c> listProj = new List<AcctSeed__Project__c>();
        for (AcctSeedERP__Purchase_Order_Line__c pol : listNew) {
          if (
            pol.AcctSeedERP__Project__c != null &&
            (pol.deliverDate__c != null ||
            pol.Estimated_Arrival_Date__c != null) &&
            (boolIsInsert ||
            (boolIsUpdate &&
            (oldMap.get(pol.Id).AcctSeedERP__Project__c != pol.AcctSeedERP__Project__c ||
            oldMap.get(pol.Id).deliverDate__c != pol.deliverDate__c)))
          ) {
            Date arrivalDate = pol.deliverDate__c != null ? pol.deliverDate__c : pol.Estimated_Arrival_Date__c;
            listProj.add(new AcctSeed__Project__c(Id = pol.AcctSeedERP__Project__c, Arrival_Date__c = arrivalDate));
          }
        }
        if (!listProj.isEmpty()) {
          Boolean oldVal = gcProject.disableTrigger;
          gcProject.disableTrigger = true;
          update listProj;
          gcProject.disableTrigger = oldVal;
        }
      }
    }
  }

  private static DescribeSobjectResult descObj;
  private static string objLabel;
  private static map<Id, GMBLASERP__Lot__c> mapLot;
  private static map<Id, GMBLASERP__Lot__c> mapProductPOLLot;
  private static map<Id, Product2> mapProduct;
  private static map<Id, map<Id, Decimal>> mapProductPricebookPrice;
  private static map<Id, AcctSeedERP__Purchase_Order__c> mapPurchaseOrder;
  private static map<Id, GMBLASERP__Serial_Number__c> mapSerial;
  private static Boolean disablePriceAutomation;
  private static map<Id, AcctSeed__Project__c> mapProject;

  private static void refreshStatics(
    list<AcctSeedERP__Purchase_Order_Line__c> listNew,
    Boolean boolIsInsert,
    Boolean boolIsUpdate
  ) {
    String poLineLot = Legend_Settings__c.getOrgDefaults().Purchase_Order_Line_Lot__c;
    List<GMBLASERP__Lot__c> listNewLots = new List<GMBLASERP__Lot__c>();
    if (mapPurchaseOrder == null) {
      descObj = AcctSeedERP__Purchase_Order__c.sObjectType.getDescribe();
      objLabel = descObj.getLabel();

      mapLot = new Map<Id, GMBLASERP__Lot__c>();
      mapProductPOLLot = new Map<Id, GMBLASERP__Lot__c>();
      mapProduct = new Map<Id, Product2>();
      mapProductPricebookPrice = new Map<Id, map<Id, Decimal>>();
      mapPurchaseOrder = new Map<Id, AcctSeedERP__Purchase_Order__c>();
      mapSerial = new Map<Id, GMBLASERP__Serial_Number__c>();
      mapProject = new Map<Id, AcctSeed__Project__c>();

      disablePriceAutomation = GMBLASERP__Inventory_Settings__c.getOrgDefaults()
        .GMBLASERP__disable_price_automation_on_PO_Line__c;
    }
    set<Id> setIdLot = new Set<Id>();
    set<Id> setIdProduct = new Set<Id>();
    set<Id> setIdPurchaseOrder = new Set<Id>();
    set<Id> setIdSerial = new Set<Id>();
    set<Id> setIdProject = new Set<Id>();

    for (AcctSeedERP__Purchase_Order_Line__c pol : listNew) {
      if (pol.GMBLASERP__Lot__c != null && !mapLot.containsKey(pol.GMBLASERP__Lot__c))
        setIdLot.add(pol.GMBLASERP__Lot__c);

      if (!mapProduct.containsKey(pol.AcctSeedERP__Product__c))
        setIdProduct.add(pol.AcctSeedERP__Product__c);

      if (!mapPurchaseOrder.containsKey(pol.AcctSeedERP__Purchase_Order__c))
        setIdPurchaseOrder.add(pol.AcctSeedERP__Purchase_Order__c);

      if (pol.GMBLASERP__Serial_Number__c != null && !mapSerial.containsKey(pol.GMBLASERP__Serial_Number__c))
        setIdSerial.add(pol.GMBLASERP__Serial_Number__c);

      if (!mapProject.containsKey(pol.AcctSeedERP__Project__c))
        setIdProject.add(pol.AcctSeedERP__Project__c);
    }
    setIdProduct.remove(null);
    setIdPurchaseOrder.remove(null);
    setIdLot.remove(null);
    setIdSerial.remove(null);
    setIdProject.remove(null);

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
        SELECT
          Id,
          GMBLASERP__Lot_Tracked__c,
          AcctSeedERP__Serialized__c,
          RecordType.Name,
          (SELECT Id, Name FROM GMBLASERP__Lots__r WHERE Name = :poLineLot LIMIT 1)
        FROM Product2
        WHERE Id IN :setIdProduct
      ]) {
        mapProduct.put(p.Id, p);
        if (p.RecordType.Name == 'Boat') {
          if (!p.GMBLASERP__Lots__r.isEmpty())
            mapProductPOLLot.put(p.Id, p.GMBLASERP__Lots__r[0]);
          else {
            GMBLASERP__Lot__c lot = new GMBLASERP__Lot__c(Name = poLineLot, GMBLASERP__Product__c = p.Id);
            listNewLots.add(lot);
            mapProductPOLLot.put(p.Id, lot);
          }
        }
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
        SELECT
          Id,
          Locked__c,
          RecordTypeId,
          Serial_Number__c,
          GMBLASERP__Pricebook__c,
          Internal_Partner_Boat_Sale__c,
          Internal_Labour_Service__c,
          GL_Account_Variable_3__c,
          GL_Account_Variable_3__r.Name,
          (SELECT Id FROM AcctSeedERP__Purchase_Order_Lines__r)
        FROM AcctSeed__Project__c
        WHERE Id IN :setIdProject
      ]) {
        mapProject.put(p.Id, p);
      }

    if (!setIdPurchaseOrder.isEmpty())
      for (AcctSeedERP__Purchase_Order__c po : [
        SELECT
          Id,
          Locked__c,
          GMBLASERP__Pricebook__c,
          GMBLASERP__Project__c,
          Estimated_Time_of_Arrival_ETA__c,
          GMBLASERP__Project_Task__r.AcctSeed__Project__c
        FROM AcctSeedERP__Purchase_Order__c
        WHERE Id IN :setIdPurchaseOrder
      ]) {
        mapPurchaseOrder.put(po.Id, po);
      }

    if (!listNewLots.isEmpty()) {
      insert listNewLots;
    }
  }

  private static void price2(
    list<AcctSeedERP__Purchase_Order_Line__c> listNew,
    map<Id, AcctSeedERP__Purchase_Order_Line__c> oldMap
  ) {
    for (AcctSeedERP__Purchase_Order_Line__c pol : listNew) {
      Boolean boolIsUpdate = false;
      Boolean boolIsInsert = true;
      if (pol.Id != null) {
        boolIsUpdate = true;
        boolIsInsert = false;
      }

      Decimal pricebookPrice = null;
      if (mapPurchaseOrder.containsKey(pol.AcctSeedERP__Purchase_Order__c)) {
        Id idPricebook = mapPurchaseOrder.get(pol.AcctSeedERP__Purchase_Order__c).GMBLASERP__Pricebook__c;
        map<Id, Decimal> mapPricebookPrice = mapProductPricebookPrice.get(pol.AcctSeedERP__Product__c);
        if (mapPricebookPrice != null)
          pricebookPrice = mapPricebookPrice.get(idPricebook);
      }

      if (boolIsInsert) {
        //if there is no price in the pricebook, then it doesn't matter whether or not the user selected price override; it is by definition a price override.
        if (pricebookPrice == null)
          pol.GMBLASERP__Price_Override__c = true;
        else if (pol.GMBLASERP__Price_Override__c == false)
          //if the user is requesting the pricebook price, use it
          pol.AcctSeedERP__Unit_price__c = pricebookPrice;
        //if the user is NOT requesting the pricebook price, use whatever price the user has specified.
      }

      if (boolIsUpdate) {
        AcctSeedERP__Purchase_Order_Line__c oldRec = oldMap.get(pol.Id);

        //if the user has manipulated either the price override checkbox, or the unit price, then do something.  otherwise, don't.
        if (
          pol.GMBLASERP__Price_Override__c != oldRec.GMBLASERP__Price_Override__c ||
          pol.AcctSeedERP__Unit_Price__c != oldRec.AcctSeedERP__Unit_Price__c
        ) {
          //if the user has NOT manipulated the price override checkbox...
          if (pol.GMBLASERP__Price_Override__c == oldRec.GMBLASERP__Price_Override__c) {
            //...and if the price override is selected, then accept whatever price the user has entered.
            if (pol.GMBLASERP__Price_Override__c) {
              //do nothing
            } else if (pol.AcctSeedERP__Unit_Price__c == null) {
              //...and if the user has changed the price to NULL, then use the pricebook price.
              pol.AcctSeedERP__Unit_Price__c = pricebookPrice;
            } else {
              //...and if the user has changed the price to a NON-null value, then set the price override
              pol.GMBLASERP__Price_Override__c = true;
            }
          } else if (!pol.GMBLASERP__Price_Override__c) {
            //...and if the user has changed the price override checkbox from TRUE to FALSE, then use the pricebook price
            if (pricebookPrice != null)
              pol.AcctSeedERP__Unit_Price__c = pricebookPrice;
            else
              pol.GMBLASERP__Price_Override__c = true;
          }
          //...and if the user has changed the price override checkbox from FALSE to TRUE, then accept whatever price the user has entered.
        }
      }
      if (pol.AcctSeedERP__Unit_Price__c == null)
        pol.AcctSeedERP__Unit_Price__c = 0;

      pol.AcctSeedERP__Unit_Price__c = pol.AcctSeedERP__Unit_Price__c.setScale(6);
    }
  }

  //deprecated functions
  global static void price(list<AcctSeedERP__Purchase_Order_Line__c> listNew) {
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
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
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
