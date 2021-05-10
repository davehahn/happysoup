@isTest
public class Test_Constants {

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

}