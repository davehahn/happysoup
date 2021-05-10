trigger productDeleteTrigger on Product2 (before delete) {
  List<Id> productIds = new List<Id>();
  List<Product_Feature_Map__c> pfMaps = new List<Product_Feature_Map__c>();
  List<Product_Option__c> pos = new List<Product_Option__c>();
  List<Product_Upgrade__c> pus = new List<Product_Upgrade__c>();

  for(Product2 p : Trigger.old) {
    productIds.add(p.Id);
  }

  //Need to delete Product_Feature_Maps
  pfMaps = [SELECT Id FROM Product_Feature_Map__c WHERE Product_Id__c IN :productIds];
  //Need to delete  Product_Options (from product and to product)
  pos = [SELECT Id FROM Product_Option__c WHERE From_Product__c IN :productIds OR To_Product__c IN :productIds];
  //Need to delete Product Upgrades (from product and to product)
  pus = [SELECT Id FROM Product_Upgrade__c WHERE From_Product__c IN :productIds OR To_Product__c IN :productIds];

  delete pfMaps;
  delete pos;
  delete pus;
}