@IsTest(SeeAllData=false)
private class gcProductMRP_Batch_T {
  final static String RECORDTYPE = 'Insurance';
  final static String FAMILY = 'Insurance';

  @TestSetup
  static void testData() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Factory_AccountPayable.insertAccountPayable(5);
    new Factory_AccountingVariables();
    List<Product2> serializedProducts = Factory_Product.createSerializedProducts(RECORDTYPE, FAMILY, 10);
  }

  @IsTest
  static void testMethod1InvokeBatch() {
    Test.StartTest();
    gcProductMRP_Batch productMrpBatch = new gcProductMRP_Batch();
    ID batchprocessid = Database.executeBatch(productMrpBatch);
    system.assertNotEquals(null, batchprocessid);
    Test.stopTest();
  }

  @IsTest
  static void testMethod2ScheduleBatch() {
    Test.StartTest();
    gcProductMRP_Batch testsche = new gcProductMRP_Batch();
    String CRON_EXP = '0 0 23 * * ?'; //'0 0 0 15 3 ? 2022';
    system.schedule('Test status Check', CRON_EXP, testsche);
    Test.stopTest();
  }
}
