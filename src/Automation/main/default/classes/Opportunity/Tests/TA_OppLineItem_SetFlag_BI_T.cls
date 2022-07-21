@isTest
public class TA_OppLineItem_SetFlag_BI_T {
  @testSetup
  static void dataSetup() {
    TA_OpportunityLine_TestHelper.dataSetup();
  }
  @isTest
  static void oppLineItem_SetFlag_Test() {
    TA_OpportunityLine_TestHelper.init();
    new TA_OppLineItem_SetFlag_BI().beforeInsert(TA_OpportunityLine_TestHelper.olis);
  }
}
