@isTest
public class Factory_AccountPayable {
  public static AcctSeed__Account_Payable__c insertAccountPayable(Integer lineItemCount) {
    AcctSeed__Account_Payable__c payable = createAccountPayable();
    createPayableLines(payable, lineItemCount);
    return payable;
  }

  private static AcctSeed__Account_Payable__c createAccountPayable() {
    Account supplier = Factory_Account.insertSupplierAccounts(1)[0];
    AcctSeed__Ledger__c ledger = [SELECT Id FROM AcctSeed__Ledger__c LIMIT 1];
    AcctSeed__Account_Payable__c result = new AcctSeed__Account_Payable__c(
      AcctSeed__Payee_Reference__c = 'Tester',
      AcctSeed__Ledger__c = ledger.Id,
      AcctSeed__Vendor__c = supplier.Id
    );
    insert result;
    return result;
  }

  private static void createPayableLines(AcctSeed__Account_Payable__c payable, Integer count) {
    if (count == 0)
      return;
    AcctSeed__GL_Account__c expense = [
      SELECT Id
      FROM AcctSeed__GL_Account__c
      WHERE AcctSeed__Type__c = 'Expense'
      LIMIT 1
    ];
    AcctSeed__Accounting_Variable__c dept;
    AcctSeed__Accounting_Variable__c businessUnit;
    for (AcctSeed__Accounting_Variable__c av : [
      SELECT Id, AcctSeed__Type__c
      FROM AcctSeed__Accounting_Variable__c
      WHERE AcctSeed__Type__c = 'GL Account Variable 1' OR AcctSeed__Type__c = 'GL Account Variable 2'
    ]) {
      if (av.AcctSeed__Type__c == 'GL Account Variable 2') {
        dept = av;
      }
      if (av.AcctSeed__Type__c == 'GL Account Variable 1') {
        businessUnit = av;
      }
    }
    AcctSeed__Account_Payable_Line__c[] lines = new List<AcctSeed__Account_Payable_Line__c>();
    for (Integer i = 0; i < count; i++) {
      lines.add(
        new AcctSeed__Account_Payable_Line__c(
          AcctSeed__Account_Payable__c = payable.Id,
          AcctSeed__Amount__c = 10,
          AcctSeed__Expense_GL_Account__c = expense.Id,
          AcctSeed__GL_Account_Variable_2__c = dept.Id,
          AcctSeed__GL_Account_Variable_1__c = businessUnit.Id
        )
      );
    }
    insert lines;
  }
}
