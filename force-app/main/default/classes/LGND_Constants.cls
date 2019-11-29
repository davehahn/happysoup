public with sharing class LGND_Constants {
  public class LGND_Constants_Exception extends Exception {}
  public static String WarrantyPayableTaskName = 'Warranty Payable';
  public static String WarrantyRecoverableTaskName = 'Warranty Recoverable';

  public static Boolean runningInASandbox {
    get {
      if( runningInASandbox == null )
      {
        runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
      }
      return runningInASandbox;
    }
    set;
  }

  public static Set<String> mercuryDiscountBoatIds {
    get {
      if( mercuryDiscountBoatIds == null )
      {
        mercuryDiscountBoatIds = new Set<String>();
        for( Mercury_Discount_Boats__c mdb : Mercury_Discount_Boats__c.getAll().values() )
        {
          mercuryDiscountBoatIds.add( mdb.boatId__c );
        }
      }
      return mercuryDiscountBoatIds;
    }
    private set;
  }


  public static Id partnerAdminProfileId {
  	get {
  		if( partnerAdminProfileId == null )
  			partnerAdminProfileId = [SELECT Id FROM Profile WHERE Name = 'Legend Partner' LIMIT 1].Id;
  		return partnerAdminProfileId;
  	}
  	private set;
  }

  public static Id savingsProductId {
    get {
      if( savingsProductId == null )
        savingsProductId = Utility_Products__c.getOrgDefaults().Savings__c;
      return savingsProductId;
    }
    private set;
  }

  public static Id partnerCustomProductId {
    get {
      if( partnerCustomProductId == null )
        partnerCustomProductId = Utility_Products__c.getOrgDefaults().Partner_Custom_Product__c;
      if( partnerCustomProductId == null )
        throw new LGND_Constants_Exception('Partner Custom Product is not setup.  Please contact an administrator to get this rectified');
      return partnerCustomProductId;
    }
    private set;
  }

  /* ++++++++++++++++++ PRICEBOOKS +++++++++++++++++++++ */

  public static Id retailPricebookId {
    get {
      if( retailPricebookId == null )
      {
        retailPricebookId = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
      }
      return retailPricebookId;
    }
    set;
  }

  public static Id partnerPricebookId {
    get {
      if( partnerPricebookId == null )
      {
        partnerPricebookId = Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c;
      }
      return partnerPricebookId;
    }
    set;
  }

  public static Id factoryPricebookId {
    get {
      if( factoryPricebookId == null )
      {
        factoryPricebookId = Legend_Settings__c.getOrgDefaults().Default_Factory_Pricebook__c;
      }
      return factoryPricebookId;
    }
    set;
  }

  public static Id standardPricebookId {
    get {
      if( standardPricebookId == null )
      {
        if( Test.isRunningTest() )
          standardPricebookId = Test.getStandardPricebookId();
        else
          standardPricebookId = [SELECT Id FROM Pricebook2 WHERE isStandard = true].Id;
      }
      return standardPricebookId;
    }
    private set;
  }

/* +++++++++++++++++ PRODUCT RECORD TYPES ++++++++++++++++++ */

  public static Id productRtId_Boat{
    get {
      if( productRtId_Boat == null ) fetchProductRecordTypes();
      if( productRtId_Boat == null )
        throw new LGND_Utilities.LGND_Exception('Product Record Type with API Name [Boat] does not exist');
      return productRtId_Boat;
    }
    set;
  }

  public static Id productRtId_Trailer{
    get {
      if( productRtId_Trailer == null ) fetchProductRecordTypes();
      if( productRtId_Trailer == null )
        throw new LGND_Utilities.LGND_Exception('Product Record Type with API Name [Trailer] does not exist');
      return productRtId_Trailer;
    }
    set;
  }

  public static Id productRtId_Motor{
    get {
      if( productRtId_Motor == null ) fetchProductRecordTypes();
      if( productRtId_Motor == null )
        throw new LGND_Utilities.LGND_Exception('Product Record Type with API Name [Motor] does not exist');
      return productRtId_Motor;
    }
    set;
  }

  public static Id productRtId_TrollingMotor{
    get {
      if( productRtId_TrollingMotor == null ) fetchProductRecordTypes();
      if( productRtId_TrollingMotor == null )
        throw new LGND_Utilities.LGND_Exception('Product Record Type with API Name [TrollingMotor] does not exist');
      return productRtId_TrollingMotor;
    }
    set;
  }

  public static Id productRtId_Part{
    get {
      if( productRtId_Part == null ) fetchProductRecordTypes();
      if( productRtId_Part == null )
        throw new LGND_Utilities.LGND_Exception('Product Record Type with API Name [Part] does not exist');
      return productRtId_Part;
    }
    set;
  }

  public static Id productRtId_Bundle{
    get {
      if( productRtId_Bundle == null ) fetchProductRecordTypes();
      if( productRtId_Bundle == null )
        throw new LGND_Utilities.LGND_Exception('Product Record Type with API Name [Package Bundle] does not exist');
      return productRtId_Bundle;
    }
    set;
  }

  public static Id productRtId_Protection{
    get {
      if( productRtId_Protection == null ) fetchProductRecordTypes();
      if( productRtId_Protection == null )
        throw new LGND_Utilities.LGND_Exception('Product Record Type with API Name [Protection and Services] does not exist');
      return productRtId_Protection;
    }
    set;
  }

  public static Id productRtId_Insurance{
    get {
      if( productRtId_Insurance == null ) fetchProductRecordTypes();
      if( productRtId_Insurance == null )
        throw new LGND_Utilities.LGND_Exception('Product Record Type with API Name [Insurance] does not exist');
      return productRtId_Insurance;
    }
    set;
  }

  private static void fetchProductRecordTypes()
  {
    for(RecordType rt :
      [SELECT Id, DeveloperName, SobjectType
       FROM RecordType
       WHERE (SobjectType = 'Product2' AND
          (DeveloperName = 'Boat' OR
           DeveloperName = 'Trailer' OR
           DeveloperName = 'Motor' OR
           DeveloperName = 'Trolling_Motor' OR
           DeveloperName = 'Part' OR
           DeveloperName = 'Package_Bundle' OR
           DeveloperName = 'Protection_and_Services' OR
           DeveloperName = 'Insurance'))])
    {
      if(rt.SobjectType == 'Product2')
      {
        if(rt.DeveloperName == 'Boat')
          productRtId_Boat = rt.Id;
        else if(rt.DeveloperName == 'Trailer')
          productRtId_Trailer = rt.Id;
        else if(rt.DeveloperName == 'Motor')
          productRtId_Motor = rt.Id;
        else if(rt.DeveloperName == 'Trolling_Motor')
          productRtId_TrollingMotor = rt.Id;
        else if(rt.DeveloperName == 'Part')
          productRtId_Part = rt.Id;
        else if(rt.DeveloperName == 'Package_Bundle')
          productRtId_Bundle = rt.Id;
        else if(rt.DeveloperName == 'Protection_and_Services')
          productRtId_Protection = rt.Id;
        else if(rt.DeveloperName == 'Insurance')
          productRtId_Insurance = rt.Id;
      }
    }
  }

}