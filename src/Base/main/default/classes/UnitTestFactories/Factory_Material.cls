/**
 * Created by dave on 2021-04-13.
 */
@IsTest
public class Factory_Material {
  public static AcctSeedERP__Material__c buildMaterial(Id erpId, Id taskId, Id prodId) {
    return new AcctSeedERP__Material__c(
      AcctSeedERP__Product__c = prodId,
      AcctSeedERP__Quantity_Per_Unit__c = 1,
      AcctSeedERP__Project__c = erpId,
      AcctSeedERP__Project_Task__c = taskId,
      GMBLASERP__Unit_Price__c = 10.00
    );
  }

  public static AcctSeedERP__Material__c buildMaterial(Id erpId, Id taskId, Id prodId, Decimal unitPrice) {
    AcctSeedERP__Material__c m = Factory_Material.buildMaterial(erpId, taskId, prodId);
    m.GMBLASERP__Unit_Price__c = unitPrice;
    return m;
  }

  public static AcctSeedERP__Material__c[] buildMaterials(Id erpId, Id taskId, Product2[] products) {
    AcctSeedERP__Material__c[] result = new List<AcctSeedERP__Material__c>();
    for (Product2 p : products) {
      result.add(buildMaterial(erpId, taskId, p.Id));
    }
    return result;
  }

  public static List<AcctSeedERP__Material__c> insertMaterials(Id erpId, Id taskId, Product2[] products) {
    List<AcctSeedERP__Material__c> result = buildMaterials(erpId, taskId, products);
    insert result;
    return result;
  }

  public static AcctSeedERP__Material__c buildMaterial(Id erpId, Id taskId, PricebookEntry pbe) {
    return new AcctSeedERP__Material__c(
      AcctSeedERP__Product__c = pbe.Product2Id,
      AcctSeedERP__Quantity_Per_Unit__c = 1,
      AcctSeedERP__Project__c = erpId,
      AcctSeedERP__Project_Task__c = taskId,
      GMBLASERP__Unit_Price__c = pbe.UnitPrice
    );
  }
}
