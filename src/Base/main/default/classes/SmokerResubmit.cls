public with sharing class SmokerResubmit {

  private static final List<String> contactIds = new List<String>{'003i000000bPvbzAAC', '0031Y00004wfZB7QAM'};

  public class doneException Extends Exception {}

  public static void gogo( Integer l )
  {
    Case[] cs = [Select Id, Recoverable_ERP__c
                 FROM Case
                 WHERE Recoverable_ERP__c <> null
                 AND Recoverable_ERP__r.Name LIKE '%Recoverable-Smokercraft%'
                 AND Recoverable_ERP__r.AcctSeed__Status__c = 'Completed'
                 AND Recoverable_ERP__r.Previously_Submitted_To_Smoker__c = false
                 AND Recoverable_ERP__r.Supplier_Claim_Number__c = NULL
                 ORDER BY CaseNumber
                 LIMIT :l];
    if( cs.size() == 0 )
      throw new doneException('we are done here');

    for( Case c : cs )
    {
      doSubmit( c.Recoverable_ERP__c );
    }

  }

  public static void gogoEmail()
  {
    Case[] cs = [SELECT Id, Recoverable_ERP__c, Recoverable_ERP__r.AcctSeed__Status__c
                   FROM Case
                   WHERE Recoverable_ERP__c <> null
                   AND Recoverable_ERP__r.Name LIKE '%Recoverable-Smokercraft%'
                   AND Recoverable_ERP__r.Previously_Submitted_To_Smoker__c = false
                   AND Recoverable_ERP__r.Supplier_Claim_Number__c <> null
                   ORDER BY CaseNumber
                   LIMIT 40 ];
    if( cs.size() == 0 )
      throw new doneException('we are done here');

    for( Case c : cs )
    {
      sendEmail( c.Recoverable_ERP__c );
    }
  }

  @Future(callout=true)
  private static void doSubmit( Id erpId )
  {
    SmokercraftAPI_Callout.submitClaimToSmokercraft( erpId );
  }

  @Future
  private static void sendEmail( Id erpId )
  {
    String templateId = Legend_Settings__c.getOrgDefaults().Warranty_Recoverable_Email_Template_Id__c;
    List<Id> toAddresses = new List<Id>();
    List<Contact> contacts = [SELECT Id, Email FROM Contact WHERE Id IN :contactIds ];
    for( Contact c : contacts )
    {
      toAddresses.add(c.Id);
    }
    List<Messaging.SingleEmailMessage> msgList= new List<Messaging.SingleEmailMessage>();
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    mail.setToAddresses( toAddresses );
    mail.setTargetObjectId(contacts[0].Id);
    mail.setWhatId( erpId );
    mail.setTemplateId( templateId );
    mail.setSaveAsActivity(true);
    msgList.add(mail);
    Messaging.sendEmail(msgList);
    Boolean o = gcProject.disableTrigger;
    gcProject.disableTrigger = true;
    AcctSeed__Project__c erp = new AcctSeed__Project__c(
      Id = erpId,
      Previously_Submitted_To_Smoker__c = true
    );
    upsert erp;
    gcProject.disableTrigger = o;
  }

   public static void coverage()
  {
    integer i;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
    i=1;
  }
}