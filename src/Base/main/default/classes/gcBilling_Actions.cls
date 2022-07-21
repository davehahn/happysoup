public with sharing class gcBilling_Actions {
  public gcBilling_Actions() {
  }

  public gcBilling_Actions(ApexPages.StandardController stc) {
    setIdFilter = new Set<Id>();
    setIdFilter.add(stc.getId());
    retUrl = '/' + stc.getId();
  }

  public gcBilling_Actions(ApexPages.StandardSetController ssc) {
    setIdFilter = new Set<Id>();

    for (AcctSeed__Billing_Line__c rec : (list<AcctSeed__Billing_Line__c>) ssc.getSelected())
      setIdFilter.add(rec.Id);

    retUrl = ApexPages.currentPage().getParameters().get('retUrl');
  }

  public pageReference back() {
    return new pageReference(retUrl);
  }

  public void init() {
    String processName = ApexPages.currentPage().getParameters().get('processName');
    String idFilter = ApexPages.currentPage().getParameters().get('idFilter');
    if (idFilter != null)
      setIdFilter.add(idFilter);

    if (retUrl == null && idFilter != null)
      retUrl = '/' + idFilter;

    if (setIdFilter.isEmpty()) {
      ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'No billing lines selected to refund.'));
      return;
    }
    if (processName == null)
      createAPLines();
    else if (processName == 'billing')
      createBillingAP();
  }

  private set<Id> setIdFilter { get; set; }
  private String retUrl { get; set; }

  public void createAPLines() {
    Set<Id> setIdProject = new Set<Id>();
    List<AcctSeed__Billing_Line__c> listBillingLines = new List<AcctSeed__Billing_Line__c>();
    Decimal billTotal = 0;
    for (AcctSeed__Billing_Line__c bl : [
      SELECT
        Id,
        AcctSeed__Billing__c,
        AcctSeed__GL_Account_Variable_1__c,
        AcctSeed__GL_Account_Variable_2__c,
        AcctSeed__GL_Account_Variable_3__c,
        AcctSeed__GL_Account_Variable_4__c,
        AcctSeed__Hours_Units__c,
        AcctSeed__Product__c,
        AcctSeed__Product_Unit_Cost__c,
        AcctSeed__Project__c,
        AcctSeed__Project_Task__c,
        AcctSeed__Rate__c,
        AcctSeed__Revenue_GL_Account__c,
        AcctSeed__Total__c,
        GMBLASERP__Material__c
      FROM AcctSeed__Billing_Line__c
      WHERE
        (Id IN :setIdFilter
        OR AcctSeed__Billing__c IN :setIdFilter
        OR AcctSeed__Project__c IN :setIdFilter)
        AND AcctSeed__Total__c != 0
        AND AcctSeed__Billing__r.GMBLASG__Posted__c = TRUE
      ORDER BY CreatedDate
    ]) {
      setIdProject.add(bl.AcctSeed__Project__c);
      listBillingLines.add(bl);
      billTotal += (bl.AcctSeed__Total__c == null) ? 0 : bl.AcctSeed__Total__c;
    }
    if (listBillingLines.isEmpty()) {
      ApexPages.addMessage(
        new ApexPages.message(
          ApexPages.Severity.ERROR,
          'No billing lines found to refund. Make sure you have selected lines from a Posted billing.'
        )
      );
      return;
    }
    if (setIdProject.size() <> 1) {
      ApexPages.addMessage(
        new ApexPages.message(ApexPages.Severity.ERROR, 'The billing lines must be from only one project.')
      );
      return;
    }
    if (billTotal <= 0) {
      ApexPages.addMessage(
        new ApexPages.message(ApexPages.Severity.ERROR, 'Billing Balance must be positive to refund.')
      );
      return;
    }

    AcctSeed__Project__c p = [
      SELECT
        Id,
        AcctSeedERP__Work_Order_Number__c,
        Serial_Number__c,
        AcctSeed__Account__c,
        AcctSeed__Opportunity__c,
        GL_Account_Variable_3__c,
        Tax_is_Harmonized__c,
        Tax_Override__c,
        Tax_Rate_Federal__c,
        Tax_Rate_Provincial__c,
        Tax_Rate_Retail__c
      FROM AcctSeed__Project__c
      WHERE Id IN :setIdProject
      LIMIT 1
    ][0];

    String payeeRef =
      p.AcctSeedERP__Work_Order_Number__c.replaceAll('[^0-9]', '') +
      String.valueOf(DateTime.now().getTime()) +
      '-Refund';
    /*for(AcctSeed__Account_Payable__c ap : [SELECT Id FROM AcctSeed__Account_Payable__c WHERE AcctSeed__Vendor__c =:p.AcctSeed__Account__c AND AcctSeed__Payee_Reference__c =:payeeRef])
	 	{
	 		ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'An AP already exists for this ERP Order with reference '+payeeRef+'.'));
	 		return;					
	 	}*/
    Savepoint sp = Database.setSavepoint();
    try {
      AcctSeed__Account_Payable__c accountPayable = new AcctSeed__Account_Payable__c(
        AcctSeed__Vendor__c = p.AcctSeed__Account__c,
        AcctSeed__Payee_Reference__c = payeeRef,
        GL_Account_Variable_3__c = p.GL_Account_Variable_3__c,
        Tax_Override__c = p.Tax_Override__c,
        Tax_is_Harmonized__c = p.Tax_is_Harmonized__c,
        Tax_Rate_Federal__c = p.Tax_Rate_Federal__c,
        Tax_Rate_Provincial__c = p.Tax_Rate_Provincial__c,
        Tax_Rate_Retail__c = p.Tax_Rate_Retail__c,
        AcctSeed__Date__c = Date.today()
      );
      insert accountPayable;

      List<AcctSeed__Account_Payable_Line__c> listAPLines = new List<AcctSeed__Account_Payable_Line__c>();
      for (AcctSeed__Billing_Line__c bl : listBillingLines) {
        AcctSeed__Account_Payable_Line__c payLine = new AcctSeed__Account_Payable_Line__c(
          AcctSeed__Account_Payable__c = accountPayable.Id,
          AcctSeed__Amount__c = bl.AcctSeed__Total__c, //(bl.AcctSeed__Total__c * -1),
          AcctSeed__Date__c = Date.today(),
          AcctSeed__Expense_GL_Account__c = bl.AcctSeed__Revenue_GL_Account__c,
          AcctSeed__GL_Account_Variable_1__c = bl.AcctSeed__GL_Account_Variable_1__c,
          AcctSeed__GL_Account_Variable_2__c = bl.AcctSeed__GL_Account_Variable_2__c,
          AcctSeed__GL_Account_Variable_3__c = bl.AcctSeed__GL_Account_Variable_3__c,
          AcctSeed__Product__c = bl.AcctSeed__Product__c,
          AcctSeed__Project__c = bl.AcctSeed__Project__c,
          AcctSeed__Project_Task__c = bl.AcctSeed__Project_Task__c
        );
        listAPLines.add(payLine);
      }

      if (!listAPLines.isEmpty())
        insert listAPLines;

      AcctSeed.AccountPayablePostService.postAccountPayables(new List<AcctSeed__Account_Payable__c>{ accountPayable });

      Decimal checkNumber = 1;
      for (AcctSeed__Cash_Disbursement__c cd : [
        SELECT Id, AcctSeed__Check_Number__c
        FROM AcctSeed__Cash_Disbursement__c
        WHERE AcctSeed__Check_Number__c != NULL
        ORDER BY AcctSeed__Check_Number__c DESC
        LIMIT 1
      ]) {
        checkNumber = cd.AcctSeed__Check_Number__c;
      }

      Id idGlBank;
      for (AcctSeed__Accounting_Settings__c s : [
        SELECT Id, AcctSeed__Default_Bank_Account__c, AcctSeed__Payment_Discount_GL_Account__c
        FROM AcctSeed__Accounting_Settings__c
        ORDER BY CreatedDate
        LIMIT 1
      ]) {
        idGlBank = s.AcctSeed__Default_Bank_Account__c;
      }
      Id idCD;
      for (AcctSeed__Account_Payable__c ap : [
        SELECT
          Id,
          AcctSeed__Payee__c,
          AcctSeed__Vendor__c,
          AcctSeed__Contact__c,
          AcctSeed__Employee__c,
          AcctSeed__Total__c,
          AcctSeed__Discount_Amount__c,
          AcctSeed__Credit_Memo_Applied_Amount__c,
          AcctSeed__Paid_Amount__c,
          AcctSeed__Balance__c
        FROM AcctSeed__Account_Payable__c
        WHERE Id = :accountPayable.Id AND AcctSeed__Status__c = 'Posted' AND AcctSeed__Balance__c != 0
      ]) {
        AcctSeed__Cash_Disbursement_Batch__c cdb = new AcctSeed__Cash_Disbursement_Batch__c(
          Name = DateTime.now().format(),
          AcctSeed__Starting_Check_Number__c = checkNumber
        );
        insert cdb;

        AcctSeed__Cash_Disbursement__c cd = new AcctSeed__Cash_Disbursement__c(
          AcctSeed__Cash_Disbursement_Batch__c = cdb.Id,
          AcctSeed__Bank_Account__c = idGlBank,
          //AcctSeed__Type__c = accountType,
          AcctSeed__Disbursement_Date__c = Date.today(),
          AcctSeed__Amount__c = ap.AcctSeed__Balance__c,
          AcctSeed__Check_Number__c = checkNumber,
          AcctSeed__Vendor__c = ap.AcctSeed__Vendor__c,
          AcctSeed__Contact__c = ap.AcctSeed__Contact__c,
          AcctSeed__Employee__c = ap.AcctSeed__Employee__c
        );

        insert cd;

        AcctSeed__AP_Disbursement__c apd = new AcctSeed__AP_Disbursement__c(
          AcctSeed__Account_Payable__c = ap.Id,
          AcctSeed__Paid_Amount__c = ap.AcctSeed__Balance__c,
          AcctSeed__Cash_Disbursement__c = cd.Id
        );

        insert apd;
        idCD = cd.Id;

        AcctSeed.CashDisbursementPostService.postCashDisbursements(new List<AcctSeed__Cash_Disbursement__c>{ cd });
      }
      String msg =
        'Account Payable has been created. <a target="_blank" href="/' +
        accountPayable.Id +
        '">Click here to view AP detail.</a>';
      msg +=
        '<br />An AP Cash disbursement has been created. <a target="_blank" href="/' +
        idCD +
        '">Click here to view CD detail.</a>';
      ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, msg));
      return;
    } catch (Exception e) {
      Database.rollback(sp);
      ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, e.getMessage()));
    }
  }

  public void createBillingAP() {
    List<AcctSeed__Billing_Line__c> listBillingLines = new List<AcctSeed__Billing_Line__c>();
    for (AcctSeed__Billing__c bill : [
      SELECT
        Id,
        Name,
        AcctSeed__Balance__c,
        AcctSeed__Billing_City__c,
        AcctSeed__Billing_Comment__c,
        AcctSeed__Billing_Contact__c,
        AcctSeed__Billing_Country__c,
        AcctSeed__Billing_Cycle_End_Date__c,
        AcctSeed__Billing_Cycle_Start_Date__c,
        AcctSeed__Billing_Format__c,
        AcctSeed__Billing_PostalCode__c,
        AcctSeed__Billing_State__c,
        AcctSeed__Billing_Street__c,
        AcctSeed__Billing_Terms_Name__c,
        AcctSeed__Customer__c,
        AcctSeed__Opportunity__c,
        AcctSeed__PO_Number__c,
        AcctSeed__Shipping_City__c,
        AcctSeed__Shipping_Contact__c,
        AcctSeed__Shipping_Country__c,
        AcctSeed__Shipping_PostalCode__c,
        AcctSeed__Shipping_State__c,
        AcctSeed__Shipping_Street__c,
        AcctSeed__Total__c,
        AcctSeedERP__Sales_Order__c,
        GL_Account_Variable_3__c,
        GMBLASERP__Project__c,
        Tax_is_Harmonized__c,
        Tax_Override__c,
        Tax_Rate_Federal__c,
        Tax_Rate_Provincial__c,
        Tax_Rate_Retail__c,
        (
          SELECT
            Id,
            AcctSeed__Billing__c,
            AcctSeed__GL_Account_Variable_1__c,
            AcctSeed__GL_Account_Variable_2__c,
            AcctSeed__GL_Account_Variable_3__c,
            AcctSeed__GL_Account_Variable_4__c,
            AcctSeed__Project__c,
            AcctSeed__Project_Task__c,
            GMBLASERP__Material__c,
            AcctSeed__Employee__c,
            AcctSeed__Expense_GL_Account__c,
            AcctSeed__Product__c,
            AcctSeed__Product_Unit_Cost__c,
            AcctSeed__Hours_Units__c,
            AcctSeed__Rate__c,
            AcctSeed__Revenue_GL_Account__c,
            AcctSeedERP__Sales_Order_Line__c,
            Taxable_Federal__c,
            Taxable_Provincial__c,
            Taxable_Retail__c,
            AcctSeed__Total__c
          FROM AcctSeed__Project_Billing_Lines__r
        )
      FROM AcctSeed__Billing__c
      WHERE Id IN :setIdFilter AND GMBLASG__Posted__c = TRUE
      LIMIT 1
    ]) {
      if (bill.AcctSeed__Balance__c >= 0) {
        ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'There is no balance to refund.'));
        return;
      }
      String msg;
      Savepoint sp = Database.setSavepoint();
      try {
        AcctSeed__Billing__c newBill = bill.clone(false, true);
        insert newBill;
        msg =
          'Billing has been created. <a target="_blank" href="/' +
          newBill.Id +
          '">Click here to view Bill detail.</a>';
        String payeeRef = bill.Name + String.valueOf(DateTime.now().getTime()) + '-Refund';
        AcctSeed__Account_Payable__c accountPayable = new AcctSeed__Account_Payable__c(
          AcctSeed__Vendor__c = bill.AcctSeed__Customer__c,
          AcctSeed__Payee_Reference__c = payeeRef,
          GL_Account_Variable_3__c = bill.GL_Account_Variable_3__c,
          Tax_Override__c = bill.Tax_Override__c,
          Tax_is_Harmonized__c = bill.Tax_is_Harmonized__c,
          Tax_Rate_Federal__c = bill.Tax_Rate_Federal__c,
          Tax_Rate_Provincial__c = bill.Tax_Rate_Provincial__c,
          Tax_Rate_Retail__c = bill.Tax_Rate_Retail__c,
          AcctSeed__Date__c = Date.today()
        );
        insert accountPayable;

        List<AcctSeed__Account_Payable_Line__c> listAPLines = new List<AcctSeed__Account_Payable_Line__c>();
        List<AcctSeed__Billing_Line__c> listBL = new List<AcctSeed__Billing_Line__c>();
        for (AcctSeed__Billing_Line__c bl : bill.AcctSeed__Project_Billing_Lines__r) {
          AcctSeed__Billing_Line__c newBL = bl.clone(false, true);
          newBL.AcctSeed__Billing__c = newBill.Id;
          newBL.AcctSeed__Rate__c = bl.AcctSeed__Rate__c * -1;
          listBL.add(newBL);
          AcctSeed__Account_Payable_Line__c payLine = new AcctSeed__Account_Payable_Line__c(
            AcctSeed__Account_Payable__c = accountPayable.Id,
            AcctSeed__Amount__c = (bl.AcctSeed__Total__c * -1),
            AcctSeed__Date__c = Date.today(),
            AcctSeed__Expense_GL_Account__c = bl.AcctSeed__Revenue_GL_Account__c,
            AcctSeed__GL_Account_Variable_1__c = bl.AcctSeed__GL_Account_Variable_1__c,
            AcctSeed__GL_Account_Variable_2__c = bl.AcctSeed__GL_Account_Variable_2__c,
            AcctSeed__GL_Account_Variable_3__c = bl.AcctSeed__GL_Account_Variable_3__c,
            AcctSeed__Product__c = bl.AcctSeed__Product__c,
            AcctSeed__Project__c = bl.AcctSeed__Project__c,
            AcctSeed__Project_Task__c = bl.AcctSeed__Project_Task__c
          );
          listAPLines.add(payLine);
        }
        insert listBL;
        AcctSeed.BillingPostService.postBillings(new List<AcctSeed__Billing__c>{ newBill });
        Id idAccountingPeriod = [
          SELECT AcctSeed__Accounting_Period__c
          FROM AcctSeed__Billing__c
          WHERE Id = :newBill.Id
        ][0]
        .AcctSeed__Accounting_Period__c;
        AcctSeed__Billing_Credit_Memo__c bcm = new AcctSeed__Billing_Credit_Memo__c(
          AcctSeed__Accounting_Period__c = idAccountingPeriod,
          AcctSeed__Amount__c = bill.AcctSeed__Total__c,
          AcctSeed__Billing_Credit_Memo__c = bill.Id,
          AcctSeed__Billing_Invoice__c = newBill.Id
        );
        insert bcm;
        msg +=
          '<br/>Billing credit has been applied. <a target="_blank" href="/' +
          bcm.Id +
          '">Click here to view Memo detail.</a>';

        if (!listAPLines.isEmpty())
          insert listAPLines;
        msg +=
          '<br/>Account Payable has been created. <a target="_blank" href="/' +
          accountPayable.Id +
          '">Click here to view AP detail.</a>';
        ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, msg));
        return;
      } catch (Exception e) {
        Database.rollback(sp);
        ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, e.getMessage()));
        return;
      }
    }
    ApexPages.addMessage(
      new ApexPages.message(ApexPages.Severity.ERROR, 'No posted billing credit memo found to refund.')
    );
  }
}
