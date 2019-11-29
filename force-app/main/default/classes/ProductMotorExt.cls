public with sharing class ProductMotorExt {

  private ApexPages.StandardController std;
  public ID recordId;

  public ProductMotorExt(ApexPages.StandardController stdCtrl) {
    std = stdCtrl;
    recordId = std.getID();
  }

  public List<Product_Upgrade__c> getMotorUpgrades(){
    return [SELECT Id, Price__c, To_Product__r.Name
            FROM Product_Upgrade__c
            WHERE From_Product__c = :recordId ];
  }

}