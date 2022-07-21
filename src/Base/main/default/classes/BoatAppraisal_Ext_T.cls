/**
 * Created by dave on 2020-03-06.
 */

@IsTest
private class BoatAppraisal_Ext_T {
  private static Boat_Appraisal__c appraisal;
  private static Attachment signature;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void initTestData(String attachmentName) {
    Account customer = Factory_Account.insertCustomerAccounts(1)[0];
    appraisal = new Boat_Appraisal__c(Customer__c = customer.Id);
    insert appraisal;
    signature = new Attachment();
    signature.Name = attachmentName;
    Blob bodyBlob = Blob.valueOf('Unit Test Attachment Body');
    signature.body = bodyBlob;
    signature.parentId = appraisal.Id;
    insert signature;
  }

  @IsTest
  static void constructorPass_Test() {
    initTestData('CustomerAppraisalSignature.png');
    ApexPages.currentPage().getParameters().put('id', appraisal.Id);
    ApexPages.StandardController stdCtr = new ApexPages.StandardController(appraisal);
    Test.startTest();
    BoatAppraisal_Ext ext = new BoatAppraisal_Ext(stdCtr);
    Test.stopTest();

    System.assertEquals(signature.Id, ext.signatureId);
  }

  @IsTest
  static void constructorFail_Test() {
    initTestData('SomeNonSignatureFile.png');
    ApexPages.currentPage().getParameters().put('id', appraisal.Id);
    ApexPages.StandardController stdCtr = new ApexPages.StandardController(appraisal);
    Test.startTest();
    BoatAppraisal_Ext ext = new BoatAppraisal_Ext(stdCtr);
    Test.stopTest();

    System.assertEquals(null, ext.signatureId);
  }
}
