/* TODO: DELETE ME */
/**
 * Created by dave on 2020-05-01.
 */

@IsTest
private class Account_TriggerHandler_T
{
//
//  static String newName = 'Changed By Test Corp.';
//
//  @testSetup static void dataSetup()
//  {
//    new Factory_TestData();
//    Factory_CustomSettings.setupInventorySettings();
//  }
//
//  @IsTest
//  static void standardUser_DealerAccountUpdate_Test()
//  {
//    User stduser = Factory_User.newUser('Standard', 'TestUser', 'System Administrator', null );
//    Account dealerAcct = Factory_Account.buildDealerAccounts(1)[0];
//    insert dealerAcct;
//    System.runAs( stdUser )
//    {
//      dealerAcct.Name = newName;
//      update dealerAcct;
//      dealerAcct = [ SELECT Id, Name FROM Account WHERE Id = :dealerAcct.Id ];
//      System.assertEquals( newName, dealerAcct.Name );
//    }
//  }
//
//  @IsTest
//  static void partnerUser_DealerAccountUpdate_Own_Test()
//  {
//    Account dealerAcct = Factory_Account.buildDealerAccounts(1)[0];
//    insert dealerAcct;
//    User partnerUser = Factory_User.createPartnerUser( dealerAcct.Id );
//    System.runAs( partnerUser )
//    {
//      dealerAcct.Name = newName;
//      update dealerAcct;
//      dealerAcct = [ SELECT Id, Name FROM Account WHERE Id = :dealerAcct.Id ];
//      System.assertEquals( newName, dealerAcct.Name );
//    }
//  }
//
//  @IsTest
//  static void partnerUser_DealerAccountUpdate_Others_Test()
//  {
//    List<Account> dealerAccounts = Factory_Account.buildDealerAccounts( 2 );
//    insert dealerAccounts;
//    User partnerUser = Factory_User.createPartnerUser( dealerAccounts[0].Id );
//    System.runAs( partnerUser )
//    {
//      try
//      {
//        dealerAccounts[1].Name = newName;
//        update dealerAccounts[1];
//      }
//      catch( Exception e )
//      {
//        System.debug( e.getMessage() );
//        System.assert(
//          e.getMessage()
//            .contains('You are not allowed to edit another Partners information')
//        );
//      }
//    }
//  }
}