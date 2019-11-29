/**
 * Created by dave on 2019-09-13.
 */

@IsTest
private class Registration_ByAccount_Controller_Test {

  static Integer accountCount = 100;
  static Id personRtId = LGND_Utilities.recordTypeIdFromName('Account', 'Person Account');
  static Account[] accts;
  static Account dealer;
  static GMBLASERP__Serial_Number__c[] serials;
  static DateTime startDate = DateTime.newInstance( 2015, 07, 07);

  @testSetup static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void buildAccounts()
  {
    dealer = Factory_Account.insertDealerAccounts(1)[0];
    accts = new List<Account>();
    for( Integer i=0; i<accountCount; i++ )
    {
      accts.add( new Account(
        RecordTypeId = personRtId,
        FirstName = 'Tester' + String.valueOf(i),
        LastName = 'McTesterson' + String.valueOf(i),
        BillingStreet = String.valueOf( 100 + i) + ' Fittons Rd West',
        BillingCity = 'Orillia',
        BillingState = 'Ontario',
        BillingCountry = 'Canada',
        BillingPostalCode = 'L3V 3V3',
        PersonMailingStreet = String.valueOf( 100 + i) + ' Fittons Rd West',
        PersonMailingCity = 'Orillia',
        PersonMailingState = 'Ontario',
        PersonMailingCountry = 'Canada',
        PersonMailingPostalCode = 'L3V 3V3',
        PersonMailingLatitude = 44.121,
        PersonMailingLongitude = -109.87463
      ));
    }
    insert accts;
  }

  private static void init()
  {
    serials = Factory_SerialNumber.insertFullSerials( accountCount, 'Boat', 'Pontoon');
    System.debug( 'Serials ' + serials.size() );
    System.debug( 'Accounts ' + accts.size() );
    List<Registration__c> regs = new List<Registration__c>();
    for( Integer i=0; i<accountCount; i++ )
    {
      Registration__c r = Factory_Registration.buildRegistration( dealer.Id, accts[i].Id, serials[i].Id );
      if( i >= 0 && i < 25 )
        r.Registered_Date__c = startDate;
      if( i >= 25 && i < 50 )
        r.Registered_Date__c = startDate.addYears(1);
      if( i >= 50 && i < 75 )
        r.Registered_Date__c = startDate.addYears(2);
      if( i >= 75 )
        r.Registered_Date__c = startDate.addYears(3);
      regs.add( r );
    }
    TriggerHandler.bypass('Registration_TriggerHandler');
    insert regs;
    TriggerHandler.clearBypass('Registration_TriggerHandler');
  }

  @IsTest
  static void fetchRegistrations_withAccountId_Test()
  {
    buildAccounts();
    init();
    Test.startTest();
    String jsonResult = Registration_ByAccount_Controller.fetchRegistrations( dealer.Id );
    Test.stopTest();
    Map<String, List<Registration_ByAccount_Controller.Customer>> result =
      (Map<String, List<Registration_ByAccount_Controller.Customer>>)JSON.deserialize(
        jsonResult, Map<String, List<Registration_ByAccount_Controller.Customer>>.class
      );
    System.assertEquals( 4, result.keySet().size() );
    System.assertEquals( 25, result.get( String.valueOf( startDate.year() ) ).size() );
  }

  @IsTest
  static void fetchRegistrations_withoutAccountIdByPartner_Test()
  {
    buildAccounts();
    User partner = Factory_User.createPartnerUser( dealer );
    System.runAs( partner )
    {
      init();
      Test.startTest();
      String jsonResult = Registration_ByAccount_Controller.fetchRegistrations( null );
      Test.stopTest();
      Map<String, List<Registration_ByAccount_Controller.Customer>> result =
        (Map<String, List<Registration_ByAccount_Controller.Customer>>)JSON.deserialize(
          jsonResult, Map<String, List<Registration_ByAccount_Controller.Customer>>.class
        );
      System.assertEquals( 4, result.keySet().size() );
      System.assertEquals( 25, result.get( String.valueOf( startDate.year() ) ).size() );
    }
  }
}