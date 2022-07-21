public without sharing class gcCashReceipt_Refund {
  public gcCashReceipt_Refund() {
  }
  public gcCashReceipt_Refund(ApexPages.StandardController st) {
  }

  @RemoteAction
  public static String createRefund(String idCR, Decimal refundAmount) {
    Set<Id> setIdAccounts = new Set<Id>();
    List<AcctSeed__Cash_Receipt__c> listCashReceipts = new List<AcctSeed__Cash_Receipt__c>();
    Decimal crTotal = 0;
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
      WHERE Id = :idCR AND AcctSeed__Balance__c > 0 AND GMBLASG__Posted__c = TRUE
    ]) {
      Savepoint sp = Database.setSavepoint();
      try {
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
          AcctSeed__Rate__c = refundAmount,
          AcctSeed__GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale,
          AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2Sales /*,
													AcctSeed__Project__c = cr.AcctSeed__Project__c, 
													AcctSeed__Project_Task__c = cr.AcctSeed__Project_Task__c */
        );
        insert newBL;
        /// Post the new Bill
        AcctSeed.BillingPostService.postBillings(new List<AcctSeed__Billing__c>{ newBill });
        /// Apply Cash Receipt on the new Bill
        AcctSeed__Billing_Cash_Receipt__c bcm = new AcctSeed__Billing_Cash_Receipt__c(
          AcctSeed__Accounting_Period__c = idAccountingPeriod,
          AcctSeed__Applied_Amount__c = refundAmount,
          AcctSeed__Billing__c = newBill.Id,
          AcctSeed__Cash_Receipt__c = cr.Id
        );
        insert bcm;

        /// Create a new Account Payable
        String payeeRef = String.valueOf(DateTime.now().getTime()) + '-Customer Refund';
        AcctSeed__Account_Payable__c accountPayable = new AcctSeed__Account_Payable__c(
          AcctSeed__Vendor__c = cr.AcctSeed__Account__c,
          AcctSeed__Payee_Reference__c = payeeRef,
          AcctSeed__Date__c = Date.today()
        );
        insert accountPayable;
        /// Create an Account Payable Line for Each Cash Receipt
        AcctSeed__Account_Payable_Line__c payLine = new AcctSeed__Account_Payable_Line__c(
          AcctSeed__Account_Payable__c = accountPayable.Id,
          AcctSeed__Amount__c = refundAmount,
          AcctSeed__Date__c = Date.today(),
          AcctSeed__Expense_GL_Account__c = gcConstants.idGlCustomerRefund,
          AcctSeed__GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale,
          AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2Sales /*,
																	AcctSeed__Project__c = cr.AcctSeed__Project__c, 
																	AcctSeed__Project_Task__c = cr.AcctSeed__Project_Task__c*/
        );
        insert payLine;
        return accountPayable.Id;
      } catch (Exception e) {
        Database.rollback(sp);
        throw new gcException(e.getMessage());
      }
    }
    throw new gcException('No Cash receipt was found with a balance.');
  }
}
