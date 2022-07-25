global without sharing class gcCashReceipt_PDF {
  global gcCashReceipt_PDF(ApexPages.StandardController c) {
    cr = (AcctSeed__Cash_Receipt__c) (c.getRecord());

    init();
  }

  global transient AcctSeed__Cash_Receipt__c cr { get; set; }
  global transient Map<String, String> mapCashReceipt { get; set; }

  global void init() {
    mapCashReceipt = new Map<String, String>();
    for (AcctSeed__Cash_Receipt__c cashReceipt : [
      SELECT
        Id,
        Name,
        AcctSeed__Account__c,
        AcctSeed__Account__r.Name,
        AcctSeed__Amount__c,
        AcctSeed__Applied_Amount__c,
        AcctSeed__Balance__c,
        AcctSeed__Bank_Account__c,
        AcctSeed__Bank_Deposit__c,
        AcctSeed__Bank_Reconciliation__c,
        AcctSeed__Cleared_Date__c,
        AcctSeed__Credit_GL_Account__c,
        AcctSeed__GL_Account_Variable_1__c,
        AcctSeed__GL_Account_Variable_2__c,
        AcctSeed__GL_Account_Variable_3__c,
        AcctSeed__GL_Account_Variable_4__c,
        AcctSeed__Number_of_Billing_Cash_Receipts__c,
        AcctSeed__Payment_Reference__c,
        AcctSeed__Project__c,
        AcctSeed__Project__r.Name,
        AcctSeed__Project_Task__c,
        AcctSeed__Project_Task__r.Name,
        AcctSeed__Purpose__c,
        AcctSeed__Receipt_Date__c,
        OwnerId,
        Owner.Name,
        Payment_Method__c
      FROM AcctSeed__Cash_Receipt__c
      WHERE Id = :cr.Id
    ]) {
      mapCashReceipt.put('accountName', cashReceipt.AcctSeed__Account__r.Name);
      mapCashReceipt.put('crName', cashReceipt.Name);
      mapCashReceipt.put(
        'receiptDate',
        cashReceipt.AcctSeed__Receipt_Date__c == null ? '' : cashReceipt.AcctSeed__Receipt_Date__c.format()
      );
      mapCashReceipt.put('payRef', cashReceipt.AcctSeed__Payment_Reference__c);
      mapCashReceipt.put('payType', cashReceipt.AcctSeed__Purpose__c);
      mapCashReceipt.put('payMethod', cashReceipt.Payment_Method__c);
      mapCashReceipt.put(
        'projectName',
        cashReceipt.AcctSeed__Project__c == null ? '' : cashReceipt.AcctSeed__Project__r.Name
      );
      mapCashReceipt.put(
        'taskName',
        cashReceipt.AcctSeed__Project_Task__c == null ? '' : cashReceipt.AcctSeed__Project_Task__r.Name
      );
      mapCashReceipt.put('ownerName', cashReceipt.Owner.Name);
      mapCashReceipt.put(
        'crAmount',
        cashReceipt.AcctSeed__Amount__c == null ? '0.00' : String.valueOf(cashReceipt.AcctSeed__Amount__c.setScale(2))
      );
    }
  }
}
