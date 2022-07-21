public with sharing class PurchaseOrderLines_MultipleClone {
  @AuraEnabled
  public static String cloneLines(String recordId, Integer lineCount) {
    List<AcctSeedERP__Purchase_Order_Line__c> pols = new List<AcctSeedERP__Purchase_Order_Line__c>();
    String query = LGND_Utilities.getCreatableFieldsSOQL(
      'AcctSeedERP__Purchase_Order_Line__c',
      ' Id = \'' +
      recordId +
      '\''
    );
    AcctSeedERP__Purchase_Order_Line__c record = Database.query(query);
    while (lineCount > 0) {
      pols.add(record.clone(false, true));
      lineCount--;
    }
    insert pols;
    return record.AcctSeedERP__Purchase_Order__c;
  }
}
