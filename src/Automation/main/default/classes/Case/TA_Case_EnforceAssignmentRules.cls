/**
 * Created by dave on 2022-01-06.
 */

public without sharing class TA_Case_EnforceAssignmentRules implements TriggerAction.AfterInsert
{
  public void afterInsert( List<Case> newList ){
    Map<Id, Case> newMap = new Map<Id, Case>(newList);
    Database.DMLOptions dmlOpts = new Database.DMLOptions();
    dmlOpts.assignmentRuleHeader.useDefaultRule= true;
    dmlOpts.EmailHeader.triggerAutoResponseEmail = true;
    dmlOpts.EmailHeader.triggerUserEmail = true;
    Case[] cases = new List<Case>();
    for( Id caseId : newMap.keySet() )
    {
      Case c = new Case( Id = caseId );
      c.setOptions( dmlOpts );
    }
    TriggerBase.bypass('Case');
    update cases;
    TriggerBase.clearBypass('Case');
  }
}