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
  static void finalizeSquarePayment_Test()
  {
    User u = Factory_User.buildUser('public', 'helpcenter', 'Legend Help Center Profile');
    insert u;
    AcctSeed__Accounting_Period__c period = [SELECT Id, AcctSeed__Start_Date__c FROM AcctSeed__Accounting_Period__c LIMIT 1];
    DateTime receiveDate = DateTime.newInstance(
      period.AcctSeed__Start_Date__c.addDays(5),
      Time.newInstance(0, 0, 0, 0)
    );
    System.runAs( u )
    {
      Account cust = Factory_Account.insertFullPersonAccount('TestFirst', 'TestLast');
      Square_Transaction__c trans = new Square_Transaction__c(
        Account__c = cust.Id,
        sqStatus__c = 'INCOMPLETE',
        Amount__c = 1000,
        Email__c = 'test@test.com'
      );
      insert trans;
      Test.startTest();
      RunSquarePaymentFlow.finalizeSquarePayment(
        trans.Id,
        receiveDate.format('yyyy-MM-dd\'T\'HH:mm:ss.\'000Z\''),
        '6aVfIp7gEaxzracrrrZPexample',
        'http://somewhere.somedomain',
        '0000001'
      );
      Test.stopTest();

//      Square_Transaction__c trx = [SELECT Id, sqStatus__c FROM Square_Transaction__c WHERE Id = :trans.Id];
//      AcctSeed__Cash_Receipt__c[] cashReceipts =
//        [ SELECT Id FROM AcctSeed__Cash_Receipt__c WHERE AcctSeed__Payment_Reference__c = :'6aVfIp7gEaxzracrrrZPexample'];
//
//      System.assertEquals('COMPLETED', trx.sqStatus__c);
//      System.assertEquals( 1, cashReceipts.size() );
    }
  }
}
