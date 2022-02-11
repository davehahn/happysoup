/**
 * Created by dave on 2022-01-06.
 */

@IsTest
private class TA_Case_EnforceAssignmentRules_T
{
  private static List<Case> cases;
  private static Account dealer;


  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void init() {
    dealer = AccountFactory.buildDealerAccount('Testy McDealer');
    insert dealer;
    cases = new List<Case>();
  }

  @IsTest
  static void TA_AfterInsert(){
    init();
    Case c = Factory_Case.buildWarrantyCase(dealer);
    TriggerBase.bypass('Case');
    insert c;
    TriggerBAse.clearBypass('Case');
    System.debug('BEFORE');
    c = [SELECT Id, Owner.Id, Owner.Name FROM Case WHERE Id = :c.Id];
    System.debug( c.OwnerId );
    System.debug(c.Owner.Name);

    cases.add(c);

    new TA_Case_EnforceAssignmentRules().afterInsert(cases);

    System.debug('AFTER');
    c = [SELECT Id, Owner.Id, Owner.Name FROM Case WHERE Id = :c.Id];
    System.debug( c.OwnerId );
    System.debug(c.Owner.Name);
  }

}