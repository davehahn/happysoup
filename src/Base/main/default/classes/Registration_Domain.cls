/**
 * Created by dave on 2019-10-08.
 */

public with sharing class Registration_Domain {

  public static void setDefaults( List<Registration__c> listNew )
  {
    for( Registration__c reg : listNew )
    {
      reg.isCurrent__c = true;
      reg.Registered_Date__c = DateTime.now();

      if( reg.RegisteredByAccount__c == null )
      {
        reg.RegisteredByAccount__c = Registration_Helper.registeredByAccountId;
      }

      if( reg.ErpOrder__c != null )
      {
        reg.Uniqueifier__c = reg.ErpOrder__c + '_' + reg.SerialNumber__c;
      }
    }
  }


}