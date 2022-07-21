/**
 * Created by dave on 2021-06-03.
 */

public inherited sharing class Application_Constants {
  private class QueuesException extends Exception {
  }

  private static Application_Constants instance = null;

  public User currentUser {
    get {
      if (currentUser == null) {
        currentUser = [SELECT Id, Sales_Department__c, Warehouse__c FROM User WHERE Id = :UserInfo.getUserId()];
      }
      return currentUser;
    }
    private set;
  }

  public ActivePricebooks activePricebooks {
    get {
      if (activePricebooks == null) {
        activePricebooks = new ActivePricebooks();
      }
      return activePricebooks;
    }
    set {
    }
  }

  public UtilityProducts utilityProducts {
    get {
      if (utilityProducts == null) {
        utilityProducts = new UtilityProducts();
      }
      return utilityProducts;
    }
    set {
    }
  }

  public Queues queues {
    get {
      if (queues == null) {
        queues = new Queues();
      }
      return queues;
    }
    set {
    }
  }

  private Application_Constants() {
  }

  public static Application_Constants getInstance() {
    if (instance == null)
      instance = new Application_Constants();
    return instance;
  }

  public class ActivePricebooks {
    private final Legend_Settings__c settings {
      get {
        if (settings == null) {
          settings = Legend_Settings__c.getOrgDefaults();
        }
        return settings;
      }
      set {
      }
    }
    public Id retailId;
    public Id partnerId;
    public Id factoryId;

    public ActivePricebooks() {
      this.retailId = settings.Default_Retail_Pricebook__c;
      this.partnerId = settings.Default_Partner_Pricebook__c;
      this.factoryId = settings.Default_Factory_Pricebook__c;
    }

    public Set<Id> idSet() {
      Set<Id> result = new Set<Id>();
      result.add(this.retailId);
      result.add(this.partnerId);
      result.add(this.factoryId);
      return result;
    }
  }

  public class UtilityProducts {
    private Utility_Products__c uProds {
      get {
        if (uProds == null) {
          uProds = Utility_Products__c.getOrgDefaults();
        }
        return uProds;
      }
      set {
      }
    }

    public UtilityProducts() {
    }

    public Id getBackOrderCredit() {
      return this.uProds.Back_Order_Credit__c;
    }
    public Id getBackOrderPrepaid() {
      return this.uProds.Back_Order_Prepaid__c;
    }
    public Id getFlexibleAccessoriesCredit() {
      return this.uProds.Flexible_Accessories_Credit__c;
    }
    public Id getFreight() {
      return this.uProds.Freight__c;
    }
    public Id getPartnerCustomProduct() {
      return this.uProds.Partner_Custom_Product__c;
    }
    public Id getPartnerWarrantyLabour() {
      return this.uProds.Partner_Warranty_Labour__c;
    }
    public Id getSavings() {
      return this.uProds.Savings__c;
    }
    public Id getSublet() {
      return this.uProds.Sublet__c;
    }
  }

  public class Queues {
    private Map<String, Group> allQueuesByDeveloperName {
      get {
        if (allQueuesByDeveloperName == null) {
          allQueuesByDeveloperName = new Map<String, Group>();
          for (Group g : [SELECT Id, Name, DeveloperName FROM Group WHERE Type = 'Queue']) {
            allQueuesByDeveloperName.put(g.DeveloperName, g);
          }
        }
        return allQueuesByDeveloperName;
      }
      set {
      }
    }

    public Queues() {
    }

    public Id getIdByDeveloperName(String devName) {
      try {
        return this.allQueuesByDeveloperName.get(devName).Id;
      } catch (Exception e) {
        throw new Application_Constants.QueuesException('Queue does not exist with Developer Name \"' + devName + '\"');
      }
    }
    public Id getAccountTeamId() {
      return getIdByDeveloperName('Accounting_Team');
    }
  }
}
