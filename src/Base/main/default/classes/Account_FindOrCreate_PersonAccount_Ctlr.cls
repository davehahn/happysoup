/**
 * Created by dave on 2020-10-02.
 */

public with sharing class Account_FindOrCreate_PersonAccount_Ctlr {
  @AuraEnabled
  public static String fetchCustomer(String recordId) {
    return RegistrationExt.fetchCustomer(recordId);
  }
}
