public with sharing class SerialNumber_History_Controller_dh {

  public class HistoryWrapper {
    public String recordId;
    public Registration__c currentRegistration;
    public Registration__c[] registrations;

    public HistoryWrapper( String recordId )
    {
      this.recordId = recordId;
      fetchRegistrations();
    }

    private void fetchRegistrations()
    {
      this.registrations = new List<Registration__c>();
      for( Registration__c reg : [SELECT Id,
                                         Registered_Motor__r.Name,
                                         Registered_Motor_Serial__c,
                                         RegisteredByAccount__r.Name,
                                         Account__c,
                                         Account__r.Name,
                                         Account__r.BillingStreet,
                                         Account__r.BillingCity,
                                         Account__r.BillingState,
                                         Account__r.BillingCountry,
                                         Account__r.BillingPostalCode,
                                         Account__r.IsPersonAccount,
                                         Delivery_Date__c,
                                         Registered_Date__c,
                                         IsCurrent__c
                                  FROM Registration__c
                                  WHERE SerialNumber__c = :this.recordId] )
      {
        if( reg.IsCurrent__c )
          this.currentRegistration = reg;
        else
          this.registrations.add( reg );
      }
    }
  }

  @AuraEnabled
  public static String fetchData( String recordId )
  {
    HistoryWrapper hw = new HistoryWrapper( recordId );
    return JSON.serialize( hw );
  }

}