/**
 * Created by dave on 2019-11-01.
 */
@IsTest
private class Lead_TriggerHandler_T
{

  private static Account orillia;
  private static Account barrie;

  @TestSetup
  static void dataSetup()
  {
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

  private static void buildDealers()
  {
    for( Account a : [ SELECT Id, Name FROM Account] )
    {
      if( a.Name == 'Barrie Dealer' )
        barrie = a;
      if( a.Name == 'Orillia Dealer' )
        orillia = a;
    }
    //orilliaUser = [ SELECT Id FROM User WHERE AccountId = :orillia.Id ];
  }

  private static Lead buildLead(Boolean isPersonAccount)
  {
    String uniq = LGND_Utilities.generateRandomString(6);
    return new Lead( FirstName = '_unitTest_First_' + uniq,
      LastName = '_unitTest_Last_' +  uniq,
      Email = 'unitTest_' + uniq +'@testing.net',
      isPersonAccount__c = isPersonAccount,
      Company = '_unitTest_Company_' + uniq );
  }

  @IsTest
  static void PersonAccountFix_Test()
  {
    Lead personlead = buildLEad( true );
    Lead businesslead = buildLead( false );
    Test.startTest();
    insert new List<Lead>{ personlead, businesslead };
    Test.stopTest();

    Lead afterPerson = [SELECT Id, Company FROM Lead WHERE Id = :personlead.Id];
    Lead afterBusiness = [SELECT Id, Company FROM Lead WHERE Id = :businesslead.Id];

    System.assertEquals( null, afterPerson.Company );
    System.assertEquals( businesslead.Company, afterBusiness.Company  );
  }

  @IsTest
  static void setClosestPartner_Insert1_Test()
  {
    buildDealers();
    Lead personLead = buildLead( true );
    personLead.IP_City__c = 'Orillia';
    Test.setMock( HttpCalloutMock.class, new Tests_CalloutMocks.GoogleDestinationsMatrixMock() );
    Test.startTest();
    insert personLead;
    Test.stopTest();
    Lead result = [SELECT Id, Closest_Partner__c FROM Lead WHERE Id = :personLead.Id ];
    System.assertEquals( orillia.Id, result.Closest_Partner__c );
  }

  @IsTest
  static void setClosestPartner_Insert_big_Test()
  {
    buildDealers();
    List<Lead> leads = new List<Lead>();
    for( Integer i=0; i<100; i++ )
    {
      Lead l = buildLead( true );
      l.IP_City__c = 'Orillia';
      leads.add( l );
    }
    Test.setMock( HttpCalloutMock.class, new Tests_CalloutMocks.GoogleDestinationsMatrixMock() );
    Test.startTest();
    insert leads;
    Test.stopTest();
    Lead result = [SELECT Id, Closest_Partner__c FROM Lead WHERE Id = :leads[0].Id ];
    System.assertEquals( orillia.Id, result.Closest_Partner__c );
  }

  @IsTest
  static void setClosestPartner_Insert2_Test()
  {
    buildDealers();
    Lead personLead = buildLead( true );
    personLead.hubspot_IP_City_Lead__c = 'Orillia';
    Test.setMock( HttpCalloutMock.class, new Tests_CalloutMocks.GoogleDestinationsMatrixMock() );
    Test.startTest();
    insert personLead;
    Test.stopTest();
    Lead result = [SELECT Id, Closest_Partner__c FROM Lead WHERE Id = :personLead.Id ];
    System.assertEquals( orillia.Id, result.Closest_Partner__c );
  }

  @IsTest
  static void setClosestPartner_Insert3_Test()
  {
    buildDealers();
    Lead personLead = buildLead( true );
    personLead.PostalCode = 'L3V3V3';
    Test.setMock( HttpCalloutMock.class, new Tests_CalloutMocks.GoogleDestinationsMatrixMock() );
    Test.startTest();
    insert personLead;
    Test.stopTest();
    Lead result = [SELECT Id, Closest_Partner__c FROM Lead WHERE Id = :personLead.Id ];
    System.assertEquals( orillia.Id, result.Closest_Partner__c );
  }

  @IsTest
  static void setClosestPartner_Update1_Test()
  {
    buildDealers();
    Lead personLead = buildLead( true );
    TriggerHandler.bypass('Lead_TriggerHandler');
    insert personLead;
    TriggerHandler.clearBypass('Lead_TriggerHandler');
    Test.setMock( HttpCalloutMock.class, new Tests_CalloutMocks.GoogleDestinationsMatrixMock() );
    Test.startTest();
    personLead.IP_City__c = 'Orillia';
    update personLead;
    Test.stopTest();
    Lead result = [SELECT Id, Closest_Partner__c FROM Lead WHERE Id = :personLead.Id ];
    System.assertEquals( orillia.Id, result.Closest_Partner__c );
  }

  @IsTest
  static void setClosestPartner_Update2_Test()
  {
    buildDealers();
    Lead personLead = buildLead( true );
    TriggerHandler.bypass('Lead_TriggerHandler');
    insert personLead;
    TriggerHandler.clearBypass('Lead_TriggerHandler');
    Test.setMock( HttpCalloutMock.class, new Tests_CalloutMocks.GoogleDestinationsMatrixMock() );
    Test.startTest();
    personLead.hubspot_IP_City_Lead__c = 'Orillia';
    update personLead;
    Test.stopTest();
    Lead result = [SELECT Id, Closest_Partner__c FROM Lead WHERE Id = :personLead.Id ];
    System.assertEquals( orillia.Id, result.Closest_Partner__c );
  }


}