/**
 * Created by dave on 2020-12-30.
 */

@IsTest
private class Application_RecordType_T
{

  static List<RecordType> rts;

  private static void fetchRecords( String sObjectName )
  {
    rts = [
      SELECT
        Id,
        DeveloperName
      FROM RecordType
      WHERE SobjectType = :sObjectName
      AND IsActive = true
    ];
  }

  @IsTest
  static void getDeveloperNameById_Test(){
    fetchRecords('Product2');
    Test.startTest();
    String rtName = new Application_RecordType().getDeveloperNameById( rts[0].Id );
    Test.stopTest();

    System.assertEquals( rts[0].DeveloperName, rtName );
  }

  @IsTest
  static void getIdFromDeveloperName_InvalidName_Test()
  {
    Application_RecordType.AccountRTs  resultRTs=
      new Application_RecordType().getAccountRecordTypes();
    String fakeRT = 'InvalidName';
    String err = 'A record type with API Name [' + fakeRT + '] for Account does not exist.';
    try
    {
      Id failedId = resultRTs.getIdFromDeveloperName(fakeRT);
    }
    catch( Exception e )
    {
      System.assertEquals( err, e.getMessage() );
    }



  }

  @IsTest
  static void AccountRecordTypes_Test()
  {
    fetchRecords( 'Account' );

    Test.startTest();
    Application_RecordType.AccountRTs  resultRTs=
      new Application_RecordType().getAccountRecordTypes();
    Test.stopTest();

    System.assertEquals( rts.size(), resultRTs.getRecordTypeCount() );
    System.assert( resultRTs.getBusinessAccountId() != null );
    System.assert( resultRTs.getDealerId() != null );
    System.assert( resultRTs.getGeoHackId() != null );
    System.assert( resultRTs.getPersonAccountId() != null );
    System.assert( resultRTs.getSupplierId() != null );
  }

  @IsTest
  static void CaseRecordTypes_Test()
  {
    fetchRecords( 'Case' );

    Test.startTest();
    Application_RecordType.CaseRTs  resultRTs=
      new Application_RecordType().getCaseRecordTypes();
    Test.stopTest();

    System.assertEquals( rts.size(), resultRTs.getRecordTypeCount() );
    System.assert( resultRTs.getCustomerCommunityId() != null );
    System.assert( resultRTs.getPartOrderRequestId() != null );
    System.assert( resultRTs.getPartInquiryId() != null );
    System.assert( resultRTs.getPartnerSupportId() != null );
    System.assert( resultRTs.getPromotionId() != null );
    System.assert( resultRTs.getReportRequestId() != null );
    System.assert( resultRTs.getServiceAppointmentId() != null );
    System.assert( resultRTs.getSupportCaseId() != null );
    System.assert( resultRTs.getTranslationId() != null );
    System.assert( resultRTs.getWarrantyId() != null );
    System.assert( resultRTs.getWarrantyReturnId() != null );
  }

  @IsTest
  static void ERPOrderRecordTypes_Test()
  {
    fetchRecords( 'AcctSeed__Project__c' );

    Test.startTest();
    Application_RecordType.ERPOrderRTs resultRTs =
      new Application_RecordType().getERPOrderRecordTypes();
    Test.stopTest();

    System.assertEquals( rts.size(), resultRTs.getRecordTypeCount() );
    System.assert( resultRTs.getCounterSaleId() != null );
    System.assert( resultRTs.getFixedAssetId() != null );
    System.assert( resultRTs.getManufacturingId() != null );
    System.assert( resultRTs.getPartnerPartsOrderId() != null );
    System.assert( resultRTs.getServiceWorkOrderId() != null );
    System.assert( resultRTs.getTradeInId() != null );
    System.assert( resultRTs.getWarrantyId() != null );
    System.assert( resultRTs.getPartnerBoatSaleId() != null );
    System.assert( resultRTs.getProjectId() != null );
    System.assert( resultRTs.getRetailBoatSaleId() != null );
  }

  @IsTest
  static void OpportunityRecordTypes_Test()
  {
    fetchRecords( 'Opportunity' );

    Test.startTest();
    Application_RecordType.OpportunityRTs resultRTs =
      new Application_RecordType().getOpportunityRecordTypes();
    Test.stopTest();

    System.assertEquals( rts.size(), resultRTs.getRecordTypeCount() );
    System.assert( resultRTs.getOnlineId() != null );
    System.assert( resultRTs.getPartnerRetailBoatSaleId() != null );
    System.assert( resultRTs.getRetailId() != null );
  }

  @IsTest
  static void PricebookRecordTypes_Test()
  {
    fetchRecords( 'Pricebook2' );

    Test.startTest();
    Application_RecordType.PriceBookRTs resultRTs =
      new Application_RecordType().getPricebookRecordTypes();
    Test.stopTest();

    System.assertEquals( rts.size(), resultRTs.getRecordTypeCount() );
    System.assert( resultRTs.getDealerId() != null );
    System.assert( resultRTs.getFactoryId() != null );
    System.assert( resultRTs.getSalesId() != null );
    System.assert( resultRTs.getSupplierId() != null );
  }

  @IsTest
  static void ProductRecordTypes_Test()
  {
    fetchRecords( 'Product2' );

    Test.startTest();
    Application_RecordType.ProductRTs resultRTs =
      new Application_RecordType().getProductRecordTypes();
    Test.stopTest();

    System.assertEquals( rts.size(), resultRTs.getRecordTypeCount() );
    System.assert( resultRTs.getBoatId() != null );
    System.assert( resultRTs.getFeesId() != null );
    System.assert( resultRTs.getInsuranceId() != null );
    System.assert( resultRTs.getInternalId() != null );
    System.assert( resultRTs.getLabourId() != null );
    System.assert( resultRTs.getMotorId() != null );
    System.assert( resultRTs.getPackageBundleId() != null );
    System.assert( resultRTs.getPartId() != null );
    System.assert( resultRTs.getPrepaidPackageId() != null );
    System.assert( resultRTs.getProtectionAndServiceId() != null );
    System.assert( resultRTs.getTrailerId() != null );
    System.assert( resultRTs.getTrollingMotorId() != null );
  }

  @IsTest
  static void SystemIssuesRecordTypes_Test()
  {
    fetchRecords( 'System_Issue__c' );

    Test.startTest();
    Application_RecordType.SystemIssueRTs  resultRTs=
      new Application_RecordType().getSystemIssueRecordTypes();
    Test.stopTest();

    System.assertEquals( rts.size(), resultRTs.getRecordTypeCount() );
    System.assert( resultRTs.getStandardId() != null );
    System.assert( resultRTs.getEpicId() != null );
  }
//  @IsTest
//  static void WorkOrderRecordTypes_Test()
//  {
//    fetchRecords( 'WorkOrder' );
//
//    Test.startTest();
//    Application_RecordType.WorkOrderRTs resultRTs =
//      new Application_RecordType().getWorkOrderRecordTypes();
//    Test.stopTest();
//
//    System.assertEquals( rts.size(), resultRTs.getRecordTypeCount() );
//    System.assert( resultRTs.getManufacturingId() != null );
//    System.assert( resultRTs.getPartnerSaleId() != null );
//    System.assert( resultRTs.getRetailSaleId() != null );
//    System.assert( resultRTs.getRetailServiceId() != null );
//    System.assert( resultRTs.getWholesaleServiceId() != null );
//  }
}