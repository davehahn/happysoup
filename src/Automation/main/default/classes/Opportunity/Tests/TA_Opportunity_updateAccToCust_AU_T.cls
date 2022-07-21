@isTest
public class TA_Opportunity_updateAccToCust_AU_T {
  @testSetup
  static void dataSetup() {
    TA_Opportunity_TestHelper.dataSetup();
  }
  @isTest
  static void updateAccountToLegendCustomer_Test() {
    TA_Opportunity_TestHelper.init();
    Account customer = Factory_Account.insertFullPersonAccount('Testy', 'McTesterson');
    Account beforeAcct = [SELECT Id, Type FROM Account WHERE Id = :customer.Id];
    TA_Opportunity_TestHelper.opp = Factory_Opportunity.insertOpportunity(customer, Test.getStandardPricebookId());
    List<Opportunity> oldOpportunities = TA_Opportunity_TestHelper.getOldList();
    Test.startTest();
    TA_Opportunity_TestHelper.opp.Approved__c = true;
    update TA_Opportunity_TestHelper.opp;
    new TA_Opportunity_updateAccountsToCust_AU()
      .afterUpdate(new List<Opportunity>{ TA_Opportunity_TestHelper.opp }, oldOpportunities);
    Test.stopTest();

    Account afterAcct = [SELECT Id, Type FROM Account WHERE Id = :customer.Id];

    System.assert(
      beforeAcct.Type != 'Legend Customer',
      'Account type should not be Legend Customer Pending before Sales manager Approval'
    );
    System.assert(afterAcct.Type == 'Legend Customer', 'Account type should now be Legend Customer');
  }
}
