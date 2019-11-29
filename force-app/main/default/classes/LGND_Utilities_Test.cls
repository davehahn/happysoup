@isTest
private class LGND_Utilities_Test {

  @isTest static void coverage_test()
  {
    LGND_Utilities.coverage();
  }

  @isTest static void recordIdFromName_Test() {
    Test.startTest();
    Id boatRtId = [SELECT Id FROM RecordType WHERE Name = 'Boat'].Id;
    Test.stopTest();

    System.assertEquals( boatRtId, LGND_Utilities.recordTypeIdFromName('Product2', 'Boat') );
  }

  @isTest static void getPickListValues_Test()
  {
    Test.startTest();
    List<Schema.PicklistEntry> ple = Opportunity.StageName.getDescribe().getPicklistValues();
    List<String> ple2 = LGND_Utilities.getPicklistValues('Opportunity', 'StageName');
    Test.stopTest();

    System.assertEquals(ple.size(), ple2.size());
  }

  @isTest static void generateRandonString_Test()
  {
    String eight = LGND_Utilities.generateRandomString(8);
    String twenty = LGND_Utilities.generateRandomString(20);

    System.assertEquals(8, eight.length() );
    System.assertEquals(20, twenty.length() );
  }

  @isTest static void getCreatableFieldsSOQL_Test()
  {
    String soqlQuery = LGND_Utilities.getCreatableFieldsSOQL('Lead', '');
    System.assert(soqlQuery.length() > 0);
  }

  @isTest static void getCreatableFieldsSOQL_withExcludeFields_Test()
  {
    String soqlQuery = LGND_Utilities.getCreatableFieldsSOQL('Lead', new Set<String>{'OwnerId'}, '');
    System.assert(soqlQuery.length() > 0);
  }

  @isTest static void GetRunningUserRecord_Test()
  {
    User u = LGND_Utilities.GetRunningUserRecord('PermissionsManagePartners');
    System.assert(u.Id != null);
  }

  @isTest static void DoesRunningUserHavePermission_Test()
  {
    Boolean permitted = LGND_Utilities.DoesRunningUserHavePermission('PermissionsManagePartners');
    System.assert(permitted);
  }

}