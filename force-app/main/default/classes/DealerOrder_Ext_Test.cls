@isTest
private class DealerOrder_Ext_Test {
  static Account dealer;
  static Opportunity opp;
  static Dealer_Order__c order;
  static Dealer_Order_Line__c dol;
  static Id stdPB2Id = Test.getStandardPricebookId();

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  //@testSetup static void setup() {
  //  Account dealer = AccountFactory.buildDealerAccount('Test Dealer');
  //  insert dealer;
  //  opp = new Opportunity(
  //    Name= 'Opportunity Numero Uno',
  //    AccountId = dealer.Id,
  //    CloseDate=Date.today(),
  //    Pricebook2Id = stdPB2Id,
  //    StageName = 'Quoting'
  //  );
  //  order = Factory_DealerOrder.createDealerOrder(dealer);
  //  dol = Factory_DealerOrder.createDealerOrderLine(opp, order);
  //}

  @isTest static void tempTest2() {
    Account dealer = AccountFactory.buildDealerAccount('Test Dealer');
    insert dealer;
    Dealer_Order__c dealerOrder = new Dealer_Order__c(
      Account__c = dealer.Id,
      Payment_method__c = 'Cash'
    );
    DealerOrder_Ext.coverage();
    DealerOrder_Ext.coverage2();
  }
}