/**
 * Created by dave on 2022-10-28.
 */

public without sharing class TA_Lead_ForceAssignAutomatedProcess implements TriggerAction.AfterInsert
{
  public void afterInsert( List<Lead> newList ){
    Set<String> autoProcNames = new Set<String>{'Automated Process', 'Legendary Devs'};
    Map<Id, Lead> newMap = new Map<Id, Lead>(newList);
    List<Lead> ownedByAutomatedProcess = new List<Lead>();
    for( Lead l : [SELECT Id, Owner.Name FROM Lead WHERE Id IN :newMap.keySet() ]){
      if( autoProcNames.contains( l.Owner.Name ) ){
        ownedByAutomatedProcess.add(l);
      }
    }
    if( ownedByAutomatedProcess.size() > 0 ){
      TriggerBase.bypass('Lead');
      Database.DMLOptions options = new Database.DMLOptions();
      options.emailHeader.triggerUserEmail = true;
      options.assignmentRuleHeader.useDefaultRule = true;
      Database.update(ownedByAutomatedProcess, options);
      TriggerBase.clearBypass('Lead');
    }
  }

}