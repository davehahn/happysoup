public without sharing class SalesOrder_Service {
  private static map<Id, Account> mapAccount;
  private static map<Id, AcctSeed__Accounting_Variable__c> mapGlv;
  private static map<String, AcctSeed__Accounting_Variable__c> mapGlv3ByName;

  public static void generateCashReceipt(List<AcctSeedERP__Sales_Order__c> lstSalesOrder) {
    List<AcctSeed__Cash_Receipt__c> lstCashReceipt = new List<AcctSeed__Cash_Receipt__c>();
    Id idGlCashFloat = gcConstants.idGlCashFloat;
    Id idGlBank;
    //Currently payment method cash
    idGlBank = idGlCashFloat;
    List<AcctSeed__Accounting_Period__c> lstAccount = [
      SELECT Id, Name, AcctSeed__End_Date__c, AcctSeed__Start_Date__c, AcctSeed__Status__c, Legend_Name__c
      FROM AcctSeed__Accounting_Period__c
    ];
    for (AcctSeedERP__Sales_Order__c so : lstSalesOrder) {
      AcctSeed__Cash_Receipt__c newCR = new AcctSeed__Cash_Receipt__c(
        Sales_Order__c = so.id,
        AcctSeed__Account__c = so.AcctSeedERP__Customer__c != null ? so.AcctSeedERP__Customer__c : null,
        AcctSeed__Amount__c = so.AcctSeedERP__Total__c,
        AcctSeed__Bank_Account__c = idGlBank,
        AcctSeed__Payment_Reference__c = so.Name + '_' + System.now().format(),
        Payment_Method__c = 'Online Store',
        AcctSeed__Purpose__c = 'Customer Receipt',
        AcctSeed__Receipt_Date__c = System.today(),
        AcctSeed__GL_Account_Variable_2__c = so.GL_Account_Variable_2__c,
        AcctSeed__GL_Account_Variable_1__c = so.GL_Account_Variable_1__c,
        AcctSeed__Status__c = 'Approved'
      );
      lstCashReceipt.add(newCR);
    }
    if (!lstCashReceipt.isEmpty()) {
      insert lstCashReceipt;
    }
    AcctSeed.PostResult[] postResultsAP = AcctSeed.CashReceiptPostService.postCashReceipts(lstCashReceipt);
    for (AcctSeed.PostResult theResult : postResultsAP) {
      if (!theResult.isSuccess) {
        for (AcctSeed.PostResult.PostErrorResult errorResult : theResult.errors) {
          throw new gcException('Cash Receipt was not posted. Please try again. REASON: ' + errorResult.message);
        }
      } else {
        System.debug('Posted! CR');
      }
    }
  }

  public static void refreshStatics(list<AcctSeedERP__Sales_Order__c> listNew) {
    if (mapGlv == null) {
      mapAccount = new Map<Id, Account>();
      mapGlv = new Map<Id, AcctSeed__Accounting_Variable__c>();
      mapGlv3ByName = new Map<String, AcctSeed__Accounting_Variable__c>();
    }

    set<Id> setIdAccount = new Set<Id>();
    set<Id> setIdGlv = new Set<Id>();
    set<String> setNameGlv = new Set<String>();

    if (!mapGlv.containsKey(gcConstants.idGlv3Ontario))
      setIdGlv.add(gcConstants.idGlv3Ontario);

    for (AcctSeedERP__Sales_Order__c b : listNew) {
      if (b.GL_Account_Variable_3__c != null && !mapGlv.containsKey(b.GL_Account_Variable_3__c))
        setIdGlv.add(b.GL_Account_Variable_3__c);
      if (b.AcctSeedERP__Customer__c != null && !mapAccount.containsKey(b.AcctSeedERP__Customer__c))
        setIdAccount.add(b.AcctSeedERP__Customer__c);
    }

    if (!setIdAccount.isEmpty())
      for (Account a : [SELECT Id, BillingState FROM Account WHERE Id IN :setIdAccount]) {
        mapAccount.put(a.Id, a);
        if (a.BillingState != null && !mapGlv3ByName.containsKey(a.BillingState))
          setNameGlv.add(a.BillingState);
      }

    setIdGlv.remove(null);
    if (!setIdGlv.isEmpty() || !setNameGlv.isEmpty()) {
      for (AcctSeed__Accounting_Variable__c glv : [
        SELECT Id, Name, Tax_is_Harmonized__c, Tax_Rate_Provincial__c, Tax_Rate_Retail__c, AcctSeed__Type__c
        FROM AcctSeed__Accounting_Variable__c
        WHERE Id IN :setIdGlv OR Name IN :setNameGlv
      ]) {
        mapGlv.put(glv.Id, glv);
        if (glv.AcctSeed__Type__c.equals('GL Account Variable 3'))
          mapGlv3ByName.put(glv.Name, glv);
      }
    }
  }

  public static void updateSalesTax(
    List<AcctSeedERP__Sales_Order__c> SalesOrderList,
    map<Id, AcctSeedERP__Sales_Order__c> oldMap
  ) {
    set<Id> setIdSOUpdateTax = new Set<Id>();
    for (AcctSeedERP__Sales_Order__c b : SalesOrderList) {
      AcctSeedERP__Sales_Order__c oldRec = oldMap.get(b.Id);
      if (
        b.GL_Account_Variable_3__c != oldRec.GL_Account_Variable_3__c ||
        b.Tax_is_Harmonized__c != oldRec.Tax_is_Harmonized__c ||
        b.Tax_Override__c != oldRec.Tax_Override__c ||
        b.Tax_Rate_Federal__c != oldRec.Tax_Rate_Federal__c ||
        b.Tax_Rate_Provincial__c != oldRec.Tax_Rate_Provincial__c ||
        b.Tax_Rate_Retail__c != oldRec.Tax_Rate_Retail__c
      ) {
        setIdSOUpdateTax.add(b.Id);
      }
    }
    if (!setIdSOUpdateTax.isEmpty())
      SalesOrderLine_Service.updateSalesTax(setIdSOUpdateTax);
  }

  public static void setTaxVariablesBI(List<AcctSeedERP__Sales_Order__c> SalesOrderList) {
    for (AcctSeedERP__Sales_Order__c b : SalesOrderList) {
      if (b.AcctSeedERP__Status__c != 'Posted') {
        Account acct = mapAccount.get(b.AcctSeedERP__Customer__c);
        if (
          acct != null &&
          acct.BillingState != null &&
          mapGlv3ByName.containsKey(acct.BillingState) &&
          b.GL_Account_Variable_3__c == null
        ) {
          b.GL_Account_Variable_3__c = mapGlv3ByName.get(acct.BillingState).Id;
        }
        if (b.GL_Account_Variable_3__c == null) {
          //b.GL_Account_Variable_3__c = gcConstants.idGlv3Others; (Set in)
          b.Tax_Override__c = true;
          b.Tax_Rate_Federal__c = 0;
          b.Tax_Rate_Provincial__c = 0;
          b.Tax_Rate_Retail__c = 0;
        }

        if (!b.Tax_Override__c) {
          b.Tax_Rate_Federal__c = 5;

          AcctSeed__Accounting_Variable__c glvTaxZone = mapGlv.get(b.GL_Account_Variable_3__c);
          if (glvTaxZone != null) {
            b.Tax_is_Harmonized__c = glvTaxZone.Tax_is_Harmonized__c;
            b.Tax_Rate_Provincial__c = glvTaxZone.Tax_Rate_Provincial__c;
            b.Tax_Rate_Retail__c = glvTaxZone.Tax_Rate_Retail__c;
          }
        }
      }
    }
  }

  public static void setTaxVariablesBU(
    List<AcctSeedERP__Sales_Order__c> SalesOrderList,
    map<Id, AcctSeedERP__Sales_Order__c> oldMap
  ) {
    for (AcctSeedERP__Sales_Order__c b : SalesOrderList) {
      AcctSeedERP__Sales_Order__c oldRec;
      oldRec = oldMap.get(b.Id);
      if (b.AcctSeedERP__Status__c == 'Posted') {
        if (
          b.GL_Account_Variable_3__c != oldRec.GL_Account_Variable_3__c ||
          b.Tax_is_Harmonized__c != oldRec.Tax_is_Harmonized__c ||
          b.Tax_Override__c != oldRec.Tax_Override__c ||
          b.Tax_Rate_Federal__c != oldRec.Tax_Rate_Federal__c ||
          b.Tax_Rate_Provincial__c != oldRec.Tax_Rate_Provincial__c ||
          b.Tax_Rate_Retail__c != oldRec.Tax_Rate_Retail__c
        ) {
          b.addError('The Sales Tax settings of a Billing may not be changed, if the billing is Posted.');
        }
      } else {
        Account acct = mapAccount.get(b.AcctSeedERP__Customer__c);
        if (
          acct != null &&
          acct.BillingState != null &&
          mapGlv3ByName.containsKey(acct.BillingState) &&
          b.AcctSeedERP__Customer__c != oldRec.AcctSeedERP__Customer__c
        ) {
          b.GL_Account_Variable_3__c = mapGlv3ByName.get(acct.BillingState).Id;
        }
        if (b.GL_Account_Variable_3__c == null) {
          //b.GL_Account_Variable_3__c = gcConstants.idGlv3Others; (Set in)
          b.Tax_Override__c = true;
          b.Tax_Rate_Federal__c = 0;
          b.Tax_Rate_Provincial__c = 0;
          b.Tax_Rate_Retail__c = 0;
        }

        if (!b.Tax_Override__c) {
          if (
            b.GL_Account_Variable_3__c != oldRec.GL_Account_Variable_3__c ||
            b.Tax_is_Harmonized__c != oldRec.Tax_is_Harmonized__c ||
            b.Tax_Override__c != oldRec.Tax_Override__c ||
            b.Tax_Rate_Federal__c != oldRec.Tax_Rate_Federal__c ||
            b.Tax_Rate_Provincial__c != oldRec.Tax_Rate_Provincial__c ||
            b.Tax_Rate_Retail__c != oldRec.Tax_Rate_Retail__c
          ) {
            b.Tax_Rate_Federal__c = 5;

            AcctSeed__Accounting_Variable__c glvTaxZone = mapGlv.get(b.GL_Account_Variable_3__c);
            if (glvTaxZone != null) {
              b.Tax_is_Harmonized__c = glvTaxZone.Tax_is_Harmonized__c;
              b.Tax_Rate_Provincial__c = glvTaxZone.Tax_Rate_Provincial__c;
              b.Tax_Rate_Retail__c = glvTaxZone.Tax_Rate_Retail__c;
            }
          }
        }
      }
    }
  }
}
