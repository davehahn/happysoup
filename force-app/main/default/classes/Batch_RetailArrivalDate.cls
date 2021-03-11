/**
 * Created by dave on 2021-03-10.
 */

global class Batch_RetailArrivalDate implements Database.Batchable<sObject>
{

  String query;

  global Batch_RetailArrivalDate()
  {
    Id rt = new Application_RecordType()
      .getERPOrderRecordTypes()
      .getPartnerBoatSaleId();
    query = 'SELECT Id, deliverDate__c, AcctSeedERP__Project__c, AcctSeedERP__Project__r.Retail_ERP__c' +
      ' FROM AcctSeedERP__Purchase_Order_Line__c' +
      ' WHERE AcctSeedERP__Project__r.RecordTypeId = \'' + rt + '\'' +
      ' AND AcctSeedERP__Project__r.Retail_ERP__c <> null' +
      ' AND deliverDate__c <> null' +
      ' AND AcctSeedERP__Project__r.Stage__c <> \'Delivered\'';
  }

  global Database.QueryLocator start( Database.BatchableContext BC )
  {
    return Database.getQueryLocator(query);
  }

  global void execute( Database.BatchableContext BC, List<SObject> scope )
  {
    List<AcctSeed__Project__c> retailERPs = new List<AcctSeed__Project__c>();
    for(
      AcctSeedERP__Purchase_Order_Line__c pol :
      (List<AcctSeedERP__Purchase_Order_Line__c>)scope
    )
    {
      retailERPs.add( new AcctSeed__Project__c(
        Id = pol.AcctSeedERP__Project__r.Retail_ERP__c,
        Arrival_Date__c = pol.deliverDate__c
      ));
    }
    gcProject.disableTrigger = true;
    System.debug( retailERPs );
    update retailERPs;
  }

  global void finish( Database.BatchableContext BC )
  {

  }

}