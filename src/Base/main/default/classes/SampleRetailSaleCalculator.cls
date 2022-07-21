public with sharing class SampleRetailSaleCalculator {
  @AuraEnabled
  public static String fetchInitialData() {
    Map<String, String> result = new Map<String, String>();
    User u = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
    if (u.AccountId == null) {
      result.put('legendVolumeDiscount', null);
      result.put('legendCoopDiscount', null);
      result.put('MercuryVolumeDiscount', null);
      result.put('isInternalAccount', 'false');
    } else {
      Account acct = [
        SELECT Id, Legend_Volume_Discount__c, Legend_Coop_Discount__c, Mercury_Volume_Discount__c, Is_Internal__c
        FROM Account
        WHERE Id = :u.AccountId
      ];
      result.put('legendVolumeDiscount', String.valueOf(acct.Legend_Volume_Discount__c));
      result.put('legendCoopDiscount', String.valueOf(acct.Legend_Coop_Discount__c));
      result.put('MercuryVolumeDiscount', String.valueOf(acct.Mercury_Volume_Discount__c));
      result.put('isInternalAccount', String.valueOf(acct.Is_Internal__c));
    }
    result.put('cpq', JSON.serialize(new CPQ('partner')));
    return JSON.serialize(result);
  }

  //@AuraEnabled
  //public static String fetchBoatOptions( String family )
  //{
  //  return JSON.serialize( new CPQ( 'Boat', family, 'partner' ) );
  //}

  @AuraEnabled
  public static String fetchMajorProductDetails(String cpqJSON) {
    CPQ theCPQ = (CPQ) JSON.deserialize(cpqJSON, CPQ.class);
    theCPQ.selectBoat();
    return JSON.serialize(theCPQ);
  }
}
