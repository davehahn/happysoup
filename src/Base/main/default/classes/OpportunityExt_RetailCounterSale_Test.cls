@isTest
private class OpportunityExt_RetailCounterSale_Test {
  @isTest
  static void test1() {
    ApexPages.StandardController std = new ApexPages.StandardController(new Opportunity());
    OpportunityExt_RetailCounterSale ex = new OpportunityExt_RetailCounterSale(std);

    System.assertEquals('English', ex.displayLanguage);
    System.assertEquals(2, ex.getLanguageOptions().size());
  }
}
