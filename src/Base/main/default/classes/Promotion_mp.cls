public without sharing class Promotion_mp {
  static Id dealerRtId = LGND_Utilities.recordTypeIdFromName('Account', 'Dealer');
  static Id promoRtId = LGND_Utilities.recordTypeIdFromName('Case', 'Promotion');

  public class PromoRegistrationWrapper {
    public Registration__c registration { get; set; }
    public Promotion_Item__c promoItem { get; set; }
    public Case promoCase { get; set; }

    public PromoRegistrationWrapper() {
    }
  }

  private static Boolean checkForExistingClaim(Id customerId, Id productId) {
    Case[] claims = [SELECT Id FROM Case WHERE ContactId = :customerId AND Promotion_Item__r.Product__c = :productId];
    if (claims.size() > 1)
      return true;
    else
      return false;
  }

  public static Id getAccountId() {
    return [SELECT AccountId FROM User WHERE Id = :Userinfo.getUserId()].AccountId;
  }

  @AuraEnabled
  public static String getPromoCases() {
    Id dealerId = getAccountId();
    Set<Id> sernoIds = new Set<Id>();
    Set<Id> promoItemIds = new Set<Id>();
    Map<Id, Case> caseMap = new Map<Id, Case>();
    Map<Id, Registration__c> regMap = new Map<Id, Registration__c>();
    Map<Id, Promotion_Item__c> piMap = new Map<Id, Promotion_Item__c>();
    List<PromoRegistrationWrapper> promoCases = new List<PromoRegistrationWrapper>();

    Case[] cases = [
      SELECT
        Id,
        AccountId,
        Account.Name,
        Promotion_Item__c,
        Promotion_Item__r.Amount__c,
        Promotion_Item__r.Product__r.Name,
        Promotion_Item__r.Promotion__r.Name,
        Serial_Number__c,
        Serial_Number__r.Name,
        Status
      FROM Case
      WHERE RecordTypeId = :promoRtId AND AccountId = :dealerId AND Status LIKE 'Pending%'
    ];

    System.debug('Cases : ' + cases);

    for (Case c : cases) {
      if (!caseMap.containsKey(c.Serial_Number__c)) {
        caseMap.put(c.Serial_Number__c, c);
      }
      sernoIds.add(c.Serial_Number__c);
      promoItemIds.add(c.Promotion_Item__c);
    }

    for (Registration__c reg : [
      SELECT Id, Account__r.Name, SerialNumber__c
      FROM Registration__c
      WHERE SerialNumber__c IN :sernoIds AND isCurrent__c = TRUE
    ]) {
      regMap.put(reg.SerialNumber__c, reg);
    }

    for (Promotion_Item__c pi : [SELECT Id FROM Promotion_Item__c WHERE Id IN :promoItemIds]) {
      if (!piMap.containsKey(pi.Id)) {
        piMap.put(pi.Id, pi);
      }
    }

    for (Case c : cases) {
      PromoRegistrationWrapper prw = new PromoRegistrationWrapper();
      prw.registration = regMap.get(c.Serial_Number__c);
      prw.promoItem = piMap.get(c.Promotion_Item__c);
      prw.promoCase = c;
      promoCases.add(prw);
    }

    System.debug(promoCases);

    return JSON.serialize(promoCases);
  }

  public static Case buildPromoCase(Id customerId, Id acctId, Id promotionItemId, Id serialNumberId, Id regId) {
    System.debug('regId: ' + regId);
    Id cId = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].ContactId;
    Case promoCase = new Case(
      ContactId = cId,
      RecordTypeId = promoRtId,
      AccountId = acctId,
      Promotion_Item__c = promotionItemId,
      Promotion_Customer_Account__c = customerId,
      Serial_Number__c = serialNumberId,
      Status = 'Pending documentation',
      Registration__c = regId
    );
    return promoCase;
  }

  @AuraEnabled
  public static Account[] getDealerAccounts() {
    return [SELECT Id, Name FROM Account WHERE RecordTypeId = :dealerRtId AND Active__c = TRUE ORDER BY Name ASC];
  }

  @AuraEnabled
  public static Promotion__c createNewPromotion(Promotion__c promotion, List<Id> selectedAccounts) {
    Promotion__c promo = new Promotion__c(
      Name = promotion.Name,
      Start_Date__c = promotion.Start_Date__c,
      End_Date__c = promotion.End_Date__c,
      Description__c = promotion.Description__c
    );
    insert promo;

    if (selectedAccounts != null) {
      Set<Promotion_Account__c> promoAccounts = new Set<Promotion_Account__c>();
      for (Id accId : selectedAccounts) {
        Promotion_Account__c promoAccount = new Promotion_Account__c(
          Name = promo.Name + ' : ' + accId,
          Account__c = accId,
          Promotion__c = promo.Id
        );
        promoAccounts.add(promoAccount);
      }
      List<Promotion_Account__c> promoAccountsList = new List<Promotion_Account__c>();
      for (Promotion_Account__c pa : promoAccounts) {
        promoAccountsList.add(pa);
      }
      insert promoAccountsList;
    }
    return promo;
  }

  @AuraEnabled
  public static Product2[] getProducts() {
    return [
      SELECT Id, Name
      FROM Product2
      WHERE isActive = TRUE AND RecordType.Name = 'Boat' AND Make__c = 'Legend'
      ORDER BY Name ASC
      LIMIT 500
    ];
  }

  @AuraEnabled
  public static Promotion_Item__c[] getDetailedProducts(String[] prodIds, Promotion__c promotion) {
    Promotion_Item__c[] promoItems = new List<Promotion_Item__c>();
    for (Product2 product : [SELECT Id, Name FROM Product2 WHERE Id IN :prodIds ORDER BY Name ASC]) {
      Promotion_Item__c promoItem = new Promotion_Item__c(
        Amount__c = 0.00,
        Product__c = product.Id,
        Promotion__c = promotion.Id,
        Retail_Amount__c = 0.00
      );
      promoItems.add(promoItem);
    }
    insert promoItems;
    /*
			Note for future dev/self:
			The reason I don't simply return the promoItems here is that I cannot
			directly reference Product__r.Name yet. In order to do so, I need to
			query the database first.
		*/
    Set<Id> promoItemIds = new Set<Id>();
    for (Promotion_Item__c promoItem : promoItems) {
      promoItemIds.add(promoItem.Id);
    }
    return [SELECT Id, Product__r.Name, Amount__c, Retail_Amount__c FROM Promotion_Item__c WHERE Id IN :promoItemIds];
  }

  @AuraEnabled
  public static Promotion__c savePromoAndItems(Promotion__c promotion, Promotion_Item__c[] promoItems) {
    update promotion;
    update promoItems;
    return promotion;
  }

  @AuraEnabled
  public static String getPromotions() {
    Id accId = [SELECT AccountId FROM User WHERE Id = :UserInfo.getUserId()].AccountId;

    Set<Id> promoIds = new Set<Id>();
    for (Promotion_Account__c ap : [
      SELECT Promotion__c
      FROM Promotion_Account__c
      WHERE
        Account__c = :accId
        AND Promotion__r.Start_Date__c <= :Datetime.now()
        AND Promotion__r.End_Date__c >= :Datetime.now()
    ]) {
      promoIds.add(ap.Promotion__c);
    }
    Promotion__c[] freePromotions = [
      SELECT Id, Name, Start_Date__c, End_Date__c, Document_Requirements__c
      FROM Promotion__c
      WHERE
        Id NOT IN (SELECT Promotion__c FROM Promotion_Account__c)
        AND Start_Date__c <= :Datetime.now()
        AND End_Date__c >= :Datetime.now()
      ORDER BY End_Date__c ASC
    ];
    Promotion__c[] accountPromotions = [
      SELECT Id, Name, Start_Date__c, End_Date__c, Document_Requirements__c
      FROM Promotion__c
      WHERE Id IN :promoIds AND Start_Date__c <= :Datetime.now() AND End_Date__c >= :Datetime.now()
      ORDER BY End_Date__c ASC
    ];
    Promotion__c[] promotions = new List<Promotion__c>();
    for (Promotion__c p : freePromotions) {
      promotions.add(p);
    }
    for (Promotion__c p : accountPromotions) {
      promotions.add(p);
    }
    return JSON.serialize(promotions);
  }

  @AuraEnabled
  public static Case claimPromotion(String caseId, String regId, String piId) {
    Case c = [
      SELECT
        Id,
        AccountId,
        Account.Name,
        Product_Name__c,
        Promotion_Item__c,
        Promotion_Item__r.Amount__c,
        Promotion_Item__r.Product__r.Name,
        Promotion_Item__r.Promotion__r.Name,
        Serial_Number__c,
        Status
      FROM Case
      WHERE Id = :caseId
    ];
    Registration__c reg = [
      SELECT Id, Account__r.Name, SerialNumber__c, SerialNumber__r.Name
      FROM Registration__c
      WHERE Id = :regId
    ];
    Promotion_Item__c pi = [SELECT Id FROM Promotion_Item__c WHERE Id = :piId];

    c.Serial_Number__c = reg.SerialNumber__c;
    c.Registration__c = reg.Id;
    c.Promotion_Item__c = pi.Id;
    c.Status = 'Pending review';

    update c;
    return c;
  }

  @AuraEnabled
  public static Case claimPromoWithoutSerno(Id promoItemId) {
    Id accId = getAccountId();
    Promotion_Item__c promoItem = [SELECT Id, Product__r.Name FROM Promotion_Item__c WHERE Id = :promoItemId];
    Case c = new Case(
      RecordTypeId = promoRtId,
      AccountId = accId,
      Promotion_Item__c = promoItem.Id,
      Status = 'Pending registration'
    );
    insert c;
    return c;
  }

  @AuraEnabled
  public static Case claimPromoWithoutSerno(Id promoItemId, Id customerId) {
    System.debug('promoItemId: ' + promoItemId);
    System.debug('customerId: ' + customerId);

    Id accId = getAccountId();
    Id customerAccId = getCustomerAccountId(customerId);

    Case c = new Case(
      RecordTypeId = promoRtId,
      AccountId = accId,
      Promotion_Item__c = promoItemId,
      Status = 'Pending registration',
      Promotion_Customer_Account__c = customerAccId
    );
    insert c;

    System.debug(c);

    return c;
  }

  @AuraEnabled
  public static String getPromoItems(Id promoId) {
    List<Promotion_Item__c> promoItems = [
      SELECT Id, Product__r.Name, Promotion__r.Name
      FROM Promotion_Item__c
      WHERE Promotion__c = :promoId
    ];
    return JSON.serialize(promoItems);
  }

  @AuraEnabled
  public static String clonePromo(Id promoId) {
    Promotion__c originalPromo = [
      SELECT Id, Name, Start_Date__c, End_Date__c, Description__c
      FROM Promotion__c
      WHERE Id = :promoId
    ];

    Promotion__c clone = new Promotion__c(
      Name = originalPromo.Name + ' (copy)',
      Start_Date__c = originalPromo.Start_Date__c,
      End_Date__c = originalPromo.End_Date__c,
      Description__c = originalPromo.Description__c
    );
    insert clone;

    Promotion_Item__c[] originalPromoItems = [
      SELECT Id, Amount__c, Product__c, Promotion__c, Retail_Amount__c
      FROM Promotion_Item__c
      WHERE Promotion__c = :promoId
    ];

    Promotion_Item__c[] newPromoItems = new List<Promotion_Item__c>();
    for (Promotion_Item__c pi : originalPromoItems) {
      Promotion_Item__c newPi = new Promotion_Item__c(
        Amount__c = pi.Amount__c,
        Product__c = pi.Product__c,
        Promotion__c = clone.Id,
        Retail_Amount__c = pi.Retail_Amount__c
      );
      newPromoItems.add(newPi);
    }
    insert newPromoItems;

    Promotion_Account__c[] originalPromoAccounts = [
      SELECT Id, Account__c, Promotion__c
      FROM Promotion_Account__c
      WHERE Promotion__c = :promoId
    ];

    Promotion_Account__c[] newPromoAccounts = new List<Promotion_Account__c>();
    for (Promotion_Account__c pa : originalPromoAccounts) {
      Promotion_Account__c newPa = new Promotion_Account__c(Account__c = pa.Account__c, Promotion__c = clone.Id);
      newPromoAccounts.add(newPa);
    }
    insert newPromoAccounts;

    return JSON.serialize(clone);
  }

  @AuraEnabled
  public static Case getClaimDetails(Id caseId) {
    System.debug(caseId);
    Case c = [
      SELECT
        Id,
        AccountId,
        Account.Name,
        CaseNumber,
        ContactId,
        Contact.AccountId,
        Customer_Name__c,
        Description,
        Promotion__c,
        Promotion_Item__r.Promotion__r.Document_Requirements__c,
        Promotion_Item__c,
        Promotion_Item__r.Product__r.Name,
        Promotion_Item__r.Retail_Amount__c,
        Promotion_Item__r.Amount__c,
        Promotion_Customer_Account__c,
        Promotion_Customer_Account__r.Name,
        Registration__c,
        Registration__r.SerialNumber__c,
        Registration__r.SerialNumber__r.Name,
        Serial_Number__c,
        Serial_Number_Name__c,
        Status
      FROM Case
      WHERE Id = :caseId
    ];
    System.debug(c);
    return c;
  }

  @AuraEnabled
  public static String getAvailablePromotionsByProduct(Id productId) {
    List<Promotion_Item__c> promoItems = [
      SELECT Id, Product__r.Name, Promotion__c, Promotion__r.Name, Promotion__r.Document_Requirements__c
      FROM Promotion_Item__c
      WHERE
        Product__c = :productId
        AND Promotion__r.Start_Date__c <= :Datetime.now()
        AND Promotion__r.End_Date__c >= :Datetime.now()
    ];
    return JSON.serialize(promoItems);
  }

  @AuraEnabled
  public static List<String> getPromoDocumentationRequirementOptions() {
    List<String> pickListValuesList = new List<String>();
    Schema.DescribeFieldResult fieldResult = Promotion__c.Document_Requirements__c.getDescribe();
    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    for (Schema.PicklistEntry pickListVal : ple) {
      pickListValuesList.add(pickListVal.getLabel());
    }
    return pickListValuesList;
  }

  @AuraEnabled
  public static Promotion_Item__c getPromotionViaItem(Id promoItemId) {
    return [
      SELECT
        Promotion__r.Id,
        Promotion__r.Name,
        Promotion__r.Start_Date__c,
        Promotion__r.End_Date__c,
        Promotion__r.Document_Requirements__c
      FROM Promotion_Item__c
      WHERE Id = :promoItemId
    ][0];
  }

  @AuraEnabled
  public static String getAvailablePromos(Id recordId) {
    Registration__c reg = [
      SELECT
        Id,
        Account__c,
        Account__r.RecordType.Name,
        Product_Name__c,
        SerialNumber__r.GMBLASERP__Product__c,
        SerialNumber__c,
        RegisteredByAccount__c,
        Registered_Date__c
      FROM Registration__c
      WHERE Id = :recordId
    ];

    if (reg.Account__r.RecordType.Name == 'Dealer') {
      return null;
    }

    Case[] claims = [SELECT Id FROM Case WHERE Registration__c = :recordId];

    if (claims.size() > 0) {
      return JSON.serialize(1);
    }

    if (claims.size() <= 0) {
      return JSON.serialize(
        [
          SELECT Id, Product__c, Product__r.Name, Promotion__c, Promotion__r.Name
          FROM Promotion_Item__c
          WHERE
            Product__c = :reg.SerialNumber__r.GMBLASERP__Product__c
            AND Promotion__r.Start_Date__c <= :reg.Registered_Date__c
            AND Promotion__r.End_Date__c >= :reg.Registered_Date__c
        ]
      );
    }
    return null;
  }

  @AuraEnabled
  public static String getClaims(Id recordId) {
    Case[] claims = [SELECT Id, Promotion_Item__r.Promotion__r.Name FROM Case WHERE Registration__c = :recordId];
    return JSON.serialize(claims);
  }

  @AuraEnabled
  public static String startClaim(Id recordId, Id promoId) {
    Registration__c reg = [
      SELECT
        Id,
        Account__c,
        Account__r.Type,
        Product_Name__c,
        SerialNumber__r.GMBLASERP__Product__c,
        SerialNumber__c,
        RegisteredByAccount__c
      FROM Registration__c
      WHERE Id = :recordId
    ];

    Promotion_Item__c pi = [
      SELECT Id, Product__c, Product__r.Name, Promotion__c, Promotion__r.Name
      FROM Promotion_Item__c
      WHERE Id = :promoId
    ];
    Case c = new Case(
      RecordTypeId = promoRtId,
      AccountId = reg.RegisteredByAccount__c,
      Promotion_Item__c = pi.Id,
      Status = 'Pending documentation',
      Promotion_Customer_Account__c = reg.Account__c,
      Registration__c = recordId,
      Serial_Number__c = reg.SerialNumber__c
    );
    insert c;

    return JSON.serialize(c);
  }

  @TestVisible
  private static Id getCustomerAccountId(Id customerId) {
    if (customerId.getSObjectType().getDescribe().getName() == 'Lead') {
      Database.LeadConvert lc = new Database.LeadConvert();
      lc.setLeadId(customerId);
      LeadStatus cStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
      lc.setConvertedStatus(cStatus.MasterLabel);
      lc.setDoNotCreateOpportunity(true);
      try {
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        return lcr.getAccountId();
      } catch (Exception e) {
        System.debug('LeadId = ' + customerId);
        return customerId;
      }
    }
    return customerId;
  }
}
