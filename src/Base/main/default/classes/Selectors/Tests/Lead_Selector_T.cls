/**
 * Created by dave on 2022-09-23.
 */

@IsTest
private class Lead_Selector_T
{
  static Integer LEAD_COUNT = 10;

  @testSetup static void dataSetup()
  {
//    new Factory_TestData();
//    Factory_CustomSettings.setupInventorySettings();
    List<Lead> leads = Factory_Lead.buildLeads( 'TestFirst', 'TestLast', LEAD_COUNT);
    insert leads;
  }

  private static Map<Id, Lead> getLeadMap(){
    return new Map<Id, Lead>([SELECT Id, Email FROM Lead]);
  }


  @IsTest
  static void allByIds()
  {
    Set<Id> ids = getLeadMap().keySet();
    Test.startTest();
    List<Lead> result = Lead_Selector.allByIds(ids);
    Test.stopTest();

    System.assertEquals( LEAD_COUNT, result.size() );
  }

  @IsTest
  static void allUncovertedByIds()
  {
    Set<Id> ids = getLeadMap().keySet();
    Test.startTest();
    List<Lead> result = Lead_Selector.allUncovertedByIds(ids);
    Test.stopTest();

    System.assertEquals( LEAD_COUNT, result.size() );
  }

  @IsTest
  static void byIdIncludingCampaignMembers(){
    Lead l = getLeadMap().values()[0];
    Test.startTest();
    Lead result = Lead_Selector.byIdIncludingCampaignMembers(l.Id);
    Test.stopTest();

    System.assertEquals(0, result.CampaignMembers.size());
  }

  @IsTest
  static void allNonConvertedByEmail(){
    Lead l = getLeadMap().values()[0];
    Test.startTest();
    List<Lead> result = Lead_Selector.allNonConvertedByEmail(l.Email);
    Test.stopTest();

    System.assertEquals(1, result.size());
  }
}