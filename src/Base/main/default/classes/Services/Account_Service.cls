/**
 * Created by dave on 2021-05-20.
 */

public inherited sharing class Account_Service {
  public static void updateOwner(Map<Id, Id> ownerIdByAccountId) {
    List<Account> accounts = new List<Account>();
    for (Id acctId : ownerIdByAccountId.keySet()) {
      accounts.add(new Account(Id = acctId, OwnerId = ownerIdByAccountId.get(acctId)));
    }
    update accounts;
  }
}
