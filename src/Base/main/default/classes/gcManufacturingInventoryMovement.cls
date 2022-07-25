global without sharing class gcManufacturingInventoryMovement {
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

  global static Boolean allowMFGERPSerialWIP {
    get {
      if (allowMFGERPSerialWIP == null)
        return false;
      else
        return allowMFGERPSerialWIP;
    }
    set {
      if (value == null)
        allowMFGERPSerialWIP = false;
      else
        allowMFGERPSerialWIP = value;
    }
  }

  public static void triggerHandler(
    map<Id, AcctSeedERP__Manufacturing_Inventory_Movement__c> oldMap,
    map<Id, AcctSeedERP__Manufacturing_Inventory_Movement__c> newMap,
    list<AcctSeedERP__Manufacturing_Inventory_Movement__c> listNew,
    Boolean boolIsBefore,
    Boolean boolIsInsert,
    Boolean boolIsUpdate,
    Boolean boolIsDelete
  ) {
    if (oldMap == null)
      oldMap = new Map<Id, AcctSeedERP__Manufacturing_Inventory_Movement__c>();
    if (newMap == null)
      newMap = new Map<Id, AcctSeedERP__Manufacturing_Inventory_Movement__c>();
    if (listNew == null)
      listNew = new List<AcctSeedERP__Manufacturing_Inventory_Movement__c>();
    Boolean boolDisableParent = gcMaterial.disableTrigger;
    gcMaterial.disableTrigger = true;
    updateAndValidate(oldMap, newMap, listNew, boolIsBefore, boolIsInsert, boolIsUpdate, boolIsDelete);
    GCR_InventoryMovement.triggerHandler(
      oldMap,
      newMap,
      listNew,
      boolIsBefore,
      boolIsInsert,
      boolIsUpdate,
      boolIsDelete
    );

    if (boolIsBefore) {
      gcSerialNumber.checkPriorMovements(listNew, oldMap);

      if (boolIsInsert) {
      }
      if (boolIsUpdate) {
      }
      if (boolIsDelete) {
      }
    } else //i.e. trigger.isAfter
    {
      Set<String> setIdSerial = new Set<String>();
      if (boolIsInsert) {
        for (AcctSeedERP__Manufacturing_Inventory_Movement__c im : listNew)
          if (im.GMBLASERP__Serial_Number__c != null)
            setIdSerial.add(im.GMBLASERP__Serial_Number__c);
      }
      if (boolIsUpdate) {
        for (AcctSeedERP__Manufacturing_Inventory_Movement__c im : listNew)
          if (im.GMBLASERP__Serial_Number__c != null)
            setIdSerial.add(im.GMBLASERP__Serial_Number__c);
        for (AcctSeedERP__Manufacturing_Inventory_Movement__c im : oldMap.values())
          if (im.GMBLASERP__Serial_Number__c != null)
            setIdSerial.add(im.GMBLASERP__Serial_Number__c);
      }
      if (boolIsDelete) {
        for (AcctSeedERP__Manufacturing_Inventory_Movement__c im : oldMap.values())
          if (im.GMBLASERP__Serial_Number__c != null)
            setIdSerial.add(im.GMBLASERP__Serial_Number__c);
      }
      /// To update serial unit cost run time (future).
      //			if(!setIdSerial.isEmpty()){
      //				List<String> listId = new List<String>();
      //				listId.addAll(setIdSerial);
      //				gcSerialNumber.updateSerialUnitCostFuture(listId);
      //			}
    }
    gcMaterial.disableTrigger = boolDisableParent;
  }

  private static void updateAndValidate(
    map<Id, AcctSeedERP__Manufacturing_Inventory_Movement__c> oldMap,
    map<Id, AcctSeedERP__Manufacturing_Inventory_Movement__c> newMap,
    list<AcctSeedERP__Manufacturing_Inventory_Movement__c> listNew,
    Boolean boolIsBefore,
    Boolean boolIsInsert,
    Boolean boolIsUpdate,
    Boolean boolIsDelete
  ) {
    /// This part is to check if a serialized item is being moved alone from MFG ERP
    Id idRTMFGERP = gcConstants.idRtProjectManufacturing;
    /// This is only used in Dev Org
    Map<Id, Boolean> mapERPIsMFG = new Map<Id, Boolean>();
    if (boolIsBefore && boolIsInsert) {
      for (AcctSeedERP__Manufacturing_Inventory_Movement__c move : listNew) {
        if (move.GMBLASERP__Serial_Number__c != null && move.GMBLASERP__Project__c != null) {
          mapERPIsMFG.put(move.GMBLASERP__Project__c, false);
        }
      }
      if (!mapERPIsMFG.isEmpty()) {
        for (AcctSeed__Project__c pr : [
          SELECT Id
          FROM AcctSeed__Project__c
          WHERE ID IN :mapERPIsMFG.keySet() AND RecordTypeId = :idRTMFGERP
        ]) {
          mapERPIsMFG.put(pr.Id, true);
        }
      }
      for (AcctSeedERP__Manufacturing_Inventory_Movement__c move : listNew) {
        if (move.GMBLASERP__Serial_Number__c != null && move.GMBLASERP__Project__c != null) {
          if (mapERPIsMFG.get(move.GMBLASERP__Project__c) && !allowMFGERPSerialWIP)
            move.addError('Cannot move single serial number from MFG ERP.');
        }
      }
    }

    if (boolIsBefore && (boolIsInsert || boolIsUpdate)) {
      //collect and map the parent materials
      map<Id, AcctSeedERP__Material__c> mapMatl = new Map<Id, AcctSeedERP__Material__c>();
      for (AcctSeedERP__Manufacturing_Inventory_Movement__c move : listNew) {
        mapMatl.put(move.AcctSeedERP__Material__c, null);
      }

      for (AcctSeedERP__Material__c matl : [
        SELECT
          Id,
          AcctSeedERP__GL_Account_Variable_1__c,
          AcctSeedERP__GL_Account_Variable_2__c,
          AcctSeedERP__GL_Account_Variable_3__c,
          AcctSeedERP__GL_Account_Variable_4__c,
          AcctSeedERP__Project__c,
          AcctSeedERP__Project_Task__c
        FROM AcctSeedERP__Material__c
        WHERE Id IN :mapMatl.keySet()
      ]) {
        mapMatl.put(matl.Id, matl);
      }

      for (AcctSeedERP__Manufacturing_Inventory_Movement__c move : listNew) {
        //SET FIELD VALUES
        AcctSeedERP__Material__c matl = mapMatl.get(move.AcctSeedERP__Material__c);

        //set field values on the purchase movement to match field values on the parent purchase order line
        move.AcctSeedERP__GL_Account_Variable_1__c = matl.AcctSeedERP__GL_Account_Variable_1__c;
        move.AcctSeedERP__GL_Account_Variable_2__c = matl.AcctSeedERP__GL_Account_Variable_2__c;
        move.AcctSeedERP__GL_Account_Variable_3__c = matl.AcctSeedERP__GL_Account_Variable_3__c;
        move.AcctSeedERP__GL_Account_Variable_4__c = matl.AcctSeedERP__GL_Account_Variable_4__c;
        move.GMBLASERP__Project__c = matl.AcctSeedERP__Project__c;
        move.GMBLASERP__Project_Task__c = matl.AcctSeedERP__Project_Task__c;
      }
    }

    /// This is only used in Dev Org
    //		if(boolIsBefore && (boolIsInsert || boolIsUpdate)){
    //			for(AcctSeedERP__Manufacturing_Inventory_Movement__c move :listNew)
    //				if(!Test.isRunningTest())move.AcctSeedERP__Ledger__c = 'a128A000003SnkCQAS';
    //		}
  }
}
