public with sharing class Prepaid_Service_dh {
  @AuraEnabled
  public static String initData(String recordId) {
    if (!allowedToCreate()) {
      String msg = 'You do not have permission. Contact your Administrator if you feel this is something you should be able to do';
      AuraHandledException ex = new AuraHandledException(msg);
      ex.setMessage(msg);
      throw ex;
    }
    AcctSeedERP__Material__c mat = [
      SELECT
        Id,
        AcctSeedERP__Project__c,
        AcctSeedERP__Project__r.Serial_Number__c,
        AcctSeedERP__Project__r.Serial_Number__r.Name,
        AcctSeedERP__Project__r.Serial_Product__c,
        AcctSeedERP__Project__r.AcctSeed__Account__c,
        AcctSeedERP__Project__r.AcctSeed__Account__r.Name,
        AcctSeedERP__Product__c,
        AcctSeedERP__Product__r.Name,
        AcctSeedERP__Quantity_Per_Unit__c
      FROM AcctSeedERP__Material__c
      WHERE Id = :recordId
    ];
    Map<String, String> result = new Map<String, String>();
    result.put('productId', mat.AcctSeedERP__Product__c);
    result.put('productName', mat.AcctSeedERP__Product__r.Name);
    result.put('erpId', mat.AcctSeedERP__Project__c);
    result.put('accountId', mat.AcctSeedERP__Project__r.AcctSeed__Account__c);
    result.put('accountName', mat.AcctSeedERP__Project__r.AcctSeed__Account__r.Name);
    result.put('quantity', String.valueOf(mat.AcctSeedERP__Quantity_Per_Unit__c));
    if (mat.AcctSeedERP__Project__r.Serial_Number__c != null) {
      result.put('serialProduct', mat.AcctSeedERP__Project__r.Serial_Product__c);
      result.put('serialId', mat.AcctSeedERP__Project__r.Serial_Number__c);
      result.put('serialNumber', mat.AcctSeedERP__Project__r.Serial_Number__r.Name);
    }
    return JSON.serialize(result);
  }

  @AuraEnabled
  public static String saveRecord(String productId, String accountId, String erpId, String serialId, Decimal quantity) {
    Prepaid_Service__c pps = new Prepaid_Service__c(
      Account__c = accountId,
      ERP_Order__c = erpId,
      Product__c = productId,
      Serial_Number__c = serialId,
      Quantity__c = quantity
    );
    if (checkIfExists(pps)) {
      String msg = 'Prepaid Service has already been created';
      AuraHandledException ex = new AuraHandledException(msg);
      ex.setMessage(msg);
      throw ex;
    }
    insert pps;
    return JSON.serialize(pps);
  }

  private static Boolean allowedToCreate() {
    return Schema.sObjectType.Prepaid_Service__c.isCreateable();
  }

  private static Boolean checkIfExists(Prepaid_Service__c pps) {
    try {
      Prepaid_Service__c existing = [
        SELECT Id
        FROM Prepaid_Service__c
        WHERE
          Account__c = :pps.Account__c
          AND ERP_Order__c = :pps.ERP_Order__c
          AND Product__c = :pps.Product__c
          AND Serial_Number__c = :pps.Serial_Number__c
      ];
      return true;
    } catch (Exception e) {
      return false;
    }
  }
}
