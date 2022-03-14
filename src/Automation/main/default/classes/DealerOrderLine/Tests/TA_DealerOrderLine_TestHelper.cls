@isTest
public class TA_DealerOrderLine_TestHelper {
    static User partnerUser;
    static public List<AcctSeed__Project__c> erps;
    public static Set<Id> erpIds;
    static PricebookEntry pbe;
    static Account partner;
    static Product2 boat;
    public static Dealer_Order__c order;
    static String partnerAccountName = 'TestPartner';
    public static List<Dealer_Order_Line__c> dealerOrderLines;
    public static Product2 motor;

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
        SYstem.debug('partner.id= '+partner.id);
        Factory_User.createPartnerUser(partner);

    }
    public static void buildDealerOrder(Boolean isBooking, String stage)
    {
        System.debug('@@ partner= '+partner.id);
        order = Factory_DealerOrder.buildDealerOrder(partner);
        order.Is_Booking_Order__c = isBooking;
        order.Stage__c = stage;
        insert order;
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
        dealerOrderLines = Factory_DealerOrder.createDealerOrderLines(erps, order, boat);
        erpIds = LGND_Utilities.getIdSetFromList((List<sObject>) erps);
        buildMotor(1000);
        Dealer_Motor_Request__c motorRequest = new Dealer_Motor_Request__c(Motor__c=motor.id,Notes__c='Test',Quantity__c=4);
        insert motorRequest;
        Legend_Transfer_Request__c transferRequest = new Legend_Transfer_Request__c(Account__c=partner.id,Notes__c='Test',Stage__c='Draft');
        insert transferRequest;
        for(Dealer_Order_Line__c dol :dealerOrderLines){
            dol.Dealer_Motor_Request__c =motorRequest.id;
            dol.Legend_Transfer_Request__c = transferRequest.id;
        }
        System.debug('dealerOrderLines= '+dealerOrderLines);
        update dealerOrderLines;

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
    public static void buildMotor( Decimal cost )
    {
        Id fpbId = LGND_Constants.factoryPricebookId;
        motor = Factory_Product.buildSerializedProduct('Motor', 'Remote');
        insert motor;
    }

}