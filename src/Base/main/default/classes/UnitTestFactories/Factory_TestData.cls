@isTest
public class Factory_TestData {

  public Factory_AccountingSettings accountingSettings;
  public Factory_AccountingVariables accountingVariables;
  public Map<String, AcctSeedERP__Warehouse__c> warehouses;
  public Map<Id, Schema.Location> warehouse2fslSiteMap;
  public Product2[] productConstants;

  public Factory_TestData()
  {
    accountingSettings = new Factory_AccountingSettings();
    accountingVariables = new Factory_AccountingVariables();
    warehouses = buildWarehouses( accountingVariables.glv3s );
    productConstants = buildProductConstants();
    Factory_CustomSettings.setupUtilityProducts();
    Factory_CustomSettings.setupUtilityAccounts();
    Factory_CustomSettings.setupFslConstants();
	}

  private void setFslSites( List<sObject> whs )
  {
    warehouse2fslSiteMap = new Map<Id, Schema.Location>();
    for( sObject obj : whs )
    {
      AcctSeedERP__Warehouse__c wh = (AcctSeedERP__Warehouse__c) obj;
      warehouse2fslSiteMap.put(wh.Id, Factory_Location.buildSite(wh.Name));
    }
    insert warehouse2fslSiteMap.values();
  }

  private Map<String, AcctSeedERP__Warehouse__c> buildWarehouses( Map<String, AcctSeed__Accounting_Variable__c> glv3s )
  {
    List<sObject> whs = Test.loadData( AcctSeedERP__Warehouse__c.sObjectType, 'TestData_Warehouses' );
    setFslSites( whs );
    Map<String, AcctSeedERP__Warehouse__c> result = new Map<String, AcctSeedERP__Warehouse__c>();
    List<Schema.Location> fsl_Locations = new List<Schema.Location>();
    List<AcctSeedERP__Location__c> acctSeedLocations = new List<AcctSeedERP__Location__c>();

    for( sObject obj : whs )
    {
      AcctSeedERP__Warehouse__c wh = (AcctSeedERP__Warehouse__c)obj;
      acctSeedLocations.add( new AcctSeedERP__Location__c(
        AcctSeedERP__Warehouse__c = wh.Id,
        Name = wh.Name,
        Unique_Purpose__c = wh.Name + '-Test'
      ));
      fsl_Locations.add( Factory_Location.buildWarehouse(
        wh,
        warehouse2fslSiteMap.get( wh.Id )
      ) );
      if( wh.Name == 'Barrie' || wh.Name == 'Whitefish' )
      {
        wh.GL_Account_Variable_3__c = glv3s.get('Ontario').Id;
      }
      if( wh.Name == 'Montreal' )
      {
        wh.GL_Account_Variable_3__c = glv3s.get('Quebec').Id;
      }
      result.put( wh.Name, wh );
    }
    insert fsl_Locations;
    insert acctSeedLocations;
    update result.values();
    return result;
  }

  private Product2[] buildProductConstants()
  {
    Product2[] result = new List<Product2>();
    List<String> listUniquefier = new list<String>{
        'SalesTaxFederal',
        'SalesTaxHarmonized',
        'SalesTaxProvincial',
        'SalesTaxRetail',
        'TaxCanada',
        'Trade in',
        'Trade in Lien',
        'TradeInBoats',
        'PrecisionFix',
        'InternalLabour',
        'InternalBilling',
        'InternalBalance'
    };
    for( String uni : listUniquefier )
    {
      result.add( new Product2(
        Name = uni,
        RecordTypeId = LGND_Constants.productRtId_Fees,
        ProductCode = uni,
        isActive = true,
        AcctSeed__Expense_GL_Account__c = accountingSettings.salesTaxPaid.Id,
        AcctSeed__Revenue_GL_Account__c = accountingSettings.salesTaxCollected.Id,
        AcctSeed__Inventory_Product__c = false
      ));
    }
    insert result;
    return result;
  }

}
