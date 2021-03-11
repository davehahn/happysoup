/**
 * Created by dave on 2021-03-10.
 */

@IsTest
private class Batch_RetailArrivalDate_T
{

  private static final Integer recordCount = 6;
  private static final Date deliveryDate = Date.today().addDays(10);

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    buildData();
  }

  private static void buildData()
  {
    gcProject.disableTrigger = true;
    Account dealer = Factory_Account.insertDealerAccounts(1)[0];
    List<Account> customers = Factory_Account.insertCustomerAccounts( recordCount );
    Product2 boat = Factory_Product.createSerializedProduct( 'Boat', 'Pontoon' );
    Id retailRtId = new Application_RecordType().getERPOrderRecordTypes().getRetailBoatSaleId();
    List<AcctSeed__Project__c> retailERPs = new List<AcctSeed__Project__c>();
    for( Account acct : customers )
    {
      retailERPs.add( Factory_ERPOrder.buildERP(
        acct, null, retailRtId
      ));
    }
    insert retailERPs;
    List<AcctSeed__Project__c> partnerERPs = Factory_ERPOrder.createPartnerBoatSales(
      dealer,
      new List<Product2>{ boat },
      retailERPs
    );

    Account vendor = Factory_Account.insertSupplierAccounts(1)[0];
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
    List<AcctSeedERP__Purchase_Order_Line__c> pols = new List<AcctSeedERP__Purchase_Order_Line__c>();
    for( AcctSeed__Project__c erp : partnerERPs )
    {
      AcctSeedERP__Purchase_Order_Line__c pol = Factory_PurchaseOrder.buildLineItem(
        po.Id,
        boat.Id,
        1
      );
      pol.AcctSeedERP__Project__c = erp.Id;
      pol.AcctSeedERP__Project_Task__c = erp.AcctSeed__Project_Tasks__r[0].Id;
      pol.deliverDate__c = deliveryDate;
      pols.add( pol );
    }
    gcPurchaseOrderLine.disableTrigger = true;
    lgndPurchaseOrderLine.disableTrigger = true;
    insert pols;
  }

  @IsTest
  static void batchExecute_Test()
  {
    Id rt = new Application_RecordType()
      .getERPOrderRecordTypes()
      .getRetailBoatSaleId();
    List<AcctSeed__Project__c> retailErps = [
      SELECT
        Id,
        Arrival_Date__c
      FROM AcctSeed__Project__c
      WHERE RecordTypeId = :rt
    ];

    for( AcctSeed__Project__c erp : retailERPs )
    {
      System.assertEquals( null, erp.Arrival_Date__c, 'Arrival Date should null');
    }

    Test.startTest();
    Database.executeBatch( new Batch_RetailArrivalDate() );
    Test.stopTest();


    retailErps = [
      SELECT
        Id,
        Arrival_Date__c
      FROM AcctSeed__Project__c
      WHERE RecordTypeId = :rt
    ];

    for( AcctSeed__Project__c erp : retailERPs )
    {
      System.assertEquals( deliveryDate, erp.Arrival_Date__c, 'Arrival Date should be populated');
    }
  }
}