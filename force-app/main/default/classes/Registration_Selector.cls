/**
 * Created by dave on 2019-09-04.
 */

public with sharing class Registration_Selector {

  public static List<Registration__c> allById( Set<Id> ids )
  {
    return [ SELECT Id,
                    isCurrent__c,
                    Registered_Date__c,
                    Delivery_Date__c,
                    CreatedDate,
                    Registered_To_Customer__c,
                    Registered_Motor__c,
                    Account__c,
                    Account__r.Id,
                    Account__r.Name,
                    Account__r.PersonEmail,
                    Account__r.Number_of_Children__c,
                    Account__r.Current_Age__pc,
                    Account__r.BillingStreet,
                    Account__r.BillingCity,
                    Account__r.BillingState,
                    Account__r.BillingStateCode,
                    Account__r.BillingCountry,
                    Account__r.BillingPostalCode,
                    Account__r.BillingLatitude,
                    Account__r.BillingLongitude,
                    SerialNumber__c,
                    SerialNumber__r.Name,
                    SerialNumber__r.IsRegisteredWithSupplier__c,
                    SerialNumber__r.GMBLASERP__Product__r.Name,
                    SerialNumber__r.GMBLASERP__Product__r.RecordTypeId,
                    SerialNumber__r.GMBLASERP__Product__r.AcctSeedERP__Default_Vendor__c,
                    SerialNumber__r.GMBLASERP__Product__r.AcctSeedERP__Default_Vendor__r.Name,
                    ERPOrder__c,
                    ERPOrder__r.RecordTypeId
                  FROM Registration__c
                  WHERE Id IN :ids ];
  }

  public static List<Registration__c> allCustomerBoatRegisteredByAccountId( String acctId )
  {
    Id boatRtId = LGND_Constants.productRtId_Boat;
    return [ SELECT Id,
                    Registered_Date__c,
                    Delivery_Date__c,
                    Account__c,
                    Account__r.Name,
                    Account__r.PersonMailingStreet,
                    Account__r.PersonMailingCity,
                    Account__r.PersonMailingState,
                    Account__r.PersonMailingCountry,
                    Account__r.PersonMailingPostalCode,
                    Account__r.PersonMailingLatitude,
                    Account__r.PersonMailingLongitude,
                    SerialNumber__r.GMBLASERP__Product__r.Name
             FROM Registration__c
             WHERE RegisteredByAccount__c = :acctId
             AND Account__r.IsPersonAccount = true
             AND SerialNumber__r.GMBLASERP__Product__r.RecordTypeId = :boatRtId
             ORDER BY Registered_Date__c DESC];
  }

  public static Registration__c currentCustomerRegistrationBySerial( String serialId )
  {
    try
    {
      return [ SELECT Id,
                      Account__r.Id,
                      Account__r.Name,
                      Account__r.PersonEmail,
                      Account__r.Number_of_Children__c,
                      Account__r.Current_Age__pc,
                      Account__r.BillingStreet,
                      Account__r.BillingCity,
                      Account__r.BillingState,
                      Account__r.BillingStateCode,
                      Account__r.BillingCountry,
                      Account__r.BillingPostalCode
               FROM Registration__c
               WHERE SerialNumber__c = :serialId
               AND isCurrent__c = true
               AND Registered_To_Customer__c = true
               LIMIT 1 ];
    }
    catch( Exception e )
    {
      return null;
    }
  }

}