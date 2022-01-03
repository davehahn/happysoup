@isTest
private class ERPOrder_CreatePartsRequest_Test {

  static Account customer;
  static GMBLASERP__Serial_Number__c serial;
  static AcctSeedERP__Warehouse__c whitefishWarehouse;
  static AcctSeed__Project__c serviceOrder;
  static Integer materialCount = 5;
  static AcctSeedERP__Material__c[] mats;
  static Case theCase;

	@testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void init()
  {
    customer = Factory_Account.insertFullPersonAccount('fName', 'lName');
    serial = Factory_SerialNumber.insertFullSerials( 1, 'Boat', 'Pontoon')[0];
    whitefishWarehouse = [ SELECT Id, Name, GL_Account_Variable_3__c
                           FROM AcctSeedERP__Warehouse__c
                           WHERE Name LIKE '%Whitefish%'
                           LIMIT 1 ];
    serviceOrder = Factory_ERPOrder.insertServiceOrders( customer,
                                                         whitefishWarehouse,
                                                         DateTime.now(),
                                                         new List<GMBLASERP__Serial_Number__c>{serial} )[0];
  }

  private static AcctSeedERP__Material__c[] addMaterials()
  {
    AcctSeed__Project_Task__c task = Factory_ERPOrder.buildProjectTask( serviceOrder.Id, 'Testing Task' );
    insert task;
    Product2[] parts = Factory_Product.buildNonSerializedProducts( 'Part', 'Hardware', materialCount);
    insert parts;
    mats = Factory_ERPOrder.buildMaterials( serviceOrder.Id,
                                            task.Id,
                                            parts );
    insert mats;
    return mats;
  }

  private static void createCase()
  {
    Id caseRtId = LGND_Utilities.recordTypeIdFromName('Case', 'Part Order Request');
    theCase = new Case(
      AccountId = serviceOrder.AcctSeed__Account__c,
      ERP_Order__c = serviceOrder.Id,
      RecordTypeId = caseRtId,
      Parts_Request_Notes__c = 'test note'
    );
    insert theCase;
    Case_Part__c[] cps = new List<Case_Part__c>();
    for( AcctSeedERP__Material__c m : mats )
    {
      cps.add( new Case_Part__c(
        Case__c = theCase.Id,
        Product__c = m.AcctSeedERP__Product__c,
        Quantity__c = m.AcctSeedERP__Quantity_Per_Unit__c,
        Material__c = m.Id
      ) );
    }
    insert cps;
  }

  @isTest
  static void getInitialData_test()
  {
    init();
    String jsonResult = ERPOrder_CreatePartsRequestController.getInitialData( serviceOrder.Id );
    Map<String, String> result = (Map<String, String>)JSON.deserialize( jsonResult,
                                                                        Map<String, String>.class );
    AcctSeed__Project__c erp =
      (AcctSeed__Project__c)JSON.deserialize( result.get('erp'), AcctSeed__Project__c.class );

    System.assertEquals( serviceOrder.Id, erp.Id );
  }

  @isTest
  static void getInitialData_WithCase_test()
  {
    init();
    addMaterials();
    createCase();
    String jsonResult = ERPOrder_CreatePartsRequestController.getInitialData( serviceOrder.Id );
    Map<String, String> result = (Map<String, String>)JSON.deserialize( jsonResult,
                                                                        Map<String, String>.class );
    AcctSeed__Project__c erp =
      (AcctSeed__Project__c)JSON.deserialize( result.get('erp'), AcctSeed__Project__c.class );
    ERPOrder_CreatePartsRequestController.CaseWrapper[] c_wrappers =
      (List<ERPOrder_CreatePartsRequestController.CaseWrapper>)JSON.deserialize( result.get('cases'),
                                                                                 List<ERPOrder_CreatePartsRequestController.CaseWrapper>.class );

    System.assertEquals( serviceOrder.Id, erp.Id );
    System.assertEquals( 1, c_wrappers.size() );
    System.assertEquals( theCase.Id, c_wrappers[0].caseId );
    System.assertEquals( materialCount, c_wrappers[0].caseParts.size() );
  }

  @isTest
  static void getMaterials_test()
  {
    init();
    addMaterials();
    String jsonResult = ERPOrder_CreatePartsRequestController.getMaterials( serviceOrder.Id );
    ERPOrder_CreatePartsRequestController.PartWrapper[] result =
      (List<ERPOrder_CreatePartsRequestController.PartWrapper>)JSON.deserialize( jsonResult,
                                                                                 List<ERPOrder_CreatePartsRequestController.PartWrapper>.class);

    System.assertEquals( materialCount, result.size() );
  }

  @isTest
  static void createPartsRequestCase_test()
  {
    Test.startTest();
    String note = 'This is a test note';
    init();
    AcctSeedERP__Material__c[] mats = addMaterials();
    Case_Part__c[] caseParts = new List<Case_Part__c>();
    for( AcctSeedERP__Material__c mat : mats )
    {
      caseParts.add( new Case_Part__c(
        Product__c = mat.AcctSeedERP__Product__c,
        Material__c = mat.Id,
        Quantity__c = mat.AcctSeedERP__Quantity_Per_Unit__c
      ));
    }
    ERPOrder_CreatePartsRequestController.createPartsRequestCase( JSON.serialize( caseParts ),
                                                                  serviceOrder.Id,
                                                                  note );
    Test.stopTest();
    Case partsRequestCase = [SELECT Id,
                                    ERP_Order__c,
                                    AccountId,
                                    Parts_Request_Notes__c
                             FROM Case
                             WHERE ERP_Order__c = :serviceOrder.Id];
    System.assertEquals( partsRequestCase.ERP_Order__c, serviceOrder.Id );
    System.assertEquals( partsRequestCase.AccountId, customer.Id );
    System.assertEquals( partsRequestCase.Parts_Request_Notes__c, note);
  }


}