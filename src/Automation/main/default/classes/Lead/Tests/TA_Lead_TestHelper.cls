/**
 * Created by dave on 2022-06-15.
 */

@IsTest
public class TA_Lead_TestHelper
{
  private Group leadQueue;
  private User user;

  public TA_Lead_TestHelper(){}

  public Group getQueue(){
    if( this.leadQueue == null ){
      this.leadQueue = new Group(
        Type = 'Queue',
        DeveloperName = 'Lead_UnitTest_Queue',
        Name = 'Lead UnitTest Queue'
      );
      insert this.leadQueue;
    }
    return this.leadQueue;
  }

  public User getUser(){
    if( this.user == null ){
      this.user = Factory_User.createUser('Lead', 'UnitTester', 'System Administrator');
    }
    return this.user;
  }

  public static Account orillia;
  public static Account barrie;

  public static void dataSetup(){
    Account orillia = Factory_Account.buildDealerAccounts(1)[0];
    orillia.Name = 'Orillia Dealer';
    orillia.BillingStreet = '139 Fittons Rd East';
    orillia.BillingCity = 'Orillia';
    orillia.BillingState = 'Ontario';
    orillia.BillingCountry = 'Canada';
    orillia.BillingPostalCode = 'L3V 2G9';
    orillia.BillingLatitude = 44.62840928065218;
    orillia.BillingLongitude = -79.41666966709374;

    Account barrie = Factory_Account.buildDealerAccounts(1)[0];
    barrie.Name = 'Barrie Dealer';
    barrie.BillingStreet = '2375 Industrial Park Rd.';
    barrie.BillingCity = 'Innisfil';
    barrie.BillingState = 'Ontario';
    barrie.BillingCountry = 'Canada';
    barrie.BillingPostalCode = 'L9S 3W1';
    barrie.BillingLatitude = 44.29638562156834;
    barrie.BillingLongitude = -79.68193162911972;

    insert new List<Account>{ barrie, orillia };
  }

  public static void setDealers()
  {
    for( Account a : [ SELECT Id, Name FROM Account] )
    {
      if( a.Name == 'Barrie Dealer' )
        barrie = a;
      if( a.Name == 'Orillia Dealer' )
        orillia = a;
    }
  }
}