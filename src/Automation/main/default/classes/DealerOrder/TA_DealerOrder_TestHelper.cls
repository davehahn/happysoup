@IsTest
public class TA_DealerOrder_TestHelper {
	static Dealer_Order__c order;
    static String partnerAccountName = 'TestPartner';
    static Account partner;
    static Product2 boat;
    static PricebookEntry pbe;
    static User partnerUser;
    static public List<AcctSeed__Project__c> erps;
    static Set<Id> erpIds;
    public static Product2 motor;

    @testSetup 
    public static void dataSetup(){
    	new Factory_TestData();
    	Factory_CustomSettings.setupInventorySettings();
    	insert new Partner_Program_Settings__c(
      				Coop_Discount_Percent__c = 2,
      				Kickstart_Booking_Order_Discount_Percent__c = 2,
      				Available_Model_Years__c = '2020,2021',
      				Available_Program_Years__c = '2021'
    	);
    	Account partner = Factory_Account.buildDealerAccounts(1)[0];
    	partner.Name = partnerAccountName;
    	partner.BillingState = 'Ontario';
    	insert partner;
    	Factory_User.createPartnerUser(partner);
   
    }
    public static void buildDealerOrder(Boolean isBooking, String stage)
    {
        order = Factory_DealerOrder.buildDealerOrder(partner);
        order.Is_Booking_Order__c = isBooking;
        order.Stage__c = stage;
    }
    public static void findPartner()
    {
        Id rtId = LGND_Utilities.recordTypeIdFromName('Account', 'Dealer');
        partner = [SELECT Id, Name, BillingState FROM Account WHERE Name = :partnerAccountName AND RecordTypeId = :rtId];
    }
    public static void init()
    {
       findPartner();
       partnerUser = [SELECT Id FROM User WHERE AccountId = :partner.Id];
    }
    public static User fetchPartnerUser(){
        return [SELECT Id FROM User WHERE AccountId = :partner.Id];
    }
    public static Dealer_Order__c insertDealerOrder(Boolean isBooking, String stage){
        buildDealerOrder(isBooking,stage);
        return order;
    }
    public static List<Dealer_Order__c> getDealerOrder(){
        return [select id,Program_Year__c,Account__c,Is_Booking_Order__c,Date_Submitted__c from Dealer_Order__c];
    }
    public static Partner_Booking_Order__c[] getPartnerBookingOrder(){
        Partner_Booking_Order__c[] bookingOrders = [
        SELECT Id
        FROM Partner_Booking_Order__c
        WHERE Dealer_Order__c = :order.Id
      ];
        return bookingOrders;
    }

    public static List<Dealer_Order__c> getNewList() {
    	return new List<Dealer_Order__c>{ order };
    }

  public static List<Dealer_Order__c> getOldList() {
    	Dealer_Order__c c = order.clone(true, true, true, true);
    	return new List<Dealer_Order__c>{ c };
    }
    
   public static void buildBoat(String family, Decimal cost, Integer stackSize)
  {
    Id fpbId = LGND_Constants.factoryPricebookId;
    boat = Factory_Product.buildSerializedProduct('Boat', family);
    boat.Stack_Size__c = stackSize;
    insert boat;
    Factory_PricebookEntry.insertStandardEntries(new List<Product2>
    {
      boat
    }, cost);
    pbe = Factory_PricebookEntry.buildEntry(boat.Id, fpbId, cost);
    insert pbe;
  }
    
  public static void createDealerOrderLines(Dealer_Order__c dealerOrder, Integer quantity)
  {
    erps = Factory_ERPOrder.createPartnerBoatSales(partner, new List<PricebookEntry>
    {
      pbe
    }, quantity);
    Factory_DealerOrder.createDealerOrderLines(erps, order, boat);
    erpIds = LGND_Utilities.getIdSetFromList((List<sObject>) erps);
  }
    public static void buildMotor( Decimal cost )
    {
        Id fpbId = LGND_Constants.factoryPricebookId;
        motor = Factory_Product.buildSerializedProduct('Motor', 'Remote');
        insert motor;
        Factory_PricebookEntry.insertStandardEntries(new List<Product2>
        {
                motor
        }, cost);
        pbe = Factory_PricebookEntry.buildEntry(motor.Id, fpbId, cost);
        insert pbe;
    }

}