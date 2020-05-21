/**
 * Created by dave on 2020-05-14.
 */

@IsTest
private class RunSquarePaymentFlow_T
{

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  @IsTest
  static void start_Test()
  {
//    User u = Factory_User.buildUser('public', 'helpcenter', 'Legend Help Center Profile');
//    insert u;
//    System.runAs( u )
//    {
      Account cust = Factory_Account.insertFullPersonAccount('TestFirst', 'TestLast');
      Square_Transaction__c trans = new Square_Transaction__c(
        Account__c = cust.Id,
        sqStatus__c = 'INCOMPLETE',
        Amount__c = 1000,
        Email__c = 'test@test.com'
      );
      insert trans;
      PageReference pageRef = Page.Square_PaymentForm;
      pageRef.getParameters().put('id', trans.Id);
      pageRef.getParameters().put('sqCaptureDate', '2019-07-14T02:51:35.984Z');
      pageRef.getParameters().put('sqOrderId', '6aVfIp7gEaxzracrrrZPexample');
      pageRef.getParameters().put('sqReceiptURL', 'http://somewhere.somedomain');
      pageRef.getParameters().put('sqReceiptNum', '0000001');
      Test.setCurrentPageReference(pageRef);
      ApexPages.StandardController stdCtr = new ApexPages.StandardController( trans );
      Test.startTest();
      RunSquarePaymentFlow flowRunner = new RunSquarePaymentFlow( stdCtr );
      flowRunner.start();
      Test.stopTest();

    //}
  }
}
