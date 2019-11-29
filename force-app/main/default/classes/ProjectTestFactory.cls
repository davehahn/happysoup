@isTest
public class ProjectTestFactory {

  public static AcctSeed__Project__c insertCounterSale()
  {
    Account acct = AccountFactory.insertPersonAccount();
    AcctSeed__Project__c counterSale = new AcctSeed__Project__c(
      RecordTypeId = gcConstants.idRtProjectCounterSale,
      AcctSeed__Account__c = acct.Id,
      Name = 'ERP Counter Sale'
    );
    insert counterSale;

    addMaterial( counterSale, 4 );
    return counterSale;
  }

  public static AcctSeed__Project__c insertBoatSale()
  {
    Account acct = AccountFactory.insertPersonAccount();
    AcctSeed__Project__c boatSale = new AcctSeed__Project__c(
      RecordTypeId = gcConstants.idRtProjectBoatSale,
      AcctSeed__Account__c = acct.Id,
      Name = 'ERP Counter Sale'
    );
    insert boatSale;

    addMaterial( boatSale, 4 );
    return boatSale;
  }

  public static List<AcctSeedERP__Material__c> addMaterial( AcctSeed__Project__c proj, Integer count)
  {
    Product2[] parts = InventoryTestFactory.insertTestProductsWithStandardPricebookEntries( count, 'Part');
    List<AcctSeedERP__Material__c> materials = new List<AcctSeedERP__Material__c>();
    for( Product2 p : parts )
    {
      materials.add( new AcctSeedERP__Material__c(
        AcctSeedERP__Quantity_Per_Unit__c = 1,
        AcctSeedERP__Product__c = p.Id,
        AcctSeedERP__Project__c = proj.Id,
        GMBLASERP__Unit_Price__c = 10
        )
      );
    }
    insert materials;
    return materials;
  }



}