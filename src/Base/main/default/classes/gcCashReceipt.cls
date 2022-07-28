public without sharing class gcCashReceipt {
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
    map<Id, AcctSeed__Cash_Receipt__c> oldMap,
    map<Id, AcctSeed__Cash_Receipt__c> newMap,
    list<AcctSeed__Cash_Receipt__c> listNew,
    Boolean boolIsBefore,
    Boolean boolIsInsert,
    Boolean boolIsUpdate,
    Boolean boolIsDelete
  ) {
    if (oldMap == null)
      oldMap = new Map<Id, AcctSeed__Cash_Receipt__c>();
    if (newMap == null)
      newMap = new Map<Id, AcctSeed__Cash_Receipt__c>();
    if (listNew == null)
      listNew = new List<AcctSeed__Cash_Receipt__c>();
    System.debug('@@ before listNew ' + listNew);
    updateAndValidate(oldMap, newMap, listNew, boolIsBefore, boolIsInsert, boolIsUpdate, boolIsDelete);

    if (boolIsBefore) {
      if (boolIsInsert) {
        System.debug('gcCashReceipt.isBeforeInsert');
        for (AcctSeed__Cash_Receipt__c cr : listNew) {
          if (cr.AcctSeed__Ledger__c == null)
            cr.AcctSeed__Ledger__c = gcConstants.idActualLedger;
        }
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

  public static void updateAndValidate(
    map<Id, AcctSeed__Cash_Receipt__c> oldMap,
    map<Id, AcctSeed__Cash_Receipt__c> newMap,
    list<AcctSeed__Cash_Receipt__c> listNew,
    Boolean boolIsBefore,
    Boolean boolIsInsert,
    Boolean boolIsUpdate,
    Boolean boolIsDelete
  ) {
    if (boolIsBefore && (boolIsUpdate || boolIsInsert)) {
      //code pulled from GMBLASG package gcCashReceipt class
      setPeriod(oldMap, newMap, listNew, boolIsBefore, boolIsInsert, boolIsUpdate, boolIsDelete);
      System.debug('@@ listNew= ' + listNew);
      retrieveStatics(listNew);
      for (AcctSeed__Cash_Receipt__c cr : listNew) {
        cr.Uniquefier__c = cr.AcctSeed__Account__c + '' + cr.AcctSeed__Payment_Reference__c;
        if (boolIsUpdate) {
          AcctSeed__Cash_Receipt__c oldRec = oldMap.get(cr.Id);
          if (
            cr.GMBLASG__Posted__c &&
            (cr.AcctSeed__Payment_Reference__c != oldRec.AcctSeed__Payment_Reference__c ||
            cr.Payment_Method__c != oldRec.Payment_Method__c ||
            cr.AcctSeed__Purpose__c != oldRec.AcctSeed__Purpose__c)
          ) {
            cr.addError(
              'You cannot update the Payment Reference, Method or Type fields on a posted record. You must unpost the record to edit any of these fields.'
            );
          }
        }
        if (boolIsInsert || (boolIsUpdate && cr.AcctSeed__Bank_Account__c == null))
          setBankGL(cr);
        if (cr.Payment_Method__c == 'Legend Bucks' && !cr.Is_Legend_Employee__c)
          cr.addError('To Use Legend bucks the customer must be a Legend Employee.');
        if (mapUser != null) {
          System.debug('mapUser:' + mapUser);
          System.debug('UserInfo.getUserId():' + UserInfo.getUserId());
          User usr = mapUser.get(UserInfo.getUserId());
          System.debug('usr:' + usr);
          if (usr != null) {
            String glv1Name = usr.GL_Account_Variable_1__c;
            System.debug('glv1Name:' + glv1Name);
            if (
              cr.AcctSeed__GL_Account_Variable_1__c == null &&
              !cr.GMBLASG__Posted__c &&
              glv1Name != null &&
              mapGlv1ByName.containsKey(glv1Name)
            ) {
              cr.AcctSeed__GL_Account_Variable_1__c = mapGlv1ByName.get(glv1Name).Id;
            }
          }
        }
      }
    }

    if (!boolIsBefore && (boolIsInsert || boolIsUpdate)) {
      System.debug('in is before');
      list<AcctSeed__Cash_Receipt__c> listAll = new List<AcctSeed__Cash_Receipt__c>();
      list<AcctSeed__Cash_Receipt__c> lstCashReceipt = new List<AcctSeed__Cash_Receipt__c>();
      listAll.addAll(listNew);
      listAll.addAll(oldMap.values());
      Set<Id> setIdProject = new Set<Id>();
      for (AcctSeed__Cash_Receipt__c cr : listAll) {
        if (cr.AcctSeed__Project__c != null && cr.GMBLASG__Posted__c)
          setIdProject.add(cr.AcctSeed__Project__c);
      }
      for (AcctSeed__Cash_Receipt__c cr : listNew) {
        if (!cr.GMBLASG__Posted__c && cr.Sales_Order__c != null) {
          lstCashReceipt.add(cr);
        }
      }
      if (!setIdProject.isEmpty())
        gcProject.lockIfNoBalanceDueFuture(setIdProject);

      AcctSeed.PostResult[] postResultsAP = AcctSeed.CashReceiptPostService.postCashReceipts(lstCashReceipt);
      //			for (AcctSeed.PostResult theResult : postResultsAP) {
      //				if (!theResult.isSuccess) {
      //					for (AcctSeed.PostResult.PostErrorResult errorResult: theResult.errors) {
      //						throw new gcException('Cash Receipt was not posted. Please try again. REASON: ' + errorResult.message);
      //					}
      //				}
      //			}
    }
  }

  public static void setPeriod(
    map<Id, AcctSeed__Cash_Receipt__c> oldMap,
    map<Id, AcctSeed__Cash_Receipt__c> newMap,
    list<AcctSeed__Cash_Receipt__c> listNew,
    Boolean boolIsBefore,
    Boolean boolIsInsert,
    Boolean boolIsUpdate,
    Boolean boolIsDelete
  ) {
    if (boolIsBefore && (boolIsInsert || boolIsUpdate)) {
      list<AcctSeed__Cash_Receipt__c> listRecordToSetPeriod = new List<AcctSeed__Cash_Receipt__c>();

      for (AcctSeed__Cash_Receipt__c cr : listNew) {
        if (cr.AcctSeed__Status__c == 'Posted')
          continue;

        if (
          (boolIsInsert && cr.AcctSeed__Accounting_Period__c == null) ||
          (boolIsUpdate &&
          (cr.AcctSeed__Receipt_Date__c != oldMap.get(cr.Id).AcctSeed__Receipt_Date__c ||
          cr.AcctSeed__Accounting_Period__c != oldMap.get(cr.Id).AcctSeed__Accounting_Period__c))
        ) {
          listRecordToSetPeriod.add(cr);
        }
      }
      if (listRecordToSetPeriod.size() > 0) {
        Map<Date, AcctSeed__Accounting_Period__c> mapDateToPeriod = mapPeriods(listRecordToSetPeriod);
        for (AcctSeed__Cash_Receipt__c cr : listRecordToSetPeriod) {
          AcctSeed__Accounting_Period__c p = mapDateToPeriod.get(cr.AcctSeed__Receipt_Date__c);

          if (p == null) {
            cr.addError('The receipt date cannot be set to a date for which a period does not exist.');
          } else if (p.AcctSeed__Status__c != 'Open') {
            cr.addError('The receipt date cannot be set to a date that is within a closed period.');
          } else {
            cr.AcctSeed__Accounting_Period__c = p.Id;
          }
        }
      }
    }
  }

  private static Map<Date, AcctSeed__Accounting_Period__c> mapPeriods(
    List<AcctSeed__Cash_Receipt__c> listRecordToSetPeriod
  ) {
    Map<Date, AcctSeed__Accounting_Period__c> mapDateToPeriod = new Map<Date, AcctSeed__Accounting_Period__c>();
    for (AcctSeed__Cash_Receipt__c cr : listRecordToSetPeriod) {
      mapDateToPeriod.put(cr.AcctSeed__Receipt_Date__c, null);
    }

    Date dateMax;
    Date dateMin;

    for (Date d : mapDateToPeriod.keySet()) {
      if (dateMin == null || d < dateMin)
        dateMin = d;

      if (dateMax == null || d > dateMax)
        dateMax = d;
    }

    for (AcctSeed__Accounting_Period__c p : [
      SELECT Id, AcctSeed__Start_Date__c, AcctSeed__End_Date__c, AcctSeed__Status__c
      FROM AcctSeed__Accounting_Period__c
      WHERE AcctSeed__Start_Date__c <= :dateMax AND AcctSeed__End_Date__c >= :dateMin
    ]) {
      for (Date d : mapDateToPeriod.keySet()) {
        if (p.AcctSeed__Start_Date__c <= d && p.AcctSeed__End_Date__c >= d) {
          mapDateToPeriod.put(d, p);
        }
      }
    }
    return mapDateToPeriod;
  }

  private static void setBankGL(AcctSeed__Cash_Receipt__c cr) {
    Id idGlGiftCards = gcConstants.idGlGiftCards;
    Id idGlMerchantDebitCredit = gcConstants.idGlMerchantDebitCredit;
    Id idGlCashFloat = gcConstants.idGlCashFloat;
    Id idGlRBCCDN = gcConstants.idGlRBCCDN;
    String paymentMethod = cr.Payment_Method__c;
    if (
      paymentMethod == 'MasterCard' ||
      paymentMethod == 'Visa' ||
      paymentMethod == 'Debit' ||
      paymentMethod == 'Accord D'
    )
      cr.AcctSeed__Bank_Account__c = gcConstants.idGlMerchantDebitCredit;
    else if (paymentMethod == 'Cheque' || paymentMethod == 'Check' || paymentMethod == 'Draft')
      cr.AcctSeed__Bank_Account__c = gcConstants.idGlRBCCDN;
    else if (paymentMethod == 'Cash')
      cr.AcctSeed__Bank_Account__c = gcConstants.idGlCashFloat;
    else if (paymentMethod == 'Gift Cards')
      cr.AcctSeed__Bank_Account__c = gcConstants.idGlGiftCards;
    else if (paymentMethod == 'Legend Bucks')
      cr.AcctSeed__Bank_Account__c = gcConstants.idGlLegendBucks;
    else if (paymentMethod == 'Online Store')
      cr.AcctSeed__Bank_Account__c = gcConstants.idGlMerchantOnline;
    else
      cr.AcctSeed__Bank_Account__c = gcConstants.idGlRBCCDN;
  }

  private static map<Id, AcctSeed__Project__c> mapProject;
  private static map<String, AcctSeed__Accounting_Variable__c> mapGlv1ByName;
  private static map<Id, User> mapUser;

  private static void retrieveStatics(list<AcctSeed__Cash_Receipt__c> listNew) {
    set<Id> setIdProject = new Set<Id>();
    set<String> setNameGlv = new Set<String>();

    if (mapProject == null) {
      mapProject = new Map<Id, AcctSeed__Project__c>();
      mapGlv1ByName = new Map<String, AcctSeed__Accounting_Variable__c>();
      mapUser = new Map<Id, User>();
    }

    for (AcctSeed__Cash_Receipt__c cr : listNew) {
      if (cr.AcctSeed__Project__c != null && !mapProject.containsKey(cr.AcctSeed__Project__c))
        setIdProject.add(cr.AcctSeed__Project__c);
    }

    if (!setIdProject.isEmpty())
      for (AcctSeed__Project__c project : [
        SELECT Id, Name, Locked__c, AcctSeed__Status__c
        FROM AcctSeed__Project__c
        WHERE Id IN :setIdProject
      ]) {
        mapProject.put(project.Id, project);
      }

    for (User u : [SELECT Id, GL_Account_Variable_1__c FROM User WHERE Id = :UserInfo.getUserId()]) {
      if (u.GL_Account_Variable_1__c != null)
        setNameGlv.add(u.GL_Account_Variable_1__c);

      mapUser.put(u.Id, u);
    }

    if (!setNameGlv.isEmpty())
      for (AcctSeed__Accounting_Variable__c glv : [
        SELECT
          Id,
          Name,
          Tax_is_Harmonized__c,
          Tax_Rate_Provincial__c,
          Tax_Rate_Retail__c,
          GL_Account_Variable_3__c,
          AcctSeed__Type__c
        FROM AcctSeed__Accounting_Variable__c
        WHERE Name IN :setNameGlv
      ]) {
        if (glv.AcctSeed__Type__c.equals('GL Account Variable 1'))
          mapGlv1ByName.put(glv.Name, glv);
      }
  }
}
