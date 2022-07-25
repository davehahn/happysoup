/**
 * Created by dave on 2022-06-15.
 */

@IsTest
private class TA_Lead_SetClosestPartner_T {
  @testSetup
  static void dataSetup() {
    TA_Lead_TestHelper.dataSetup();
  }

  @IsTest
  static void afterInsert_Trigger_ByLeadSource() {
    Lead personLead = Factory_Lead.buildLead(true);
    List<String> leadSources = new List<String>(Lead_Service.factoryAccountIdByLeadSource.keySet());
    personLead.LeadSource = leadSources[0];
    Test.startTest();
    insert personLead;
    Test.stopTest();
    Lead result = [SELECT Id, Closest_Partner__c FROM Lead WHERE Id = :personLead.Id];
    System.assertEquals(Lead_Service.factoryAccountIdByLeadSource.get(leadSources[0]), result.Closest_Partner__c);
  }

  @IsTest
  static void afterInsert_Trigger_IpCity() {
    TA_Lead_TestHelper.setDealers();
    Lead personLead = Factory_Lead.buildLead(true);
    personLead.IP_City__c = 'Orillia';
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new Tests_CalloutMocks.GoogleDestinationsMatrixMock());
    insert personLead;
    Test.stopTest();
    Lead result = [SELECT Id, Closest_Partner__c FROM Lead WHERE Id = :personLead.Id];
    System.assertEquals(TA_Lead_TestHelper.orillia.Id, result.Closest_Partner__c);
  }

  @IsTest
  static void afterInsert_Trigger_HubSpotIpCity() {
    TA_Lead_TestHelper.setDealers();
    Lead personLead = Factory_Lead.buildLead(true);
    personLead.hubspot_IP_City_Lead__c = 'Orillia';
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new Tests_CalloutMocks.GoogleDestinationsMatrixMock());
    insert personLead;
    Test.stopTest();
    Lead result = [SELECT Id, Closest_Partner__c FROM Lead WHERE Id = :personLead.Id];
    System.assertEquals(TA_Lead_TestHelper.orillia.Id, result.Closest_Partner__c);
  }

  @IsTest
  static void afterInsert_Trigger_PostalCode() {
    TA_Lead_TestHelper.setDealers();
    Lead personLead = Factory_Lead.buildLead(true);
    personLead.PostalCode = 'L3V3V3';
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new Tests_CalloutMocks.GoogleDestinationsMatrixMock());
    insert personLead;
    Test.stopTest();
    Lead result = [SELECT Id, Closest_Partner__c FROM Lead WHERE Id = :personLead.Id];
    System.assertEquals(TA_Lead_TestHelper.orillia.Id, result.Closest_Partner__c);
  }

  @IsTest
  static void afterInsert_Trigger_100() {
    TA_Lead_TestHelper.setDealers();
    List<Lead> leads = new List<Lead>();
    for (Integer i = 0; i < 100; i++) {
      Lead l = Factory_Lead.buildLead(true);
      l.IP_City__c = 'Orillia';
      leads.add(l);
    }
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new Tests_CalloutMocks.GoogleDestinationsMatrixMock());
    insert leads;
    Test.stopTest();
    Lead result = [SELECT Id, Closest_Partner__c FROM Lead WHERE Id = :leads[0].Id];
    System.assertEquals(TA_Lead_TestHelper.orillia.Id, result.Closest_Partner__c);
  }

  @IsTest
  static void afterUpdate() {
    TA_Lead_TestHelper.setDealers();
    Lead personLead = Factory_Lead.buildLead(true);
    TriggerBase.bypass('Lead');
    insert personLead;
    TriggerBase.clearBypass('Lead');

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new Tests_CalloutMocks.GoogleDestinationsMatrixMock());
    personLead.IP_City__c = 'Orillia';
    update personLead;
    Test.stopTest();
    Lead result = [SELECT Id, Closest_Partner__c FROM Lead WHERE Id = :personLead.Id];
    System.assertEquals(TA_Lead_TestHelper.orillia.Id, result.Closest_Partner__c);
  }
}
