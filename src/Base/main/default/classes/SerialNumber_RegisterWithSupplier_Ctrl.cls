/**
 * Created by dave on 2019-10-22.
 */

public with sharing class SerialNumber_RegisterWithSupplier_Ctrl {
  @AuraEnabled
  public static GMBLASERP__Serial_Number__c fetchSerialNumber(String serialId) {
    return [
      SELECT
        Id,
        IsRegisteredWithSupplier__c,
        RegisteredWithSupplierDate__c,
        GMBLASERP__Product__r.AcctSeedERP__Default_Vendor__r.Name
      FROM GMBLASERP__Serial_Number__c
      WHERE Id = :serialId
    ];
  }

  @AuraEnabled
  public static Registration__c fetchRegistration(String serialId) {
    return Registration_Selector.currentCustomerRegistrationBySerial(serialId);
  }

  @AuraEnabled
  public static void doRegister(String registrationId) {
    String errorMessage;
    SupplierRegistration sr = new SupplierRegistration(new Set<Id>{ registrationId });
    SupplierRegistration.Result[] results = sr.execute();
    if (results.size() == 0) {
      throwError('Registration through Salesforce is not supported for this Supplier. Yet!');
    }
    SupplierRegistration.Result result = results[0];
    if (result.status == 'error') {
      throwError(result.errorMessage);
    }
    update new GMBLASERP__Serial_Number__c(
      Id = result.wrapper.SerialId,
      IsRegisteredWithSupplier__c = true,
      RegisteredWithSupplierDate__c = DateTime.now()
    );
  }

  private static void throwError(String msg) {
    AuraHandledException ex = new AuraHandledException(msg);
    ex.setMessage(msg);
    throw ex;
  }
}
