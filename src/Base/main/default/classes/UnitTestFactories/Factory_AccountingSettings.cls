@isTest
public class Factory_AccountingSettings {
  public AcctSeed__Ledger__c defaultLedger;
  public AcctSeed__GL_Account__c defaultBankAccount;
  public AcctSeed__GL_Account__c currentYearEarningGL;
  public AcctSeed__GL_Account__c retainedEarningGL;
  public AcctSeed__GL_Account__c defaultRevenueGL;
  public AcctSeed__GL_Account__c arControlGL;
  public AcctSeed__GL_Account__c unappliedCashGL;
  public AcctSeed__GL_Account__c customerPaymentAdjGL;
  public AcctSeed__GL_Account__c apControlGL;
  public AcctSeed__GL_Account__c vendorPaymentDiscountGL;
  public AcctSeed__GL_Account__c laborClearingGL;
  public AcctSeed__GL_Account__c defaultProjectTaskLaborGL;
  public AcctSeed__GL_Account__c vouchersPayableGL;
  public AcctSeed__GL_Account__c inventoryVarianceGL;
  public AcctSeed__GL_Account__c workInProgressGL;
  public AcctSeed__GL_Account__c salesTaxCollected;
  public AcctSeed__GL_Account__c salesTaxPaid;
  public AcctSeed__Billing_Format__c defaultBillingFormat;
  public AcctSeed__Billing_Format__c billingActivityStatementFormat;
  public AcctSeed__Billing_Format__c billingOutstandingStatementFormat;
  public AcctSeed__Billing_Format__c purchaseOrderStatementFormat;
  public AcctSeed__Billing_Format__c packingSlipStatementFormat;

  public Factory_AccountingSettings() {
    setGlAccounts();
    setPDFFormats();
    defaultLedger = buildLedger();
    buildRecord();
    buildCurrentPeriod();
  }

  private void setGlAccounts() {
    List<sObject> glAccts = Test.loadData(AcctSeed__GL_Account__c.sObjectType, 'TestData_GL_Accounts');
    for (sObject o : glAccts) {
      AcctSeed__GL_Account__c glAcct = (AcctSeed__GL_Account__c) o;
      if (glAcct.Name.contains('1050'))
        defaultBankAccount = glAcct;
      if (glAcct.Name.contains('3525'))
        currentYearEarningGL = glAcct;
      if (glAcct.Name.contains('3500'))
        retainedEarningGL = glAcct;
      if (glAcct.Name.contains('4000'))
        defaultRevenueGL = glAcct;
      if (glAcct.Name.contains('1100'))
        arControlGL = glAcct;
      if (glAcct.Name.contains('1101'))
        unappliedCashGL = glAcct;
      if (glAcct.Name.contains('4900'))
        customerPaymentAdjGL = glAcct;
      if (glAcct.Name.contains('2100'))
        apControlGL = glAcct;
      if (glAcct.Name.contains('5185'))
        vendorPaymentDiscountGL = glAcct;
      if (glAcct.Name.contains('5882'))
        laborClearingGL = glAcct;
      if (glAcct.Name.contains('5883'))
        defaultProjectTaskLaborGL = glAcct;
      if (glAcct.Name.contains('2105'))
        vouchersPayableGL = glAcct;
      if (glAcct.Name.contains('5195'))
        inventoryVarianceGL = glAcct;
      if (glAcct.Name.contains('1300'))
        workInProgressGL = glAcct;
      if (glAcct.Name.contains('2280'))
        salesTaxCollected = glAcct;
      if (glAcct.Name.contains('2281'))
        salesTaxPaid = glAcct;
    }
  }

  private void setPDFFormats() {
    List<sObject> pdfFormats = Test.loadData(AcctSeed__Billing_Format__c.sObjectType, 'TestData_PDF_Formats');
    for (sObject obj : pdfFormats) {
      AcctSeed__Billing_Format__c f = (AcctSeed__Billing_Format__c) obj;
      if (f.Name == 'Billing PDF Format')
        defaultBillingFormat = f;
      if (f.Name == 'Billing Activity Statement')
        billingActivityStatementFormat = f;
      if (f.Name == 'Billing Outstanding Statement')
        billingOutstandingStatementFormat = f;
      if (f.Name == 'Purchase Order PDF Format')
        purchaseOrderStatementFormat = f;
      if (f.Name == 'Default Packing Slip')
        packingSlipStatementFormat = f;
    }
  }

  private AcctSeed__Ledger__c buildLedger() {
    AcctSeed__Ledger__c l = new AcctSeed__Ledger__c(
      Name = 'Actual',
      AcctSeed__Type__c = 'Transactional',
      AcctSeed__Billing_Activity_Statement_Format__c = billingActivityStatementFormat.Id,
      AcctSeed__Billing_Outstanding_Statement_Format__c = billingOutstandingStatementFormat.Id,
      AcctSeed__Default_Bank_Account__c = defaultBankAccount.Id,
      AcctSeed__Default_Billing_Format__c = defaultBillingFormat.Id,
      AcctSeed__Default_Purchase_Order_Format__c = purchaseOrderStatementFormat.Id,
      AcctSeed__Default_Packing_Slip_Format__c = packingSlipStatementFormat.Id
    );
    insert l;
    return l;
  }

  private void buildCurrentPeriod() {
    Date d = Date.Today().addMonths(-1);
    AcctSeed__Accounting_Period__c period = new AcctSeed__Accounting_Period__c(
      AcctSeed__End_Date__c = d.addMonths(3).toStartOfMonth().addDays(-1),
      AcctSeed__Start_Date__c = d.toStartOfMonth(),
      AcctSeed__Status__c = 'Open',
      Name = Datetime.Now().format('YYYY-MM')
    );
    insert period;
  }

  private void buildRecord() {
    AcctSeed__Accounting_Settings__c rec = new AcctSeed__Accounting_Settings__c(
      AcctSeed__Default_Bank_Account__c = defaultBankAccount.Id,
      AcctSeed__Current_Year_Earnings_GL_Account__c = currentYearEarningGL.Id,
      AcctSeed__Retained_Earnings_GL_Account__c = retainedEarningGL.Id,
      AcctSeed__Revenue_GL_Account__c = defaultRevenueGL.Id,
      AcctSeed__AR_Control_GL_Account__c = arControlGL.Id,
      AcctSeed__Unapplied_Cash_GL_Account__c = unappliedCashGL.Id,
      AcctSeed__Customer_Payment_Adjustment_GL_Account__c = customerPaymentAdjGL.Id,
      AcctSeed__AP_Control_GL_Account__c = apControlGL.Id,
      AcctSeed__Payment_Discount_GL_Account__c = vendorPaymentDiscountGL.Id,
      AcctSeed__Labor_GL_Account__c = laborClearingGL.Id,
      AcctSeed__Default_Project_Task_Labor_GL_Account__c = defaultProjectTaskLaborGL.Id,
      AcctSeed__Vouchers_Payable_GL_Account__c = vouchersPayableGL.Id,
      AcctSeed__Inventory_Variance_GL_Account__c = inventoryVarianceGL.Id,
      AcctSeed__Work_in_Process_GL_Account__c = workInProgressGL.Id,
      AcctSeed__Default_Ledger__c = defaultLedger.Id,
      AcctSeed__Default_Billing_Format__c = defaultBillingFormat.Id,
      AcctSeed__Default_Purchase_Order_Format__c = purchaseOrderStatementFormat.Id,
      AcctSeed__Billing_Activity_Statement_Format__c = billingActivityStatementFormat.Id,
      AcctSeed__Billing_Outstanding_Statement_Format__c = billingOutstandingStatementFormat.Id,
      AcctSeed__Enable_Cash_Flow_Statement__c = true
    );
    rec.AcctSeed__Inventory_Valuation_Method__c = 'Standard Cost';
    insert rec;
  }
}
