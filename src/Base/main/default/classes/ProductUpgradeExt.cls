public class ProductUpgradeExt {
  private ApexPages.StandardController std;
  public ID recordId;
  public ID toProductId;
  public ID fromProductId;
  public Boolean newRecord { get; set; }
  public List<Product2> products;
  //public ID redirectItemId;

  public ProductUpgradeExt(ApexPages.StandardController stdCtrl) {
    std = stdCtrl;
    this.std = std;
    recordId = std.getID();
    this.newRecord = recordId == null ? true : false;
    toProductId = ApexPages.currentpage().getparameters().get('toProductId');
    fromProductId = ApexPages.currentpage().getparameters().get('fromProductId');
    //redirectItemId = ApexPages.currentpage().getparameters().get('redirectId');
    if (toProductId != null && fromProductId != null) {
      Product_Upgrade__c pu = (Product_Upgrade__c) std.getRecord();
      if (pu.Id == null) {
        pu.To_Product__c = toProductId;
        pu.From_Product__c = fromProductId;
        pu.To_Product__r = getToProduct();
        pu.From_Product__r = getFromProduct();
      }
    }
  }

  public PageReference save() {
    try {
      std.save();
      PageReference pageRef = returnToChart();
      // if( redirectItemId != null){
      //   pageRef = new PageReference('/' + redirectItemId);
      //   pageRef.setRedirect(true);
      // }
      return pageRef;
    } catch (Exception e) {
      return null;
    }
  }

  public PageReference deleteRecord() {
    try {
      Product_Upgrade__c pu = (Product_Upgrade__c) std.getRecord();
      delete pu;
      return returnToChart();
    } catch (Exception e) {
      return null;
    }
  }

  public Product2 getToProduct() {
    return [SELECT Id, Name FROM Product2 WHERE id = :toProductId];
  }

  public Product2 getFromProduct() {
    return [SELECT Id, Name FROM Product2 WHERE id = :fromProductId];
  }

  public PageReference returnToChart() {
    PageReference pr = new PageReference('/apex/ProductUpgradeChart');
    pr.setRedirect(true);
    return pr;
  }
}
