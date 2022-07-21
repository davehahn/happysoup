@isTest
private class CommissionERP_Tests {
  @isTest
  static void coverage_tests() {
    CommissionRecordERP.coverage();
    CommissionLineItemERP.coverage();
  }

  @isTest
  static void triggerTests() {
    CommissionRecord__c cr = new CommissionRecord__c(Name = 'Test Commy');
    insert cr;
    cr.Name = 'Test Commy 2';
    update cr;
  }
}
