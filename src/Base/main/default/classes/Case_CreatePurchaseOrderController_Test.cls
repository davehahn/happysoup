@isTest
private with sharing class Case_CreatePurchaseOrderController_Test {

  static Case theCase;
  static Case_Part__c[] caseParts;
  static Integer partCount = 5;
  static AcctSeedERP__Purchase_Order__c  po;
  static AcctSeedERP__Purchase_Order_Line__c pol;
  static Product2[] parts;
  static Account supplier;
  static Account shipper;
  static Account dealer;
  static AcctSeed__Project__c serviceOrder;
  static AcctSeed__Project__c partsOrder;
  static AcctSeedERP__Warehouse__c whitefishWarehouse;
  static final Date eta = Date.today().addDays(10);

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void setWareHouse() {
    whitefishWarehouse = [ SELECT Id, Name, GL_Account_Variable_3__c
                           FROM AcctSeedERP__Warehouse__c
                           WHERE Name LIKE '%Whitefish%'
                           LIMIT 1 ];
  }

  private static void initPartsOrder()
  {
    Application_RecordType appRecordTypes = new Application_RecordType();
    supplier = Factory_Account.insertSupplierAccounts(1)[0];
    dealer = Factory_Account.insertDealerAccounts(1)[0];
    parts = Factory_Product.buildNonSerializedProducts('Part', 'Electronics', partCount );
    for( Product2 p : parts )
    {
      p.AcctSeedERP__Default_Vendor__c = supplier.Id;
    }
    insert parts;
    //Parts ERP
    Boolean orig = gcProject.disableTrigger;
    gcProject.disableTrigger = true;
    partsOrder = Factory_ERPOrder.insertPartnerPartsOrder( dealer, Test_Constants.idWarehouse );
    gcProject.disableTrigger = orig;
    //Parts Task
    AcctSeed__Project_Task__c task = Factory_ERPOrderTask.buildProjectTask(
      partsOrder.Id,
      'Test Parts Order'
    );
    insert task;
    //Parts ERP Materials
    AcctSeedERP__Material__c mat = Factory_ERPOrder.buildMaterial(
      partsOrder.Id,
      task.Id,
      parts[0].Id
    );
    insert mat;
    //Case
    theCase = new Case(
      RecordTypeId = appRecordTypes.getCaseRecordTypes().getPartOrderRequestId(),
      Parts_Request_Notes__c = 'test note',
      ERP_Order__c = partsOrder.Id
    );
    insert theCase;
    //Case Parts
    caseParts = new List<Case_Part__c>();
    caseParts.add( new Case_Part__c(
      Product__c = parts[0].Id,
      Quantity__c = 1,
      Case__c = theCase.Id
    ));
    insert caseParts;
    //PO and PO Line
    po = Factory_PurchaseOrder.createMinimalPO( supplier.Id, null );
    pol = Factory_PurchaseOrder.buildLineItem(
      po.Id,
      parts[0].Id,
      10
    );
    pol.deliverDate__c = eta;
    insert pol;
  }

  private static void init( Boolean addPartsSupplier)
  {
    supplier = Factory_Account.insertSupplierAccounts(1)[0];
    shipper  = Factory_Account.insertDealerAccounts(1)[0];
    GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertFullSerials( 1, 'Boat', 'Pontoon')[0];
    Boolean orig = gcProject.disableTrigger;
    gcProject.disableTrigger = true;
    serviceOrder = Factory_ERPOrder.insertServiceOrders( shipper,
                                                         whitefishWarehouse,
                                                         DateTime.now(),
                                                         new List<GMBLASERP__Serial_Number__c>{serial} )[0];
    gcProject.disableTrigger = orig;
    Id caseRtId = LGND_Utilities.recordTypeIdFromName('Case', 'Part Order Request');
    theCase = new Case(
      RecordTypeId = caseRtId,
      Parts_Request_Notes__c = 'test note',
      ERP_Order__c = serviceOrder.Id
    );
    insert theCase;
    parts = Factory_Product.buildNonSerializedProducts('Part', 'Electronics', partCount );
    if( addPartsSupplier )
    {
      for( Product2 p : parts )
      {
        p.AcctSeedERP__Default_Vendor__c = supplier.Id;
      }
    }
    insert parts;
    caseParts = new List<Case_Part__c>();
    for( Product2 p : parts )
    {
      caseParts.add( new Case_Part__c(
        Product__c = p.Id,
        Quantity__c = 1,
        Case__c = theCase.Id
      ));
    }
    insert caseParts;
  }

  private static void initPO( Boolean withLines )
  {
    AcctSeedERP__Warehouse__c wh = [ SELECT Id,
                                            Name,
                                            GL_Account_Variable_3__c
                                     FROM AcctSeedERP__Warehouse__c
                                     LIMIT 1 ];
    AcctSeed__Ledger__c ledger = [SELECT Id
                                  FROM AcctSeed__Ledger__c
                                  LIMIT 1];
    AcctSeed__Billing_Format__c pdfFormat = [SELECT Id
                                             FROM AcctSeed__Billing_Format__c
                                             LIMIT 1];
    po = new AcctSeedERP__Purchase_Order__c(
      AcctSeedERP__Order_Date__c = Date.today(),
      Warehouse__c = wh.Id,
      AcctSeedERP__Purchase_Order_Format__c = pdfFormat.Id,
      AcctSeedERP__Vendor__c = supplier.Id,
      AcctSeedERP__Shipping_Company__c = shipper.Id,
      AcctSeedERP__Ledger__c = ledger.Id,
      AcctSeedERP__Comment__c = 'Test Comment',
      Internal_Notes__c = 'Test Notes',
      Parts_Request_Case__c = theCase.Id
    );
    insert po;
    if( withLines )
    {
      Map<String, AcctSeedERP__Purchase_Order_Line__c> pols = new Map<String, AcctSeedERP__Purchase_Order_Line__c>();
      for( Case_Part__c cp : caseParts )
      {
        pols.put( cp.Id, new AcctSeedERP__Purchase_Order_Line__c(
          AcctSeedERP__Product__c = cp.Product__c,
          AcctSeedERP__Quantity__c = cp.Quantity__c,
          AcctSeedERP__Purchase_Order__c = po.Id
        ));
      }
      insert pols.values();
      Case_Part__c[] caseParts = new List<Case_Part__c>();
      for( String casePartId : pols.keySet() )
      {
        caseParts.add( new Case_Part__c(
          Id = casePartId,
          Purchase_Order_Line__c = pols.get( casePartId ).Id
        ));
      }
      update caseParts;
    }
  }

  @isTest
  static void checkForPo_Empty_Test()
  {
    setWareHouse();
    init(false);
    Integer result = Case_CreatePurchaseOrderController_dh.checkForParts( theCase.Id );
    System.assertEquals( partCount, result );
  }

  @isTest
  static void checkForPo_wPO_Test()
  {
    setWareHouse();
    init(false);
    initPO(true);
    theCase.Purchase_Order__c = po.Id;
    update theCase;

    Integer result = Case_CreatePurchaseOrderController_dh.checkForParts( theCase.Id );
    System.assertEquals( 0, result );
  }

  @isTest
  static void fetchInitialPoData_Test()
  {
    setWareHouse();
    User wfUser = Factory_User.newUser('Fname',
                                       'Lname',
                                       'System Administrator',
                                       whitefishWarehouse);
    System.runAs( wfUser )
    {
      init(true);
      String jsonResult = Case_CreatePurchaseOrderController_dh.fetchInitialPoData( theCase.Id );
      Map<String, String> result =
        (Map<String, String>)JSON.deserialize( jsonResult, Map<String, String>.class);
      String warehouseId = result.get('userWarehouse');
      String vendorsJSON = result.get('vendors');
      List<Case_CreatePurchaseOrderController_dh.Vendor> vendors =
        (List<Case_CreatePurchaseOrderController_dh.Vendor>)JSON.deserialize( vendorsJSON,
                                                                              List<Case_CreatePurchaseOrderController_dh.Vendor>.class );
      //System.debug( 'warehouseId = ' + warehouseId );
      //System.debug( 'whitefishWarehouseId = ' + whitefishWarehouse.Id);
      System.assertEquals( warehouseId, whitefishWarehouse.Id );
      System.assertEquals( 1, vendors.size() );
      System.assertEquals( partCount, vendors[0].caseParts.size() );
    }
  }

  @isTest
  static void createPOlinesAndUdateCase_withoutProductUpdate_Test()
  {
    setWareHouse();
    init(true);
    initPO(false);
    List<String> cpIds = new List<String>();
    for( Case_Part__c cp : caseParts ){
      cpIds.add( cp.Id );
    }
    Case_CreatePurchaseOrderController_dh.createPOlinesAndUdateCase( cpIds,
                                                                     po.Id,
                                                                     false );
    caseParts = [SELECT Id, Purchase_Order_Line__c
                      FROM Case_Part__c
                      WHERE Id IN :cpIds ];
    AcctSeedERP__Purchase_Order_Line__c[] pols = [SELECT Id
                                                  FROM AcctSeedERP__Purchase_Order_Line__c
                                                  WHERE AcctSeedERP__Purchase_Order__c = :po.Id ];
    System.assert( caseParts[0].Purchase_Order_Line__c != null  );
    System.assertEquals( partCount, pols.size() );
  }

  @isTest
  static void createPOlinesAndUdateCase_withProductUpdate_Test()
  {
    setWareHouse();
    init(false);
    initPO(false);
    List<String> cpIds = new List<String>();
    for( Case_Part__c cp : caseParts ){
      cpIds.add( cp.Id );
    }
    Product2 partBefore = [SELECT Id, AcctSeedERP__Default_Vendor__c
                           FROM Product2
                           WHERE Id = :caseParts[0].Product__c ];
    Case_CreatePurchaseOrderController_dh.createPOlinesAndUdateCase( cpIds,
                                                                     po.Id,
                                                                     true );
    caseParts = [SELECT Id, Product__c, Purchase_Order_Line__c
                 FROM Case_Part__c
                 WHERE Id IN :cpIds ];

    Product2 partAfter = [SELECT Id, AcctSeedERP__Default_Vendor__c
                           FROM Product2
                           WHERE Id = :caseParts[0].Product__c ];
    AcctSeedERP__Purchase_Order_Line__c[] pols = [SELECT Id
                                                  FROM AcctSeedERP__Purchase_Order_Line__c
                                                  WHERE AcctSeedERP__Purchase_Order__c = :po.Id ];

    System.assertEquals( null, partBefore.AcctSeedERP__Default_Vendor__c);
    System.assertEquals( supplier.Id, partAfter.AcctSeedERP__Default_Vendor__c);
    System.assert( caseParts[0].Purchase_Order_Line__c != null  );
    System.assertEquals( partCount, pols.size() );
  }

  @IsTest
  static void findOpenPOs_Test()
  {
    initPartsOrder();
    List<Id> prodIds = new List<Id>{ parts[0].Id };
    Test.startTest();
    List<Map<String, Object>> result = Case_CreatePurchaseOrderController_dh.findOpenPOs(
      supplier.Id,
      Test_Constants.idWarehouse,
      prodIds
    );
    Test.stopTest();

    System.assertEquals( 1, result.size(), 'There should be one Purchase Order Line found');
    System.assertEquals( pol.Id, (Id)result[0].get('id') );
    System.assertEquals( parts[0].Id, (Id)result[0].get('productId') );
    System.assertEquals( eta, (Date)result[0].get('eta') );
  }

  @IsTest
  static void linkPurchaseOrderLineToCasePart_Test()
  {
    initPartsOrder();
    Test.startTest();
    Case_Part__c cp = Case_CreatePurchaseOrderController_dh.linkPurchaseOrderLineToCasePart(
      caseParts[0].Id,
      pol.Id
    );
    Test.stopTest();

    cp = [
      SELECT
        Id,
        Purchase_Order_Line__c
      FROM Case_Part__c
      WHERE Id = :cp.Id
    ];

    System.assertEquals( pol.Id, cp.Purchase_Order_Line__c );
  }

}