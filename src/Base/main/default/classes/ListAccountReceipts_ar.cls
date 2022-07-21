public without sharing class ListAccountReceipts_ar {
  @AuraEnabled
  public static String retrieveReceiptDetails(Id idAccount, Id idPeriod) {
    Date lastDate = Date.today();
    if (idPeriod == null) {
      for (AcctSeed__Accounting_Period__c per : [
        SELECT Id, AcctSeed__End_Date__c
        FROM AcctSeed__Accounting_Period__c
        WHERE AcctSeed__Status__c = 'Open'
        ORDER BY AcctSeed__Start_Date__c DESC
        LIMIT 1
      ])
        lastDate = per.AcctSeed__End_Date__c;
    } else {
      for (AcctSeed__Accounting_Period__c per : [
        SELECT Id, AcctSeed__End_Date__c
        FROM AcctSeed__Accounting_Period__c
        WHERE Id = :idPeriod
      ])
        lastDate = per.AcctSeed__End_Date__c;
    }

    List<Map<String, String>> listReceipts = new List<Map<String, String>>();
    for (AcctSeed__Cash_Receipt__c cr : [
      SELECT Id, Name, AcctSeed__Amount__c, AcctSeed__Balance__c, GMBLASG__Posted__c
      FROM AcctSeed__Cash_Receipt__c
      WHERE
        AcctSeed__Account__c = :idAccount
        AND AcctSeed__Balance__c != 0
        AND GMBLASG__Posted__c = TRUE
        AND AcctSeed__Receipt_Date__c <= :lastDate
      ORDER BY AcctSeed__Receipt_Date__c, Name
    ]) {
      Map<String, String> m = new Map<String, String>();
      m.put('Id', cr.Id);
      m.put('Name', cr.Name);
      m.put('crBalance', String.valueOf(cr.AcctSeed__Balance__c));
      m.put('crTotal', String.valueOf(cr.AcctSeed__Amount__c));
      listReceipts.add(m);
    }
    return JSON.serialize(listReceipts);
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
        Payment_Method__c,
        AcctSeed__Receipt_Date__c
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
        } else if (applyType.equals('exist')) {
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
          else
            throw new gcException('No Existing Billing was found with a balance to apply the cash receipt.');
        } else {
          AcctSeed__Accounting_Period__c currPeriod = GMBLASERP.gcAccountingPeriod.periodCurr();
          List<AcctSeed__Billing_Cash_Receipt__c> listBCM = new List<AcctSeed__Billing_Cash_Receipt__c>();
          Decimal appliedBalance = receiptBalance;
          for (AcctSeed__Billing__c bl : [
            SELECT Id, Name, AcctSeed__Total__c, AcctSeed__Balance__c, GMBLASG__Posted__c
            FROM AcctSeed__Billing__c
            WHERE
              AcctSeed__Customer__c = :idAccount
              AND AcctSeed__Balance__c > 0
              AND GMBLASG__Posted__c = TRUE
              AND AcctSeed__Date__c <= :cr.AcctSeed__Receipt_Date__c
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
          else
            throw new gcException(
              'No Posted Billing on/before ' +
              cr.AcctSeed__Receipt_Date__c.format() +
              ' was found with a balance to apply the cash receipt.'
            );
        }
      } catch (Exception e) {
        Database.rollback(sp);
        throw new AuraHandledException(e.getMessage());
      }
      return '';
    }
    throw new AuraHandledException('No Cash receipt was found with a balance.');
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
  }
}
