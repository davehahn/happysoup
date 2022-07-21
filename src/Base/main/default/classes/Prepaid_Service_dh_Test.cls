@isTest
private class Prepaid_Service_dh_Test {
  static User whitefishUser;
  static User sysAdmin;
  static Account person;
  static AcctSeedERP__Warehouse__c wh;
  static AcctSeed__Project__c erp;
  static GMBLASERP__Serial_Number__c serial;
  static Product2 prePaidProduct;
  static AcctSeedERP__Material__c prepaidMaterialLine;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void init() {
    for (AcctSeedERP__Warehouse__c warehouse : [
      SELECT Id, Name, GL_Account_Variable_3__c
      FROM AcctSeedERP__Warehouse__c
    ]) {
      if (warehouse.Name == 'Whitefish')
        wh = warehouse;
    }
    whitefishUser = Factory_User.newUser('whitefish', 'mcTesterson', 'Legend Standard User - New', wh);
    sysAdmin = Factory_User.newUser('sysAdmin', 'mcTesterson', 'System Administrator', wh);
    person = Factory_Account.insertFullPersonAccount('Testy', 'McTesterson');
    serial = Factory_SerialNumber.insertFullSerials(1, 'Boat', 'Pontoon')[0];
  }

  private static void buildERP() {
    erp = Factory_ERPOrder.insertRetailBoatSale(person, wh, DateTime.now(), serial);
    AcctSeed__Project_Task__c task = [SELECT Id FROM AcctSeed__Project_Task__c WHERE AcctSeed__Project__c = :erp.Id];
    prePaidProduct = Factory_Product.createNonSerializedProduct('Protection and Services', 'Service Packages');
    prepaidMaterialLine = Factory_ERPOrder.buildMaterial(erp.Id, task.Id, prePaidProduct.Id);
    insert prepaidMaterialLine;
  }

  @isTest
  static void initData_Test() {
    init();
    System.runAs(sysAdmin) {
      buildERP();
      Test.startTest();
      String jsonResult = Prepaid_Service_dh.initData(prepaidMaterialLine.Id);
      Map<String, String> result = (Map<String, String>) JSON.deserialize(jsonResult, Map<String, String>.class);
      Test.stopTest();

      System.assertEquals(prePaidProduct.Id, result.get('productId'));
      System.assertEquals(erp.Id, result.get('erpId'));
      System.assertEquals(person.Id, result.get('accountId'));
      System.assertEquals(
        prepaidMaterialLine.AcctSeedERP__Quantity_Per_Unit__c,
        Decimal.valueOf(result.get('quantity'))
      );
      System.assertEquals(serial.Id, result.get('serialId'));
    }
  }

  @isTest
  static void initData_noAccess_Test() {
    init();
    System.runAs(whitefishUser) {
      buildERP();
      Test.startTest();
      String err;
      try {
        String jsonResult = Prepaid_Service_dh.initData(prepaidMaterialLine.Id);
      } catch (Exception e) {
        err = e.getMessage();
      }
      Test.stopTest();
      System.assertEquals(
        err,
        'You do not have permission. Contact your Administrator if you feel this is something you should be able to do'
      );
    }
  }

  @isTest
  static void saveRecord_Test() {
    init();
    System.runAs(whitefishUser) {
      buildERP();
      Test.startTest();
      String err;
      String productId = prePaidProduct.Id;
      String accountId = person.Id;
      String erpId = erp.Id;
      String serialId = serial.Id;
      Decimal quantity = prepaidMaterialLine.AcctSeedERP__Quantity_Per_Unit__c;
      String jsonResult = Prepaid_Service_dh.saveRecord(productId, accountId, erpId, serialId, quantity);
      Prepaid_Service__c pps = (Prepaid_Service__c) JSON.deserialize(jsonResult, Prepaid_Service__c.class);
      //try and save again
      try {
        Prepaid_Service_dh.saveRecord(productId, accountId, erpId, serialId, quantity);
      } catch (Exception e) {
        err = e.getMessage();
      }
      Test.stopTest();

      System.assertEquals(productId, pps.Product__c);
      System.assertEquals(accountId, pps.Account__c);
      System.assertEquals(erpId, pps.ERP_Order__c);
      System.assertEquals(serialId, pps.Serial_Number__c);
      System.assert(pps.Id != null);
      System.assertEquals(err, 'Prepaid Service has already been created');
    }
  }
}
