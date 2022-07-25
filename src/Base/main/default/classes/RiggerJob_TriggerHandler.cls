/**
 * Created by dave on 2019-11-26.
 */

public without sharing class RiggerJob_TriggerHandler extends TriggerHandler {
  //  protected override void bulkBefore()
  //  {
  //    system.debug('[RiggerJob_TriggerHandler] bulk before');
  //  }

  //  protected override void bulkAfter()
  //  {
  //    system.debug('[RiggerJob_TriggerHandler] bulk after');
  //  }

  protected override void beforeInsert() {
    setName((List<Rigger_Job__c>) Trigger.new);
  }

  //  protected override void beforeUpdate()
  //  {
  //    system.debug('[RiggerJob_TriggerHandler] before update');
  //  }

  //  protected override void beforeDelete()
  //  {
  //    system.debug('[RiggerJob_TriggerHandler] before delete');
  //  }

  //  protected override void afterInsert()
  //  {
  //    system.debug('[RiggerJob_TriggerHandler] after insert');
  //  }

  //  protected override void afterUpdate()
  //  {
  //    system.debug('[RiggerJob_TriggerHandler] after update');
  //  }

  //  protected override void afterDelete()
  //  {
  //    system.debug('[RiggerJob_TriggerHandler] after delete');
  //  }

  //  protected override void afterUndelete()
  //  {
  //    system.debug('[RiggerJob_TriggerHandler] after undelete');
  //  }

  //  protected override void finalActions()
  //  {
  //    system.debug('[RiggerJob_TriggerHandler] final actions');
  //  }

  private void setName(List<Rigger_Job__c> listNew) {
    Set<Id> erpIds = new Set<Id>();
    for (Rigger_Job__c job : listNew) {
      if (job.ERP_Order__c != null)
        erpIds.add(job.ERP_Order__c);
    }
    Map<Id, AcctSeed__Project__c> erps = new Map<Id, AcctSeed__Project__c>(
      [SELECT Id, Name FROM AcctSeed__Project__c WHERE Id IN :erpIds]
    );
    for (Rigger_Job__c job : listNew) {
      if (job.ERP_Order__c != null && erps.containsKey(job.ERP_Order__c)) {
        job.Name = erps.get(job.ERP_Order__c).Name;
      }
    }
  }
}
