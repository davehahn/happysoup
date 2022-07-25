@isTest
private class LGND_Constants_Test {
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  @isTest
  static void statics_Test() {
    System.assertEquals('Warranty Payable', LGND_Constants.WarrantyPayableTaskName);
    System.assertEquals('Warranty Recoverable', LGND_Constants.WarrantyRecoverableTaskName);
  }

  @IsTest
  static void googleApiKeys_Test() {
    Map<String, String> keys = new Map<String, String>();
    for (GoogleApiKey__mdt key : [SELECT DeveloperName, Key__c FROM GoogleApiKey__mdt]) {
      keys.put(key.DeveloperName, key.Key__c);
    }

    System.assertEquals(keys.get('Maps'), LGND_Constants.googleMapsAPI_Key);
  }

  @IsTest
  static void inSandboxTest() {
    Boolean inSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    System.assertEquals(inSandbox, LGND_Constants.runningInASandbox);
  }

  @IsTest
  static void retailLabourRateTest() {
    Labour_Rate__mdt rate = [SELECT Hourly_Rate__c FROM Labour_Rate__mdt WHERE DeveloperName = 'Retail'];
    System.assertEquals(rate.Hourly_Rate__c, LGND_Constants.retailLabourRate);
  }

  @IsTest
  static void mercuryDiscountBoats_Test() {
    Product2[] boats = Factory_Product.createNonSerializedProducts('Boat', 'Full Windshield', 3);
    Mercury_Discount_Boats__c[] discountBoats = new List<Mercury_Discount_Boats__c>();
    for (Product2 b : boats) {
      discountBoats.add(new Mercury_Discount_Boats__c(Name = b.Name, boatId__c = b.Id));
    }
    insert discountBoats;

    System.assertEquals(3, LGND_Constants.mercuryDiscountBoatIds.size());
  }

  @IsTest
  static void accountRecordType_Test() {
    Map<Id, String> idMap = new Map<Id, String>();
    for (RecordType rt : [SELECT Id, DeveloperName, SobjectType FROM RecordType WHERE SobjectType = 'Account']) {
      idMap.put(rt.Id, rt.DeveloperName);
    }

    System.assertEquals('Dealer', idMap.get(LGND_Constants.accountRtId_Dealer));
  }

  @isTest
  static void partnerAdminProfileId() {
    Id profileId = LGND_Constants.partnerAdminProfileId;

    String profileName = [SELECT Name FROM Profile WHERE Id = :profileId LIMIT 1].Name;

    System.assert(profileName == 'Legend Partner');
  }

  @isTest
  static void pricebooks_Test() {
    Map<String, Id> pbIdMap = new Map<String, Id>{
      'standard' => Test.getStandardPricebookId(),
      'retail' => Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c,
      'partner' => Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c,
      'factory' => Legend_Settings__c.getOrgDefaults().Default_Factory_Pricebook__c
    };
    Id stdPbId = LGND_Constants.standardPricebookId;
    Id retailPbId = LGND_Constants.retailPricebookId;
    Id partnerPbId = LGND_Constants.partnerPricebookId;
    Id factoryPbId = LGND_Constants.factoryPricebookId;
    System.assertEquals(pbIdMap.get('standard'), stdPbId);
    System.assertEquals(pbIdMap.get('retail'), retailPbId);
    System.assertEquals(pbIdMap.get('partner'), partnerPbId);
    System.assertEquals(pbIdMap.get('factory'), factoryPbId);
  }

  @isTest
  static void savingsProductId() {
    Product2 savings = [SELECT Id FROM Product2 WHERE Family = 'Discount' LIMIT 1];
    System.assertEquals(savings.Id, LGND_Constants.savingsProductId);
  }

  @isTest
  static void ppsaProductId() {
    Product2 ppsa = [SELECT Id FROM Product2 WHERE Family = 'Bank Registration PPSA Fee' LIMIT 1];
    System.assertEquals(ppsa.Id, LGND_Constants.ppsaProductId);
  }

  @isTest
  static void partnerCustomProductProductId() {
    Product2 partner = [
      SELECT Id
      FROM Product2
      WHERE Name = 'Partner Custom Product' AND Family = 'Boat Build Option'
      LIMIT 1
    ];
    System.assertEquals(partner.Id, LGND_Constants.partnerCustomProductId);
  }

  @isTest
  static void productRT_Test() {
    Id boat;
    Id motor;
    Id trailer;
    Id trollingMotor;
    Id part;
    Id packageBundle;
    Id protection;
    Id insurance;
    Id fees;

    for (RecordType rt : [
      SELECT Id, DeveloperName, SobjectType
      FROM RecordType
      WHERE
        SobjectType = 'Product2'
        AND (DeveloperName = 'Boat'
        OR DeveloperName = 'Trailer'
        OR DeveloperName = 'Motor'
        OR DeveloperName = 'Trolling_Motor'
        OR DeveloperName = 'Part'
        OR DeveloperName = 'Package_Bundle'
        OR DeveloperName = 'Protection_and_Services'
        OR DeveloperName = 'Insurance'
        OR DeveloperName = 'Fees')
    ]) {
      if (rt.SobjectType == 'Product2') {
        if (rt.DeveloperName == 'Boat')
          boat = rt.Id;
        else if (rt.DeveloperName == 'Trailer')
          trailer = rt.Id;
        else if (rt.DeveloperName == 'Motor')
          motor = rt.Id;
        else if (rt.DeveloperName == 'Trolling_Motor')
          trollingMotor = rt.Id;
        else if (rt.DeveloperName == 'Part')
          part = rt.Id;
        else if (rt.DeveloperName == 'Package_Bundle')
          packageBundle = rt.Id;
        else if (rt.DeveloperName == 'Protection_and_Services')
          protection = rt.Id;
        else if (rt.DeveloperName == 'Insurance')
          insurance = rt.Id;
        else if (rt.DeveloperName == 'Fees')
          fees = rt.Id;
      }
    }

    System.assertEquals(boat, LGND_Constants.productRtId_Boat);
    System.assertEquals(trailer, LGND_Constants.productRtId_Trailer);
    System.assertEquals(motor, LGND_Constants.productRtId_Motor);
    System.assertEquals(trollingMotor, LGND_Constants.productRtId_TrollingMotor);
    System.assertEquals(part, LGND_Constants.productRtId_Part);
    System.assertEquals(packageBundle, LGND_Constants.productRtId_Bundle);
    System.assertEquals(protection, LGND_Constants.productRtId_Protection);
    System.assertEquals(insurance, LGND_Constants.productRtId_Insurance);
    System.assertEquals(fees, LGND_Constants.productRtId_Fees);
  }

  @IsTest
  static void GLV2s_Test() {
    Map<Id, String> idMap = new Map<Id, String>();
    for (AcctSeed__Accounting_Variable__c var : [
      SELECT Id, Name
      FROM AcctSeed__Accounting_Variable__c
      WHERE AcctSeed__Type__c = 'GL Account Variable 2'
    ]) {
      idMap.put(var.Id, var.Name);
    }

    System.assertEquals('Accounting & Admin', idMap.get(LGND_Constants.GLV2Id_AccountingAndAdmin));
    System.assertEquals('Business Office', idMap.get(LGND_Constants.GLV2Id_BusinessOffice));
    System.assertEquals('IT', idMap.get(LGND_Constants.GLV2Id_IT));
    System.assertEquals('Logistics', idMap.get(LGND_Constants.GLV2Id_Logistics));
    System.assertEquals('Marketing', idMap.get(LGND_Constants.GLV2Id_Marketing));
    System.assertEquals('Parts + Service', idMap.get(LGND_Constants.GLV2Id_PartsAndService));
    System.assertEquals('Production', idMap.get(LGND_Constants.GLV2Id_Production));
    System.assertEquals('Sales', idMap.get(LGND_Constants.GLV2Id_Sales));
    System.assertEquals('Warranty', idMap.get(LGND_Constants.GLV2Id_Warranty));
  }
}
