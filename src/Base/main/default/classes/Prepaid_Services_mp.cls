public with sharing class Prepaid_Services_mp {
  public class PrepaidService {
    public Prepaid_Service__c prepaid { get; set; }
    public Product2[] products { get; set; }
    public PrepaidService() {
      this.products = new List<Product2>();
    }
  }

  public class PrepaidServiceItem {
    public String prepaidId { get; set; }
    public String name { get; set; }
    public String prepaidServiceName { get; set; }
    public String product { get; set; }
    public String productId { get; set; }
    public Decimal quantity { get; set; }
    public Decimal redeemed { get; set; }
    public Decimal balance { get; set; }
    public Decimal toredeem { get; set; }
    public Decimal riggingTime { get; set; }
    public PrepaidServiceItem[] children { get; set; }
    public PrepaidServiceItem() {
      this.children = new List<PrepaidServiceItem>();
    }
  }

  public class Bundle {
    public Id Id { get; set; }
    public String Name { get; set; }
    public String ProductCode { get; set; }
    public Prepaid_Package_Item__c[] items { get; set; }
    public Boolean isPrepayable { get; set; }
    public Bundle() {
      this.items = new List<Prepaid_Package_Item__c>();
    }
  }

  @AuraEnabled
  public static String getPrepaidsOnAccount(Id accountId) {
    Set<Id> productIds = new Set<Id>();

    Map<Id, PrepaidService> servicesMap = new Map<Id, PrepaidService>();
    for (Prepaid_Service__c service : [
      SELECT Id, Name, Product__c, Product__r.Name, Product__r.Rigging_Time__c, Quantity__c, Redeemed__c, Balance__c
      FROM Prepaid_Service__c
      WHERE Account__c = :accountId
    ]) {
      PrepaidService s = new PrepaidService();
      s.prepaid = service;
      servicesMap.put(service.Id, s);
      productIds.add(service.Product__c);
    }

    Map<Id, Prepaid_Package_Item__c> packageItemsMap = new Map<Id, Prepaid_Package_Item__c>();
    Set<Id> itemProductIds = new Set<Id>();
    for (Prepaid_Package_Item__c packageItem : [
      SELECT Id, Package__c, Item__c
      FROM Prepaid_Package_Item__c
      WHERE Package__c IN :productIds
    ]) {
      packageItemsMap.put(packageItem.Package__c, packageItem);
      itemProductIds.add(packageItem.Item__c);
    }

    Map<Id, Product2> productMap = new Map<Id, Product2>();
    for (Product2 product : [SELECT Id, Name FROM Product2 WHERE Id IN :itemProductIds]) {
      productMap.put(product.Id, product);
    }

    for (Id serviceId : servicesMap.keySet()) {
      for (Id itemId : packageItemsMap.keySet()) {
        if (servicesMap.get(serviceId).prepaid.Product__c == packageItemsMap.get(itemId).Package__c) {
          servicesMap.get(serviceId).products.add(productMap.get(packageItemsMap.get(itemId).Item__c));
        }
      }
    }

    return formatPrepaidsForDisplay(servicesMap.values());
  }

  public static void redeemPrepaids(String prepaids, Id accountId, Id projectId, AcctSeed__Project_Task__c[] tasks) {
    PrepaidServiceItem[] services;
    Prepaid_Service_Redeemed__c[] redemptions;
    AcctSeedERP__Material__c[] materials;
    AcctSeedERP__Material__c[] redemptionMaterials;

    services = (List<PrepaidServiceItem>) JSON.deserialize(prepaids, List<PrepaidServiceItem>.class);

    redemptions = createRedemptions(services, accountId, projectId);
    materials = createMaterials(services, tasks, projectId);
    redemptionMaterials = createCreditEntries(materials, projectId);
  }

  private static Prepaid_Service_Redeemed__c[] createRedemptions(
    PrepaidServiceItem[] services,
    Id accountId,
    Id projectId
  ) {
    Prepaid_Service_Redeemed__c[] redemptions = new List<Prepaid_Service_Redeemed__c>();
    for (PrepaidServiceItem s : services) {
      for (Integer i = 0; i < s.toredeem; i++) {
        Prepaid_Service_Redeemed__c r = new Prepaid_Service_Redeemed__c();
        r.Account__c = accountId;
        r.ERP_Order__c = projectId;
        r.Prepaid_Service__c = s.prepaidId;
        redemptions.add(r);
      }
    }

    insert redemptions;

    return redemptions;
  }

  private static AcctSeedERP__Material__c[] createMaterials(
    PrepaidServiceItem[] services,
    AcctSeed__Project_Task__c[] tasks,
    Id projectId
  ) {
    AcctSeedERP__Material__c[] materials = new List<AcctSeedERP__Material__c>();
    for (AcctSeed__Project_Task__c t : tasks) {
      for (PrepaidServiceItem s : services) {
        if (t.Name == s.product) {
          AcctSeedERP__Material__c m = new AcctSeedERP__Material__c();
          m.AcctSeedERP__Project__c = projectId;
          m.AcctSeedERP__Product__c = s.productId;
          m.AcctSeedERP__Quantity_per_Unit__c = 1;
          m.AcctSeedERP__Project_Task__c = t.Id;
          materials.add(m);
        }
      }
    }

    insert materials;

    return materials;
  }

  private static AcctSeedERP__Material__c[] createCreditEntries(AcctSeedERP__Material__c[] materials, Id projectId) {
    AcctSeedERP__Material__c[] redemptionMaterials = new List<AcctSeedERP__Material__c>();

    Product2 creditProduct = [SELECT Id FROM Product2 WHERE Name = 'Prepaid Maintenance Package Credit'];

    Set<Id> materialIds = new Set<Id>();

    for (AcctSeedERP__Material__c m : materials) {
      materialIds.add(m.Id);
    }

    for (AcctSeedERP__Material__c m : [
      SELECT
        Id,
        AcctSeedERP__Project__c,
        AcctSeedERP__Product__c,
        AcctSeedERP__Product__r.Name,
        AcctSeedERP__Project_Task__c,
        AcctSeedERP__Quantity_per_Unit__c,
        GMBLASERP__Unit_Price__c
      FROM AcctSeedERP__Material__c
      WHERE Id IN :materialIds
    ]) {
      AcctSeedERP__Material__c rm = new AcctSeedERP__Material__c();
      rm.AcctSeedERP__Project__c = projectId;
      rm.AcctSeedERP__Product__c = creditProduct.Id;
      rm.AcctSeedERP__Quantity_per_Unit__c = 1;
      rm.GMBLASERP__Unit_Price__c = m.GMBLASERP__Unit_Price__c * -1;
      rm.AcctSeedERP__Project_Task__c = m.AcctSeedERP__Project_Task__c;
      redemptionMaterials.add(rm);
    }

    insert redemptionMaterials;

    return redemptionMaterials;
  }

  public static void handleProjectPrepaids(Set<Id> projectsToCreditPrepaids, Set<Id> projectsToCleanPrepaids) {
    System.enqueueJob(new ProjectPrepaids_Queue(projectsToCreditPrepaids, projectsToCleanPrepaids));
  }

  public class ProjectPrepaids_Queue implements Queueable {
    public final Set<Id> projectsToCreditPrepaids;
    public final Set<Id> projectsToCleanPrepaids;

    public ProjectPrepaids_Queue(Set<Id> projectsToCreditPrepaids, Set<Id> projectsToCleanPrepaids) {
      this.projectsToCleanPrepaids = projectsToCleanPrepaids;
      this.projectsToCreditPrepaids = projectsToCreditPrepaids;
    }

    public void execute(QueueableContext context) {
      if (this.projectsToCreditPrepaids.size() > 0)
        creditPrepaids(this.projectsToCreditPrepaids);

      if (this.projectsToCleanPrepaids.size() > 0)
        cleanPrepaids(this.projectsToCleanPrepaids);
    }

    private void creditPrepaids(Set<Id> projectIds) {
      Set<Id> prepaidBundleIds = new Set<Id>();

      cleanPrepaids(projectIds);

      AcctSeedERP__Material__c[] materials = [
        SELECT
          Id,
          AcctSeedERP__Product__c,
          AcctSeedERP__Product__r.RecordTypeId,
          AcctSeedERP__Project__c,
          AcctSeedERP__Project__r.AcctSeed__Account__c,
          AcctSeedERP__Quantity_per_Unit__c,
          isPrepaid__c
        FROM AcctSeedERP__Material__c
        WHERE AcctSeedERP__Project__c IN :projectIds AND isPrepaid__c = TRUE
      ];

      for (AcctSeedERP__Material__c m : materials) {
        if (m.AcctSeedERP__Product__r.RecordTypeId == LGND_Constants.productRtId_Bundle) {
          prepaidBundleIds.add(m.AcctSeedERP__Product__c);
        }
      }

      Prepaid_Package_Item__c[] packageItems = [
        SELECT Id, Package__c, Item__c, Quantity__c
        FROM Prepaid_Package_Item__c
        WHERE Package__c IN :prepaidBundleIds
      ];

      Prepaid_Service__c[] services = [
        SELECT Id, Account__c, ERP_Order__c, Product__c, Quantity__c
        FROM Prepaid_Service__c
        WHERE ERP_Order__c IN :projectIds
      ];

      for (AcctSeedERP__Material__c p : materials) {
        if (p.AcctSeedERP__Product__r.RecordTypeId == LGND_Constants.productRtId_Bundle) {
          for (Prepaid_Package_Item__c item : packageItems) {
            if (item.Package__c == p.AcctSeedERP__Product__c) {
              Boolean serviceFound = false;
              for (Prepaid_Service__c existingService : services) {
                if (
                  existingService.Account__c == p.AcctSeedERP__Project__r.AcctSeed__Account__c &&
                  existingService.Product__c == item.Item__c &&
                  existingService.ERP_Order__c == p.AcctSeedERP__Project__c
                ) {
                  existingService.Quantity__c = item.Quantity__c;
                  serviceFound = true;
                }
              }
              if (!serviceFound) {
                services.add(
                  new Prepaid_Service__c(
                    Account__c = p.AcctSeedERP__Project__r.AcctSeed__Account__c,
                    ERP_Order__c = p.AcctSeedERP__Project__c,
                    Product__c = item.Item__c,
                    Quantity__c = item.Quantity__c
                  )
                );
              }
            }
          }
        } else {
          Boolean serviceFound = false;
          for (Prepaid_Service__c existingService : services) {
            if (
              existingService.Account__c == p.AcctSeedERP__Project__r.AcctSeed__Account__c &&
              existingService.Product__c == p.AcctSeedERP__Product__c &&
              existingService.ERP_Order__c == p.AcctSeedERP__Project__c
            ) {
              existingService.Quantity__c = p.AcctSeedERP__Quantity_per_Unit__c;
              serviceFound = true;
            }
          }
          if (!serviceFound) {
            services.add(
              new Prepaid_Service__c(
                Account__c = p.AcctSeedERP__Project__r.AcctSeed__Account__c,
                ERP_Order__c = p.AcctSeedERP__Project__c,
                Product__c = p.AcctSeedERP__Product__c,
                Quantity__c = p.AcctSeedERP__Quantity_per_Unit__c
              )
            );
          }
        }
      }

      if (services.size() > 0) {
        upsert services;
      }
    }

    private void cleanPrepaids(Set<Id> projectIds) {
      Prepaid_Service__c[] services = [SELECT Id FROM Prepaid_Service__c WHERE ERP_Order__c IN :projectIds];

      for (Prepaid_Service__c s : services) {
        s.Quantity__c = 0;
      }

      update services;
    }
  }

  @TestVisible
  private static String formatPrepaidsForDisplay(PrepaidService[] prepaids) {
    PrepaidServiceItem[] items = new List<PrepaidServiceItem>();

    Integer x = 0;

    for (PrepaidService p : prepaids) {
      x++;
      PrepaidServiceItem s = new PrepaidServiceItem();
      s.name = x + '';
      s.prepaidId = p.prepaid.Id;
      s.prepaidServiceName = p.prepaid.Name;
      s.product = p.prepaid.Product__r.Name;
      s.productId = p.prepaid.Product__c;
      s.quantity = p.prepaid.Quantity__c;
      s.redeemed = p.prepaid.Redeemed__c;
      s.balance = p.prepaid.Balance__c;
      s.riggingTime = (p.prepaid.Product__r.Rigging_Time__c == null) ? 0 : p.prepaid.Product__r.Rigging_Time__c;

      Integer y = 0;
      for (Product2 product : p.products) {
        y++;
        PrepaidServiceItem child = new PrepaidServiceItem();
        child.name = x + '.' + y;
        child.product = product.Name;
        s.children.add(child);
      }
      items.add(s);
    }
    return JSON.serialize(items);
  }
}
