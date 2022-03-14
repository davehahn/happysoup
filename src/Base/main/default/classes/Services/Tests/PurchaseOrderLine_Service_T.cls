/**
 * Created by dave on 2021-03-09.
 */
@IsTest
private class PurchaseOrderLine_Service_T
{

  private static final Integer recordCount = 10;
  private static List<AcctSeed__Project__c> retailERPs;
  private static List<AcctSeed__Project__c> partnerERPs;
  private static List<AcctSeedERP__Purchase_Order_Line__c> pols;

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void initData()
  {
    Account dealer = Factory_Account.insertDealerAccounts(1)[0];
    Account vendor = Factory_Account.insertSupplierAccounts(1)[0];
    List<Account> customers = Factory_Account.insertCustomerAccounts( recordCount );
    Product2 boat = Factory_Product.createSerializedProduct( 'Boat', 'Pontoon' );
    partnerERPs = Factory_ERPOrder.createPartnerBoatSales(
      dealer,
      new List<Product2>{ boat },
      recordCount
    );
    Id retailRtId = new Application_RecordType().getERPOrderRecordTypes().getRetailBoatSaleId();
    retailERPs = new List<AcctSeed__Project__c>();
    for( Account acct : customers )
    {
      retailERPs.add( Factory_ERPOrder.buildERP(
        acct, null, retailRtId
      ));
    }
    insert retailERPs;
    for( Integer i=0; i<recordCount; i++ )
    {
      partnerERPs[i].Retail_ERP__c = retailERPs[i].Id;
    }
    update partnerERPs;
    Set<Id> partnerERPids = new Set<Id>();
    for( AcctSeed__Project__c erp : partnerERPs )
    {
      partnerERPids.add( erp.Id );
    }
    partnerERPs = [
      SELECT
        Id,
      (SELECT
        Id
       FROM AcctSeed__Project_Tasks__r )
      FROM AcctSeed__Project__c
      WHERE Id IN : partnerERPids
    ];
    AcctSeedERP__Purchase_Order__c po = Factory_PurchaseOrder.createMinimalPO(
      vendor.Id, null
    );
    pols = new List<AcctSeedERP__Purchase_Order_Line__c>();
    GMBLASERP__Lot__c lot = new GMBLASERP__Lot__c(
      GMBLASERP__Product__c = boat.Id,
      Name = String.valueOf( Date.today().year() )
    );
    insert lot;
    for( AcctSeed__Project__c erp : partnerERPs )
    {
      AcctSeedERP__Purchase_Order_Line__c pol = Factory_PurchaseOrder.buildLineItem(
        po.Id,
        boat.Id,
        1
      );
      pol.AcctSeedERP__Project__c = erp.Id;
      pol.AcctSeedERP__Project_Task__c = erp.AcctSeed__Project_Tasks__r[0].Id;
      pol.GMBLASERP__Lot__c = lot.Id;
      pols.add( pol );
    }
    TriggerBase.bypass('AcctSeedERP__Purchase_Order_Line__c');
    insert pols;
    TriggerBase.clearBypass('AcctSeedERP__Purchase_Order_Line__c');
  }

  @IsTest
  static void propagateDeliveryDate_Single_Test()
  {
    initData();
    AcctSeedERP__Purchase_Order_Line__c pol = pols[0];
    Date deliverDate = Date.today().addMonths(2);
    TriggerBase.bypass('AcctSeedERP__Purchase_Order_Line__c');
    pol.deliverDate__c = deliverDate;
    update pol;
    TriggerBase.clearBypass('AcctSeedERP__Purchase_Order_Line__c');
    Test.startTest();
    PurchaseOrderLine_Service.propagateDeliveryDate( new Set<Id>{ pol.Id } );
    Test.stopTest();

    AcctSeed__Project__c retailERP = [
      SELECT
        Id,
        Arrival_Date__c
      FROM AcctSeed__Project__c
      WHERE Id = :retailERPs[0].Id
    ];

    System.assertEquals( deliverDate, retailERP.Arrival_Date__c, 'Arrival Date should now be populated on the retail ERP');

  }

  @IsTest
  static void propagateDeliveryDate_throughTrigger_Single_Test()
  {
    initData();
    AcctSeedERP__Purchase_Order_Line__c pol = pols[0];
    Date deliverDate = Date.today().addMonths(2);
    pol.deliverDate__c = deliverDate;
    Test.startTest();
    update pol;
    Test.stopTest();

    AcctSeed__Project__c retailERP = [
      SELECT
        Id,
        Arrival_Date__c
      FROM AcctSeed__Project__c
      WHERE Id = :retailERPs[0].Id
    ];

    System.assertEquals( deliverDate, retailERP.Arrival_Date__c, 'Arrival Date should now be populated on the retail ERP');

  }

  @IsTest
  static void propagateDeliveryDate_Multiple_Test()
  {
    initData();
    Date deliverDate = Date.today().addMonths(2);
    TriggerBase.bypass('AcctSeedERP__Purchase_Order_Line__c');
    Set<Id> polIds = new Set<Id>();
    for( AcctSeedERP__Purchase_Order_Line__c pol : pols )
    {
      pol.deliverDate__c = deliverDate;
      polIds.add( pol.Id );
    }
    update pols;
    TriggerBase.clearBypass('AcctSeedERP__Purchase_Order_Line__c');
    Test.startTest();
    PurchaseOrderLine_Service.propagateDeliveryDate( polIds );
    Test.stopTest();

    Set<Id> retailIds = new Set<Id>();
    for( AcctSeed__Project__c erp : retailERPs )
    {
      retailIds.add( erp.Id );
    }

    retailERPs = [
      SELECT
        Id,
        Arrival_Date__c
      FROM AcctSeed__Project__c
      WHERE Id = :retailIds
    ];

    for( AcctSeed__Project__c erp : retailERPs )
    {
      System.assertEquals(deliverDate, erp.Arrival_Date__c, 'Arrival Date should now be populated on the retail ERP');
    }

  }

  @IsTest
  static void propagateDeliveryDate_throughTrigger_Update_Multiple_Test()
  {
    initData();
    Date deliverDate = Date.today().addMonths(2);
    for( AcctSeedERP__Purchase_Order_Line__c pol : pols )
    {
      pol.deliverDate__c = deliverDate;
    }

    Test.startTest();
    update pols;
    Test.stopTest();

    Set<Id> retailIds = new Set<Id>();
    for( AcctSeed__Project__c erp : retailERPs )
    {
      retailIds.add( erp.Id );
    }

    retailERPs = [
      SELECT
        Id,
        Arrival_Date__c
      FROM AcctSeed__Project__c
      WHERE Id = :retailIds
    ];

    for( AcctSeed__Project__c erp : retailERPs )
    {
      System.assertEquals(deliverDate, erp.Arrival_Date__c, 'Arrival Date should now be populated on the retail ERP');
    }

  }
}