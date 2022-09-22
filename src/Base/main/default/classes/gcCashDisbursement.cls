public without sharing class gcCashDisbursement {
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

  private static final Set<String> POSTED_LOCKED_FIELDS = new Set<String>{
    'AcctSeed__Check_Number__c',
    'AcctSeed__Reference__c',
    'AcctSeed__Type__c',
    'AcctSeed__Employee__c',
    'AcctSeed__Contact__c',
    'AcctSeed__Vendor__c',
    'AcctSeed__GL_Account_Variable_1__c',
    'AcctSeed__GL_Account_Variable_2__c',
    'AcctSeed__GL_Account_Variable_3__c',
    'AcctSeed__GL_Account_Variable_4__c',
    'AcctSeed__Bank_Account__c',
    'AcctSeed__Debit_GL_Account__c',
    'AcctSeed__Disbursement_Date__c',
    'AcctSeed__Project__c',
    'AcctSeed__Project_Task__c',
    'AcctSeed__Source__c'
  };

  public static void triggerHandler(
    map<Id, AcctSeed__Cash_Disbursement__c> oldMap,
    map<Id, AcctSeed__Cash_Disbursement__c> newMap,
    list<AcctSeed__Cash_Disbursement__c> listNew,
    Boolean boolIsBefore,
    Boolean boolIsInsert,
    Boolean boolIsUpdate,
    Boolean boolIsDelete
  ) {
    if (oldMap == null)
      oldMap = new Map<Id, AcctSeed__Cash_Disbursement__c>();
    if (newMap == null)
      newMap = new Map<Id, AcctSeed__Cash_Disbursement__c>();
    if (listNew == null)
      listNew = new List<AcctSeed__Cash_Disbursement__c>();

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

  public static void updateAndValidate(
    map<Id, AcctSeed__Cash_Disbursement__c> oldMap,
    map<Id, AcctSeed__Cash_Disbursement__c> newMap,
    list<AcctSeed__Cash_Disbursement__c> listNew,
    Boolean boolIsBefore,
    Boolean boolIsInsert,
    Boolean boolIsUpdate,
    Boolean boolIsDelete
  ) {
    if (boolIsBefore && (boolIsUpdate || boolIsInsert)) {
      retrieveStatics(listNew);
      User usr = mapUser.get(UserInfo.getUserId());
      String glv1Name = usr.GL_Account_Variable_1__c;
      for (AcctSeed__Cash_Disbursement__c cd : listNew) {
        //cd.AcctSeed__Ledger__c = 'a121D000001muWMQAY';
        if (!cd.GMBLASG__Posted__c) {
          if (cd.AcctSeed__Reference__c != null && cd.AcctSeed__Reference__c.contains('refund')) {
            cd.AcctSeed__Cash_Flow_Category__c = gcConstants.idGlRevenueCF;
          }
          /// SFISSUES-970
          if (
            cd.AcctSeed__Bank_Account__c == gcConstants.idGlCCPayable &&
            cd.AcctSeed__GL_Account_Variable_4__c == null
          ) {
            cd.addError('For Company Credit Card a GL Variable 4 must be selected.');
          }
          /// SFISSUES-778
          if (cd.AcctSeed__Check_Number__c != null && cd.AcctSeed__Bank_Account__c != null) {
            cd.Unique_Check_Number__c = cd.AcctSeed__Bank_Account__c + String.valueOf(cd.AcctSeed__Check_Number__c);
          }
          // SFISSUES-2086
          if (cd.AcctSeed__Check_Number__c == null) {
            cd.Unique_Check_Number__c = null;
          }
        }
        if (!cd.GMBLASG__Posted__c && (boolIsInsert || (boolIsUpdate && cd.AcctSeed__Bank_Account__c == null))) {
          System.debug('Not Posted');
          setBankGL(cd);
        }
        if (boolIsUpdate) {
          if (cd.GMBLASG__Posted__c) {
            postedValidation(cd, oldMap.get(cd.Id));
          }
        }

        if (cd.AcctSeed__GL_Account_Variable_1__c == null && !cd.GMBLASG__Posted__c && glv1Name != null)
          cd.AcctSeed__GL_Account_Variable_1__c = mapGlv1ByName.get(glv1Name).Id;
        /// SFISSUES-2041
        if(cd.AcctSeed__GL_Account_Variable_4__c != null && !cd.GMBLASG__Posted__c){
          AcctSeed__Accounting_Variable__c glv = mapGlv4ById.get(cd.AcctSeed__GL_Account_Variable_4__c);
          if(!glv.AcctSeed__Active__c){
            cd.addError('Cannot use inactive GL Account Variable 4. Please use an active one.');
          }
        }
      }
    }
  }

  @TestVisible
  private static void postedValidation(AcctSeed__Cash_Disbursement__c cd, AcctSeed__Cash_Disbursement__c oldRec) {
    for(String fieldName : POSTED_LOCKED_FIELDS ){
      validatePostedField(cd, oldRec, fieldName);
    }
  }

  private static void validatePostedField(
    AcctSeed__Cash_Disbursement__c cd,
    AcctSeed__Cash_Disbursement__c oldRec,
    String fieldName
  ) {
    if (cd.get(fieldName) != oldRec.get(fieldName)) {
      cd.addError(genPostedErrorMsg(fieldName));
    }
  }

  @TestVisible
  private static String genPostedErrorMsg(String fieldName) {
    String fieldLabel = Schema.getGlobalDescribe()
      .get('AcctSeed__Cash_Disbursement__c')
      .getDescribe()
      .fields.getMap()
      .get(fieldName)
      .getDescribe()
      .getLabel();
    return 'You cannot update the ' +
      fieldLabel +
      ' on a posted record. You must unpost the record to edit any of these fields.';
  }

  private static void setBankGL(AcctSeed__Cash_Disbursement__c cd) {
    String paymentMethod = cd.AcctSeed__Type__c;
    system.debug('Payment Method ---> ' + paymentMethod);
    if (
      paymentMethod == 'MasterCard' ||
      paymentMethod == 'Visa' ||
      paymentMethod == 'Debit' ||
      paymentMethod == 'Credit Card' ||
      paymentMethod == 'Accord D'
    )
      cd.AcctSeed__Bank_Account__c = gcConstants.idGlMerchantDebitCredit;
    else if (paymentMethod == 'Cheque' || paymentMethod == 'Check' || paymentMethod == 'Draft')
      cd.AcctSeed__Bank_Account__c = gcConstants.idGlRBCCDN;
    else if (paymentMethod == 'Company Credit Card')
      cd.AcctSeed__Bank_Account__c = gcConstants.idGlCCPayable;
    else if (paymentMethod == 'Cash')
      cd.AcctSeed__Bank_Account__c = gcConstants.idGlCashFloat;
    else if (paymentMethod == 'Wire' || paymentMethod == 'US Check')
      cd.AcctSeed__Bank_Account__c = gcConstants.idGlRBCUS;
    else if (paymentMethod == 'Legend Bucks')
      cd.AcctSeed__Bank_Account__c = gcConstants.idGlLegendBucks;
    else if (paymentMethod == 'Online Store')
      cd.AcctSeed__Bank_Account__c = gcConstants.idGlMerchantOnline;
    else if (paymentMethod == 'Financed')
      cd.AcctSeed__Bank_Account__c = gcConstants.idGlWellsFargoLoan;
    else
      cd.AcctSeed__Bank_Account__c = gcConstants.idGlRBCCDN;
  }

  private static map<String, AcctSeed__Accounting_Variable__c> mapGlv1ByName;
  private static map<Id, AcctSeed__Accounting_Variable__c> mapGlv4ById;
  private static map<Id, User> mapUser;

  private static void retrieveStatics(list<AcctSeed__Cash_Disbursement__c> listNew) {
    set<String> setNameGlv = new Set<String>();
    set<Id> setIdGlv = new Set<Id>();

    if (mapGlv1ByName == null) {
      mapGlv1ByName = new Map<String, AcctSeed__Accounting_Variable__c>();
      mapUser = new Map<Id, User>();
    }

    for (User u : [SELECT Id, GL_Account_Variable_1__c FROM User WHERE Id = :UserInfo.getUserId()]) {
      if (u.GL_Account_Variable_1__c != null)
        setNameGlv.add(u.GL_Account_Variable_1__c);

      mapUser.put(u.Id, u);
    }

    for(AcctSeed__Cash_Disbursement__c cd : listNew){
      if(cd.AcctSeed__GL_Account_Variable_4__c != null){
        setIdGlv.add(cd.AcctSeed__GL_Account_Variable_4__c);
      }
    }

    if (!setNameGlv.isEmpty())
      for (AcctSeed__Accounting_Variable__c glv : [
        SELECT
          Id,
          Name,
          AcctSeed__Active__c,
          Tax_is_Harmonized__c,
          Tax_Rate_Provincial__c,
          Tax_Rate_Retail__c,
          GL_Account_Variable_3__c,
          AcctSeed__Type__c
        FROM AcctSeed__Accounting_Variable__c
        WHERE (Name IN :setNameGlv OR Id IN:setIdGlv)
      ]) {
        if (glv.AcctSeed__Type__c.equals('GL Account Variable 1'))
          mapGlv1ByName.put(glv.Name, glv);
        if (glv.AcctSeed__Type__c.equals('GL Account Variable 4'))
          mapGlv4ById.put(glv.Id, glv);
      }
  }
}
