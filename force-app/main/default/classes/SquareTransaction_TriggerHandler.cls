/**
 * Created by dave on 2020-06-19.
 */

public without sharing class SquareTransaction_TriggerHandler extends TriggerHandler
{

//  protected override void bulkBefore()
//  {
//    system.debug('[SquareTransaction_TriggerHandler] bulk before');
//  }

//  protected override void bulkAfter()
//  {
//    system.debug('[SquareTransaction_TriggerHandler] bulk after');
//  }

//  protected override void beforeInsert()
//  {
//    system.debug('[SquareTransaction_TriggerHandler] before insert');
//  }

//  protected override void beforeUpdate()
//  {
//    system.debug('[SquareTransaction_TriggerHandler] before update');
//  }

//  protected override void beforeDelete()
//  {
//    system.debug('[SquareTransaction_TriggerHandler] before delete');
//  }

  protected override void afterInsert()
  {
    createCashReceipt(
      (List<Square_Transaction__c>)Trigger.new,
      new Map<Id, Square_Transaction__c>()
    );
  }

  protected override void afterUpdate()
  {
    createCashReceipt(
      (List<Square_Transaction__c>)Trigger.new,
      (Map<Id, Square_Transaction__c>)Trigger.oldMap
    );
  }

//  protected override void afterDelete()
//  {
//    system.debug('[SquareTransaction_TriggerHandler] after delete');
//  }

//  protected override void afterUndelete()
//  {
//    system.debug('[SquareTransaction_TriggerHandler] after undelete');
//  }

//  protected override void finalActions()
//  {
//    system.debug('[SquareTransaction_TriggerHandler] final actions');
//  }

  private void createCashReceipt(
    List<Square_Transaction__c> listNew,
    Map<Id, Square_Transaction__c> oldMap )
  {
    List<Square_Transaction__c> toCreateCashReceipts = new List<Square_Transaction__c>();
    for( Square_Transaction__c sqT : listNew )
    {
      if( shouldCreateCashReceipt( sqT, oldMap.containsKey( sqT.Id) ? oldMap.get( sqT.Id ) : null ) )
      {
        toCreateCashReceipts.add( sqT );
      }
    }
    if( toCreateCashReceipts.size() > 0 )
      SquareTransaction_Service.createCashReceipts( toCreateCashReceipts );
  }

  private Boolean shouldCreateCashReceipt( Square_Transaction__c newRec, Square_Transaction__c oldRec )
  {
    if( oldRec == null )
    {
      if( newRec.sqStatus__c == 'COMPLETED' ) return true;
      return false;
    }
    if( newRec.sqStatus__c == 'COMPLETED' && oldRec.sqStatus__c != 'COMPLETED' ) return true;
    return false;
  }
}