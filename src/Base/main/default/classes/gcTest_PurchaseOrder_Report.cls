@isTest(SeeAllData=true)
private class gcTest_PurchaseOrder_Report {
  static testMethod void testMethod01() {
    gcPurchaseOrder_Report.retrieveVendors();
    gcPurchaseOrder_Report.retrieveProducts();
    gcPurchaseOrder_Report.coverage();
  }
}
