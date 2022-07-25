@isTest(seeAllData=true)
private class OpportunityDetailExt_Test {
  static OpportunityDetailExt ode;
  static Opportunity opp;

  static {
    //OpportunityTriggerHandler.disableAutoPricebookSet = true;
    opp = OpportunityFactory.insertRetailBoatSale();
    Opportunity_Service.disableAutoPricebookSet = true;
    ApexPages.StandardController std = new ApexPages.StandardController(opp);
    ode = new OpportunityDetailExt(std);
  }

  @isTest
  static void getterTests() {
    System.assertEquals(true, ode.getHAsLineItems());
    System.assertEquals('Not Set', ode.getFormattedDeliveryDate());
  }

  @isTest
  static void updateStageTest() {
    System.assertEquals('Quoting', opp.StageName);
    opp = OpportunityDetailExt.updateStage(opp.Id, 'Pending Rigging');
    System.assertEquals('Pending Rigging', opp.StageName);
    opp = OpportunityDetailExt.updateStage(opp.Id, 'Pending Rigging');
    System.assertEquals('Pending Work Order', opp.StageName);
    opp = OpportunityDetailExt.updateStage(opp.Id, 'Picked Up / Won');
    System.assertEquals('Picked Up / Won', opp.StageName);
  }
}
