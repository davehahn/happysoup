@isTest
public class Factory_TestData {

  public Factory_AccountingSettings accountingSettings;
  public Factory_AccountingVariables accountingVariables;
  public Map<String, AcctSeedERP__Warehouse__c> warehouses;
  public Product2[] productConstants;

  public Factory_TestData()
  {
    accountingSettings = new Factory_AccountingSettings();
    accountingVariables = new Factory_AccountingVariables();
    warehouses = buildWarehouses( accountingVariables.glv3s );
    productConstants = buildProductConstants();
    Factory_CustomSettings.setupUtilityProducts();
    Factory_CustomSettings.setupUtilityAccounts();
	}

  private Map<String, AcctSeedERP__Warehouse__c> buildWarehouses( Map<String, AcctSeed__Accounting_Variable__c> glv3s )
  {
    Map<String, AcctSeedERP__Warehouse__c> result = new Map<String, AcctSeedERP__Warehouse__c>();
    List<sObject> whs = Test.loadData( AcctSeedERP__Warehouse__c.sObjectType, 'TestData_Warehouses' );
    for( sObject obj : whs )
    {
      AcctSeedERP__Warehouse__c wh = (AcctSeedERP__Warehouse__c)obj;
      if( wh.Name == 'Barrie' || wh.Name == 'Whitefish' )
        wh.GL_Account_Variable_3__c = glv3s.get('Ontario').Id;
      if( wh.Name == 'Montreal' )
        wh.GL_Account_Variable_3__c = glv3s.get('Quebec').Id;
      result.put( wh.Name, wh );
    }
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
        Unique_Product_Code__c = uni,
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