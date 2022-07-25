/**
 * Created by dave on 2022-01-18.
 */

@IsTest
private class TA_CommLI2_ChatterAboutChanges_T {
  @testSetup
  static void dataSetup() {
    TA_CommLI2_TestHelper.testDataSetup();
  }

  @IsTest
  static void TA_afterInsert() {
    TA_CommLI2_TestHelper helper = new TA_CommLI2_TestHelper();
    helper.initForPart();
    helper.populateLineItemForPart();

    List<CommissionLineItem2__c> newList = new List<CommissionLineItem2__c>{
      helper.lineItem.clone(true, true, true, true)
    };

    Test.startTest();
    new TA_CommLI2_ChatterAboutChanges().afterInsert(newList);
    Test.stopTest();
  }

  @IsTest
  static void TA_afterUpdate() {
    TA_CommLI2_TestHelper helper = new TA_CommLI2_TestHelper();
    helper.initForPart();
    helper.populateLineItemForPart();

    CommissionLineItem2__c oldLine = helper.lineItem.clone(true, true, true, true);
    CommissionLineItem2__c newLine = helper.lineItem.clone(true, true, true, true);

    newLine.Quantity__c = newLine.Quantity__c + 1;
    newLine.Sale_Price__c = newLine.Sale_Price__c + 5000;

    List<CommissionLineItem2__c> oldList = new List<CommissionLineItem2__c>{ oldLine };
    List<CommissionLineItem2__c> newList = new List<CommissionLineItem2__c>{ newLine };

    Test.startTest();
    new TA_CommLI2_ChatterAboutChanges().afterUpdate(newList, oldList);
    Test.stopTest();
  }

  @IsTest
  static void TA_afterDelete() {
    TA_CommLI2_TestHelper helper = new TA_CommLI2_TestHelper();
    helper.initForPart();
    helper.populateLineItemForPart();

    List<CommissionLineItem2__c> newList = new List<CommissionLineItem2__c>{
      helper.lineItem.clone(true, true, true, true)
    };

    Test.startTest();
    new TA_CommLI2_ChatterAboutChanges().afterDelete(newList);
    Test.stopTest();
  }

  @IsTest
  static void buildChangeMap_Test_Insert() {
    TA_CommLI2_TestHelper helper = new TA_CommLI2_TestHelper();
    helper.initForPart();
    helper.populateLineItemForPart();

    helper.lineItem.Id = null;
    TriggerBase.bypass('CommissionLineItem2__c');
    Id recordId = helper.insertLineItem();
    TriggerBase.clearBypass('CommissionLineItem2__c');

    CommissionLineItem2__c cli = [
      SELECT Id, Descriptor__c, Quantity__c, Sale_Price__c, CommissionRecord2__c
      FROM CommissionLineItem2__c
      WHERE Id = :recordId
    ];

    List<CommissionLineItem2__c> newList = new List<CommissionLineItem2__c>{ cli };

    Test.startTest();
    Map<Id, List<String>> changeMap = new TA_CommLI2_ChatterAboutChanges().buildChangeMap(newLIst, null, 'insert');
    Test.stopTest();

    String message = String.valueOf(cli.Quantity__c) + ' X ' + cli.Descriptor__c + ' has been added';
    System.assert(changeMap.containsKey(cli.CommissionRecord2__c));
    System.assertEquals(1, changeMap.get(cli.CommissionRecord2__c).size());
    System.assertEquals(message, changeMap.get(cli.CommissionRecord2__c)[0]);
  }

  @IsTest
  static void buildChangeMap_Test_Update() {
    TA_CommLI2_TestHelper helper = new TA_CommLI2_TestHelper();
    helper.initForPart();
    helper.populateLineItemForPart();

    helper.lineItem.Id = null;
    TriggerBase.bypass('CommissionLineItem2__c');
    Id recordId = helper.insertLineItem();
    TriggerBase.clearBypass('CommissionLineItem2__c');

    CommissionLineItem2__c oldRecord = [
      SELECT Id, Descriptor__c, Quantity__c, Sale_Price__c, CommissionRecord2__c
      FROM CommissionLineItem2__c
      WHERE Id = :recordId
    ];
    Map<Id, CommissionLineItem2__c> oldMap = new Map<Id, CommissionLineItem2__c>(
      new List<CommissionLineItem2__c>{ oldRecord }
    );

    CommissionLineItem2__c newRecord = oldRecord.clone(true, true, true, true);
    newRecord.Quantity__c = 3;
    newRecord.Sale_Price__c = 30000;
    List<CommissionLineItem2__c> newList = new List<CommissionLineItem2__c>{ newRecord };

    Test.startTest();
    Map<Id, List<String>> changeMap = new TA_CommLI2_ChatterAboutChanges().buildChangeMap(newLIst, oldMap, 'update');
    Test.stopTest();

    String message1 =
      'Quantity of ' +
      oldRecord.Descriptor__c +
      ' has changed from ' +
      String.valueOf(oldRecord.Quantity__c) +
      ' to ' +
      String.valueOf(newRecord.Quantity__c);
    String message2 =
      'The Sale Price on ' +
      oldRecord.Descriptor__c +
      ' has changed from $' +
      String.valueOf(oldRecord.Sale_Price__c) +
      ' to $' +
      String.valueOf(newRecord.Sale_Price__c);
    System.assert(changeMap.containsKey(oldRecord.CommissionRecord2__c));
    System.assertEquals(2, changeMap.get(oldRecord.CommissionRecord2__c).size());
    System.assertEquals(message1, changeMap.get(oldRecord.CommissionRecord2__c)[0]);
    System.assertEquals(message2, changeMap.get(oldRecord.CommissionRecord2__c)[1]);
  }

  @IsTest
  static void buildChangeMap_Test_Delete() {
    TA_CommLI2_TestHelper helper = new TA_CommLI2_TestHelper();
    helper.initForPart();
    helper.populateLineItemForPart();

    helper.lineItem.Id = null;
    TriggerBase.bypass('CommissionLineItem2__c');
    Id recordId = helper.insertLineItem();
    TriggerBase.clearBypass('CommissionLineItem2__c');

    CommissionLineItem2__c cli = [
      SELECT Id, Descriptor__c, Quantity__c, Sale_Price__c, CommissionRecord2__c
      FROM CommissionLineItem2__c
      WHERE Id = :recordId
    ];

    List<CommissionLineItem2__c> newList = new List<CommissionLineItem2__c>{ cli };

    Test.startTest();
    Map<Id, List<String>> changeMap = new TA_CommLI2_ChatterAboutChanges().buildChangeMap(newLIst, null, 'delete');
    Test.stopTest();

    String message = cli.Descriptor__c + ' has been removed';
    System.assert(changeMap.containsKey(cli.CommissionRecord2__c));
    System.assertEquals(1, changeMap.get(cli.CommissionRecord2__c).size());
    System.assertEquals(message, changeMap.get(cli.CommissionRecord2__c)[0]);
  }
}
