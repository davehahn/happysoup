@isTest
private class LGND_Constants_Test {

  @testSetup
  static void dataSetup()
  {
    Factory_CustomSettings.setupInventorySettings();
  }

	@isTest static void statics_Test() {
		System.assertEquals('Warranty Payable', LGND_Constants.WarrantyPayableTaskName);
    System.assertEquals('Warranty Recoverable', LGND_Constants.WarrantyRecoverableTaskName);
	}

	@isTest
  static void partnerAdminProfileId() {
		Id profileId = LGND_Constants.partnerAdminProfileId;

		String profileName = [SELECT Name FROM Profile WHERE Id =:profileId LIMIT 1].Name;

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
    System.assertEquals( pbIdMap.get('standard'), stdPbId );
    System.assertEquals( pbIdMap.get('retail'), retailPbId );
    System.assertEquals( pbIdMap.get('partner'), partnerPbId );
    System.assertEquals( pbIdMap.get('factory'), factoryPbId );
  }

  @isTest
  static void savingsProductId() {
    Product2 savings = Factory_Product.createSavingsProduct();
    insert new Utility_Products__c( Savings__c = savings.Id );
    Id savId = LGND_Constants.savingsProductId;
    System.assertEquals( savings.Id, savId );
  }

  @isTest
  static void productRT_Test()
  {
    Id boat;
    Id motor;
    Id trailer;
    Id trollingMotor;
    Id part;

    for(RecordType rt :
      [SELECT Id, DeveloperName, SobjectType
       FROM RecordType
       WHERE (SobjectType = 'Product2' AND
          (DeveloperName = 'Boat' OR
           DeveloperName = 'Trailer' OR
           DeveloperName = 'Motor' OR
           DeveloperName = 'Trolling_Motor' OR
           DeveloperName = 'Part'))])
    {
      if(rt.SobjectType == 'Product2')
      {
        if(rt.DeveloperName == 'Boat')
         boat = rt.Id;
        else if(rt.DeveloperName == 'Trailer')
          trailer = rt.Id;
        else if(rt.DeveloperName == 'Motor')
          motor = rt.Id;
          else if(rt.DeveloperName == 'Trolling_Motor')
          trollingMotor = rt.Id;
        else if(rt.DeveloperName == 'Part')
          part = rt.Id;
      }
    }

    System.assertEquals( boat, LGND_Constants.productRtId_Boat );
    System.assertEquals( trailer, LGND_Constants.productRtId_Trailer );
    System.assertEquals( motor, LGND_Constants.productRtId_Motor );
    System.assertEquals( trollingMotor, LGND_Constants.productRtId_TrollingMotor );
    System.assertEquals( part, LGND_Constants.productRtId_Part );
  }

}