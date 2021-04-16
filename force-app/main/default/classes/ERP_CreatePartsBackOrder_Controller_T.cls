/**
 * Created by dave on 2021-04-13.
 */

@IsTest
private class ERP_CreatePartsBackOrder_Controller_T
{
  private static final Integer PARTS_COUNT = 3;
  private static AcctSeed__Project__c erp;
  private static AcctSeed__Project_Task__c erpTask;
  private static  List<AcctSeedERP__Material__c> materials;
  private static List<Id> materialIds;
  private static CommissionRecord2__c commRec;

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Account customer = Factory_Account.insertCustomerAccounts(1)[0];
    AcctSeedERP__Warehouse__c wh = [SELECT Id, Name FROM AcctSeedERP__Warehouse__c LIMIT 1][0];
    GMBLASERP__Serial_Number__c ser = Factory_SerialNumber.insertFullSerial(
      'Boat',
      'Full Windshield',
      'TEST-FULLWINDSHIELD-0001'
    );
    gcProject.disableTrigger = true;
    gcProjectTask.disableTrigger = true;
    gcMaterial.disableTrigger = true;
    AcctSeed__Project__c retailSale = Factory_ERPOrder.insertRetailBoatSale(
      customer,
      wh,
      DateTime.now().addDays(20),
      ser
    );
    retailSale.GL_Account_Variable_1__c = gcConstants.idGlv1Whitefish;
    retailSale.GL_Account_Variable_2__c = gcConstants.idGlv2Sales;
    retailSale.GL_Account_Variable_3__c = gcConstants.idGlv3Ontario;
    update retailSale;
    AcctSeed__Project_Task__c retailTask = [
      SELECT
        Id
      FROM AcctSeed__Project_Task__c
      WHERE AcctSeed__Project__c = :retailSale.Id
    ];
    List<Product2> parts = Factory_Product.createNonSerializedProducts(
      'Part',
      'Electronics',
      PARTS_COUNT
    );
    Factory_Material.insertMaterials(
      retailSale.Id,
      retailTask.Id,
      parts
    );
  }

  private static void initErpData()
  {
    erp = [
      SELECT
        Id,
        AcctSeed__Account__c,
        AcctSeed__Account__r.Name,
        GMBLASERP__Warehouse__c,
        GL_Account_Variable_1__c,
        GL_Account_Variable_2__c,
        GL_Account_Variable_3__c,
        RecordType.Name,
      ( SELECT
          Id,
          Commission_Calculation_Method__c
        FROM AcctSeed__Project_Tasks__r ),
      ( SELECT
          Id,
          AcctSeedERP__Product__c,
          AcctSeedERP__Product__r.Name,
          AcctSeedERP__Project_Task__c,
          AcctSeedERP__Quantity_Per_Unit__c,
          GMBLASERP__Unit_Price__c,
          GMBLASERP__Price_Override__c,
          AcctSeedERP__Comment__c
      FROM AcctSeedERP__Project_Materials__r
      WHERE AcctSeedERP__Product__r.RecordTypeId = :new Application_RecordType().getProductRecordTypes().getPartId() )
      FROM
        AcctSeed__Project__c
      LIMIT 1][0];
    erpTask = erp.AcctSeed__Project_Tasks__r[0];
    materialIds = new List<Id>();
    materials = new List<AcctSeedERP__Material__c>();
    for( AcctSeedERP__Material__c mat : erp.AcctSeedERP__Project_Materials__r )
    {
      materials.add( mat );
      materialIds.add( mat.Id );
    }
    commRec = new CommissionRecord2__c(
      Project_Task__c = erpTask.Id,
      Calculation_Method__c = erpTask.Commission_Calculation_Method__c
    );
    insert commRec;
  }

  @IsTest
  static void fetchMaterials_Test()
  {
    initErpData();
    Test.startTest();
    Map<String, Object> result = ERP_CreatePartsBackOrder_Controller.fetchMaterials( erp.Id );
    Test.stopTest();

    Utility_Products__c ups = Utility_Products__c.getOrgDefaults();
    List<AcctSeedERP__Material__c> returnedMaterials =
      (List<AcctSeedERP__Material__c>)result.get('materials');
    System.assert( (String)result.get('saleType') == 'retail');
    System.assertEquals( ups.Back_Order_Prepaid__c, (String)result.get('prepaidProductId') );
    System.assertEquals( ups.Back_Order_Credit__c, (String)result.get('creditProductId') );
    System.assertEquals( PARTS_COUNT, returnedMaterials.size() );
  }

  @IsTest
  static void findPartsRequestCases_NoCases_Test()
  {
    initErpData();
    Test.startTest();
    List<case> result = ERP_CreatePartsBackOrder_Controller.findPartsRequestCases(
      erp.Id,
      materialIds
    );
    Test.stopTest();
    System.assert( result.size() == 0 );
  }

  @IsTest
  static void findPartsRequestCases_OneCase_Test()
  {
    initErpData();
    Factory_Case.createPartsRequestCase(
      erp.Id,
      erp.AcctSeed__Account__c,
      materials
    );
    Test.startTest();
    List<case> result = ERP_CreatePartsBackOrder_Controller.findPartsRequestCases(
      erp.Id,
      materialIds
    );
    Test.stopTest();
    System.assertEquals( 1, result.size() );
  }

  @IsTest
  static void findPartsRequestCases_OneCaseAndOneCaseWithoutSelectedMaterial_Test()
  {
    initErpData();
    Factory_Case.createPartsRequestCase(
      erp.Id,
      erp.AcctSeed__Account__c,
      materials
    );
    List<Product2> newParts = Factory_Product.createNonSerializedProducts(
      'Part',
      'Electronics',
      1
    );
    gcMaterial.disableTrigger = true;
    List<AcctSeedERP__Material__c> newMaterial = Factory_Material.insertMaterials(
      erp.Id,
      erpTask.Id,
      newParts
    );
    Factory_Case.createPartsRequestCase(
      erp.Id,
      erp.AcctSeed__Account__c,
      newMaterial
    );
    Test.startTest();
    List<case> result = ERP_CreatePartsBackOrder_Controller.findPartsRequestCases(
      erp.Id,
      materialIds
    );
    Test.stopTest();
    List<Case> cases = [
      SELECT
        Id
      FROM Case
      WHERE ERP_Order__c = :erp.Id
    ];

    System.assertEquals( 2, cases.size() );
    System.assertEquals( 1, result.size() );
  }

  @IsTest
  static void buildBackOrderERP_Test()
  {
    initErpData();
    Test.startTest();
    Map<Id, Decimal> quantityMap = new Map<Id, Decimal>();
    for( AcctSeedERP__Material__c mat : materials )
    {
      quantityMap.put( mat.Id, mat.AcctSeedERP__Quantity_Per_Unit__c );
    }
    Map<String, Object> result = ERP_CreatePartsBackOrder_Controller.buildBackOrderERP(
      erp.Id,
      JSON.serialize( quantityMap ),
      '\'This a Back Order Task from Unit Test\''
    );
    Test.stopTest();
    AcctSeed__Project__c resultERP = (AcctSeed__Project__c)result.get('erp');
    AcctSeed__Project_Task__c resultTask = (AcctSeed__Project_Task__c)result.get('task');
    List<AcctSeedERP__Material__c> resultMaterials =
      (List<AcctSeedERP__Material__c>)result.get('materials');

    System.assert( result != null );
    System.assertEquals( erp.Id, resultERP.Original_ERP__c );
    System.assert( resultERP.Name.contains( erp.AcctSeed__Account__r.Name ) );
    System.assert( resultTask.Name.contains( erp.RecordType.Name ) );
    System.assertEquals( true, resultTask.Locked__c );
    System.assertEquals( (materials.size() + 1), resultMaterials.size() );
  }

  @IsTest
  static void createBackOrderERP_Test()
  {
    initErpData();
    AcctSeed__Project__c newErp = new AcctSeed__Project__c(
      RecordTypeId = new Application_RecordType().getERPOrderRecordTypes().getServiceWorkOrderId(),
      Name = erp.AcctSeed__Account__r.Name + '-Back Order',
      AcctSeed__Account__c = erp.AcctSeed__Account__c,
      GMBLASERP__Warehouse__c = erp.GMBLASERP__Warehouse__c,
      GL_Account_Variable_1__c = erp.GL_Account_Variable_1__c,
      GL_Account_Variable_2__c = erp.GL_Account_Variable_2__c,
      GL_Account_Variable_3__c = erp.GL_Account_Variable_3__c,
      Stage__c = 'Pending Diagnostic',
      Job_Status__c = 'Boat Required',
      Original_ERP__c = erp.Id
    );
    AcctSeed__Project_Task__c newTask = new AcctSeed__Project_Task__c(
      Cause_dh__c = 'This a Back Order Task from Unit Test',
      Name = erp.RecordType.Name + ' - Back Order',
      DisplayOnCustomerInvoice__c = true,
      Locked__c = true
    );
    List<AcctSeedERP__Material__c> newMats = new List<AcctSeedERP__Material__c>();
    Decimal total = 0;
    for( AcctSeedERP__Material__c mat : materials )
    {
      newMats.add( new AcctSeedERP__Material__c(
        AcctSeedERP__Product__c = mat.AcctSeedERP__Product__c,
        AcctSeedERP__Quantity_Per_Unit__c = mat.AcctSeedERP__Quantity_Per_Unit__c,
        GMBLASERP__Unit_Price__c = mat.GMBLASERP__Unit_Price__c,
        GMBLASERP__Price_Override__c = mat.GMBLASERP__Price_Override__c,
        AcctSeedERP__Comment__c = mat.AcctSeedERP__Comment__c
      ));
      total += mat.GMBLASERP__Unit_Price__c * mat.AcctSeedERP__Quantity_Per_Unit__c;
    }
    newMats.add( new AcctSeedERP__Material__c(
      AcctSeedERP__Product__c = Utility_Products__c.getOrgDefaults().Back_Order_Credit__c,
      AcctSeedERP__Quantity_Per_Unit__c = 1,
      GMBLASERP__Unit_Price__c = total,
      GMBLASERP__Price_Override__c = true,
      AcctSeedERP__Comment__c = 'Back Order_Credit'
    ));
    Case c = Factory_Case.createPartsRequestCase(
      erp.Id,
      erp.AcctSeed__Account__c,
      materials
    );

    Test.startTest();
    Map<String, Object> result = ERP_CreatePartsBackOrder_Controller.createBackOrderERP(
      newErp,
      newTask,
      newMats,
      new List<Id>{c.Id}
    );
    Test.stopTest();
    AcctSeed__Project__c resultERP = (AcctSeed__Project__c)result.get('erp');
    AcctSeed__Project_Task__c resultTask = (AcctSeed__Project_Task__c)result.get('task');
    List<AcctSeedERP__Material__c> resultMaterials =
      (List<AcctSeedERP__Material__c>)result.get('materials');

    System.assert( result != null );
    System.assertEquals( erp.Id, resultERP.Original_ERP__c );
    System.assert( resultERP.Name.contains( erp.AcctSeed__Account__r.Name ) );
    System.assert( resultTask.Name.contains( erp.RecordType.Name ) );
    System.assertEquals( true, resultTask.Locked__c );
    System.assertEquals( (materials.size() + 1), resultMaterials.size() );
  }

  @IsTest
  static void buildCommissionLines_Test()
  {
    initErpData();
    Decimal totalSale = 0;
    for( AcctSeedERP__Material__c mat : materials )
    {
      totalSale += mat.GMBLASERP__Unit_Price__c * mat.AcctSeedERP__Quantity_Per_Unit__c;
    }
    Test.startTest();
    List<CommissionLineItem2__c> result =
      ERP_CreatePartsBackOrder_Controller.buildCommissionLines( materials );
    Test.stopTest();

    System.assertEquals( 1, result.size() );
    System.assertEquals( totalSale, result[0].Sale_Price__c );
    System.assertEquals( CommissionLineItem2_Service.grossMarginRate, result[0].Commission_Rate__c );
  }

  @IsTest
  static void updateOriginalSale_Test()
  {
    initErpData();
    Decimal totalSale = 0;
    List<Id> deleteMatIds = new List<Id>();
    for( AcctSeedERP__Material__c mat : materials )
    {
      deleteMatIds.add( mat.Id );
      totalSale += mat.GMBLASERP__Unit_Price__c * mat.AcctSeedERP__Quantity_Per_Unit__c;
    }
    List<AcctSeedERP__Material__c> newMats = new List<AcctSeedERP__Material__c>();
    newMats.add( new AcctSeedERP__Material__c(
      AcctSeedERP__Product__c = Utility_Products__c.getOrgDefaults().Back_Order_Prepaid__c,
      AcctSeedERP__Project__c = erp.Id,
      AcctSeedERP__Project_Task__c = erpTask.Id,
      AcctSeedERP__Quantity_Per_Unit__c = 1,
      GMBLASERP__Unit_Price__c = totalSale,
      GMBLASERP__Price_Override__c = true,
      AcctSeedERP__Comment__c = 'Prepaid Back Ordered Items'
    ));
    List<CommissionLineItem2__c> commLines = new List<CommissionLineItem2__c>();
    commLines.add( new CommissionLineItem2__c(
      Comment__c = 'Parts Back Order Entry',
      CommissionRecord2__c = commRec.Id,
      Cost__c = 0,
      Sale_Price__c = totalSale,
      Description__c = 'Parts Back Order Entry',
      Labour_Cost__c = 0,
      Quantity__c = 1,
      Commission_Rate__c = CommissionLineItem2_Service.grossMarginRate
    ));

    Test.startTest();
    ERP_CreatePartsBackOrder_Controller.updateOriginalSale(
      deleteMatIds,
      newMats,
      commLines
    );
    Test.stopTest();

    List<AcctSeedERP__Material__c> mats = [
      SELECT
        Id,
        AcctSeedERP__Product__r.Name
      FROM AcctSeedERP__Material__c
      WHERE AcctSeedERP__Project__c = :erp.Id
    ];
    //one for the boat, one for the back order prepaid
    System.debug( mats[0].AcctSeedERP__Product__r.Name );
    System.assertEquals( 2, mats.size() );
  }

}