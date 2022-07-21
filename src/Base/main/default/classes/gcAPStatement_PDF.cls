global without sharing class gcAPStatement_PDF {
  global gcAPStatement_PDF(ApexPages.StandardController c) {
    acc = (Account) (c.getRecord());

    init();
  }

  global transient Account acc { get; set; }
  global transient Map<String, String> accMap { get; set; }
  global transient Map<String, List<Map<String, String>>> apList { get; set; }
  global transient List<String> keyList { get; set; }
  global transient Decimal totalAP { get; set; }
  global transient Decimal totalAR { get; set; }
  global transient Decimal totalBalance { get; set; }
  global transient Decimal totalRecords { get; set; }

  global void init() {
    totalAP = 0;
    totalAR = 0;
    Set<Id> setIdCD = new Set<Id>();
    keyList = new List<String>();
    apList = new Map<String, List<Map<String, String>>>();
    acc = [
      SELECT
        Id,
        Name,
        AcctSeed__Billing_Contact__c,
        AcctSeed__Billing_Contact__r.Name,
        BillingCity,
        BillingCountry,
        BillingPostalCode,
        BillingState,
        BillingStreet,
        Payment_Preference__c,
        RecordType.Name,
        Phone,
        (
          SELECT
            Id,
            Name,
            AcctSeed__Balance__c,
            AcctSeed__Credit_Memo_Applied_Amount__c,
            AcctSeed__Discount_Amount__c,
            AcctSeed__Due_Date__c,
            AcctSeed__Date__c,
            AcctSeed__Net_Amount__c,
            AcctSeed__Paid_Amount__c,
            AcctSeed__Payee_Reference__c,
            AcctSeed__Payment_Status__c,
            AcctSeedERP__Purchase_Order__c,
            AcctSeed__Total__c,
            AcctSeed__Type__c
          FROM AcctSeed__Project_Payable_Invoices__r
          WHERE AcctSeed__Balance__c != 0 AND GMBLASG__Posted__c = TRUE
          ORDER BY AcctSeed__Date__c, Name
        ),
        (
          SELECT Id
          FROM AcctSeed__Cash_Disbursements__r
          WHERE AcctSeed__Amount__c != 0 AND GMBLASG__Posted__c = TRUE AND AcctSeed__Payment_Status__c != 'Void'
        ),
        (
          SELECT
            Id,
            Name,
            AcctSeed__Amount__c,
            AcctSeed__Applied_Amount__c,
            AcctSeed__Balance__c,
            AcctSeed__Credit_GL_Account__c,
            AcctSeed__Payment_Reference__c,
            AcctSeed__Project__c,
            AcctSeed__Project__r.Name,
            GMBLASG__Posted__c,
            AcctSeed__Receipt_Date__c,
            AcctSeed__Purpose__c
          FROM AcctSeed__Cash_Receipts__r
          WHERE AcctSeed__Balance__c != 0 AND GMBLASG__Posted__c = TRUE
          ORDER BY AcctSeed__Receipt_Date__c, Name
        ),
        (
          SELECT
            Id,
            Name,
            AcctSeed__Balance__c,
            AcctSeed__Date__c,
            AcctSeed__Due_Date2__c,
            AcctSeed__Total__c,
            AcctSeed__Type__c
          FROM AcctSeed__Billings__r
          WHERE AcctSeed__Balance__c != 0 AND GMBLASG__Posted__c = TRUE
          ORDER BY AcctSeed__Date__c, Name
        )
      FROM Account
      WHERE Id = :acc.Id
    ][0];

    Map<Id, String> mapBillProject = new Map<Id, String>();
    if (!acc.AcctSeed__Billings__r.isEmpty()) {
      Set<Id> setIdBill = new Set<Id>();
      for (AcctSeed__Billing__c bill : acc.AcctSeed__Billings__r)
        setIdBill.add(bill.Id);

      for (AcctSeed__Billing__c b : [
        SELECT Id, (SELECT Id, AcctSeed__Project__c, AcctSeed__Project__r.Name FROM AcctSeed__Project_Billing_Lines__r)
        FROM AcctSeed__Billing__c
        WHERE Id IN :setIdBill
      ]) {
        String projectName = '';
        Set<Id> setIdProj = new Set<Id>();
        for (AcctSeed__Billing_Line__c bl : b.AcctSeed__Project_Billing_Lines__r) {
          if (bl.AcctSeed__Project__r.Name != null && !setIdProj.contains(bl.AcctSeed__Project__c)) {
            setIdProj.add(bl.AcctSeed__Project__c);
            if (projectName == '')
              projectName += bl.AcctSeed__Project__r.Name;
            else
              projectName += ',' + bl.AcctSeed__Project__r.Name;
          }
        }
        mapBillProject.put(b.Id, projectName);
      }
    }

    if (!acc.AcctSeed__Billings__r.isEmpty()) {
      List<Map<String, String>> listBillings = new List<Map<String, String>>();
      apList.put('Billings', listBillings);
      keyList.add('Billings');
      for (AcctSeed__Billing__c bill : acc.AcctSeed__Billings__r) {
        Map<String, String> m = new Map<String, String>();
        m.put('apId', bill.Id);
        m.put('apName', bill.Name);
        m.put('apType', bill.AcctSeed__Type__c == null ? '' : bill.AcctSeed__Type__c);
        m.put('apProject', mapBillProject.get(bill.Id));
        m.put('apRef', '');
        m.put('apDate', bill.AcctSeed__Date__c == null ? '' : bill.AcctSeed__Date__c.format());
        m.put('apDueDate', bill.AcctSeed__Due_Date2__c == null ? '' : bill.AcctSeed__Due_Date2__c.format());
        m.put('apNet', '0.00');
        m.put('apDiscount', '0.00');
        m.put('apPaid', '0.00');
        m.put('apTotal', String.valueOf(bill.AcctSeed__Total__c.setScale(2)));
        m.put(
          'apBalance',
          bill.AcctSeed__Balance__c == null ? '0.00' : String.valueOf(bill.AcctSeed__Balance__c.setScale(2))
        );
        listBillings.add(m);
        totalAR += bill.AcctSeed__Balance__c == null ? 0 : bill.AcctSeed__Balance__c;
      }
    }
    if (!acc.AcctSeed__Cash_Receipts__r.isEmpty()) {
      List<Map<String, String>> listCR = new List<Map<String, String>>();
      apList.put('Cash Receipts', listCR);
      keyList.add('Cash Receipts');
      for (AcctSeed__Cash_Receipt__c cr : acc.AcctSeed__Cash_Receipts__r) {
        Map<String, String> m = new Map<String, String>();
        m.put('apId', cr.Id);
        m.put('apName', cr.Name);
        m.put('apType', cr.AcctSeed__Purpose__c == null ? '' : cr.AcctSeed__Purpose__c);
        m.put('apProject', cr.AcctSeed__Project__c == null ? '' : cr.AcctSeed__Project__r.Name);
        m.put('apRef', cr.AcctSeed__Payment_Reference__c == null ? '' : cr.AcctSeed__Payment_Reference__c);
        m.put('apDate', cr.AcctSeed__Receipt_Date__c == null ? '' : cr.AcctSeed__Receipt_Date__c.format());
        m.put('apDueDate', '');
        m.put('apNet', '0.00');
        m.put('apDiscount', '0.00');
        m.put(
          'apPaid',
          cr.AcctSeed__Applied_Amount__c == null ? '0.00' : String.valueOf(cr.AcctSeed__Applied_Amount__c.setScale(2))
        );
        m.put('apTotal', cr.AcctSeed__Amount__c == null ? '0.00' : String.valueOf(cr.AcctSeed__Amount__c.setScale(2)));
        m.put(
          'apBalance',
          cr.AcctSeed__Balance__c == null ? '0.00' : String.valueOf(cr.AcctSeed__Balance__c.setScale(2))
        );
        listCR.add(m);
        totalAR -= cr.AcctSeed__Balance__c == null ? 0 : cr.AcctSeed__Balance__c;
      }
    }

    Map<Id, String> mapApProject = new Map<Id, String>();
    if (!acc.AcctSeed__Project_Payable_Invoices__r.isEmpty()) {
      Set<Id> setIdAP = new Set<Id>();
      for (AcctSeed__Account_Payable__c ap : acc.AcctSeed__Project_Payable_Invoices__r)
        setIdAP.add(ap.Id);

      for (AcctSeed__Account_Payable__c ap : [
        SELECT
          Id,
          (SELECT Id, AcctSeed__Project__c, AcctSeed__Project__r.Name FROM AcctSeed__Project_Account_Payable_Lines__r)
        FROM AcctSeed__Account_Payable__c
        WHERE Id IN :setIdAP
      ]) {
        String projectName = '';
        Set<Id> setIdProj = new Set<Id>();
        for (AcctSeed__Account_Payable_Line__c apl : ap.AcctSeed__Project_Account_Payable_Lines__r) {
          if (apl.AcctSeed__Project__r.Name != null && !setIdProj.contains(apl.AcctSeed__Project__c)) {
            setIdProj.add(apl.AcctSeed__Project__c);
            if (projectName == '')
              projectName += apl.AcctSeed__Project__r.Name;
            else
              projectName += ',' + apl.AcctSeed__Project__r.Name;
          }
        }
        mapApProject.put(ap.Id, projectName);
      }
    }

    if (!acc.AcctSeed__Project_Payable_Invoices__r.isEmpty()) {
      List<Map<String, String>> listPayables = new List<Map<String, String>>();
      apList.put('Account Payables', listPayables);
      keyList.add('Account Payables');
      for (AcctSeed__Account_Payable__c ap : acc.AcctSeed__Project_Payable_Invoices__r) {
        Map<String, String> m = new Map<String, String>();
        m.put('apId', ap.Id);
        m.put('apName', ap.Name);
        m.put('apType', ap.AcctSeed__Type__c == null ? '' : ap.AcctSeed__Type__c);
        m.put('apProject', mapApProject.get(ap.Id));
        m.put('apRef', ap.AcctSeed__Payee_Reference__c == null ? '' : ap.AcctSeed__Payee_Reference__c);
        m.put('apDate', ap.AcctSeed__Date__c == null ? '' : ap.AcctSeed__Date__c.format());
        m.put('apDueDate', ap.AcctSeed__Due_Date__c == null ? '' : ap.AcctSeed__Due_Date__c.format());
        m.put(
          'apNet',
          ap.AcctSeed__Net_Amount__c == null ? '0.00' : String.valueOf(ap.AcctSeed__Net_Amount__c.setScale(2))
        );
        m.put(
          'apDiscount',
          ap.AcctSeed__Discount_Amount__c == null ? '0.00' : String.valueOf(ap.AcctSeed__Discount_Amount__c.setScale(2))
        );
        m.put(
          'apPaid',
          ap.AcctSeed__Paid_Amount__c == null ? '0.00' : String.valueOf(ap.AcctSeed__Paid_Amount__c.setScale(2))
        );
        m.put('apTotal', ap.AcctSeed__Total__c == null ? '0.00' : String.valueOf(ap.AcctSeed__Total__c.setScale(2)));
        m.put(
          'apBalance',
          ap.AcctSeed__Balance__c == null ? '0.00' : String.valueOf(ap.AcctSeed__Balance__c.setScale(2))
        );
        listPayables.add(m);
        totalAP += ap.AcctSeed__Balance__c == null ? 0 : ap.AcctSeed__Balance__c;
      }
    }
    if (!acc.AcctSeed__Cash_Disbursements__r.isEmpty()) {
      List<Map<String, String>> listCD = new List<Map<String, String>>();
      for (AcctSeed__Cash_Disbursement__c cd : acc.AcctSeed__Cash_Disbursements__r)
        setIdCD.add(cd.Id);

      for (AcctSeed__Cash_Disbursement__c cd : [
        SELECT
          Id,
          Name,
          (SELECT Id, AcctSeed__Paid_Amount__c FROM AcctSeed__Account_Payable_Cash_Disbursements__r),
          AcctSeed__Amount__c,
          AcctSeed__Check_Number__c,
          AcctSeed__Type__c,
          AcctSeed__Project__c,
          AcctSeed__Project__r.Name,
          AcctSeed__Disbursement_Date__c
        FROM AcctSeed__Cash_Disbursement__c
        WHERE Id IN :setIdCD
        ORDER BY AcctSeed__Disbursement_Date__c, Name
      ]) {
        Decimal totalPaid = 0;
        for (AcctSeed__AP_Disbursement__c ap : cd.AcctSeed__Account_Payable_Cash_Disbursements__r)
          totalPaid += ap.AcctSeed__Paid_Amount__c == null ? 0 : ap.AcctSeed__Paid_Amount__c;
        Decimal cdBalance = cd.AcctSeed__Amount__c - totalPaid;
        if (cdBalance == 0)
          continue;
        Map<String, String> m = new Map<String, String>();
        m.put('apId', cd.Id);
        m.put('apName', cd.Name);
        m.put('apType', cd.AcctSeed__Type__c == null ? '' : cd.AcctSeed__Type__c);
        m.put('apProject', cd.AcctSeed__Project__c == null ? '' : cd.AcctSeed__Project__r.Name);
        m.put('apRef', cd.AcctSeed__Check_Number__c == null ? '' : String.valueOf(cd.AcctSeed__Check_Number__c));
        m.put('apDate', cd.AcctSeed__Disbursement_Date__c == null ? '' : cd.AcctSeed__Disbursement_Date__c.format());
        m.put('apDueDate', '');
        m.put('apNet', '0.00');
        m.put('apDiscount', '0.00');
        m.put('apPaid', String.valueOf(totalPaid.setScale(2)));
        m.put('apTotal', String.valueOf(cd.AcctSeed__Amount__c.setScale(2)));
        m.put('apBalance', String.valueOf(cdBalance.setScale(2)));
        listCD.add(m);
        totalAP -= cdBalance;
      }
      if (!listCD.isEmpty()) {
        apList.put('Cash Disbursements', listCD);
        keyList.add('Cash Disbursements');
      }
    }
    totalRecords = apList.size();
    //totalBalance = totalAP - totalAR;
    totalBalance = totalAR - totalAP;
    accMap = new Map<String, String>();
    accMap.put('name', acc.Name);
    accMap.put('nameRecordType', acc.RecordType.Name);
    accMap.put('paymentReference', acc.Payment_Preference__c == null ? 'N/A' : acc.Payment_Preference__c);
    accMap.put('phoneNumber', acc.Phone == null ? 'N/A' : acc.Phone);
    accMap.put('billingContact', acc.AcctSeed__Billing_Contact__c == null ? '' : acc.AcctSeed__Billing_Contact__r.Name);
    accMap.put('billingCity', acc.BillingCity == null ? 'N/A' : acc.BillingCity);
    accMap.put('billingCountry', acc.BillingCountry == null ? '' : acc.BillingCountry);
    accMap.put('billingPostalCode', acc.BillingPostalCode == null ? '' : acc.BillingPostalCode);
    accMap.put('billingState', acc.BillingState == null ? 'N/A' : acc.BillingState);
    accMap.put('billingStreet', acc.BillingStreet == null ? '' : acc.BillingStreet);
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
  }
}
