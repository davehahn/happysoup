/**
 * Created by dave on 2021-11-02.
 */

@IsTest
private class Pricebook_TriggerHandler_T {
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  @IsTest
  static void unquefierBeforeInsert_FailUniqueness_Test() {
    RecordType rt = [
      SELECT Id, DeveloperName
      FROM RecordType
      WHERE SobjectType = 'Pricebook2'
      LIMIT 1
    ];
    System.debug(rt);
    String y = String.valueOf(Date.today().year());
    Pricebook2 pb = new Pricebook2(
      Name = 'Test PB',
      IsActive = true,
      RecordTypeId = rt.Id,
      Version__c = 1,
      Sales_Year__c = y
    );
    String message;
    Test.startTest();
    try {
      insert pb;
    } catch (Exception e) {
      message = e.getMessage();
    }
    Test.stopTest();

    System.assert(message != null);
    System.assert(message.contains('DUPLICATE_VALUE'));
  }

  @IsTest
  static void unquefierBeforeInsert_PassUniqueness_Test() {
    RecordType rt = [
      SELECT Id, DeveloperName
      FROM RecordType
      WHERE SobjectType = 'Pricebook2'
      LIMIT 1
    ];
    System.debug(rt);
    String y = String.valueOf(Date.today().year());
    Pricebook2 pb = new Pricebook2(
      Name = 'Test PB',
      IsActive = true,
      RecordTypeId = rt.Id,
      Version__c = 2,
      Sales_Year__c = y
    );
    String expected = y + '_' + rt.DeveloperName + '_v.2';
    Test.startTest();
    insert pb;
    Test.stopTest();

    pb = [SELECT Id, Uniquefier__c FROM Pricebook2 WHERE Id = :pb.Id];

    System.assertEquals(expected, pb.Uniquefier__c);
  }

  @IsTest
  static void unquefierBeforeUpdate_FailUniqueness_Test() {
    RecordType rt = [
      SELECT Id, DeveloperName
      FROM RecordType
      WHERE SobjectType = 'Pricebook2'
      LIMIT 1
    ];
    String y = String.valueOf(Date.today().year());
    Pricebook2 pb = new Pricebook2(
      Name = 'Test PB',
      IsActive = true,
      RecordTypeId = rt.Id,
      Version__c = 2,
      Sales_Year__c = y,
      Uniquefier__c =  y + '_' + rt.DeveloperName + '_v.2'
    );
    TriggerHandler.bypass('Pricebook_TriggerHandler');
    insert pb;
    TriggerHandler.clearBypass('Pricebook_TriggerHandler');

    String message;
    Test.startTest();
    try {
      pb.Version__c = 1;
      update pb;
    } catch (Exception e) {
      message = e.getMessage();
    }
    Test.stopTest();

    System.assert(message != null);
    System.assert(message.contains('DUPLICATE_VALUE'));
  }

  @IsTest
  static void unquefierUpdateInsert_PassUniqueness_Test() {
    RecordType rt = [
      SELECT Id, DeveloperName
      FROM RecordType
      WHERE SobjectType = 'Pricebook2'
      LIMIT 1
    ];
    String y = String.valueOf(Date.today().year());
    Pricebook2 pb = new Pricebook2(
      Name = 'Test PB',
      IsActive = true,
      RecordTypeId = rt.Id,
      Version__c = 2,
      Sales_Year__c = y,
      Uniquefier__c =  y + '_' + rt.DeveloperName + '_v.2'
    );
    TriggerHandler.bypass('Pricebook_TriggerHandler');
    insert pb;
    TriggerHandler.clearBypass('Pricebook_TriggerHandler');
    pb.Version__c = 3;
    Test.startTest();
    update pb;
    Test.stopTest();

    String expected = y + '_' + rt.DeveloperName + '_v.3';
    pb = [SELECT Id, Uniquefier__c FROM Pricebook2 WHERE Id = :pb.Id];

    System.assertEquals(expected, pb.Uniquefier__c);
  }
}
