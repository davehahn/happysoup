@isTest(seeAllData=true)
private class Dealer_Order_Line_Ext_Test {

  @isTest static void tempTest() {
    Dealer_Order_Line_Ext.coverage();
    Account dealer = AccountFactory.buildDealerAccount('Test Dealer');
    insert dealer;
    Dealer_Order__c dealerOrder = Factory_DealerOrder.createDealerOrder( dealer );
    Opportunity opp = OpportunityFactory.insertRetailBoatSale();
    Dealer_Order_Line__c dol = new Dealer_Order_Line__c(
      Opportunity__c = opp.Id,
      Dealer_Order__c = dealerOrder.Id,
      Order_Group_Id__c = LGND_Utilities.generateRandomString( 16 ),
      Model_Year__c = dealerOrder.Program_Year__c
    );
    insert dol;
    Dealer_Order_Line_Ext.cloneOrderLine( dol.Id, 10 );

    Dealer_Order_Line__c[] dols = [SELECT Id FROM Dealer_Order_Line__c WHERE Dealer_Order__c = :dealerOrder.Id];
    System.assertEquals(11, dols.size());
    //update [SELECT Id FROM Dealer_Order_Line__c ORDER BY CreatedDate DESC LIMIT 1];
  }


}