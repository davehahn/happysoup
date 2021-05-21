/**
 * Created by dave on 2019-08-06.
 */

public inherited sharing class Opportunity_Selector Extends Application_Selector {

  public Opportunity_Selector()
  {
    this.sObjectName = 'Opportunity';
    this.fields = new List<String>{
      'Id',
      'CampaignId',
      'LeadSource',
      'Name',
      'RecordTypeId',
      'RecordType.Name',
      'Trade_In_Amount__c',
      'Trade_In_Value__c',
      'Business_Manager__c',
      'Warehouse__c',
      'Deposit__c',
      'Deposit_Method__c',
      'On_Water_Orientation__c',
      'Finance_Status__c',
      'Customer_Notes__c',
      'Pricebook2Id',
      'ContactEmail__c',
      'OwnerId',
      'Owner.Name',
      'AccountId',
      'Account.Name',
      'Total_Amount__c',
      'BoatId__c',
      'StageName',
      'BoatId__r.Name',
      'Pickup_Location__c',
      'Delivery_Date__c',
      'Payment_Method__c',
      'InvoiceNumber__c',
      'Reference_Number__c',
      'GL_Account_Variable_3__c',
      'Insurance_Term__c',
      'Finance_Term__c',
      'Finance_Annual_Interest__c',
      'Finance_Ammortization__c',
      'Finance_Payments_Per_Year__c',
      'Finance_Compound__c',
      'Tax_Override__c',
      'Tax_Rate_Federal__c',
      'Tax_Rate_Provincial__c',
      'Tax_Rate_Retail__c',
      'Boat_Specialist_Id__c',
      'Boat_Model_Year__c',
      'Trailer_Model_Year__c',
      'IsPickupDealershipPartner__c',
      'PickupDealership__c',
      'PickupDealership__r.Id',
      'PickupDealership__r.Name',
      'Contract_Start_Date__c',
      'First_Payment_Date__c'
    };
  }

  public static Opportunity[] allByIds( Set<Id> ids )
  {
    Opportunity_Selector selector = new Opportunity_Selector();
    selector.addWhereIdIn( ids );
    return selector.query();
  }

  public static Opportunity[] allSchedulableRetailBoatSaleByLocation( String warehouseName )
  {
    String locString = '%' + warehouseName + '%';
    Id oppBoatSaleRT = LGND_Utilities.recordTypeIdFromName('Opportunity', 'Retail');
    Opportunity_Selector selector = new Opportunity_Selector();
    selector
      .addWhere('RecordTYpeId = \'' + oppBoatSaleRT + '\'')
      .addWhere( '(Pickup_Location__c LIKE \'' + locString + '\' OR Pickup_Location__c = null)')
      .addWhere( 'Delivery_Date__c = null')
      .addWhere('Probability > 69')
      .addWhere('Probability < 100')
      .addOrderBy('Pickup_Location__c DESC');
    return selector.query();
  }

  public static Opportunity[] allRetailBoatSaleByLocationAndDeliveryDateRange( String location,
                                                                                Date startDate,
                                                                                Date endDate )
  {
    String locString = '%' + location + '%';
    Opportunity_Selector selector = new Opportunity_Selector();
    selector
      .addWhere('Probability < 100' )
      .addWhere('Probability > 0' )
      .addWhere('Pickup_Location__c LIKE \'' + locString + '\'')
      .addWhere('Delivery_Date__c >= ' + toDateString( startDate ) )
      .addWhere('Delivery_Date__c <= ' + toDateString( endDate ) );
    return selector.query();
  }

  public static Opportunity[] selectAllByIdWithLineItems( Set<Id> oppIds )
  {
    OpportunityLineItem_Selector oliSelector = new OpportunityLineItem_Selector();
    return new Opportunity_Selector()
      .addWhereIdIn( oppIds )
      .addChildQuery( oliSelector )
      .query();
  }

}
