@isTest
private class arSearchProject_Test{

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void setup()
  {
    Account[] persons = Factory_Account.insertCustomerAccounts(4);
    Account[] dealers = Factory_Account.insertDealerAccounts(4);
    AcctSeed__Project__c[] erps = new List<AcctSeed__Project__c>();
    for( Account p : persons )
    {
      erps.add( Factory_ERPOrder.buildERP( p,
                                           null,
                                           recordTypeIdFromName('AcctSeed__Project__c',
                                                                'Retail Boat Sale')
                                         ) );
    }
    for( Account d : dealers )
    {
      erps.add( Factory_ERPOrder.buildERP( d,
                                           null,
                                           recordTypeIdFromName('AcctSeed__Project__c',
                                                                'Partner Boat Sale')
                                         ) );
    }
    Boolean orig = gcProject.disableTrigger;
    gcProject.disableTrigger = true;
    insert erps;
    gcProject.disableTrigger = orig;
  }

  @isTest
  static void personSearch_Test()
  {
    setup();
    List<Map<String, String>> result = arSearchProject.searchProjects('Person');
    System.assertEquals( 4, result.size() );
  }

  @isTest
  static void dealerSearch_Test()
  {
    setup();
    List<Map<String, String>> result = arSearchProject.searchProjects('Dealer');
    System.assertEquals( 4, result.size() );
  }

  public static Id recordTypeIdFromName( String sObjectName,  String recordName )
  {
    return Schema.getGlobalDescribe()
      .get( sObjectName )
      .getDescribe()
      .getRecordTypeInfosByName()
      .get( recordName )
      .getRecordTypeId();
  }

}