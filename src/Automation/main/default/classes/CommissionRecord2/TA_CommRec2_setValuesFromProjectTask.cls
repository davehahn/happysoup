/**
 * Created by dave on 2022-01-11.
 */

public inherited sharing class TA_CommRec2_setValuesFromProjectTask implements TriggerAction.BeforeInsert {
  public void beforeInsert(List<CommissionRecord2__c> newList) {
    Map<Id, CommissionRecord2__c> taskIdMap = new Map<Id, CommissionRecord2__c>();
    for (CommissionRecord2__c cr : newList) {
      taskIdMap.put(cr.Project_Task__c, cr);
    }
    for (AcctSeed__Project_Task__c task : ProjectTask_Selector.allById(taskIdMap.keySet())) {
      taskIdMap.get(task.Id).Project__c = task.AcctSeed__Project__c;
      taskIdMap.get(task.Id).Retail_Pricebook__c = task.AcctSeed__Project__r.GMBLASERP__Pricebook__c;
      taskIdMap.get(task.Id).Calculation_Method__c = task.Commission_Calculation_Method__c;
      taskIdMap.get(task.Id).Department_GLV2__c = task.AcctSeed__GL_Account_Variable_2__c;
    }
  }
}
