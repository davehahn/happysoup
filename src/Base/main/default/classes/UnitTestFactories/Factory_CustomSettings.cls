@isTest
public class Factory_CustomSettings {
  private static final List<String> LegendStoreNames = new List<String>{
    'Legend Boats Barrie',
    'Legend Boats Whitefish',
    'Legend Boats Montreal',
    'Legend Boats Wholesale'
  };

  public static void setupInventorySettings() {
    Map<String, Pricebook2> pbMap = buildPricebooks();
    Map<String, Account> legendAccountsMap = buildLegendAccounts();
    //create entries for Legend Stettings
    insert new Legend_Settings__c(
      Default_Partner_Pricebook__c = pbMap.get('partner').Id,
      Default_Retail_Pricebook__c = pbMap.get('retail').Id,
      Default_Factory_Pricebook__c = pbMap.get('factory').Id,
      LegendWhitefishAccountId__c = legendAccountsMap.get('Legend Boats Whitefish').Id,
      LegendBarrieAccountId__c = legendAccountsMap.get('Legend Boats Barrie').Id,
      LegendMontrealAccountId__c = legendAccountsMap.get('Legend Boats Montreal').Id,
      LegendWholesaleAccountId__c = legendAccountsMap.get('Legend Boats Wholesale').Id,
      FederalTaxRate__c = 5.0,
      Purchase_Order_Line_Lot__c = String.valueOf(Date.today().year()),
      Email_Logo_Id_English__c = 'theEnglishId',
      Email_Logo_Id_French__c = 'theFrenchId'
    );

    //create entries for GMBLASERP Inventory Settings
    GMBLASERP__Inventory_Settings__c invSettings = new GMBLASERP__Inventory_Settings__c();
    invSettings.Work_Order_Retail_Pricebook_Id__c = String.valueOf(pbMap.get('retail').Id).substring(0, 15);
    invSettings.Work_Order_Partner_Pricebook_Id__c = String.valueOf(pbMap.get('partner').Id).substring(0, 15);
    invSettings.GMBLASERP__disable_gtInboundInventoryMovement__c = true;
    invSettings.GMBLASERP__disable_gtManufacturingInventoryMovement__c = true;
    invSettings.GMBLASERP__disable_gtOutboundInventoryMovement__c = true;
    invSettings.GMBLASERP__disable_gtPurchaseOrderInventoryMovement__c = true;
    invSettings.GMBLASERP__disable_gtMaterial__c = true;
    invSettings.GMBLASERP__disable_gtPurchaseOrderLine__c = true;
    //    invSettings.GMBLASERP__Inventory_Transfer_Same_Day__c = true;
    for (AcctSeedERP__Warehouse__c whs : [SELECT Id, Name FROM AcctSeedERP__Warehouse__c]) {
      if (whs.Name == 'In Transit') {
        invSettings.GMBLASERP__Transit_Warehouse_Id__c = String.valueOf(whs.Id).left(15);
      }
      if (whs.Name == 'Adjustments') {
        invSettings.GMBLASERP__Adjustment_Warehouse_Id__c = String.valueOf(whs.Id).left(15);
      }
    }
    insert invSettings;

    // disable the gcCashReceipt trigger handler in GMBLASG package due to
    // guest user sharing issues introduced in Summer 20
    GMBLASG__Settings__c gmblSettings = new GMBLASG__Settings__c();
    gmblSettings.GMBLASG__disable_gtCashReceipt__c = true;
    insert gmblSettings;
  }

  public static void setupUtilityProducts() {
    Utility_Products__c ups = new Utility_Products__c();
    List<sObject> prods = Test.loadData(Product2.sObjectType, 'TestData_UtilityProducts');
    for (sObject o : prods) {
      Product2 p = (Product2) o;
      if (p.Family == 'Other Boat Components' && p.Name == 'Sublet Weld / Vinyl / Canvas Repair') {
        ups.Sublet__c = p.Id;
      }
      if (p.Family == 'Freight') {
        ups.Freight__c = p.Id;
      }
      if (p.Family == 'Discount') {
        ups.Savings__c = p.Id;
      }
      if (p.Family == 'Boat Build Option' && p.Name == 'Partner Custom Product') {
        ups.Partner_Custom_Product__c = p.Id;
      }
      if (p.Family == 'Labour' && p.Name == 'Partner Warranty Labour') {
        ups.Partner_Warranty_Labour__c = p.Id;
      }
      if (p.Family == 'Maintenance Package' && p.Name == 'Back Ordered Parts - Credit') {
        ups.Back_Order_Credit__c = p.Id;
      }
      if (p.Family == 'Maintenance Package' && p.Name == 'Back Ordered Parts - Prepaid') {
        ups.Back_Order_Prepaid__c = p.Id;
      }
      if (p.ProductCode == 'FAC') {
        ups.Flexible_Accessories_Credit__c = p.Id;
      }
    }
    insert ups;

    Id feeRtId = LGND_Constants.productRtId_Fees; // [SELECT Id FROM RecordType WHERE DeveloperName = 'Fees' AND SobjectType = 'Product2'].Id;
    Product2 ppsa = new Product2(
      RecordTypeId = feeRtId,
      Family = 'Bank Registration PPSA Fee',
      IsActive = true,
      Name = 'PPSA Fee'
    );
    insert ppsa;
  }

  public static Map<String, Account> buildLegendAccounts() {
    Map<String, Account> result = new Map<String, Account>();
    for (String name : LegendStoreNames) {
      Account a = Factory_Account.buildDealerAccounts(1)[0];
      a.Name = name;
      a.Is_Internal__c = true;
      result.put(name, a);
    }
    insert result.values();
    return result;
  }

  public static void setupUtilityAccounts() {
    Account merc = Factory_Account.insertSupplierAccounts(1)[0];
    insert new Utility_Account__c(Mercury__c = merc.Id);
  }

  public static void erpOrderTaskNames(Integer count) {
    ERPOrderTaskNames__c[] tNames = new List<ERPOrderTaskNames__c>();
    for (Integer i = 0; i < count; i++) {
      tNames.add(new ERPOrderTaskNames__c(Name = 'Task-#' + String.valueOf(i), Show_In_Invoice__c = true));
    }
    insert tNames;
  }

  public static void setupFslConstants() {
    Factory_ServiceTerritory.insertWholeSale();
  }

  private static Map<String, Pricebook2> buildPricebooks() {
    Map<String, Pricebook2> result = new Map<String, Pricebook2>();
    result.put(
      'retail',
      new Pricebook2(
        Name = 'Retail PB',
        isActive = true,
        Sales_Year__c = String.valueOf(Date.today().year()),
        Version__c = 1,
        RecordTypeId = LGND_Utilities.recordTypeIdFromName('Pricebook2', 'Sales')
      )
    );
    result.put(
      'partner',
      new Pricebook2(
        Name = 'Partner PB',
        isActive = true,
        Sales_Year__c = String.valueOf(Date.today().year()),
        Version__c = 1,
        RecordTypeId = LGND_Utilities.recordTypeIdFromName('Pricebook2', 'Dealer')
      )
    );
    result.put(
      'factory',
      new Pricebook2(
        Name = 'Factory PB',
        isActive = true,
        Sales_Year__c = String.valueOf(Date.today().year()),
        Version__c = 1,
        RecordTypeId = LGND_Utilities.recordTypeIdFromName('Pricebook2', 'Factory')
      )
    );
    insert result.values();
    return result;
  }
}
