@isTest
public class ProjectTestFactory {
  public static AcctSeed__Project__c insertCounterSale() {
    Account acct = AccountFactory.insertPersonAccount();
    AcctSeed__Project__c counterSale = new AcctSeed__Project__c(
      RecordTypeId = gcConstants.idRtProjectCounterSale,
      AcctSeed__Account__c = acct.Id,
      Name = 'ERP Counter Sale'
    );
    insert counterSale;
    AcctSeed__Project_Task__c pt = Factory_ERPOrderTask.buildProjectTask(counterSale.Id, 'Test Task');
    gcProjectTask.disableTrigger = true;
    insert pt;
    addMaterial(counterSale, 4);
    return counterSale;
  }

  public static AcctSeed__Project__c insertBoatSale() {
    Account acct = AccountFactory.insertPersonAccount();
    AcctSeed__Project__c boatSale = new AcctSeed__Project__c(
      RecordTypeId = gcConstants.idRtProjectBoatSale,
      AcctSeed__Account__c = acct.Id,
      Name = 'ERP Counter Sale'
    );
    insert boatSale;

    addMaterial(boatSale, 4);
    return boatSale;
  }

  public static List<AcctSeedERP__Material__c> addMaterial(AcctSeed__Project__c proj, Integer count) {
    Product2[] parts = InventoryTestFactory.insertTestProductsWithStandardPricebookEntries(count, 'Part');
    AcctSeed__Project_Task__c pt;
    for (AcctSeed__Project_Task__c projTask : [
      SELECT Id
      FROM AcctSeed__Project_Task__c
      WHERE AcctSeed__Project__c = :proj.Id
      LIMIT 1
    ]) {
      pt = projTask;
    }
    if (pt == null) {
      pt = Factory_ERPOrderTask.buildProjectTask(proj.Id, 'Test Task');
      gcProjectTask.disableTrigger = true;
      insert pt;
      gcProjectTask.disableTrigger = false;
    }
    List<AcctSeedERP__Material__c> materials = new List<AcctSeedERP__Material__c>();
    for (Product2 p : parts) {
      materials.add(
        new AcctSeedERP__Material__c(
          AcctSeedERP__Quantity_Per_Unit__c = 1,
          AcctSeedERP__Product__c = p.Id,
          AcctSeedERP__Project__c = proj.Id,
          AcctSeedERP__Project_Task__c = pt.Id,
          GMBLASERP__Unit_Price__c = 10
        )
      );
    }
    insert materials;
    return materials;
  }
}
