/**
 * Created by dave on 2020-12-29.
 */

public virtual class Application_RecordType
{
  public class Application_RecordType_Exception extends Exception{}

  private Map<String,List<RecordType>> recordTypesBySobjectName {
    get {
      if( recordTypesBySobjectName == null )
      {
        fetchAllRecordTypes();
      }
      return recordTypesBySobjectName;
    }
    set;
  }

  public Map<Id, String> developerNameById {
    get {
      if( developerNameById == null )
      {
        fetchAllRecordTypes();
      }
      return developerNameById;
    }
    set;
  }

  private AccountRTs accountRTs {
    get {
      if( this.accountRTs == null )
      {
        this.accountRTs = new AccountRTs();
      }
      return accountRTs;
    }
    private set;
  }
  private CaseRTs caseRTs {
    get {
      if( this.caseRTs == null )
      {
        this.caseRTs = new CaseRTs();
      }
      return caseRTs;
    }
    private set;
  }
  private ERPOrderRTs erpOrderRTs {
    get {
      if( this.erpOrderRTs == null )
      {
        this.erpOrderRTs = new ERPOrderRTs();
      }
      return erpOrderRTs;
    }
    private set;
  }
  private OpportunityRTs opportunityRTs {
    get {
      if( this.opportunityRTs == null )
      {
        this.opportunityRTs = new OpportunityRTs();
      }
      return opportunityRTs;
    }
    private set;
  }
  private PricebookRTs pricebookRTs {
    get {
      if( this.pricebookRTs == null )
      {
        this.pricebookRTs = new PricebookRTs();
      }
      return pricebookRTs;
    }
    private set;
  }
  private ProductRTs productRTs {
    get {
      if( this.productRTs == null )
      {
        this.productRTs = new ProductRTs();
      }
      return productRTs;
    }
    private set;
  }
  private SystemIssueRTs systemIssueRTs {
    get {
      if( this.systemIssueRTs == null )
      {
        this.systemIssueRTs = new SystemIssueRTs();
      }
      return systemIssueRTs;
    }
    private set;
  }
//  private WorkOrderRTs workOrderRTs {
//    get {
//      if( this.workOrderRTs == null )
//      {
//        this.workOrderRTs = new WorkOrderRTs();
//      }
//      return workOrderRTs;
//    }
//    private set;
//  }

  public Application_RecordType(){}

  public String getDeveloperNameById( Id recordId ){
    System.debug(this.developerNameById );
    System.debug( this.recordTypesBySobjectName.get('Pricebook2'));
    System.debug(recordId);
    if( this.developerNameById.containsKey(recordId) ){
      return this.developerNameById.get(recordId);
    }
    String err = 'A record type with Id [' + recordId + '] does not exist.';
    Application_RecordType_Exception ex = new Application_RecordType_Exception(
      err
    );
    ex.setMessage( err );
    throw ex;
  }


  public AccountRTs getAccountRecordTypes()
  {
    return this.accountRTs;
  }

  public CaseRTs getCaseRecordTypes()
  {
    return this.caseRTs;
  }

  public ERPOrderRTs getERPOrderRecordTypes()
  {
    return this.erpOrderRTs;
  }

  public OpportunityRTs getOpportunityRecordTypes()
  {
    return this.opportunityRTs;
  }

  public PricebookRTs getPricebookRecordTypes()
  {
    return this.pricebookRTs;
  }

  public ProductRTs getProductRecordTypes()
  {
    return this.productRTs;
  }

  public SystemIssueRTs getSystemIssueRecordTypes(){
    return this.systemIssueRTs;
  }

//  public WorkOrderRTs getWorkOrderRecordTypes()
//  {
//    return this.workOrderRTs;
//  }

  public virtual class SObjectRecordType extends Application_RecordType
  {
    private String sObjectName;

    public Map<String, RecordType> recordTypeByDeveloperName {
      get {
        if( recordTypeByDeveloperName == null )
        {
          recordTypeByDeveloperName = buildDeveloperMapFor(this.sObjectName );
        }
        return recordTypeByDeveloperName;
      }
      set;
    }

    public SObjectRecordType( String sObjectName )
    {
      this.sObjectName = sObjectName;
    }

    public Id getIdFromDeveloperName( String devName )
    {
      if( this.recordTypeByDeveloperName.containsKey( devName ) )
      {
        return this.recordTypeByDeveloperName.get(devName).Id;
      }
      String err = 'A record type with API Name [' + devName + '] for ' + this.sObjectName + ' does not exist.';
      Application_RecordType_Exception ex = new Application_RecordType_Exception(
        err
      );
      ex.setMessage( err );
      throw ex;
    }

    public Integer getRecordTypeCount()
    {
      return this.recordTypeByDeveloperName.keySet().size();
    }

    private Map<String, RecordType> buildDeveloperMapFor( String sObjectName )
    {
      Map<String, RecordType> result = new Map<String, RecordType>();
      for( RecordType rt : super.recordTypesBySobjectName.get( sObjectName ) )
      {
        result.put( rt.DeveloperName, rt );
      }
      return result;
    }

    private Map<Id, String> buildNameMapFor( String sObjectName )
    {
      Map<Id, String> result = new Map<Id, String>();
      for( RecordType rt : super.recordTypesBySobjectName.get( sObjectName ) )
      {
        result.put( rt.Id, rt.DeveloperName );
      }
      return result;
    }
  }

  public virtual class AccountRTs extends SObjectRecordType
  {

    public AccountRTs()
    {
      super('Account');
    }

    public Id getBusinessAccountId()
    {
      return this.getIdFromDeveloperName('Business_Account');
    }

    public Id getDealerId()
    {
      return this.getIdFromDeveloperName('Dealer');
    }

    public Id getGeoHackId()
    {
      return this.getIdFromDeveloperName('GeoHack');
    }

    public Id getPersonAccountId()
    {
      return this.getIdFromDeveloperName('PersonAccount');
    }

    public Id getSupplierId()
    {
      return this.getIdFromDeveloperName('Supplier');
    }
  }

  public virtual class CaseRTs extends SObjectRecordType
  {

    public CaseRTs()
    {
      super('Case');
    }

    public Id getCustomerCommunityId()
    {
      return this.getIdFromDeveloperName('Customer_Community');
    }

    public Id getPartOrderRequestId()
    {
      return this.getIdFromDeveloperName('Part_Order_Request');
    }

    public Id getPartInquiryId()
    {
      return this.getIdFromDeveloperName('PartInquiry');
    }

    public Id getPartnerSupportId()
    {
      return this.getIdFromDeveloperName('Partner_Support_Process');
    }

    public Id getPromotionId()
    {
      return this.getIdFromDeveloperName('Promotion');
    }

    public Id getReportRequestId()
    {
      return this.getIdFromDeveloperName('Report_Request');
    }

    public Id getServiceAppointmentId()
    {
      return this.getIdFromDeveloperName('Service_Appointment');
    }

    public Id getSupportCaseId()
    {
      return this.getIdFromDeveloperName('Support_Case');
    }

    public Id getTranslationId()
    {
      return this.getIdFromDeveloperName('Translation');
    }

    public Id getWarrantyId()
    {
      return this.getIdFromDeveloperName('Warranty');
    }

    public Id getWarrantyReturnId()
    {
      return this.getIdFromDeveloperName('Warranty_Returns');
    }
  }

  public virtual class ERPOrderRTs extends SObjectRecordType
  {

    public ERPOrderRTs()
    {
      super('AcctSeed__Project__c');
    }

    public Id getCounterSaleId()
    {
      return this.getIdFromDeveloperName('CounterSale');
    }

    public Id getFixedAssetId()
    {
      return this.getIdFromDeveloperName('LegendFixedAsset');
    }

    public Id getManufacturingId()
    {
      return this.getIdFromDeveloperName('Manufacturing');
    }

    public Id getPartnerPartsOrderId()
    {
      return this.getIdFromDeveloperName('LegendPartnerPartsOrder');
    }

    public Id getPartnerRetailBoatSaleId()
    {
      return this.getIdFromDeveloperName('PartnerRetailBoatSale');
    }

    public Id getServiceWorkOrderId()
    {
      return this.getIdFromDeveloperName('Service');
    }

    public Id getTradeInId()
    {
      return this.getIdFromDeveloperName('TradeIn');
    }

    public Id getWarrantyId()
    {
      return this.getIdFromDeveloperName('Legend_Warranty');
    }

    public Id getPartnerBoatSaleId()
    {
      return this.getIdFromDeveloperName('PartnerBoatSale');
    }

    public Id getProjectId()
    {
      return this.getIdFromDeveloperName('Project');
    }

    public Id getRetailBoatSaleId()
    {
      return this.getIdFromDeveloperName('BoatSale');
    }

  }

  public virtual class OpportunityRTs extends SObjectRecordType
  {

    public OpportunityRTs()
    {
      super('Opportunity');
    }

    public Id getOnlineId()
    {
      return this.getIdFromDeveloperName('Online');
    }

    public Id getPartnerRetailBoatSaleId()
    {
      return this.getIdFromDeveloperName('Partner_Retail_Boat_Sale');
    }

    public Id getRetailId()
    {
      return this.getIdFromDeveloperName('Retail');
    }
  }

  public virtual class PriceBookRTs extends SObjectRecordType
  {
    public PriceBookRTs()
    {
      super('Pricebook2');
    }

    public Id getDealerId()
    {
      return this.getIdFromDeveloperName('Dealer');
    }

    public Id getFactoryId()
    {
      return this.getIdFromDeveloperName('Factory');
    }

    public Id getSalesId()
    {
      return this.getIdFromDeveloperName('Sales');
    }

    public Id getSupplierId()
    {
      return this.getIdFromDeveloperName('Supplier');
    }
  }

  public virtual class ProductRTs extends SObjectRecordType
  {

    public ProductRTs()
    {
      super('Product2');
    }

    public Id getBoatId()
    {
      return this.getIdFromDeveloperName('Boat');
    }

    public Id getFeesId()
    {
      return this.getIdFromDeveloperName('Fees');
    }

    public Id getInsuranceId()
    {
      return this.getIdFromDeveloperName('Insurance');
    }

    public Id getInternalId()
    {
      return this.getIdFromDeveloperName('Internal');
    }

    public Id getLabourId()
    {
      return this.getIdFromDeveloperName('Labour');
    }

    public Id getMotorId()
    {
      return this.getIdFromDeveloperName('Motor');
    }

    public Id getPackageBundleId()
    {
      return this.getIdFromDeveloperName('Package_Bundle');
    }

    public Id getPartId()
    {
      return this.getIdFromDeveloperName('Part');
    }

    public Id getPrepaidPackageId()
    {
      return this.getIdFromDeveloperName('Prepaid_Package');
    }

    public Id getProtectionAndServiceId()
    {
      return this.getIdFromDeveloperName('Protection_and_Services');
    }

    public Id getTrailerId()
    {
      return this.getIdFromDeveloperName('Trailer');
    }

    public Id getTrollingMotorId()
    {
      return this.getIdFromDeveloperName('Trolling_Motor');
    }

  }

  public virtual class SystemIssueRTs extends SObjectRecordType {
    public SystemIssueRTs(){
      super('System_Issue__c');
    }

    public Id getStandardId(){
      return this.getIdFromDeveloperName('Standard');
    }

    public Id getEpicId(){
      return this.getIdFromDeveloperName('Epic');
    }
  }

//  public virtual class WorkOrderRTs extends SObjectRecordType
//  {
//
//    public WorkOrderRTs()
//    {
//      super('WorkOrder');
//    }
//
//    public Id getManufacturingId()
//    {
//      return this.getIdFromDeveloperName('Manufacturing');
//    }
//
//    public Id getPartnerSaleId()
//    {
//      return this.getIdFromDeveloperName('Partner_Sale');
//    }
//
//    public Id getRetailSaleId()
//    {
//      return this.getIdFromDeveloperName('Retail_Sale');
//    }
//
//    public Id getRetailServiceId()
//    {
//      return this.getIdFromDeveloperName('Retail_Service');
//    }
//
//    public Id getWholesaleServiceId()
//    {
//      return this.getIdFromDeveloperName('Wholesale_Service');
//    }
//
//  }

  private void fetchAllRecordTypes()
  {
    System.debug('fetching all rerordTypes');
    this.recordTypesBySobjectName = new Map<String, List<RecordType>>();
    this.developerNameById = new Map<Id, String>();
    List<RecordType> rts = [
      SELECT
        Id,
        Name,
        DeveloperName,
        SobjectType
      FROM RecordType
      WHERE IsActive = true
    ];
    for( RecordType rt : rts )
    {
      this.developerNameById.put( rt.Id, rt.DeveloperName );
      if( !this.recordTypesBySobjectName.containsKey( rt.SobjectType ) )
      {
        this.recordTypesBySobjectName.put( rt.SobjectType, new List<RecordType>() );
      }
      this.recordTypesBySobjectName.get( rt.SobjectType ).add( rt );
    }
  }

}