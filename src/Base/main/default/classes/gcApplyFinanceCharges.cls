public with sharing class gcApplyFinanceCharges {
  public gcApplyFinanceCharges(ApexPages.standardController ctrl) {
  }
  public gcApplyFinanceCharges() {
  }

  @RemoteAction
  @ReadOnly
  public static AcctSeed__Cash_Receipt__c retrieveCR(Id idCashReceipt) {
    return [
      SELECT AcctSeed__Balance__c, AcctSeed__Applied_Amount__c
      FROM AcctSeed__Cash_Receipt__c
      WHERE Id = :idCashReceipt
    ][0];
  }

  @RemoteAction
  @ReadOnly
  public static List<Map<String, String>> retrieveAppliedCash(Id idCashReceipt) {
    List<Map<String, String>> listJSON = new List<Map<String, String>>();
    for (AcctSeed__Billing_Cash_Receipt__c bcr : [
      SELECT
        Id,
        Name,
        AcctSeed__Accounting_Period__c,
        AcctSeed__Accounting_Period__r.AcctSeed__Status__c,
        AcctSeed__Accounting_Period__r.Name,
        AcctSeed__Adjustment_Amount__c,
        AcctSeed__Adjustment_GL_Account__c,
        AcctSeed__Adjustment_GL_Account__r.Name,
        AcctSeed__Applied_Amount__c,
        AcctSeed__Billing__c,
        AcctSeed__Billing__r.Name,
        AcctSeed__Billing__r.AcctSeed__Total__c,
        AcctSeed__Billing__r.AcctSeed__Balance__c,
        AcctSeed__Cash_Receipt__c,
        AcctSeed__Period_Applied__c
      FROM AcctSeed__Billing_Cash_Receipt__c
      WHERE AcctSeed__Cash_Receipt__c = :idCashReceipt
      ORDER BY AcctSeed__Billing__r.Name, AcctSeed__Billing__r.CreatedDate
    ]) {
      Map<String, String> m = new Map<String, String>();
      m.put('idBCR', bcr.Id);
      m.put('bcrName', bcr.Name);
      m.put('idPeriod', bcr.AcctSeed__Accounting_Period__c);
      m.put('periodIsOpen', bcr.AcctSeed__Accounting_Period__r.AcctSeed__Status__c);
      m.put('idBilling', bcr.AcctSeed__Billing__c);
      m.put('billingName', bcr.AcctSeed__Billing__r.Name);
      m.put('billingTotal', String.valueOf(bcr.AcctSeed__Billing__r.AcctSeed__Total__c.setScale(6)));
      m.put('billingBalance', String.valueOf(bcr.AcctSeed__Billing__r.AcctSeed__Balance__c.setScale(6)));
      m.put('appliedAmount', String.valueOf(bcr.AcctSeed__Applied_Amount__c.setScale(6)));
      m.put('periodApplied', bcr.AcctSeed__Period_Applied__c);
      m.put('adjustedAmount', '0.00');
      m.put('idAdjustmentGL', '');
      m.put('adjustmentGL', '');
      if (bcr.AcctSeed__Adjustment_Amount__c != null) {
        m.put('adjustedAmount', String.valueOf(bcr.AcctSeed__Adjustment_Amount__c.setScale(6)));
        m.put('idAdjustmentGL', bcr.AcctSeed__Adjustment_GL_Account__c);
        m.put('adjustmentGL', bcr.AcctSeed__Adjustment_GL_Account__r.Name);
      }
      listJSON.add(m);
    }
    return listJSON;
  }

  @RemoteAction
  public static void createFCBill(Id idCashReceipt, Decimal financeCharge, Decimal bankCharge) {
    AcctSeed__Accounting_Period__c period = GMBLASERP.gcAccountingPeriod.periodCurr();
    AcctSeed__Cash_Receipt__c cr = [
      SELECT Id, AcctSeed__Account__c, AcctSeed__Balance__c
      FROM AcctSeed__Cash_Receipt__c
      WHERE Id = :idCashReceipt
    ][0];

    if (cr.AcctSeed__Balance__c == 0)
      throw new gcException('No more available balance for this cash receipt.');

    if (cr.AcctSeed__Balance__c < (financeCharge + bankCharge))
      throw new gcException('Sum of Bank Fees and Dealer Reserved Amount cannot be greater than cash receipt balance.');

    AcctSeed__Billing__c newBill = new AcctSeed__Billing__c(AcctSeed__Customer__c = cr.AcctSeed__Account__c);

    insert newBill;
    List<AcctSeed__Billing_Line__c> listBLines = new List<AcctSeed__Billing_Line__c>();
    AcctSeed__Billing_Line__c newBLFC = new AcctSeed__Billing_Line__c(
      AcctSeed__Billing__c = newBill.Id,
      AcctSeed__Revenue_GL_Account__c = gcConstants.idGlFinancingFees,
      AcctSeed__Hours_Units__c = 1,
      AcctSeed__Rate__c = financeCharge.setScale(6),
      AcctSeed__GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale,
      AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2Sales
    );
    listBLines.add(newBLFC);

    AcctSeed__Billing_Line__c newBLBC = new AcctSeed__Billing_Line__c(
      AcctSeed__Billing__c = newBill.Id,
      AcctSeed__Revenue_GL_Account__c = gcConstants.idGlBankFees,
      AcctSeed__Hours_Units__c = 1,
      AcctSeed__Rate__c = bankCharge.setScale(6),
      AcctSeed__GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale,
      AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2Sales
    );
    listBLines.add(newBLBC);
    insert listBLines;

    AcctSeed.BillingPostService.postBillings(new List<AcctSeed__Billing__c>{ newBill });

    AcctSeed__Billing_Cash_Receipt__c newBCR = new AcctSeed__Billing_Cash_Receipt__c(
      AcctSeed__Billing__c = newBill.Id,
      AcctSeed__Cash_Receipt__c = cr.Id,
      AcctSeed__Applied_Amount__c = (financeCharge + bankCharge),
      AcctSeed__Accounting_Period__c = period.Id
    );

    insert newBCR;
  }

  @RemoteAction
  @ReadOnly
  public static List<Map<String, String>> retrieveOpenBillings(Id idCashReceipt) {
    List<Map<String, String>> listJSON = new List<Map<String, String>>();
    Id idCustomer = [SELECT AcctSeed__Account__c FROM AcctSeed__Cash_Receipt__c WHERE Id = :idCashReceipt][0]
    .AcctSeed__Account__c;
    for (
      AcctSeed__Billing__c bill : [
        SELECT
          Id,
          AcctSeed__Balance__c,
          AcctSeed__Date__c,
          AcctSeed__Total__c,
          AcctSeed__Customer__c,
          AcctSeed__Customer__r.Name,
          Name
        FROM AcctSeed__Billing__c
        WHERE
          /*Id NOT IN (SELECT AcctSeed__Billing__c FROM AcctSeed__Billing_Cash_Receipt__c	WHERE AcctSeed__Cash_Receipt__c =:idCashReceipt)
           AND */ AcctSeed__Balance__c > 0
          AND AcctSeed__Status__c = 'Posted'
      ]
    ) {
      listJSON.add(wrapCashReceipt(bill));
    }
    return listJSON;
  }

  public static Map<String, String> wrapCashReceipt(AcctSeed__Billing__c bill) {
    Map<String, String> m = new Map<String, String>();
    m.put('idBill', bill.Id);
    m.put('billingName', bill.Name);
    m.put('billDate', bill.AcctSeed__Date__c.format());
    m.put('billTotal', String.valueOf(bill.AcctSeed__Total__c.setScale(6)));
    m.put('billBalance', String.valueOf(bill.AcctSeed__Balance__c.setScale(6)));
    m.put('idCustomer', bill.AcctSeed__Customer__c);
    m.put('customerName', bill.AcctSeed__Customer__r.Name);
    return m;
  }

  @RemoteAction
  public static void deleteBCR(String idBCR) {
    delete [SELECT Id FROM AcctSeed__Billing_Cash_Receipt__c WHERE Id = :idBCR];
  }

  @RemoteAction
  public static Map<String, String> applyBCR(String idCashReceipt, String idBill, Decimal amountToApply) {
    AcctSeed__Accounting_Period__c period = GMBLASERP.gcAccountingPeriod.periodCurr();
    AcctSeed__Billing__c bill = [SELECT Id, AcctSeed__Balance__c FROM AcctSeed__Billing__c WHERE Id = :idBill][0];
    AcctSeed__Cash_Receipt__c cr = [
      SELECT Id, AcctSeed__Balance__c
      FROM AcctSeed__Cash_Receipt__c
      WHERE Id = :idCashReceipt
    ][0];

    if (cr.AcctSeed__Balance__c == 0)
      throw new gcException('No more available balance for this cash receipt.');

    //Decimal amountToApply = cr.AcctSeed__Balance__c;
    if (amountToApply > bill.AcctSeed__Balance__c)
      throw new gcException('Applied amount cannot be greater than billing balance.');
    else if (amountToApply > cr.AcctSeed__Balance__c)
      throw new gcException('Applied amount cannot be greater than cash receipt balance.');

    AcctSeed__Billing_Cash_Receipt__c newBCR = new AcctSeed__Billing_Cash_Receipt__c(
      AcctSeed__Billing__c = bill.Id,
      AcctSeed__Cash_Receipt__c = cr.Id,
      AcctSeed__Applied_Amount__c = amountToApply,
      AcctSeed__Accounting_Period__c = period.Id
    );

    insert newBCR;

    Map<String, String> mapJSON = new Map<String, String>();

    for (AcctSeed__Billing__c b : [
      SELECT
        Id,
        AcctSeed__Balance__c,
        AcctSeed__Date__c,
        AcctSeed__Total__c,
        AcctSeed__Customer__c,
        AcctSeed__Customer__r.Name,
        Name
      FROM AcctSeed__Billing__c
      WHERE Id = :idBill AND AcctSeed__Balance__c > 0 AND AcctSeed__Status__c = 'Posted'
    ]) {
      mapJSON = wrapCashReceipt(b);
    }
    return mapJSON;
  }
}
