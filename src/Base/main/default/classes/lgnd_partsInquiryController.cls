public with sharing class lgnd_partsInquiryController {
  @AuraEnabled
  public static String save(String sernoName, String model, Integer lot, String description, String partnerReference) {
    Id accountId;
    if (String.isBlank(sernoName)) {
      throw new SerialNumber_Exception('You must specify Boat serial number');
    }
    Case c = new Case(
      Inquiry_Serial_Number__c = sernoName,
      Inquiry_Product_Name__c = model,
      Inquiry_Product_Year__c = lot,
      Description = description,
      Partner_Reference__c = partnerReference,
      recordTypeId = LGND_Utilities.recordTypeIdFromName('Case', 'PartInquiry')
    );

    try {
      accountId = [SELECT AccountId FROM User WHERE Id = :Userinfo.getUserId()].AccountId;
      if (accountId != null) {
        c.AccountId = accountId;
      } else {
        c.AccountId = '';
      }
    } catch (Exception e) {
      System.debug(e);
    }

    System.debug(sernoName);

    upsert c;

    return c.Id;
    // throw new Exception('').getMessage();
    //return new Exception('invalid').getMessage();
  }
  public class SerialNumber_Exception extends Exception {
  }
}
