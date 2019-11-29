public with sharing class DealerOrderDiscounts {

  private Dealer_Program_Settings__c theProgram = Dealer_Program_Settings__c.getValues('2018');

  public class DiscountWrapper {
    public String name { get; set; }
    public Decimal amount { get; set; }
    public String discountType { get; set; }
  }

  public DiscountWrapper[] availableDiscounts { get; set; }
  private Dealer_Order__c dealerOrder;

	public DealerOrderDiscounts( String dealerOrderId) {
    findDealerOrder( dealerOrderId );
    this.availableDiscounts = new List<DiscountWrapper>();
    if( !this.dealerOrder.Account__r.Is_Internal__c )
    {
		  checkForEarlyOrder();
      buildCoOpDiscount();
    }
	}

  private void findDealerOrder( Id doId )
  {
    this.dealerOrder = [SELECT Id, Is_Booking_Order__c, Account__r.Is_Internal__c
                        FROM Dealer_Order__c
                        WHERE Id = :doId ];
  }

  private DealerOrderDiscounts checkForEarlyOrder()
  {
    if( this.dealerOrder.Is_Booking_Order__c )
    {
      if( Date.today() <= theProgram.Early_Order_Discount_Date__c )
        addDiscount('Early Booking Discount',
                    theProgram.Early_Order_Discount_Rate__c,
                    'percent');
    }
    return this;
  }

  private DealerOrderDiscounts buildCoOpDiscount()
  {
    addDiscount('Co-Op Discount', 2, 'percent');
    return this;
  }

  private void addDiscount( String name, Decimal amount, String type )
  {
    DiscountWrapper nd = new DiscountWrapper();
    nd.name = name;
    nd.amount = amount;
    nd.discountType = type;
    this.availableDiscounts.add( nd );
  }
}