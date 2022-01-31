public with sharing class lgnd_newClaimController {
  public class ClaimException extends Exception{}

  private static Id pricebookId = LGND_Constants.partnerPricebookId;

  @AuraEnabled
  public static Map<String, Object> initForm()
  {
    Id warrantyLabourProduct = LGND_Constants.partnerWarrantyLabourProductId;
    Map<String, Object> result = New Map<String, Object>();
    result.put('pricebookId', pricebookId);
    result.put('warrantyLabourProduct', warrantyLabourProduct);
    result.put('laborPrice', getUnitPrice(warrantyLabourProduct) );
    result.put('claimTypeOptions', buildClaimTypeOptions() );
    return result;
  }

  @AuraEnabled
  public static Id getPricebookId() {
    return pricebookId;
  }

  @AuraEnabled
  public static String saveWithParts(String caseJson, List<Case_Part__c> caseParts) {
    Case c;

    if (caseJson == null) {
      return null;
    } else {
      c = (Case)JSON.deserialize(caseJson, Case.class);
    }

    Id accountId;

    try {
      accountId = [SELECT AccountId FROM User WHERE Id = :Userinfo.getUserId()].AccountId;

      if (accountId != null) {
        c.AccountId = accountId;
      } else {
        c.AccountId = '';
      }
    }
    catch( Exception e ){
      System.debug(e);
    }

    System.debug(c);

    c.recordTypeId = LGND_Utilities.recordTypeIdFromName('Case','Warranty');

    upsert c;

    System.debug(caseParts);

    if (caseParts != null) {
      /// Delete previously entered case parts.
      for (Case_Part__c casePart: caseParts) {
        if(casePart.Case__c == null)
          casePart.Case__c = c.Id;
      }
      upsert caseParts;
    }

    System.debug(String.ValueOf(c.Id));

    return String.ValueOf(c.Id);
  }

  @AuraEnabled
  public static String saveWithoutParts(Case c) {

    System.debug('newClaim.saveWithoutParts');

    if (c == null) {
      return null;
    } else {
      System.debug(c);
    }

    Id accountId;

    try {
      accountId = [SELECT AccountId FROM User WHERE Id = :Userinfo.getUserId()].AccountId;

      if (accountId != null) {
        c.AccountId = accountId;
      } else {
        c.AccountId = '';
      }
    }
    catch( Exception e ){
      System.debug(e);
    }

    System.debug(c);

    c.recordTypeId = LGND_Utilities.recordTypeIdFromName('Case','Warranty');

    upsert c;

    System.debug(String.ValueOf(c.Id));

    return String.ValueOf(c.Id);
  }

  @AuraEnabled
  public static List<ContentVersion> getDocs (Id caseId) {
    System.debug(caseId);
    ContentDocumentLink[] links = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :caseId];
    Set<Id> contentDocIds = new Set<Id>();
    for (ContentDocumentLink contentDocLink : links) {
        contentDocIds.add(contentDocLink.ContentDocumentId);
    }
    List<Id> contentDocIdList = new List<Id>(contentDocIds);

    ContentVersion[] docs = [SELECT Title FROM ContentVersion WHERE ContentDocumentId IN :contentDocIdList AND IsLatest = True];
    return docs;
  }

  @AuraEnabled
  public static Registration__c getRegistration(Id serialId) {
    if (String.isBlank(serialId)) {
      return null;
    }
    List<Registration__c> registrations = [SELECT Account__r.Name, CreatedDate FROM Registration__c WHERE SerialNumber__c = :serialId LIMIT 1];
    if (registrations.size() > 0) {
      return registrations.get(0);
    }
    // otherwise no registration found
    return null;
  }

  @AuraEnabled
  public static Product2 getProduct(Id id) {
    if (String.isBlank(id)) {
      return null;
    }
    List<Product2> product = [SELECT Id, Name, Family FROM Product2 WHERE Id = :id];
    if (product.isEmpty()) {
      return null;
    }
    return product[0];
  }

  @AuraEnabled
  public static Case_Part__c[] getParts(Case c) {
    return [SELECT Case__c,
                   Id,
                   Material__c,
                   Name,
                   Product__c,
                   Product__r.Name,
                   Product__r.Family,
                   Product_Code__c,
                   Unit_Price__c,
                   Order_Quantity__c,
                   Quantity__c,
                   Case__r.Status
              FROM Case_Part__c
             WHERE Case__c = :c.Id];
  }

  @AuraEnabled
  public static Case_Part__c[] getPartByCaseId(Id caseId) {
    return [SELECT Case__c,
                   Id,
                   Material__c,
                   Name,
                   Product__c,
                   Product__r.Name,
                   Product__r.Family,
                   Product_Code__c,
                   Unit_Price__c,
                   Order_Quantity__c,
                   Quantity__c,
                   Case__r.Status
              FROM Case_Part__c
             WHERE Case__c = :caseId];
  }

  @AuraEnabled
  public static Boolean deleteClaims(List<String> claimIds) {
    Case[] deadClaimsWalking = [SELECT Id FROM Case WHERE Id IN :claimIds];
    System.debug(deadClaimsWalking);
    try {
      delete deadClaimsWalking;
    } catch (DmlException e) {
      System.debug(e);
      return false;
    }
    return true;
  }

  @AuraEnabled
  public static void deletePartById(Id idPart) {
    delete [SELECT Id FROM Case_Part__c WHERE Id =:idPart];
  }

  @AuraEnabled
  public static void updatePartById(Id idPart,String qty) {
    Case_Part__c part = [SELECT Id FROM Case_Part__c WHERE Id =:idPart];
    part.Quantity__c = Integer.valueOf(qty);
    update part;
  }

  @AuraEnabled
  public static Decimal getUnitPrice(String productId) {
    System.debug( '>>>>>>>>>>>>>>>> ' + productId + ' <<<<<<<<<<<<<<');
    try {
      PriceBookEntry pbe =  [SELECT UnitPrice
                              FROM PricebookEntry
                              WHERE Pricebook2Id = :pricebookId
                              AND Product2Id = :productId
                              LIMIT 1];
      System.debug( pbe );
      return pbe.UnitPrice;
    }
    catch( Exception e )
    {
      System.debug('>>>>> In catch block <<<<<<<<< ');
      Product2 p = getProduct(productId);
      Pricebook2 pb = [SELECT Id, Name FROM Pricebook2 WHERE Id = :priceBookId];
      String message = '';
      message += p.Name;
      message += ' can not be found in ' + pb.Name + ' Pricebook. \n';
      message += 'Please contact your Product Specialist to help remedy this issue.';
      throw new AuraHandledException(message);
    }
  }

  @AuraEnabled
  public static Id getProductIdByName(String name) {
    return [select Id from Product2 where Name = :name limit 1].Id;
  }

  private static List<Map<String, Object>> buildClaimTypeOptions()
  {
    List<Map<String, Object>> options = new List<Map<String, Object>>();
    options.add( new Map<String, Object>{
      'class' => 'optionClass',
      'label' => '--None--',
      'value' => '',
      'selected' => false
    });
    for( String claimType : LGND_Utilities.getPicklistValues('Case', 'Claim_Type__c'))
    {
      options.add( new Map<String, Object>{
        'class' => 'optionClass',
        'label' => claimType,
        'value' => claimType
      });
    }
    return options;
  }
}