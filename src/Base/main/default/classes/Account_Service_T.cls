/**
 * Created by dave on 2021-05-20.
 */

@IsTest
private class Account_Service_T
{

  static final List<String> accountName = new List<String>{'TestAccountFirst', 'TestAccountLast'};
  static final List<String> userName = new List<String>{'tuf', 'tul'};


  @testSetup static void dataSetup()
  {
    Factory_Account.insertFullPersonAccount(
      accountName[0],
      accountName[1]
    );
    User u = Factory_User.newUser(
      userName[0],
      userName[1],
      'System Administrator',
      null
    );
    insert u;
    System.debug( u );
  }

  @IsTest
  static void updateOwner_Test()
  {
    Account acct = [
      SELECT
        Id,
        OwnerId
      FROM Account
      WHERE FirstName = :accountName[0]
      AND LastName = :accountName[1]
      LIMIT 1
    ];
    User u = [
      SELECT
        Id
      FROM User
      WHERE FirstName = :userName[0]
      AND LastName = :userName[1]
      LIMIT 1
    ];

    System.assertNotEquals( u.Id, acct.OwnerId );

    Map<Id, Id> ownerIdByAccountId = new Map<Id, Id>{
      acct.Id => u.Id
    };

    Test.startTest();
    Account_Service.updateOwner( ownerIdByAccountId );
    Test.stopTest();

    acct = [
      SELECT
        Id,
        OwnerId
      FROM Account
      WHERE FirstName = :accountName[0]
      AND LastName = :accountName[1]
      LIMIT 1
    ];

    System.assertEquals( u.Id, acct.OwnerId );
  }
}