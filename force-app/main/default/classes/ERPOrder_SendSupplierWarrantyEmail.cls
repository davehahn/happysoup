public with sharing class ERPOrder_SendSupplierWarrantyEmail {

  @AuraEnabled
  public static String fetchERPInfo( String recordId )
  {
    String smokerId = Legend_Settings__c.getOrgDefaults().Smokercraft_Account_Id__c;
    Map<String, Boolean> result = new Map<String, Boolean>();
    AcctSeed__Project__c erp = [SELECT Id, AcctSeed__Status__c, AcctSeed__Account__c
                                FROM AcctSeed__Project__c
                                WHERE Id = : recordId];
    result.put('isActive', erp.AcctSeed__Status__c == 'Active'  );
    result.put('isSmoker', erp.AcctSeed__Account__c == smokerId );
    result.put('hasPermission', LGND_Utilities.CustomPermissions.canSubmitRecoverableErpToSupplier );
    return JSON.serialize( result );
  }

  @AuraEnabled
	public static List<Contact> findContacts( String recordId )
  {
    AcctSeed__Project__c erp = [SELECT Id, AcctSeed__Account__c FROM AcctSeed__Project__c WHERE Id = :recordId];
    return [SELECT Id, Email, Name
            FROM Contact
            WHERE AccountId = :erp.AcctSeed__Account__c
            AND Email <> null];
	}

  @AuraEnabled
  public static void postToSmokerAPI( String recordId )
  {
    String errorMessage;
    try {
      SmokercraftAPI_Callout.submitClaimToSmokercraft( recordId );
    }
    catch( SmokercraftAPI_Callout.SmokerAPIException e )
    {
      errorMessage = e.getMessage();
      AuraHandledException ex = new AuraHandledException('An error occured submitting the claim to Smokercraft. \n\r System admins have been notified');
      ex.setMessage('SmokerCraft API Error');
      throw ex;
    }
    finally
    {
      if( errorMessage != null )
      {
        sendApiErrorNotification( errorMessage, recordId );
      }
    }
  }

  private static void sendApiErrorNotification( String errorMessage, Id recordId )
  {
    List<String> emailAddrs = new List<String>();
    for( User u : [SELECT Id, Email
                   FROM User
                   WHERE ProfileId IN (SELECT Id From Profile WHERE Name = 'System Administrator')
                   AND isActive = true] )
    {
      emailAddrs.add( u.Email );
    }
    List<Messaging.SingleEmailMessage> msgList= new List<Messaging.SingleEmailMessage>();
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    mail.setToAddresses( emailAddrs );
    mail.setSubject( 'Smoker API Warranty Submission Error - ' + recordId );
    mail.setPlainTextBody( errorMessage );
    if( !Test.isRunningTest() )
    {
      Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
  }

  @AuraEnabled
  public static void sendRecoverableEmail( String erpId, List<String> contactIds )
  {
    createBillingAndCompleteERP( erpId );
    String templateId = Legend_Settings__c.getOrgDefaults().Warranty_Recoverable_Email_Template_Id__c;
    List<Id> toAddresses = new List<Id>();
    List<Contact> contacts = [SELECT Id, Email FROM Contact WHERE Id IN :contactIds ];
    for( Contact c : contacts )
    {
      toAddresses.add(c.Id);
    }

    List<Messaging.SingleEmailMessage> msgList= new List<Messaging.SingleEmailMessage>();
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    try {
      Id orgEmailId = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'Dealer Care' LIMIT 1].Id;
      mail.setOrgWideEmailAddressId( orgEmailId );
    }
    catch(Exception e){}
    mail.setToAddresses( toAddresses );
    mail.setTargetObjectId(contacts[0].Id);
    mail.setWhatId( erpId );
    mail.setTemplateId( templateId );
    mail.setSaveAsActivity(true);
    msgList.add(mail);
    if( !Test.isRunningTest() )
      Messaging.sendEmail(msgList);
  }

  private static void createBillingAndCompleteERP( Id erpId )
  {
    AcctSeed__Project__c erp = [SELECT Id, Locked__c FROM AcctSeed__Project__c WHERE Id = :erpId ];
    if( !erp.locked__c )
    {
      gcProject_Ext.createBilling( erpId , null);

      erp.AcctSeed__Status__c = 'Completed';

      if( Test.isRunningTest() )
      {
        Boolean ot = gcProject.disableTrigger;
        gcProject.disableTrigger = true;
        update erp;
        gcProject.disableTrigger = ot;
      }
      else {
        update erp;
      }

    }
  }
}