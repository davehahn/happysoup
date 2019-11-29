global with sharing class BoatRemoter {
  public class BoatRemoterException extends Exception{}
  private ApexPages.StandardController std;
  // //private final Motor_Upgrade__c mu;

  public BoatRemoter(ApexPages.StandardController stdCtrl) {
    std = stdCtrl;
  }

  //@RemoteAction
  //global static Product_Upgrade__c fetchEditUpgradeDetails(String id) {
  //  try{
  //    Product_Upgrade__c pu = [SELECT Id, Price__c, From_Product__r.Name, To_Product__r.Name
  //                          FROM Product_Upgrade__c
  //                          WHERE id= :id];
  //    return pu;
  //  }
  //  catch(QueryException qe) {
  //    return null;
  //  }
  //}

  @RemoteAction
  global static Product_Upgrade_Cost__c fetchEditUpgradeDetails(String id) {
    try{
      Product_Upgrade_Cost__c puc = [SELECT Id,
                                            Cost__c,
                                            Price_Book__c,
                                            Product_Upgrade__c,
                                            Product_Upgrade__r.From_Product__r.Name,
                                            Product_Upgrade__r.To_Product__r.Name
                                     FROM Product_Upgrade_Cost__c
                                     WHERE id= :id];
      return puc;
    }
    catch(QueryException qe) {
      return null;
    }
  }

  @RemoteAction
  global static Product_Option__c setMaximumMotor(String optionId)
  {
    Product_Option__c newMax = [SELECT Id, To_Product__c FROM Product_Option__c WHERE Id = :optionId];
    Product_Option__c[] allOptions = [SELECT Id
                                      FROM Product_Option__c
                                      WHERE Id != :newMax.Id
                                      AND To_Product__c = :newMax.To_Product__c];
    newMax.isBiggestMotor__c = true;
    for( Product_Option__c op : allOptions )
    {
      op.isBiggestMotor__c = false;
    }
    allOptions.add(newMax);
    update allOptions;
    return newMax;
  }

  @RemoteAction
  global static Boolean toggleDisplayOnWeb( String optionId )
  {
    if( !Schema.sObjectType.Product_Option__c.fields.DisplayOnWeb__c.isAccessible() )
      throw new BoatRemoterException(' You do not have required access to edit Display on Web status');

    Product_Option__c opt = [SELECT Id, displayOnWeb__c FROM Product_Option__c WHERE Id = :optionId ];
    opt.displayOnWeb__c = opt.displayOnWeb__c == true ? false : true;
    update opt;
    return opt.displayOnWeb__c;
  }


  @RemoteAction
  global static Product_Upgrade_Cost__c newProductUpgradeCost(String jsonData) {
    Product_Upgrade_Cost__c puc = (Product_Upgrade_Cost__c)JSON.deserialize(jsonData, Product_Upgrade_Cost__c.class);
    Product_Upgrade__c pu = [SELECT Id, From_Product__r.Name, To_Product__r.Name
                             FROM Product_Upgrade__c
                             WHERE Id = :puc.Product_Upgrade__c];

    Product_Upgrade_Cost__c new_puc = new Product_Upgrade_Cost__c(
      Price_Book__c = puc.Price_Book__c,
      Product_Upgrade__r = pu,
      Product_Upgrade__c = pu.Id
    );

    return new_puc;
  }


  @RemoteAction
  global static Product_Upgrade__c newProductUpgrade(String From_Product_Id, String To_Product_Id) {
    Product2 toProduct = [Select Id, Name FROM Product2 WHERE Id = :To_Product_Id];
    Product2 fromProduct = [Select Id, Name FROM Product2 WHERE Id = :From_Product_Id];

    Product_Upgrade__c pu = new Product_Upgrade__c(To_Product__r = toProduct, From_Product__r = fromProduct, To_Product__c = To_Product_Id, From_Product__c = From_Product_Id);

    return pu;
  }

  @RemoteAction
  global static Product_Upgrade__c createProductUpgrade(String From_Product_Id, String To_Product_Id, String price){
    try {
      Product_Upgrade__c pu = new Product_Upgrade__c( To_Product__c = To_Product_Id,
                                                  From_Product__c = From_Product_Id,
                                                  Price__c = Decimal.valueOf(price) );
      insert pu;
      return pu;
    }
    catch(Exception e) {
      return null;
    }

  }

  @RemoteAction
  public static Product_Upgrade_Cost__c updateCost(String jsonData)
  {
    Product_Upgrade_Cost__c puc = (Product_Upgrade_Cost__c)JSON.deserialize(jsonData, Product_Upgrade_Cost__c.class);
    upsert puc;
    return puc;
  }

  @RemoteAction
  global static Product_Upgrade__c updatePrice(String id, String price) {

    Product_Upgrade__c up = [SELECT Id, Price__c FROM Product_Upgrade__c WHERE Id = :id];

    try{
      up.Price__c = Decimal.valueOf(price);
      update up;
      return up;
    }
      catch(Exception e) {
      return null;
    }

  }


  // Here are Methods for Product Options  Will probably rename this file to BoatChildrenEditRemoter or somthing later



  @RemoteAction
  global static Product_Option__c editOptionDetails(String Id) {
    try{
      return [SELECT Id, Maximum__c, Standard__c, From_Product__r.Name
              FROM Product_Option__c
              WHERE Id = : Id];
    }
    catch(QueryException qe) {
      return null;
    }
  }

  @RemoteAction
  global static Product_Option__c updateOptionDetails(String data) {
    Map<String, String> dataMap = mapParamsSting(data);
    try {
      Product_Option__c opt = [SELECT Id, Maximum__c, Standard__c
                         FROM Product_Option__c
                         WHERE id = :dataMap.get('Id')];
      opt.Maximum__c = Decimal.valueOf(dataMap.get('Maximum__c'));
      opt.Standard__c = Decimal.valueOf(dataMap.get('Standard__c'));
      update opt;
      return opt;
    }
    catch(Exception e) {
      return null;
    }
  }

  public static Map<String, String> mapParamsSting(String params) {
    String[] c = params.split('&');
    Map<String, String> map1 = new Map<String,String>();
    for(String a : c) {
        String[] x = a.split('=');
        map1.put(x[0],x[1]);
    }
    return map1;
  }


  // Method for Product Features

  @RemoteAction
  global static Feature__c createNewFeature(String description) {
      Feature__c f = new Feature__c(description__c = description);
      insert f;
      return f;
  }



}