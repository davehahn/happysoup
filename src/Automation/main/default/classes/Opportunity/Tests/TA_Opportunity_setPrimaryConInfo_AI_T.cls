@IsTest
public with sharing class TA_Opportunity_setPrimaryConInfo_AI_T {
  @testSetup
  static void dataSetup() {
    TA_Opportunity_TestHelper.dataSetup();
  }

  @isTest
  static void setPrimaryConInfo_Test() {
    TA_Opportunity_TestHelper.init();
    Test.startTest();
    Account personAccount = AccountFactory.insertPersonAccount();
    Decimal defaultFedTaxRate = Legend_Settings__c.getOrgDefaults().FederalTaxRate__c;
    System.runAs(TA_Opportunity_TestHelper.whitefishUser) {
      TA_Opportunity_TestHelper.opp = OpportunityFactory.buildBasicRetail(personAccount.id);
      TA_Opportunity_TestHelper.opp.ownerId = TA_Opportunity_TestHelper.whitefishUser.id;
      insert TA_Opportunity_TestHelper.opp;
      new TA_Opportunity_Before_Insert().beforeInsert(new List<Opportunity>{ TA_Opportunity_TestHelper.opp });
      new TA_Opportunity_setPrimaryContactInfo_AI().afterInsert(new List<Opportunity>{ TA_Opportunity_TestHelper.opp });
      List<OpportunityContactRole> oppContactRole = [
        SELECT id
        FROM OpportunityContactRole
        WHERE OpportunityId = :TA_Opportunity_TestHelper.opp.id
      ];
      System.assert(!oppContactRole.isEmpty());
    }
  }
}
