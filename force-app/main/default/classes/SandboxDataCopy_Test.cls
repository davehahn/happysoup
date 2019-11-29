@isTest
private class SandboxDataCopy_Test {

  @isTest
  static void runningInASandbox_test()
  {
    Boolean runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    System.assertEquals( runningInASandbox, SandboxDataCopy.runningInASandbox );
  }

  @isTest
  static void factoryAccounts_test()
  {
    Test.startTest();
    SandboxDataCopy.factoryAccounts();
    Test.stopTest();
    Account[] acct = [SELECT Id FROM Account];
    System.assertEquals( 3, acct.size() );
  }

  @isTest
  static void insertAccounts_test()
  {
    Account[] accts = new List<Account>();
    for( Integer i=0; i<3; i++ )
    {
      accts.add( new Account(
        Name = 'Dealer - ' + String.valueOf( i ),
        Type = 'Dealer'
      ));
    }
    SandboxDataCopy.insertAccounts( JSON.serialize( accts ) );
    Account[] acct = [SELECT Id FROM Account];
    System.assertEquals( 3, acct.size() );
  }

}