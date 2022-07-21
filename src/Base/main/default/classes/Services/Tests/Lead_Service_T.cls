/**
 * Created by dave on 2021-04-21.
 */

@IsTest
private class Lead_Service_T {
  private static final String fName = 'TestFirst';
  private static final String lName = 'TestLast';
  private static final String leadSource = 'Online - Web';

  @testSetup
  static void dataSetup() {
    Lead l = Factory_Lead.buildLead(fName, lName, leadSource);
    insert l;
  }

  @IsTest
  static void duplicate_Test() {
    Lead newLead;
    System.Exception ex;
    try {
      newLead = Factory_Lead.insertLead(fName, lName, leadSource);
    } catch (Exception e) {
      ex = e;
    }

    System.assertNotEquals(null, ex);
    System.assertEquals(null, newLead);
    System.assertEquals(StatusCode.DUPLICATES_DETECTED, ex.getDmlType(0));
  }

  @IsTest
  static void insertOrUpdateDuplicate_NonDup_Test() {
    Lead l = Factory_Lead.buildLead(fName + '1', lName + '1', leadSource);
    Test.startTest();
    Lead_Service service = new Lead_Service(l);
    Lead_Service.LeadSaveResult result = service.insertOrUpdateDuplicate();
    Test.stopTest();

    List<Lead> leads = [SELECT Id FROM Lead];

    System.assert(result.isSuccess(), 'Should be successful');
    System.assert(result.getRecord() != null);
    System.assertEquals(fName + '1', result.getRecord().FirstName);
    System.assertEquals(lName + '1', result.getRecord().LastName);
    System.assertEquals(2, leads.size());
  }

  @IsTest
  static void insertOrUpdateDuplicate_WithDup_Test() {
    Lead l = Factory_Lead.buildLead(fName, lName, leadSource);
    l.MobilePhone = '333-333-3333';

    List<Lead> beforeLeads = [SELECT Id, MobilePhone FROM Lead];
    Test.startTest();
    Lead_Service service = new Lead_Service(l);
    Lead_Service.LeadSaveResult result = service.insertOrUpdateDuplicate();
    Test.stopTest();

    List<Lead> afterLeads = [SELECT Id, MobilePhone FROM Lead];

    System.assert(result.isSuccess(), 'Should be successful');
    System.assert(result.getRecord() != null);
    System.assertEquals(fName, result.getRecord().FirstName);
    System.assertEquals(lName, result.getRecord().LastName);
    System.assertEquals('333-333-3333', result.getRecord().MobilePhone);
    System.assertEquals('222-222-2222', beforeLeads[0].MobilePhone);
    System.assertEquals(1, afterLeads.size());
    System.assertEquals('333-333-3333', afterLeads[0].MobilePhone);
  }

  @IsTest
  static void insertOrUpdateDuplicate_WithMultipleDups_Test() {
    List<Lead> dups = new List<Lead>();
    for (Integer i = 0; i < 3; i++) {
      dups.add(Factory_Lead.buildLead(fName, lName, leadSource));
    }
    Database.DMLOptions dml = new Database.DMLOptions();
    dml.DuplicateRuleHeader.allowSave = true;
    dml.DuplicateRuleHeader.runAsCurrentUser = true;
    Database.SaveResult[] sr = Database.insert(dups, dml);
    System.debug(sr);
    Lead l = Factory_Lead.buildLead(fName, lName, leadSource);
    l.MobilePhone = '333-333-3333';

    List<Lead> beforeLeads = [SELECT Id, MobilePhone FROM Lead];
    Test.startTest();
    Lead_Service service = new Lead_Service(l);
    Lead_Service.LeadSaveResult result = service.insertOrUpdateDuplicate();
    Test.stopTest();

    List<Lead> afterLeads = [SELECT Id, MobilePhone FROM Lead];

    System.assert(result.isSuccess(), 'Should be successful');
    System.assert(result.getRecord() != null);
    System.assertEquals(fName, result.getRecord().FirstName);
    System.assertEquals(lName, result.getRecord().LastName);
    System.assertEquals('333-333-3333', result.getRecord().MobilePhone);
    System.assertEquals('222-222-2222', beforeLeads[0].MobilePhone);
    System.assertEquals(4, beforeLeads.size());
    System.assertEquals(1, afterLeads.size());
    System.assertEquals('333-333-3333', afterLeads[0].MobilePhone);
  }
}
