/**
 * Created by dave on 2022-06-15.
 */

@IsTest
private class TA_Lead_HubspotPersonAccountFix_T {
  @testSetup
  static void dataSetup() {
    TA_Lead_TestHelper.dataSetup();
  }

  @IsTest
  static void beforeInsert_TA() {
    List<Lead> newList = new List<Lead>();
    newList.add(Factory_Lead.buildLead(true));
    newList.add(Factory_Lead.buildLead(false));

    Test.startTest();
    new TA_Lead_HubspotPersonAccountFix().beforeInsert(newList);
    Test.stopTest();

    System.assert(null == newList[0].Company);
    System.assert(null != newList[1].Company);
  }

  @IsTest
  static void beforeInsert_Trigger() {
    List<Lead> newList = new List<Lead>();
    newList.add(Factory_Lead.buildLead(true));
    newList.add(Factory_Lead.buildLead(false));

    Test.startTest();
    insert newList;
    Test.stopTest();

    Lead person = [SELECT Id, Company FROM Lead WHERE Id = :newList[0].Id];
    Lead business = [SELECT Id, Company FROM Lead WHERE Id = :newList[1].Id];

    System.assert(null == person.Company);
    System.assert(null != business.Company);
  }
}
