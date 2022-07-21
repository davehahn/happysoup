public without sharing class gcProjectLaborJobCost_BatchSchedulable implements Schedulable {
  //To schedule the batch to run every hour at 10 minutes past the hour:
  //system.schedule('Job Cost Labor Cleansweep','0 10 * * * ?',new gcProjectLaborJobCost_BatchSchedulable());
  public void execute(SchedulableContext sc) {
    AcctSeed__Accounting_Period__c period;

    //find the current period, and if it's open, run the batch for the current period.
    for (AcctSeed__Accounting_Period__c p : [
      SELECT Id, AcctSeed__Start_Date__c, AcctSeed__End_Date__c, AcctSeed__Status__c
      FROM AcctSeed__Accounting_Period__c
      WHERE AcctSeed__Start_Date__c <= TODAY AND AcctSeed__End_Date__c >= TODAY
    ]) {
      period = p;
    }

    if (period == null)
      return;

    if (period.AcctSeed__Status__c == 'Open')
      Database.executeBatch(new gcProjectLaborJobCost_Batch(period.Id), 10);

    //if the prior period is still open, run the batch for that period too.
    for (AcctSeed__Accounting_Period__c p : [
      SELECT Id
      FROM AcctSeed__Accounting_Period__c
      WHERE AcctSeed__Start_Date__c < :period.AcctSeed__Start_Date__c AND AcctSeed__Status__c = 'Open'
      ORDER BY AcctSeed__Start_Date__c DESC
      LIMIT 1
    ]) {
      Database.executeBatch(new gcProjectLaborJobCost_Batch(period.Id), 10);
    }
  }
}
