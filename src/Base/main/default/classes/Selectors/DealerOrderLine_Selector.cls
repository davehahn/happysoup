/**
 * Created by dave on 2021-05-30.
 */

public virtual class DealerOrderLine_Selector extends Application_Selector {
  private final List<String> defaultFields = new List<String>{
    'Id',
    'ERP_Order__c',
    'ERP_Order__r.Reserved_For_Customer_Account__c',
    'ERP_Order__r.Reserved_For_Customer_Account__r.Name',
    'Dealer_Order__c',
    'Dealer_Order__r.Is_Booking_Order__c',
    'Is_For_Factory_Store__c',
    'Model_Year__c',
    'Order_Group_Id__c'
  };

  public DealerOrderLine_Selector() {
    this.sObjectName = 'Dealer_Order_Line__c';
    this.fields = defaultFields;
  }

  public static List<Dealer_Order_Line__c> allBYDealerOrder(Set<Id> dealerOrderIds) {
    return new DealerOrderLine_Selector().addWhereIdInField(dealerOrderIds, 'Dealer_Order__c').query();
  }
}
