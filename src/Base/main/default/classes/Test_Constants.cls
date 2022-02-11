@isTest
public class Test_Constants {

  private static Legend_Settings__c legendSettings {
    get{
      if( legendSettings == null ){
        legendSettings = Legend_Settings__c.getOrgDefaults();
      }
      return legendSettings;
    }
    set {}
  }

  public static Id idPdfFormat {
    get {
      if( idPdfFormat == null )
      {
        idPdfFormat = [SELECT Id FROM AcctSeed__Billing_Format__c LIMIT 1].Id;
      }
      return idPdfFormat;
    }
    set;
  }

  public static Id idWarehouse {
    get {
      if( idWarehouse == null )
      {
        idWarehouse = [SELECT Id FROM AcctSeedERP__Warehouse__c LIMIT 1].Id;
      }
      return idWarehouse;
    }
    set;
  }

  public static Id idLedger {
    get {
      if( idLedger == null )
      {
        idLedger = [SELECT Id FROM AcctSeed__Ledger__c LIMIT 1].Id;
      }
      return idLedger;
    }
    set;
  }

  public static Id idPeriod {
    get {
      if( idPeriod == null )
      {
        idPeriod = [SELECT Id FROM AcctSeed__Accounting_Period__c LIMIT 1].Id;
      }
      return idPeriod;
    }
    set;
  }

  public static Id idExpenseGLAccount {
    get {
      if( idExpenseGLAccount == null )
      {
        idExpenseGLAccount = [
          SELECT
            Id
          FROM AcctSeed__GL_Account__c
          WHERE AcctSeed__Active__c = TRUE
          AND AcctSeed__Type__c = 'Expense'
          LIMIT 1
        ].Id;
      }
      return idExpenseGLAccount;
    }
    set;
  }

  public static Id idRetailPricebook{
    get {
      if( idRetailPricebook == null )
      {
        idRetailPricebook = legendSettings.Default_Retail_Pricebook__c;
      }
      return idRetailPricebook;
    }
    set;
  }

  public static Id idFactoryPricebook{
    get {
      if( idFactoryPricebook == null )
      {
        idFactoryPricebook = legendSettings.Default_Factory_Pricebook__c;
      }
      return idFactoryPricebook;
    }
    set;
  }

}
