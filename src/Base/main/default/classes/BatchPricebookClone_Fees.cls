global class BatchPricebookClone_Fees implements Database.Batchable<sObject> {
  global final String query;
  global final Id newPbId;
  global final String newPbName;

  global BatchPricebookClone_Fees(Id oldId, Id newId) {
    query = LGND_Utilities.getCreatableFieldsSOQL(
      'Product_Fee_Amount__c',
      new Set<String>{ 'OwnerId' },
      'Price_Book__c = \'' +
      oldId +
      '\''
    );
    newPbId = newId;
    newPbName = [SELECT Name FROM Pricebook2 WHERE Id = :newId].Name;
  }

  global Database.QueryLocator start(Database.BatchableContext BC) {
    return Database.getQueryLocator(query);
  }

  global void execute(Database.BatchableContext BC, List<Product_Fee_Amount__c> scope) {
    List<Product_Fee_Amount__c> entries = new List<Product_Fee_Amount__c>();
    for (Product_Fee_Amount__c pfa : scope) {
      Product_Fee_Amount__c n = pfa.clone(false, true);
      n.Price_Book__c = newPbId;
      entries.add(n);
    }
    insert entries;
  }

  global void finish(Database.BatchableContext BC) {
    Pricebook2_CloneController_dh.sendBatchCompleteEmail(BC, newPbName + ' - cloning Fees');
  }
}
