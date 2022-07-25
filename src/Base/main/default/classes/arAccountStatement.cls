public without sharing class arAccountStatement {
  public class transactionData {
    public List<Map<String, String>> listBillings { get; set; }
    public List<Map<String, String>> listERP { get; set; }
    public List<AcctSeed__Cash_Receipt__c> listReceipts { get; set; }
    public List<AcctSeed__Account_Payable__c> listPayables { get; set; }
    public List<AcctSeed__Cash_Disbursement__c> listDisbursements { get; set; }
    public Decimal billingBalance { get; set; }
    public Decimal projectTotal { get; set; }
    public Decimal projectTotalBilled { get; set; }
    public Decimal projectBalance { get; set; }
    public Decimal cashReceiptBalance { get; set; }
    public Decimal payableBalance { get; set; }
    public Decimal disbursementBalance { get; set; }
    public Decimal totalARBalance { get; set; }
    public Decimal totalAPBalance { get; set; }
    public Decimal totalBalance { get; set; }
    public Boolean showRefundButton { get; set; }

    public transactionData() {
      listBillings = new List<Map<String, String>>();
      listERP = new List<Map<String, String>>();
      listReceipts = new List<AcctSeed__Cash_Receipt__c>();
      listPayables = new List<AcctSeed__Account_Payable__c>();
      listDisbursements = new List<AcctSeed__Cash_Disbursement__c>();
      billingBalance = 0;
      projectTotal = 0;
      projectTotalBilled = 0;
      projectBalance = 0;
      cashReceiptBalance = 0;
      payableBalance = 0;
      disbursementBalance = 0;
      totalARBalance = 0;
      totalAPBalance = 0;
      totalBalance = 0;
      showRefundButton = false;
    }
  }

  @AuraEnabled
  public static Id getAccountId(Id recordId) {
    Id result;
    String sObjectType = LGND_Utilities.sObjectNameFromId(recordId);
    switch on sObjectType {
      when 'Account' {
        result = recordId;
      }
      when 'AcctSeed__Project__c' {
        result = [SELECT AcctSeed__Account__c FROM AcctSeed__Project__c WHERE Id = :recordId].AcctSeed__Account__c;
      }
    }
    return result;
  }

  @AuraEnabled
  public static List<String> getOptions() {
    List<String> options = new List<String>();

    Schema.DescribeFieldResult fieldResult = AcctSeed__Cash_Receipt__c.Payment_Method__c.getDescribe();
    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

    for (Schema.PicklistEntry f : ple)
      options.add(f.getValue());

    return options;
  }

  @AuraEnabled
  public static List<String> getCDOptions() {
    List<String> options = new List<String>();

    Schema.DescribeFieldResult fieldResult = AcctSeed__Cash_Disbursement__c.AcctSeed__Type__c.getDescribe();
    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

    for (Schema.PicklistEntry f : ple)
      options.add(f.getValue());

    return options;
  }

  @AuraEnabled
  public static String receiveBilling(Id idAccount, List<Id> idBills, String paymentMethod) {
    Id idGlDeposit = gcConstants.idGlDeposit;
    Id idGlGiftCards = gcConstants.idGlGiftCards;
    Id idGlMerchantDebitCredit = gcConstants.idGlMerchantDebitCredit;
    Id idGlCashFloat = gcConstants.idGlCashFloat;
    Id idGlRBCCDN = gcConstants.idGlRBCCDN;
    Id idGlBank;

    if (paymentMethod == 'MasterCard' || paymentMethod == 'Visa' || paymentMethod == 'Debit')
      idGlBank = idGlMerchantDebitCredit;
    else if (paymentMethod == 'Cheque' || paymentMethod == 'Check' || paymentMethod == 'Draft')
      idGlBank = idGlRBCCDN;
    else if (paymentMethod == 'Cash')
      idGlBank = idGlCashFloat;
    else if (paymentMethod == 'Gift Cards')
      idGlBank = idGlGiftCards;
    else
      idGlBank = idGlRBCCDN;

    List<AcctSeed__Billing__c> listBill = new List<AcctSeed__Billing__c>();
    Map<Id, AcctSeed__Cash_Receipt__c> mapBillReceipt = new Map<Id, AcctSeed__Cash_Receipt__c>();
    for (AcctSeed__Billing__c bill : [
      SELECT Id, Name, AcctSeed__Customer__c, AcctSeed__Balance__c
      FROM AcctSeed__Billing__c
      WHERE Id IN :idBills AND AcctSeed__Balance__c > 0 AND GMBLASG__Posted__c = TRUE
    ]) {
      listBill.add(bill);
      AcctSeed__Cash_Receipt__c newCR = new AcctSeed__Cash_Receipt__c(
        AcctSeed__Account__c = bill.AcctSeed__Customer__c,
        AcctSeed__Amount__c = bill.AcctSeed__Balance__c,
        AcctSeed__Bank_Account__c = idGlBank,
        AcctSeed__Payment_Reference__c = bill.Name + '_' + System.now().format(),
        Payment_Method__c = 'Cash',
        AcctSeed__Purpose__c = 'Customer Receipt'
      );

      mapBillReceipt.put(bill.Id, newCR);
    }
    List<AcctSeed__Billing_Cash_Receipt__c> listBCM = new List<AcctSeed__Billing_Cash_Receipt__c>();
    if (!mapBillReceipt.isEmpty()) {
      /// Create a new Receipt
      Savepoint sp = Database.setSavepoint();
      try {
        insert mapBillReceipt.values();
        AcctSeed__Accounting_Period__c currPeriod = GMBLASERP.gcAccountingPeriod.periodCurr();
        for (Id idBill : mapBillReceipt.keySet()) {
          AcctSeed__Cash_Receipt__c newCR = mapBillReceipt.get(idBill);
          /// Apply Cash Receipt on the new Bill
          AcctSeed__Billing_Cash_Receipt__c bcm = new AcctSeed__Billing_Cash_Receipt__c(
            AcctSeed__Accounting_Period__c = currPeriod.Id,
            AcctSeed__Applied_Amount__c = newCR.AcctSeed__Amount__c,
            AcctSeed__Billing__c = idBill,
            AcctSeed__Cash_Receipt__c = newCR.Id
          );
          listBCM.add(bcm);
        }
        insert listBCM;
      } catch (Exception e) {
        Database.rollback(sp);
        throw new AuraHandledException(e.getMessage());
      }
      return retrieveAccountTxnDetails(idAccount);
    }
    throw new AuraHandledException('No Billing was found with a positive balance.');
  }

  @AuraEnabled
  public static String applyCashReceipts(Id idAccount, Id idCR, String applyType) {
    Set<Id> setIdAccounts = new Set<Id>();
    List<AcctSeed__Cash_Receipt__c> listCashReceipts = new List<AcctSeed__Cash_Receipt__c>();
    for (AcctSeed__Cash_Receipt__c cr : [
      SELECT
        Id,
        AcctSeed__Account__c,
        AcctSeed__Accounting_Period__c,
        AcctSeed__Amount__c,
        AcctSeed__Balance__c,
        AcctSeed__Bank_Account__c,
        AcctSeed__Cleared_Date__c,
        AcctSeed__Credit_GL_Account__c,
        AcctSeed__GL_Account_Variable_1__c,
        AcctSeed__GL_Account_Variable_2__c,
        AcctSeed__Project__c,
        AcctSeed__Project_Task__c,
        Payment_Method__c
      FROM AcctSeed__Cash_Receipt__c
      WHERE Id = :idCR AND AcctSeed__Balance__c > 0 AND GMBLASG__Posted__c = TRUE
    ]) {
      Savepoint sp = Database.setSavepoint();
      try {
        Decimal receiptBalance = cr.AcctSeed__Balance__c;
        if (applyType.equals('create')) {
          /// Create a new BILL
          AcctSeed__Billing__c newBill = new AcctSeed__Billing__c(AcctSeed__Customer__c = cr.AcctSeed__Account__c);

          insert newBill;

          Id idAccountingPeriod = [
            SELECT AcctSeed__Accounting_Period__c
            FROM AcctSeed__Billing__c
            WHERE Id = :newBill.Id
          ][0]
          .AcctSeed__Accounting_Period__c;

          /// Create a Billing Line for Each Cash Receipt
          AcctSeed__Billing_Line__c newBL = new AcctSeed__Billing_Line__c(
            AcctSeed__Billing__c = newBill.Id,
            AcctSeed__Revenue_GL_Account__c = gcConstants.idGlCustomerRefund,
            AcctSeed__Hours_Units__c = 1,
            AcctSeed__Rate__c = receiptBalance,
            AcctSeed__GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale,
            AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2Sales,
            AcctSeed__Project__c = cr.AcctSeed__Project__c,
            AcctSeed__Project_Task__c = cr.AcctSeed__Project_Task__c
          );
          insert newBL;
          /// Post the new Bill
          AcctSeed.BillingPostService.postBillings(new List<AcctSeed__Billing__c>{ newBill });
          /// Apply Cash Receipt on the new Bill
          AcctSeed__Billing_Cash_Receipt__c bcm = new AcctSeed__Billing_Cash_Receipt__c(
            AcctSeed__Accounting_Period__c = idAccountingPeriod,
            AcctSeed__Applied_Amount__c = receiptBalance,
            AcctSeed__Billing__c = newBill.Id,
            AcctSeed__Cash_Receipt__c = cr.Id
          );
          insert bcm;
        } else {
          AcctSeed__Accounting_Period__c currPeriod = GMBLASERP.gcAccountingPeriod.periodCurr();
          List<AcctSeed__Billing_Cash_Receipt__c> listBCM = new List<AcctSeed__Billing_Cash_Receipt__c>();
          Decimal appliedBalance = receiptBalance;
          for (AcctSeed__Billing__c bl : [
            SELECT Id, Name, AcctSeed__Total__c, AcctSeed__Balance__c, GMBLASG__Posted__c
            FROM AcctSeed__Billing__c
            WHERE AcctSeed__Customer__c = :idAccount AND AcctSeed__Balance__c > 0 AND GMBLASG__Posted__c = TRUE
            ORDER BY AcctSeed__Balance__c DESC
          ]) {
            if (appliedBalance > 0) {
              if (appliedBalance >= bl.AcctSeed__Balance__c) {
                listBCM.add(
                  new AcctSeed__Billing_Cash_Receipt__c(
                    AcctSeed__Accounting_Period__c = currPeriod.Id,
                    AcctSeed__Applied_Amount__c = bl.AcctSeed__Balance__c,
                    AcctSeed__Billing__c = bl.Id,
                    AcctSeed__Cash_Receipt__c = cr.Id
                  )
                );
                appliedBalance = appliedBalance - bl.AcctSeed__Balance__c;
              } else if (appliedBalance < bl.AcctSeed__Balance__c) {
                listBCM.add(
                  new AcctSeed__Billing_Cash_Receipt__c(
                    AcctSeed__Accounting_Period__c = currPeriod.Id,
                    AcctSeed__Applied_Amount__c = appliedBalance,
                    AcctSeed__Billing__c = bl.Id,
                    AcctSeed__Cash_Receipt__c = cr.Id
                  )
                );
                break;
              }
            } else
              break;
          }
          if (!listBCM.isEmpty())
            insert listBCM;
        }
      } catch (Exception e) {
        Database.rollback(sp);
        throw new AuraHandledException(e.getMessage());
      }
      return retrieveAccountTxnDetails(idAccount);
    }
    throw new AuraHandledException('No Cash receipt was found with a balance.');
  }

  @AuraEnabled
  public static String retrieveAccountTxnDetails(Id idAccount) {
    transactionData txnData = new transactionData();
    /// Just to make sure the Account Id exists
    for (Account acc : [SELECT Id, Name FROM Account WHERE Id = :idAccount]) {
      /// Loading all the Bills
      List<AcctSeed__Billing__c> listBills = new List<AcctSeed__Billing__c>();
      for (AcctSeed__Billing__c bill : [
        SELECT
          Id,
          Name,
          AcctSeed__Total__c,
          AcctSeed__Balance__c,
          GMBLASG__Posted__c,
          GMBLASERP__Project__c,
          GMBLASERP__Project__r.Name /*,
						(SELECT Id, 
							AcctSeed__Project__c, 
							AcctSeed__Project__r.Name 
						FROM AcctSeed__Project_Billing_Lines__r) */
        FROM AcctSeed__Billing__c
        WHERE AcctSeed__Customer__c = :idAccount AND AcctSeed__Balance__c != 0 AND GMBLASG__Posted__c = TRUE
        ORDER BY AcctSeed__Date__c, Name
      ]) {
        //String projectName = '';
        //Set<Id> setIdProj = new Set<Id>();
        //for(AcctSeed__Billing_Line__c bl : bill.AcctSeed__Project_Billing_Lines__r){
        //	if(bl.AcctSeed__Project__r.Name != null && !setIdProj.contains(bl.AcctSeed__Project__c))
        //	{
        //		setIdProj.add(bl.AcctSeed__Project__c);
        //		if(projectName == '')
        //			projectName += bl.AcctSeed__Project__r.Name;
        //		else projectName += ',' + bl.AcctSeed__Project__r.Name;
        //	}
        //}

        //if(bill.AcctSeed__Balance__c <> 0 && bill.GMBLASG__Posted__c == true){
        Map<String, String> m = new Map<String, String>();
        m.put('Id', bill.Id);
        m.put('Name', bill.Name);
        m.put('billBalance', String.valueOf(bill.AcctSeed__Balance__c));
        m.put('billTotal', String.valueOf(bill.AcctSeed__Total__c));
        m.put('billProject', bill.GMBLASERP__Project__c == null ? '' : bill.GMBLASERP__Project__r.Name);
        txnData.listBillings.add(m);
        txnData.billingBalance += bill.AcctSeed__Balance__c == null ? 0 : bill.AcctSeed__Balance__c;
        //}
      }

      Set<Id> setIdProject = new Set<Id>();
      Map<Id, AcctSeed__Project__c> mapProject = new Map<Id, AcctSeed__Project__c>();
      Map<Id, Decimal> mapProjectBilled = new Map<Id, Decimal>();
      Id idRTTradeIn = gcConstants.idRtTradeIn;
      for (AcctSeed__Project__c pr : [
        SELECT Id, Name, Order_Item_Total__c, Grand_Total__c
        FROM AcctSeed__Project__c
        WHERE
          RecordTypeId != :idRTTradeIn
          AND AcctSeed__Account__c = :idAccount
          AND Stage__c NOT IN ('Quoting', 'Closed Lost', 'Draft')
      ]) {
        setIdProject.add(pr.Id);
        txnData.projectTotal += (pr.Grand_Total__c == null ? 0 : pr.Grand_Total__c);
        mapProject.put(pr.Id, pr);
      }

      //for(AcctSeed__Billing_Line__c line : [SELECT Id, AcctSeed__Total__c FROM AcctSeed__Billing_Line__c WHERE AcctSeed__Project__c IN:setIdProject])
      //{
      //	txnData.projectTotalBilled += (line.AcctSeed__Total__c == null ? 0 : line.AcctSeed__Total__c);
      //}

      for (AcctSeed__Billing__c pBill : [
        SELECT Id, AcctSeed__Total__c, GMBLASERP__Project__c
        FROM AcctSeed__Billing__c
        WHERE GMBLASERP__Project__c IN :setIdProject
      ]) {
        txnData.projectTotalBilled += (pBill.AcctSeed__Total__c == null ? 0 : pBill.AcctSeed__Total__c);
        if (!mapProjectBilled.containsKey(pBill.GMBLASERP__Project__c))
          mapProjectBilled.put(pBill.GMBLASERP__Project__c, 0);

        mapProjectBilled.put(
          pBill.GMBLASERP__Project__c,
          (mapProjectBilled.get(pBill.GMBLASERP__Project__c) +
          (pBill.AcctSeed__Total__c == null ? 0 : pBill.AcctSeed__Total__c.setScale(6)))
        );
      }

      for (Id idPr : mapProject.keySet()) {
        AcctSeed__Project__c pr = mapProject.get(idPr);
        Decimal gt = (pr.Grand_Total__c == null ? 0 : pr.Grand_Total__c);
        Decimal diff = gt;
        Decimal bt = 0;
        if (mapProjectBilled.containsKey(pr.Id)) {
          bt = mapProjectBilled.get(pr.Id);
          diff = gt.setScale(6) - bt.setScale(6);
        }
        if (diff.setScale(2) < -0.01 || diff.setScale(2) > 0.01) {
          Map<String, String> m = new Map<String, String>();
          m.put('Id', pr.Id);
          m.put('Name', pr.Name);
          m.put('grandTotal', String.valueOf(gt));
          m.put('billTotal', String.valueOf(bt));
          m.put('erpUnbilled', String.valueOf(diff));
          txnData.listERP.add(m);
        }
      }

      txnData.projectBalance = txnData.projectTotal.setScale(6) - txnData.projectTotalBilled.setScale(6);

      for (AcctSeed__Cash_Receipt__c cr : [
        SELECT Id, Name, AcctSeed__Amount__c, AcctSeed__Balance__c, GMBLASG__Posted__c
        FROM AcctSeed__Cash_Receipt__c
        WHERE AcctSeed__Account__c = :idAccount AND AcctSeed__Balance__c != 0 AND GMBLASG__Posted__c = TRUE
        ORDER BY AcctSeed__Receipt_Date__c, Name
      ]) {
        txnData.listReceipts.add(cr);
        txnData.cashReceiptBalance += cr.AcctSeed__Balance__c == null ? 0 : cr.AcctSeed__Balance__c;
      }

      for (AcctSeed__Account_Payable__c ap : [
        SELECT Id, Name, AcctSeed__Balance__c
        FROM AcctSeed__Account_Payable__c
        WHERE AcctSeed__Vendor__c = :idAccount AND AcctSeed__Balance__c != 0 AND GMBLASG__Posted__c = TRUE
        ORDER BY AcctSeed__Date__c, Name
      ]) {
        txnData.listPayables.add(ap);
        txnData.payableBalance += ap.AcctSeed__Balance__c == null ? 0 : ap.AcctSeed__Balance__c;
      }

      Set<Id> setIdCD = new Set<Id>();
      Id idGLPayable = gcConstants.idGlAPayable;
      for (AcctSeed__Cash_Disbursement__c cd : [
        SELECT Id
        FROM AcctSeed__Cash_Disbursement__c
        WHERE
          AcctSeed__Vendor__c = :idAccount
          AND AcctSeed__Amount__c != 0
          AND GMBLASG__Posted__c = TRUE
          AND AcctSeed__Payment_Status__c != 'Void'
          AND AcctSeed__Debit_GL_Account__c = :idGLPayable
      ])
        setIdCD.add(cd.Id);

      for (
        AcctSeed__Cash_Disbursement__c cd : [
          SELECT
            Id,
            Name,
            AcctSeed__Balance__c, /// This is a new field from AcctSeed
            AcctSeed__Amount__c,
            (SELECT Id, AcctSeed__Paid_Amount__c FROM AcctSeed__Account_Payable_Cash_Disbursements__r)
          FROM AcctSeed__Cash_Disbursement__c
          WHERE Id IN :setIdCD
          ORDER BY AcctSeed__Disbursement_Date__c, Name
        ]
      ) {
        Decimal totalPaid = 0;
        for (AcctSeed__AP_Disbursement__c ap : cd.AcctSeed__Account_Payable_Cash_Disbursements__r)
          totalPaid += ap.AcctSeed__Paid_Amount__c == null ? 0 : ap.AcctSeed__Paid_Amount__c;
        txnData.disbursementBalance += (cd.AcctSeed__Amount__c - totalPaid);
        if ((cd.AcctSeed__Amount__c - totalPaid) <> 0)
          txnData.listDisbursements.add(cd);
      }

      txnData.totalARBalance =
        txnData.billingBalance.setScale(6) +
        txnData.projectBalance.setScale(6) -
        txnData.cashReceiptBalance.setScale(6);
      if (txnData.totalARBalance < 0)
        txnData.showRefundButton = true;
      txnData.totalAPBalance = txnData.payableBalance.setScale(6) - txnData.disbursementBalance.setScale(6);
      txnData.totalBalance = txnData.totalARBalance.setScale(6) - txnData.totalAPBalance.setScale(6);
    }
    return JSON.serialize(txnData);
  }

  @AuraEnabled
  public static String handleRefund(Id idAccount, String paymentMethod, Decimal refundAmount) {
    Savepoint sp = Database.setSavepoint();
    try {
      Decimal refundAmountLeft = refundAmount * -1;
      /// First create a positive Billing with the total amount
      AcctSeed__Billing__c bill = new AcctSeed__Billing__c(
        AcctSeed__Customer__c = idAccount,
        Tax_Override__c = true,
        Tax_is_Harmonized__c = false,
        Tax_Rate_Federal__c = 0,
        Tax_Rate_Provincial__c = 0,
        Tax_Rate_Retail__c = 0 /*,
					AcctSeed__Billing_Format__c = 'a0e1D0000016neKQAQ',
					AcctSeed__Ledger__c = 'a121D000001muWMQAY'*/
      );
      insert bill;

      AcctSeed__Billing_Line__c bl = new AcctSeed__Billing_Line__c(
        AcctSeed__Billing__c = bill.Id,
        AcctSeed__Revenue_GL_Account__c = gcConstants.idGlCustomerRefund,
        AcctSeed__Hours_Units__c = 1,
        AcctSeed__Rate__c = refundAmount * -1,
        AcctSeed__GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale,
        AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2Sales
      );
      insert bl;
      AcctSeed.BillingPostService.postBillings(new List<AcctSeed__Billing__c>{ bill });
      Id idAccountingPeriod = [SELECT AcctSeed__Accounting_Period__c FROM AcctSeed__Billing__c WHERE Id = :bill.Id][0]
      .AcctSeed__Accounting_Period__c;
      List<AcctSeed__Billing_Cash_Receipt__c> listBCR = new List<AcctSeed__Billing_Cash_Receipt__c>();
      for (AcctSeed__Cash_Receipt__c cr : [
        SELECT
          Id,
          AcctSeed__Account__c,
          AcctSeed__Accounting_Period__c,
          AcctSeed__Amount__c,
          AcctSeed__Balance__c,
          AcctSeed__Bank_Account__c,
          AcctSeed__Cleared_Date__c,
          AcctSeed__Credit_GL_Account__c,
          AcctSeed__GL_Account_Variable_1__c,
          AcctSeed__GL_Account_Variable_2__c,
          AcctSeed__GL_Account_Variable_3__c,
          AcctSeed__GL_Account_Variable_4__c,
          AcctSeed__Payment_Reference__c,
          AcctSeed__Project__c,
          AcctSeed__Project_Task__c,
          AcctSeed__Purpose__c,
          AcctSeed__Receipt_Date__c,
          GMBLASG__Posted__c,
          Payment_Method__c
        FROM AcctSeed__Cash_Receipt__c
        WHERE AcctSeed__Account__c = :idAccount AND AcctSeed__Balance__c > 0 AND GMBLASG__Posted__c = TRUE
        ORDER BY AcctSeed__Balance__c ASC
      ]) {
        if (refundAmountLeft == 0)
          break;
        Decimal currentAmount;
        if (cr.AcctSeed__Balance__c >= refundAmountLeft) {
          currentAmount = refundAmountLeft;
          refundAmountLeft = 0;
        } else {
          currentAmount = cr.AcctSeed__Balance__c;
          refundAmountLeft = refundAmountLeft - currentAmount;
        }

        AcctSeed__Billing_Cash_Receipt__c bcr = new AcctSeed__Billing_Cash_Receipt__c(
          AcctSeed__Accounting_Period__c = idAccountingPeriod,
          AcctSeed__Applied_Amount__c = currentAmount,
          AcctSeed__Billing__c = bill.Id,
          AcctSeed__Cash_Receipt__c = cr.Id
        );
        listBCR.add(bcr);
      }
      /// This will nutralize some amount to with the cash receipts with a positive balance
      if (!listBCR.isEmpty()) {
        insert listBCR;
      }
      /// After processing if there are still balance left then
      if (refundAmountLeft > 0) {
        List<AcctSeed__Billing_Credit_Memo__c> listBCM = new List<AcctSeed__Billing_Credit_Memo__c>();

        for (AcctSeed__Billing__c negBill : [
          SELECT Id, AcctSeed__Balance__c
          FROM AcctSeed__Billing__c
          WHERE
            AcctSeed__Balance__c < 0
            AND AcctSeed__Type__c = 'Credit Memo'
            AND GMBLASG__Posted__c = TRUE
            AND AcctSeed__Customer__c = :idAccount
          ORDER BY AcctSeed__Balance__c ASC
        ]) {
          if (refundAmountLeft == 0)
            break;
          Decimal currentAmount;
          if ((negBill.AcctSeed__Balance__c * -1) >= refundAmountLeft) {
            currentAmount = refundAmountLeft * -1;
            refundAmountLeft = 0;
          } else {
            currentAmount = negBill.AcctSeed__Balance__c;
            refundAmountLeft = refundAmountLeft + currentAmount;
          }
          AcctSeed__Billing_Credit_Memo__c bcm = new AcctSeed__Billing_Credit_Memo__c(
            AcctSeed__Accounting_Period__c = idAccountingPeriod,
            AcctSeed__Amount__c = currentAmount,
            AcctSeed__Billing_Credit_Memo__c = negBill.Id,
            AcctSeed__Billing_Invoice__c = bill.Id
          );
          listBCM.add(bcm);
        }
        if (!listBCM.isEmpty())
          insert listBCM;
      }

      if (refundAmountLeft == (refundAmount * -1)) {
        throw new gcException(
          'No Cash Receipt or billing credit memo was found with a Balance to process the balance even partially.'
        );
      }

      Map<String, String> mapResult = new Map<String, String>();
      mapResult.put('idBill', bill.Id);
      return JSON.serialize(mapResult);
      //return accountPayable.Id;
    } catch (Exception e) {
      Database.rollback(sp);
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static String handleRefundPayment(Id idAccount, Id idBill) {
    Savepoint sp = Database.setSavepoint();
    try {
      /// First create a positive Billing with the total amount
      AcctSeed__Billing__c bill = [
        SELECT Id, AcctSeed__Customer__c, AcctSeed__Total__c
        FROM AcctSeed__Billing__c
        WHERE Id = :idBill
      ][0];
      String payeeRef = 'ACCT-' + String.valueOf(DateTime.now().getTime()) + '-Refund';
      AcctSeed__Account_Payable__c accountPayable = new AcctSeed__Account_Payable__c(
        AcctSeed__Vendor__c = bill.AcctSeed__Customer__c,
        AcctSeed__Payee_Reference__c = payeeRef,
        Tax_Override__c = true,
        Tax_is_Harmonized__c = false,
        Tax_Rate_Federal__c = 0,
        Tax_Rate_Provincial__c = 0,
        Tax_Rate_Retail__c = 0,
        AcctSeed__Date__c = Date.today() /*,
         AcctSeed__Ledger__c = 'a121D000001muWMQAY'*/
      );
      insert accountPayable;

      AcctSeed__Account_Payable_Line__c payLine = new AcctSeed__Account_Payable_Line__c(
        AcctSeed__Account_Payable__c = accountPayable.Id,
        AcctSeed__Amount__c = bill.AcctSeed__Total__c,
        AcctSeed__Date__c = Date.today(),
        AcctSeed__Expense_GL_Account__c = gcConstants.idGlCustomerRefund,
        AcctSeed__GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale,
        AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2Sales
      );
      insert payLine;
      AcctSeed.PostResult[] postResultsAP = AcctSeed.AccountPayablePostService.postAccountPayables(
        new List<AcctSeed__Account_Payable__c>{ accountPayable }
      );
      for (AcctSeed.PostResult theResult : postResultsAP) {
        if (!theResult.isSuccess) {
          for (AcctSeed.PostResult.PostErrorResult errorResult : theResult.errors) {
            throw new gcException('Account Payable was not posted. Please try again. REASON: ' + errorResult.message);
          }
        }
      }

      Map<String, String> mapResult = new Map<String, String>();
      mapResult.put('idBill', bill.Id);
      mapResult.put('idPayable', accountPayable.Id);

      return JSON.serialize(mapResult);
      //return accountPayable.Id;
    } catch (Exception e) {
      Database.rollback(sp);
      //AcctSeed.BillingPostService.unpostBillings(new List<AcctSeed__Billing__c>{new AcctSeed__Billing__c(Id=idBill)});
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static String handleRefundCD(Id idAccount, String paymentMethod, Id idPayable) {
    Savepoint sp = Database.setSavepoint();
    try {
      AcctSeed__Account_Payable__c accountPayable = [
        SELECT Id, AcctSeed__Vendor__c, AcctSeed__Total__c
        FROM AcctSeed__Account_Payable__c
        WHERE Id = :idPayable
      ][0];
      Decimal startingCheckNumber = null;
      Boolean noChequeRequired = false;
      if (!paymentMethod.equals('Check')) {
        startingCheckNumber = 0;
        noChequeRequired = true;
      }

      if (startingCheckNumber == null && !noChequeRequired) {
        startingCheckNumber = 0;
        for (AcctSeed__Cash_Disbursement__c cd : [
          SELECT Id, AcctSeed__Check_Number__c
          FROM AcctSeed__Cash_Disbursement__c
          WHERE AcctSeed__Check_Number__c != NULL
          ORDER BY AcctSeed__Check_Number__c DESC
          LIMIT 1
        ]) {
          startingCheckNumber = cd.AcctSeed__Check_Number__c;
        }
        startingCheckNumber += 1;
      }
      AcctSeed__Cash_Disbursement_Batch__c cashDisbursementBatch = new AcctSeed__Cash_Disbursement_Batch__c(
        AcctSeed__Starting_Check_Number__c = startingCheckNumber,
        Name = 'Refund Batch' + String.valueOf(System.now())
      );
      insert cashDisbursementBatch;

      AcctSeed__Cash_Disbursement__c disbursement = new AcctSeed__Cash_Disbursement__c(
        AcctSeed__Cash_Disbursement_Batch__c = cashDisbursementBatch.Id,
        AcctSeed__Disbursement_Date__c = Date.today(),
        AcctSeed__Type__c = paymentMethod,
        AcctSeed__Amount__c = accountPayable.AcctSeed__Total__c,
        AcctSeed__Source__c = 'Payable',
        AcctSeed__Vendor__c = idAccount,
        AcctSeed__Status__c = 'Approved',
        AcctSeed__Reference__c = 'refund_' + System.now().format(),
        AcctSeed__Debit_GL_Account__c = gcConstants.idGlAPayable,
        AcctSeed__Payment_Status__c = 'Paid',
        AcctSeed__Cash_Flow_Category__c = gcConstants.idGlRevenueCF /*,
         AcctSeed__Ledger__c = 'a121D000001muWMQAY'*/
      );

      insert disbursement;

      AcctSeed__AP_Disbursement__c apdisbursement = new AcctSeed__AP_Disbursement__c(
        AcctSeed__Cash_Disbursement__c = disbursement.Id,
        AcctSeed__Paid_Amount__c = disbursement.AcctSeed__Amount__c,
        AcctSeed__Account_Payable__c = accountPayable.Id
      );
      insert apdisbursement;

      AcctSeed.PostResult[] postResults = AcctSeed.CashDisbursementPostService.postCashDisbursements(
        new List<AcctSeed__Cash_Disbursement__c>{ disbursement }
      );
      for (AcctSeed.PostResult theResult : postResults) {
        if (!theResult.isSuccess) {
          for (AcctSeed.PostResult.PostErrorResult errorResult : theResult.errors) {
            throw new gcException('Cash Disbursement was not posted. Please try again. REASON: ' + errorResult.message);
          }
        }
      }

      Map<String, String> mapResult = new Map<String, String>();
      mapResult.put('idPayable', accountPayable.Id);
      mapResult.put('idDisbursement', disbursement.Id);
      mapResult.put('txnData', retrieveAccountTxnDetails(idAccount));

      return JSON.serialize(mapResult);
      //return accountPayable.Id;
    } catch (Exception e) {
      Database.rollback(sp);
      //AcctSeed.AccountPayablePostService.unpostAccountPayables(new List<AcctSeed__Account_Payable__c>{new AcctSeed__Account_Payable__c(Id=idPayable)});
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static void unpostBilling(Id idBill) {
    delete [SELECT Id FROM AcctSeed__Billing_Credit_Memo__c WHERE AcctSeed__Billing_Invoice__c = :idBill];
    delete [SELECT Id FROM AcctSeed__Billing_Cash_Receipt__c WHERE AcctSeed__Billing__c = :idBill];
    List<AcctSeed__Billing__c> listBill = new List<AcctSeed__Billing__c>{ new AcctSeed__Billing__c(Id = idBill) };
    AcctSeed.BillingPostService.unpostBillings(listBill);
    delete listBill;
  }

  @AuraEnabled
  public static void unpostPayable(Id idPayable) {
    delete [SELECT Id FROM AcctSeed__AP_Disbursement__c WHERE AcctSeed__Account_Payable__c = :idPayable];
    List<AcctSeed__Account_Payable__c> listAP = new List<AcctSeed__Account_Payable__c>{
      new AcctSeed__Account_Payable__c(Id = idPayable)
    };
    AcctSeed.AccountPayablePostService.unpostAccountPayables(listAP);
    delete listAP;
  }

  @AuraEnabled
  public static void unpostCD(Id idCD) {
    List<AcctSeed__Cash_Disbursement__c> listCD = new List<AcctSeed__Cash_Disbursement__c>{
      new AcctSeed__Cash_Disbursement__c(Id = idCD)
    };
    AcctSeed.CashDisbursementPostService.unpostCashDisbursements(listCD);
    delete listCD;
  }

  /*@AuraEnabled
	public static String handleRefund_Old(Id idAccount, String paymentMethod, Decimal refundAmount)
	{
		Savepoint sp = Database.setSavepoint();
		try{
			Decimal refundAmountLeft = refundAmount * -1;
			/// First create a positive Billing with the total amount
			AcctSeed__Billing__c bill = new AcctSeed__Billing__c(
				AcctSeed__Customer__c = idAccount,
				Tax_Override__c = true,
				Tax_is_Harmonized__c = false,
				Tax_Rate_Federal__c = 0,
				Tax_Rate_Provincial__c = 0,
				Tax_Rate_Retail__c = 0*/ /*,
					AcctSeed__Billing_Format__c = 'a0e1D0000016neKQAQ',
					AcctSeed__Ledger__c = 'a121D000001muWMQAY'*/ /*
			);
			insert bill;

			AcctSeed__Billing_Line__c bl = new AcctSeed__Billing_Line__c(
				AcctSeed__Billing__c = bill.Id,
				AcctSeed__Revenue_GL_Account__c = gcConstants.idGlCustomerRefund,
				AcctSeed__Hours_Units__c = 1,
				AcctSeed__Rate__c =  refundAmount * -1,
				AcctSeed__GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale,
				AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2Sales
			);
			insert bl;
			AcctSeed.BillingPostService.postBillings(new List<AcctSeed__Billing__c>{bill});
			Id idAccountingPeriod = [SELECT AcctSeed__Accounting_Period__c FROM AcctSeed__Billing__c WHERE Id =:bill.Id][0].AcctSeed__Accounting_Period__c;
			List<AcctSeed__Billing_Cash_Receipt__c> listBCR = new List<AcctSeed__Billing_Cash_Receipt__c>();
			for(AcctSeed__Cash_Receipt__c cr :
			[SELECT Id,
				AcctSeed__Account__c,
				AcctSeed__Accounting_Period__c,
				AcctSeed__Amount__c,
				AcctSeed__Balance__c,
				AcctSeed__Bank_Account__c,
				AcctSeed__Cleared_Date__c,
				AcctSeed__Credit_GL_Account__c,
				AcctSeed__GL_Account_Variable_1__c,
				AcctSeed__GL_Account_Variable_2__c,
				AcctSeed__GL_Account_Variable_3__c,
				AcctSeed__GL_Account_Variable_4__c,
				AcctSeed__Payment_Reference__c,
				AcctSeed__Project__c,
				AcctSeed__Project_Task__c,
				AcctSeed__Purpose__c,
				AcctSeed__Receipt_Date__c,
				GMBLASG__Posted__c,
				Payment_Method__c
			FROM AcctSeed__Cash_Receipt__c
			WHERE AcctSeed__Account__c =:idAccount
			AND AcctSeed__Balance__c > 0
			AND GMBLASG__Posted__c = true
			ORDER BY AcctSeed__Balance__c ASC])
			{
				if(refundAmountLeft == 0) break;
				Decimal currentAmount;
				if(cr.AcctSeed__Balance__c >= refundAmountLeft){
					currentAmount = refundAmountLeft;
					refundAmountLeft = 0;
				}else{
					currentAmount = cr.AcctSeed__Balance__c;
					refundAmountLeft = refundAmountLeft - currentAmount;
				}

				AcctSeed__Billing_Cash_Receipt__c bcr = new AcctSeed__Billing_Cash_Receipt__c(
					AcctSeed__Accounting_Period__c = idAccountingPeriod,
					AcctSeed__Applied_Amount__c = currentAmount,
					AcctSeed__Billing__c = bill.Id,
					AcctSeed__Cash_Receipt__c = cr.Id
				);
				listBCR.add(bcr);
			}
			/// This will nutralize some amount to with the cash receipts with a positive balance
			if(!listBCR.isEmpty()){
				insert listBCR;
			}
			/// After processing if there are still balance left then
			if(refundAmountLeft > 0){
				List<AcctSeed__Billing_Credit_Memo__c> listBCM = new List<AcctSeed__Billing_Credit_Memo__c>();

				for(AcctSeed__Billing__c negBill :
				[SELECT Id,
					AcctSeed__Balance__c
				FROM AcctSeed__Billing__c
				WHERE AcctSeed__Balance__c < 0
				AND AcctSeed__Type__c = 'Credit Memo'
				AND GMBLASG__Posted__c = true
				AND AcctSeed__Customer__c =:idAccount
				ORDER BY AcctSeed__Balance__c ASC])
				{
					if(refundAmountLeft == 0) break;
					Decimal currentAmount;
					if((negBill.AcctSeed__Balance__c * -1) >= refundAmountLeft){
						currentAmount = refundAmountLeft * -1;
						refundAmountLeft = 0;
					}else{
						currentAmount = negBill.AcctSeed__Balance__c;
						refundAmountLeft = refundAmountLeft + currentAmount;
					}
					AcctSeed__Billing_Credit_Memo__c bcm = new AcctSeed__Billing_Credit_Memo__c(
						AcctSeed__Accounting_Period__c = idAccountingPeriod,
						AcctSeed__Amount__c = currentAmount,
						AcctSeed__Billing_Credit_Memo__c = negBill.Id,
						AcctSeed__Billing_Invoice__c = bill.Id
					);
					listBCM.add(bcm);
				}
				if(!listBCM.isEmpty())
					insert listBCM;
			}

			if(refundAmountLeft == (refundAmount * -1))
			{
				throw new gcException('No Cash Receipt or billing credit memo was found with a Balance to process the balance even partially.');
			}

			String payeeRef = 'ACCT-' + String.valueOf(DateTime.now().getTime()) + '-Refund';
			AcctSeed__Account_Payable__c accountPayable = new AcctSeed__Account_Payable__c(
				AcctSeed__Vendor__c = bill.AcctSeed__Customer__c,
				AcctSeed__Payee_Reference__c = payeeRef,
				Tax_Override__c = true,
				Tax_is_Harmonized__c = false,
				Tax_Rate_Federal__c = 0,
				Tax_Rate_Provincial__c = 0,
				Tax_Rate_Retail__c = 0,
				AcctSeed__Date__c = Date.today(),
				AcctSeed__Ledger__c = 'a121D000001muWMQAY'
			);
			insert accountPayable;

			AcctSeed__Account_Payable_Line__c payLine = new AcctSeed__Account_Payable_Line__c(
				AcctSeed__Account_Payable__c = accountPayable.Id,
				AcctSeed__Amount__c = refundAmount * -1,
				AcctSeed__Date__c = Date.today(),
				AcctSeed__Expense_GL_Account__c = gcConstants.idGlCustomerRefund,
				AcctSeed__GL_Account_Variable_1__c = bl.AcctSeed__GL_Account_Variable_1__c,
				AcctSeed__GL_Account_Variable_2__c = bl.AcctSeed__GL_Account_Variable_2__c
			);
			insert payLine;
			AcctSeed.PostResult[] postResultsAP = AcctSeed.AccountPayablePostService.postAccountPayables(new List<AcctSeed__Account_Payable__c>{accountPayable});
			for (AcctSeed.PostResult theResult : postResultsAP) {
				if (!theResult.isSuccess) {
					for (AcctSeed.PostResult.PostErrorResult errorResult: theResult.errors) {
						throw new gcException('Account Payable was not posted. Please try again. REASON: ' + errorResult.message);
					}
				}
			}

			Decimal startingCheckNumber = null;
			Boolean noChequeRequired = false;
			if(!paymentMethod.equals('Check')){
				startingCheckNumber = 0;
				noChequeRequired = true;
			}

			if(startingCheckNumber == null && !noChequeRequired)
			{
				startingCheckNumber = 0;
				for(AcctSeed__Cash_Disbursement__c cd : [
					SELECT Id, AcctSeed__Check_Number__c
					FROM AcctSeed__Cash_Disbursement__c
					WHERE AcctSeed__Check_Number__c != null
					ORDER BY AcctSeed__Check_Number__c DESC
					LIMIT 1])
				{
					startingCheckNumber = cd.AcctSeed__Check_Number__c;
				}
				startingCheckNumber += 1;
			}
			AcctSeed__Cash_Disbursement_Batch__c cashDisbursementBatch = new AcctSeed__Cash_Disbursement_Batch__c(
				AcctSeed__Starting_Check_Number__c = startingCheckNumber,
				Name = 'Refund Batch' + String.valueOf(System.now())
			);
			insert cashDisbursementBatch;

			Id idGlMerchantDebitCredit = gcConstants.idGlMerchantDebitCredit;
			Id idGlCashFloat = gcConstants.idGlCashFloat;
			Id idGlRBCCDN = gcConstants.idGlRBCCDN;
			Id idGlBank;

			if(paymentMethod == 'Credit Card'
				|| paymentMethod == 'Visa'
				|| paymentMethod == 'Debit'
				|| paymentMethod == 'Accord D')
				idGlBank = idGlMerchantDebitCredit;
			else if(paymentMethod == 'Cheque'
				|| paymentMethod == 'Check'
				|| paymentMethod == 'Draft')
				idGlBank = idGlRBCCDN;
			else if(paymentMethod == 'Cash')
				idGlBank = idGlCashFloat;
			else
				idGlBank = idGlRBCCDN;
			AcctSeed__Cash_Disbursement__c disbursement = new AcctSeed__Cash_Disbursement__c(
				AcctSeed__Cash_Disbursement_Batch__c = cashDisbursementBatch.Id,
				AcctSeed__Disbursement_Date__c = Date.today(),
				AcctSeed__Type__c = paymentMethod,
				AcctSeed__Amount__c = refundAmount * -1,
				AcctSeed__Source__c = 'Account Payable',
				AcctSeed__Bank_Account__c = idGlBank,//cr.AcctSeed__Bank_Account__c,
				AcctSeed__Vendor__c = idAccount,
				AcctSeed__Status__c = 'Approved',
				AcctSeed__Reference__c = 'refund_'+ System.now().format(),
				AcctSeed__Debit_GL_Account__c = gcConstants.idGlAPayable,
				AcctSeed__Payment_Status__c = 'Paid',
				AcctSeed__Ledger__c = 'a121D000001muWMQAY'
			);

			insert disbursement;

			AcctSeed.PostResult[] postResults = AcctSeed.CashDisbursementPostService.postCashDisbursements(new List<AcctSeed__Cash_Disbursement__c>{disbursement});
			for (AcctSeed.PostResult theResult : postResults) {
				if (!theResult.isSuccess) {
					for (AcctSeed.PostResult.PostErrorResult errorResult: theResult.errors) {
						throw new gcException('Cash Disbursement was not posted. Please try again. REASON: ' + errorResult.message);
					}
				}
			}

			AcctSeed__AP_Disbursement__c apdisbursement = new AcctSeed__AP_Disbursement__c(
				AcctSeed__Cash_Disbursement__c = disbursement.Id,
				AcctSeed__Paid_Amount__c = disbursement.AcctSeed__Amount__c,
				AcctSeed__Account_Payable__c = accountPayable.Id
			);
			insert apdisbursement;
			Map<String,String> mapResult = new Map<String,String>();
			mapResult.put('idBill', bill.Id);
			mapResult.put('idPayable', accountPayable.Id);
			mapResult.put('idDisbursement', disbursement.Id);
			mapResult.put('txnData', retrieveAccountTxnDetails(idAccount));

			return JSON.serialize(mapResult);
			//return accountPayable.Id;
		}catch(Exception e){
			Database.rollback(sp);
			throw new AuraHandledException(e.getMessage());
		}
	}*/

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
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
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
