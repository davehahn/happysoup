@isTest
private class lgnd_ObjectHeaderController_Test {
  @isTest
  static void fetchRecordDetails_Test() {
    List<String> fields = new List<String>{ 'FirstName', 'LastName' };
    Account acct = AccountFactory.insertPersonAccount();
    String acct2JSON = lgnd_ObjectHeaderController.fetchRecordDetails('Account', acct.Id, fields);
    Account acct2 = (Account) JSON.deserialize(acct2JSON, Account.class);

    System.assertEquals(acct.FirstName, acct2.FirstName);
    System.assertEquals(acct.LastName, acct2.LastName);
  }
}
