global class BatchPricebookClone_Upgrades implements Database.Batchable<sObject> {
  global final String query;
  global final Id newPbId;
  global final String newPbName;

  global BatchPricebookClone_Upgrades(Id oldId, Id newId) {
    query = LGND_Utilities.getCreatableFieldsSOQL('Product_Upgrade_Cost__c', 'Price_Book__c = \'' + oldId + '\'');
    newPbName = [SELECT Name FROM Pricebook2 WHERE Id = :newId].Name;
    newPbId = newId;
  }

  global Database.QueryLocator start(Database.BatchableContext BC) {
    return Database.getQueryLocator(query);
  }

  global void execute(Database.BatchableContext BC, List<Product_Upgrade_Cost__c> scope) {
    List<Product_Upgrade_Cost__c> entries = new List<Product_Upgrade_Cost__c>();
    for (Product_Upgrade_Cost__c puc : scope) {
      Product_Upgrade_Cost__c n = puc.clone(false, true);
      n.Price_Book__c = newPbId;
      entries.add(n);
    }
    insert entries;
  }

  global void finish(Database.BatchableContext BC) {
    Pricebook2_CloneController_dh.sendBatchCompleteEmail(BC, newPbName + ' - cloning Upgrades');
  }
}
