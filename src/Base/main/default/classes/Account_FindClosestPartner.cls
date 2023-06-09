public with sharing class Account_FindClosestPartner {
  @AuraEnabled
  public static String findClosestPartner(String lookupValue, Integer resultCount, String excludedAccountIds) {
    PartnerLocator locator = new PartnerLocator();
    if (excludedAccountIds != null && excludedAccountIds.length() > 0)
      locator.exclude(excludedAccountIds);
    try {
      return JSON.serialize(locator.execute(lookupValue, resultCount, null));
    } catch (Exception e) {
      AuraHandledException ex = new AuraHandledException(e.getMessage());
      ex.setMessage(e.getMessage());
      throw ex;
    }
  }
}
