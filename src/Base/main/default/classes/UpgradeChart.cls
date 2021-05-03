public with sharing class UpgradeChart {

  public ID to_Id { set; get; }
  public Product2 FromObj { set; get; }

    public UpgradeChart() {

    }

  public Product_Upgrade__c getProductUpgradeCost() {
    List<Product_Upgrade__c> ups = FromObj.From_Product_Upgrades__r;
    Product_Upgrade__c temp = new Product_Upgrade__c();
    if( ups.isEmpty()) {
       return temp;
    }
    if(FromObj.Id == to_Id) {
      return temp;
    }
    for(Product_Upgrade__c mu : ups) {
      if(mu.To_Product__c == to_Id && mu.From_Product__c == FromObj.Id) {
        temp = mu;
      }
    }
    return temp;
   }

  // public Trailer_Upgrade__c getTrailerUpgradeCost() {
  //   List<Trailer_Upgrade__c> ups = FromObj.From_Trailer_Upgrades__r;
  //   Trailer_Upgrade__c temp = new Trailer_Upgrade__c();
  //   if( ups.isEmpty()) {
  //      return temp;
  //   }
  //   if(FromObj.Id == to_Id) {
  //     return temp;
  //   }
  //   for(Trailer_Upgrade__c tu : ups) {
  //     if(tu.To_Trailer__c == to_Id && tu.From_Trailer__c == FromObj.Id) {
  //       temp = tu;
  //     }
  //   }
  //   return temp;
  // }

}