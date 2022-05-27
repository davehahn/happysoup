/* TODO: Move to Application Constants */

public without sharing class LGND_Constants {
  public class LGND_Constants_Exception extends Exception {}
  public static String WarrantyPayableTaskName = 'Warranty Payable';
  public static String WarrantyRecoverableTaskName = 'Warranty Recoverable';

  public static Boolean runningInASandbox {
    get {
      if( runningInASandbox == null )
      {
        runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
      }
      return runningInASandbox;
    }
    set;
  }

  /* Labour Rates */
  public static final Decimal retailLabourRate
  {
    get
    {
      if( retailLabourRate == null )
      {
        try
        {
          Labour_Rate__mdt rate = [SELECT Hourly_Rate__c FROM Labour_Rate__mdt WHERE DeveloperName = 'Retail'];
          retailLabourRate = rate.Hourly_Rate__c;
        }
        catch( Exception e )
        {
          throw new LGND_Constants.LGND_Constants_Exception('No Retail Labour Rate set.  Please have your administrator set a Retail Labour rate in Labour Rates Custom Metadata Type');
        }
      }
      return retailLabourRate;
    }
    set;
  }

  public static Set<String> mercuryDiscountBoatIds {
    get {
      if( mercuryDiscountBoatIds == null )
      {
        mercuryDiscountBoatIds = new Set<String>();
        for( Mercury_Discount_Boats__c mdb : Mercury_Discount_Boats__c.getAll().values() )
        {
          mercuryDiscountBoatIds.add( mdb.boatId__c );
        }
      }
      return mercuryDiscountBoatIds;
    }
    private set;
  }


  public static Id partnerAdminProfileId {
  	get {
  		if( partnerAdminProfileId == null )
  			partnerAdminProfileId = [SELECT Id FROM Profile WHERE Name = 'Legend Partner' LIMIT 1].Id;
  		return partnerAdminProfileId;
  	}
  	private set;
  }

  /* SPECIAL PRODUCTS ++++++++++++++++... */
  public static Id ppsaProductId {
    get {
      if( ppsaProductId == null )
      {
        try
        {
          ppsaProductId = [
            SELECT Id
            FROM Product2
            WHERE Family = 'Bank Registration PPSA Fee'
            AND RecordTypeId = :productRtId_Fees
          ].Id;
        }
        catch( Exception e )
        {
          throw new LGND_Constants_Exception('A PPSA Product was not found. Please contact your administrator with this error and where you encountered it');
        }
      }
      return ppsaProductId;
    }
    private set;
  }

  public static Id savingsProductId {
    get {
      if( savingsProductId == null )
        savingsProductId = Utility_Products__c.getOrgDefaults().Savings__c;
      return savingsProductId;
    }
    private set;
  }

  public static Id partnerCustomProductId {
    get {
      if( partnerCustomProductId == null )
        partnerCustomProductId = Utility_Products__c.getOrgDefaults().Partner_Custom_Product__c;
      if( partnerCustomProductId == null )
        throw new LGND_Constants_Exception('Partner Custom Product is not setup.  Please contact an administrator to get this rectified');
      return partnerCustomProductId;
    }
    private set;
  }

  public static Id partnerWarrantyLabourProductId {
    get {
      if( partnerWarrantyLabourProductId == null )
        partnerWarrantyLabourProductId = Utility_Products__c.getOrgDefaults().Partner_Warranty_Labour__c;
      if( partnerWarrantyLabourProductId == null )
        throw new LGND_Constants_Exception('Partner Warranty Labour Product is not setup.  Please contact an administrator to get this rectified');
      return partnerWarrantyLabourProductId;
    }
    private set;
  }

  /* ACCOUNT RECORD TYPES ++++++++++++ .. */

  private static Application_RecordType.AccountRTs accountRTs;

  public static Id accountRtId_Dealer {
    get {
      if(accountRTs == null)
      {
        accountRTs = new Application_RecordType.AccountRTs();
      }
      return accountRTs.getDealerId();
    }
    set;
  }

//  private static void fetchAccountRecordTypes()
//  {
//    for(RecordType rt : [ SELECT Id, DeveloperName, SobjectType
//                          FROM RecordType
//                          WHERE SobjectType = 'Account' ])
//    {
//      if( rt.DeveloperName == 'Dealer' )
//        accountRtId_Dealer = rt.Id;
//    }
//  }

  /* CASE RECORD TYPES */

  private static Application_RecordType.CaseRTs caseRTs;

  public static Id caseRtId_Promotion {
    get {
      if(caseRTs == null)
      {
        caseRTs = new Application_RecordType.CaseRTs();
      }
      return caseRTs.getPromotionId();
    }
  }

  public static Id caseRtId_Warranty {
    get {
      if(caseRTs == null)
      {
        caseRTs = new Application_RecordType.CaseRTs();
      }
      return caseRTs.getWarrantyId();
    }
  }

//  private static void fetchCaseRecordTypes()
//  {
//    for(RecordType rt : [ SELECT Id, DeveloperName, SobjectType
//    FROM RecordType
//    WHERE SobjectType = 'Case' ])
//    {
//      if( rt.DeveloperName == 'Promotion' )
//        caseRtId_Promotion = rt.Id;
//      if( rt.DeveloperName == 'Warranty' )
//        caseRtId_Warranty = rt.Id;
//    }
//  }

  /* ++++++++++++++++++ PRICEBOOKS +++++++++++++++++++++ */

  public static Id retailPricebookId {
    get {
      if( retailPricebookId == null )
      {
        retailPricebookId = Application_Constants.getInstance().activePricebooks.retailId;
      }
      return retailPricebookId;
    }
    set;
  }

  public static Id partnerPricebookId {
    get {
      if( partnerPricebookId == null )
      {
        partnerPricebookId =Application_Constants.getInstance().activePricebooks.partnerId;
      }
      return partnerPricebookId;
    }
    set;
  }

  public static Id factoryPricebookId {
    get {
      if( factoryPricebookId == null )
      {
        factoryPricebookId = Application_Constants.getInstance().activePricebooks.factoryId;
      }
      return factoryPricebookId;
    }
    set;
  }

  public static Id standardPricebookId {
    get {
      if( standardPricebookId == null )
      {
        if( Test.isRunningTest() )
          standardPricebookId = Test.getStandardPricebookId();
        else
          standardPricebookId = [SELECT Id FROM Pricebook2 WHERE isStandard = true].Id;
      }
      return standardPricebookId;
    }
    private set;
  }

  /* +++++++++++++++++ GOOGLE API KEYS +++++++++++++++++++++++ */

  public static String googleMapsAPI_Key
  {
    get
    {
      if( googleMapsAPI_Key == null )
        fetchGoogleAPIKeys();
      if( googleMapsAPI_Key == null )
        throw new LGND_Utilities.LGND_Exception('A Google API Key with Name [Maps] does not exist.');
      return googleMapsAPI_Key;
    }
    private set;
  }

  private static void fetchGoogleAPIKeys()
  {
    for( GoogleAPIKey__mdt gKey : [ SELECT DeveloperName, Key__c FROM GoogleAPIKey__mdt ] )
    {
      if( gKey.DeveloperName == 'Maps' )
        googleMapsAPI_Key = gKey.Key__c;
    }
  }

  /* +++++++++++++++++ PRODUCT RECORD TYPES ++++++++++++++++++ */

  private static Application_RecordType.ProductRTs productRTs;

  public static Id productRtId_Boat{
    get {
      if(productRTs == null)
      {
        productRTs = new Application_RecordType.ProductRTs();
      }
      return productRTs.getBoatId();
    }
    set;
  }

  public static Id productRtId_Trailer{
    get {
      if(productRTs == null)
      {
        productRTs = new Application_RecordType.ProductRTs();
      }
      return productRTs.getTrailerId();
    }
    set;
  }

  public static Id productRtId_Motor{
    get {
      if(productRTs == null)
      {
        productRTs = new Application_RecordType.ProductRTs();
      }
      return productRTs.getMotorId();
    }
    set;
  }

  public static Id productRtId_TrollingMotor{
    get {
      if(productRTs == null)
      {
        productRTs = new Application_RecordType.ProductRTs();
      }
      return productRTs.getTrollingMotorId();
    }
    set;
  }

  public static Id productRtId_Part{
    get {
      if(productRTs == null)
      {
        productRTs = new Application_RecordType.ProductRTs();
      }
      return productRTs.getPartId();
    }
    set;
  }

  public static Id productRtId_Bundle{
    get {
      if(productRTs == null)
      {
        productRTs = new Application_RecordType.ProductRTs();
      }
      return productRTs.getPackageBundleId();
    }
    set;
  }

  public static Id productRtId_Protection{
    get {
      if(productRTs == null)
      {
        productRTs = new Application_RecordType.ProductRTs();
      }
      return productRTs.getProtectionAndServiceId();
    }
    set;
  }

  public static Id productRtId_Insurance{
    get {
      if(productRTs == null)
      {
        productRTs = new Application_RecordType.ProductRTs();
      }
      return productRTs.getInsuranceId();
    }
    set;
  }

  public static Id productRtId_Fees{
    get {
      if(productRTs == null)
      {
        productRTs = new Application_RecordType.ProductRTs();
      }
      return productRTs.getFeesId();
    }
    set;
  }

//  private static void fetchProductRecordTypes()
//  {
//    for(RecordType rt :
//      [SELECT Id, DeveloperName, SobjectType
//       FROM RecordType
//       WHERE (SobjectType = 'Product2' AND
//          (DeveloperName = 'Boat' OR
//           DeveloperName = 'Trailer' OR
//           DeveloperName = 'Motor' OR
//           DeveloperName = 'Trolling_Motor' OR
//           DeveloperName = 'Part' OR
//           DeveloperName = 'Package_Bundle' OR
//           DeveloperName = 'Protection_and_Services' OR
//           DeveloperName = 'Insurance' OR
//           DeveloperName = 'Fees'))])
//    {
//      if(rt.SobjectType == 'Product2')
//      {
//        if(rt.DeveloperName == 'Boat')
//          productRtId_Boat = rt.Id;
//        else if(rt.DeveloperName == 'Trailer')
//          productRtId_Trailer = rt.Id;
//        else if(rt.DeveloperName == 'Motor')
//          productRtId_Motor = rt.Id;
//        else if(rt.DeveloperName == 'Trolling_Motor')
//          productRtId_TrollingMotor = rt.Id;
//        else if(rt.DeveloperName == 'Part')
//          productRtId_Part = rt.Id;
//        else if(rt.DeveloperName == 'Package_Bundle')
//          productRtId_Bundle = rt.Id;
//        else if(rt.DeveloperName == 'Protection_and_Services')
//          productRtId_Protection = rt.Id;
//        else if(rt.DeveloperName == 'Insurance')
//          productRtId_Insurance = rt.Id;
//        else if(rt.DeveloperName == 'Fees')
//          productRtId_Fees = rt.Id;
//      }
//    }
//  }

  /* GLV2's */

  public static Id GLV2Id_AccountingAndAdmin {
    get {
      if( GLV2Id_AccountingAndAdmin == null ) fetchGLV2s();
      return GLV2Id_AccountingAndAdmin;
    }
    set{
      GLV2Id_AccountingAndAdmin = value;
    }
  }

  public static Id GLV2Id_BusinessOffice {
    get {
      if( GLV2Id_BusinessOffice == null ) fetchGLV2s();
      return GLV2Id_BusinessOffice;
    }
    set{
      GLV2Id_BusinessOffice = value;
    }
  }

  public static Id GLV2Id_IT {
    get {
      if( GLV2Id_IT == null ) fetchGLV2s();
      return GLV2Id_IT;
    }
    set{
      GLV2Id_IT = value;
    }
  }

  public static Id GLV2Id_Logistics {
    get {
      if( GLV2Id_Logistics == null ) fetchGLV2s();
      return GLV2Id_Logistics;
    }
    set{
      GLV2Id_Logistics = value;
    }
  }

  public static Id GLV2Id_Marketing {
    get {
      if( GLV2Id_Marketing == null ) fetchGLV2s();
      return GLV2Id_Marketing;
    }
    set{
      GLV2Id_Marketing = value;
    }
  }

  public static Id GLV2Id_PartsAndService {
    get {
      if( GLV2Id_PartsAndService == null ) fetchGLV2s();
      return GLV2Id_PartsAndService;
    }
    set{
      GLV2Id_PartsAndService = value;
    }
  }

  public static Id GLV2Id_Production {
    get {
      if( GLV2Id_Production == null ) fetchGLV2s();
      return GLV2Id_Production;
    }
    set{
      GLV2Id_Production = value;
    }
  }

  public static Id GLV2Id_Sales {
    get {
      if( GLV2Id_Sales == null ) fetchGLV2s();
      return GLV2Id_Sales;
    }
    set{
      GLV2Id_Sales = value;
    }
  }

  public static Id GLV2Id_Warranty {
    get {
      if( GLV2Id_Warranty == null ) fetchGLV2s();
      return GLV2Id_Warranty;
    }
    set{
      GLV2Id_Warranty = value;
    }
  }

  private static void fetchGLV2s()
  {
    for( AcctSeed__Accounting_Variable__c var : [ SELECT Id, Name FROM AcctSeed__Accounting_Variable__c WHERE AcctSeed__Type__c = 'GL Account Variable 2'] )
    {
      if( var.Name == 'Accounting & Admin' )
        GLV2Id_AccountingAndAdmin = var.Id;
      if( var.Name == 'Business Office' )
        GLV2Id_BusinessOffice = var.Id;
      if( var.Name == 'IT' )
        GLV2Id_IT = var.Id;
      if( var.Name == 'Logistics' )
        GLV2Id_Logistics = var.Id;
      if( var.Name == 'Marketing' )
        GLV2Id_Marketing = var.Id;
      if( var.Name == 'Parts + Service' )
        GLV2Id_PartsAndService = var.Id;
      if( var.Name == 'Production' )
        GLV2Id_Production = var.Id;
      if( var.Name == 'Sales' )
        GLV2Id_Sales = var.Id;
      if( var.Name == 'Warranty' )
        GLV2Id_Warranty = var.Id;
    }
  }


}