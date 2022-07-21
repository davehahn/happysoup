@isTest
private class Partner_Customer_Trigger_Handler_Test {
  @isTest
  static void trigger_test() {
    Account dealer = AccountFactory.buildDealerAccount('Test Dealer');
    insert dealer;
    Account customer = AccountFactory.insertPersonAccount();
    Partner_Customer__c pc = new Partner_Customer__c(Partner__c = dealer.Id, Customer__c = customer.Id);
    insert pc;
    pc = [SELECT Id, Uniqueifier__c FROM Partner_Customer__c WHERE Id = :pc.Id];
    System.assertEquals(dealer.Id + '-' + customer.Id, pc.Uniqueifier__c);
  }
}
