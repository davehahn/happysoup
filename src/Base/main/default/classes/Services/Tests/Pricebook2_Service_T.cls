/**
 * Created by dave on 2021-11-02.
 */
@IsTest
private class Pricebook2_Service_T {
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  @IsTest
  static void getMatchingRetailIdFromDealerId_Pass() {
    Application_RecordType.PriceBookRTs rts = Application_RecordType.getInstance().getPricebookRecordTypes();
    Pricebook2 sourcePb = [
      SELECT Id, Name, RecordTypeId, Sales_Year__c, Version__c
      FROM Pricebook2
      WHERE RecordTYpeId = :rts.getDealerId()
    ][0];
    Pricebook2 resultPb = [
      SELECT Id, Name, RecordTypeId, Sales_Year__c, Version__c
      FROM Pricebook2
      WHERE RecordTypeId = :rts.getSalesId()
    ][0];

    Test.startTest();
    Pricebook2_Service pb = Pricebook2_Service.getInstance();
    Id resultId = pb.getMatchingRetailIdFromDealerId(sourcePb.Id);
    Test.stopTest();

    System.assertEquals(resultPb.Id, resultId);
  }

  @IsTest
  static void getMatchingRetailIdFromDealerId_Fail() {
    Application_RecordType.PriceBookRTs rts = Application_RecordType.getInstance().getPricebookRecordTypes();
    Pricebook2 newPb = new Pricebook2(
      Name = 'fail Dealer PB',
      IsActive = true,
      Sales_Year__c = String.valueOf(Date.today().year()),
      Version__c = 2,
      RecordTypeId = rts.getDealerId()
    );
    insert newPb;

    String errMsg;

    Test.startTest();
    Pricebook2_Service pb = Pricebook2_Service.getInstance();
    try {
      pb.getMatchingRetailIdFromDealerId(newPb.Id);
    } catch (Exception e) {
      errMsg = e.getMessage();
    }
    Test.stopTest();

    System.assertEquals('No matching Retail Pricebook found', errMsg);
  }

  @IsTest
  static void getRetailToFactory_Map_Test() {
    Application_RecordType.PriceBookRTs rts = Application_RecordType.getInstance().getPricebookRecordTypes();
    Test.startTest();
    Map<Id, Id> retail2Factory_Map = Pricebook2_Service.getRetailToFactory_Map();
    Test.stopTest();

    Id keyId = new List<Id>(retail2Factory_Map.keySet())[0];
    Id valueId = retail2Factory_Map.values()[0];

    Pricebook2 keyPb = [SELECT Id, Name, RecordTypeId, Sales_Year__c, Version__c FROM Pricebook2 WHERE Id = :keyId];
    Pricebook2 valuePb = [SELECT Id, Name, RecordTypeId, Sales_Year__c, Version__c FROM Pricebook2 WHERE Id = :valueId];

    System.assertEquals(1, retail2Factory_Map.size());
    System.assertEquals(rts.getSalesId(), keyPb.RecordTypeId);
    System.assertEquals(rts.getFactoryId(), valuePb.RecordTypeId);
    System.assertEquals(keyPb.Sales_Year__c, valuePb.Sales_Year__c);
    System.assertEquals(keyPb.Version__c, valuePb.Version__c);
  }

  @IsTest
  static void getDealerToRetail_Map_Test() {
    Application_RecordType.PriceBookRTs rts = Application_RecordType.getInstance().getPricebookRecordTypes();
    Test.startTest();
    Map<Id, Id> retail2Factory_Map = Pricebook2_Service.getDealerToRetail_Map();
    Test.stopTest();

    Id keyId = new List<Id>(retail2Factory_Map.keySet())[0];
    Id valueId = retail2Factory_Map.values()[0];

    Pricebook2 keyPb = [SELECT Id, Name, RecordTypeId, Sales_Year__c, Version__c FROM Pricebook2 WHERE Id = :keyId];
    Pricebook2 valuePb = [SELECT Id, Name, RecordTypeId, Sales_Year__c, Version__c FROM Pricebook2 WHERE Id = :valueId];

    System.assertEquals(1, retail2Factory_Map.size());
    System.assertEquals(rts.getDealerId(), keyPb.RecordTypeId);
    System.assertEquals(rts.getSalesId(), valuePb.RecordTypeId);
    System.assertEquals(keyPb.Sales_Year__c, valuePb.Sales_Year__c);
    System.assertEquals(keyPb.Version__c, valuePb.Version__c);
  }
}
