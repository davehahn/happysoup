public class SandboxDataCopy {
  public static Boolean runningInASandbox {
    get {
      if (runningInASandbox == null) {
        runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
      }
      return runningInASandbox;
    }
    set;
  }

  public static void factoryAccounts() {
    if (Test.isRunningTest()) {
      Factory_Account.insertDealerAccounts(3);
    } else if (runningInASandbox) {
      PageReference fileRef = PageReference.forResource('SandboxData', '/Accounts/FactoryStores.json');
      insertAccounts(fileRef.getContent().toString());
    }
  }

  @TestVisible
  private static void insertAccounts(String jsonData) {
    List<Account> accts = (List<Account>) JSON.deserialize(jsonData, List<Account>.class);
    RecordType dealerRT = [
      SELECT Id, DeveloperName, SobjectType
      FROM RecordType
      WHERE DeveloperName = 'Dealer' AND SobjectType = 'Account'
    ];
    for (Account a : accts) {
      a.RecordTypeId = dealerRT.id;
      a.Dump_Id__c = a.Id;
      a.Id = null;
    }
    insert accts;
  }
}
