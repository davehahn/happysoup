@isTest
public with sharing class Factory_PurchaseOrder {

  public static AcctSeedERP__Purchase_Order__c createMinimalPO( Id vendorId,
                                                                Id shipToId )
  {
    //AcctSeed__Billing_Format__c pdf_format = [SELECT Id FROM AcctSeed__Billing_Format__c LIMIT 1];
    //AcctSeedERP__Warehouse__c wh = [SELECT Id FROM AcctSeedERP__Warehouse__c LIMIT 1];
    //AcctSeed__Ledger__c ledger = [SELECT Id FROM AcctSeed__Ledger__c LIMIT 1];
    AcctSeedERP__Purchase_Order__c po = new AcctSeedERP__Purchase_Order__c(
      AcctSeedERP__Shipping_Company__c = shipToId,
      AcctSeedERP__Vendor__c = vendorId,
      AcctSeedERP__Type__c = 'Standard',
      AcctSeedERP__Status__c = 'Open',
      AcctSeedERP__Purchase_Order_Format__c = Test_Constants.idPdfFormat,
      Warehouse__c = Test_Constants.idWareHouse,
      AcctSeedERP__Ledger__c = Test_Constants.idLedger
      //AcctSeedERP__Vendor_Country__c = 'Canada'
    );
    insert po;
    return po;
  }

  public static AcctSeedERP__Purchase_Order_Line__c createLineItem(
    Id poId,
    Id prodId,
    Integer count
  )
  {
    AcctSeedERP__Purchase_Order_Line__c pol = buildLineItem(
      poId,
      prodId,
      count
    );
    insert pol;
    return pol;
  }

  public static AcctSeedERP__Purchase_Order_Line__c buildLineItem(
    Id poId,
    Id prodId,
    Integer count
  )
  {
    return new AcctSeedERP__Purchase_Order_Line__c(
      AcctSeedERP__Purchase_Order__c = poId,
      AcctSeedERP__Product__c = prodId,
      AcctSeedERP__Quantity__c = count,
      AcctSeedERP__Unit_Price__c = 10.00
    );
  }

  public static void addPOLines( Integer count,  Id poId )
  {
    AcctSeedERP__Purchase_Order_Line__c[] pols = new List<AcctSeedERP__Purchase_Order_Line__c>();
    Product2[] parts = Factory_Product.buildNonSerializedProducts( 'Part', 'Hardware', count );
    insert parts;
    for( Product2 p : parts )
    {
      pols.add( buildLineItem( poId, p.Id, 1 ) );
    }
    insert pols;
  }

}