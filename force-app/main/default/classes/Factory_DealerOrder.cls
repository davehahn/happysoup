@isTest
public class Factory_DealerOrder {
	static Account dealer;
	static Opportunity opp;
	static Dealer_Order__c order;
	static Dealer_Order_Line__c dol;

  public static Dealer_Order__c createDealerOrder(Account dealer) {
		order = new Dealer_Order__c(
      Account__c = dealer.Id,
      Payment_method__c = 'Cash',
      Model_Year__c = String.valueOf( Date.today().year() )
    );
    insert order;
    return order;
  }

  public static Dealer_Order__c createDealerOrder(Account dealer, String stage ) {
    order = new Dealer_Order__c(
      Account__c = dealer.Id,
      Payment_method__c = 'Cash',
      Stage__C = stage,
      Model_Year__c = String.valueOf( Date.today().year() )
    );
    insert order;
    return order;
  }

  public static Dealer_Order_Line__c createDealerOrderLine(Opportunity opp, Dealer_Order__c order) {
		Dealer_Order_Line__c dol = new Dealer_Order_Line__c(
      Opportunity__c = opp.Id,
      Dealer_Order__c = order.Id,
      Order_Group_Id__c = LGND_Utilities.generateRandomString( 16 )
    );
    insert dol;
    return dol;
  }

  public static Dealer_Order_Line__c buildDealerOrderLine( AcctSeed__Project__c erp,
                                                            Dealer_Order__c order,
                                                            Product2 prod ) {
    Dealer_Order_Line__c dol = new Dealer_Order_Line__c(
      ERP_Order__c = erp.Id,
      Product__c = prod.Id,
      Dealer_Order__c = order.Id,
      Order_Group_Id__c = LGND_Utilities.generateRandomString( 16 )
    );
    return dol;
  }

  public static List<Dealer_Order_Line__c> createDealerOrderLines( List<AcctSeed__Project__c> erps,
                                                                   Dealer_Order__c order,
                                                                   Product2 prod )
  {
    List<Dealer_Order_Line__c> dols = new List<Dealer_Order_Line__c>();
    String oId = LGND_Utilities.generateRandomString( 16 );
    for( AcctSeed__Project__c erp : erps )
    {
      dols.add( new Dealer_Order_Line__c(
        ERP_Order__c = erp.Id,
        Product__c = prod.Id,
        Dealer_Order__c = order.Id,
        Order_Group_Id__c = oId
      ));
    }
    insert dols;
    return dols;
  }

}