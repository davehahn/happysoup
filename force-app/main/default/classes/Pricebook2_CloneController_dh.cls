public with sharing class Pricebook2_CloneController_dh {

  @AuraEnabled
  public static Pricebook2 fetchPricebook( String recordId )
  {
    if( !Schema.sObjectType.Pricebook2.isCreateable() )
    {
      String msg = 'You do not have permission to create Pricebooks';
      AuraHandledException ex = new AuraHandledException(msg);
      ex.setMessage(msg);
      throw ex;
    }
    try {
      return [ SELECT Id, Name FROM Pricebook2 WHERE Id = :recordId ];
    }
    catch( Exception e )
    {
      String sObjectName = LGND_Utilities.sObjectNameFromId( recordId );
      String msg = 'Pricebook not found! Id supplied was for ' + sObjectName + ' object';
      AuraHandledException ex = new AuraHandledException(msg);
      ex.setMessage(msg);
      throw ex;
    }
  }

  @AuraEnabled
  public static Pricebook2 clonePricebook( String origPbId,
                                           Pricebook2 pricebook,
                                           Boolean includeEntries,
                                           Boolean includeFees,
                                           Boolean includeUpgrades )
  {
    Pricebook2 origPb = [SELECT Id, RecordTypeId FROM Pricebook2 WHERE Id = :origPbId];
    pricebook.RecordTypeId = origPb.RecordTypeId;
    insert pricebook;
    if( includeEntries )
    {
      batchPricebookClone bpc = new batchPricebookClone( origPbId, pricebook.Id );
      Database.executeBatch( bpc );
    }
    if( includeFees )
    {
      BatchPricebookClone_Fees bpcf = new BatchPricebookClone_Fees( origPbId, pricebook.Id );
      Database.executeBatch( bpcf );
    }
    if( includeUpgrades )
    {
      BatchPricebookClone_Upgrades bpcu = new BatchPricebookClone_Upgrades( origPbId, pricebook.Id );
      Database.executeBatch( bpcu );
    }
    return pricebook;
  }

  public static void sendBatchCompleteEmail( Database.BatchableContext BC,
                                             String jobDescription )
  {
    AsyncApexJob a = [SELECT Id,
                             Status,
                             ExtendedStatus,
                             NumberOfErrors,
                             JobItemsProcessed,
                             TotalJobItems,
                             CreatedBy.Email
                      FROM AsyncApexJob
                      WHERE Id =:BC.getJobId()];

    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    String[] toAddresses = new String[] {a.CreatedBy.Email};
    mail.setToAddresses(toAddresses);
    mail.setSubject(jobDescription + ' - ' + a.Status);
    mail.setPlainTextBody( (a.TotalJobItems * 200) + ' records where processed in ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.');
    if( !Test.isRunningTest() )
    {
      Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
  }
}