/**
 * Created by dave on 2020-05-01.
 */

public without sharing class Account_TriggerHandler extends TriggerHandler
{

//  protected override void bulkBefore()
//  {
//    system.debug('[Account_TriggerHandler] bulk before');
//  }

//  protected override void bulkAfter()
//  {
//    system.debug('[Account_TriggerHandler] bulk after');
//  }

//  protected override void beforeInsert()
//  {
//    system.debug('[Account_TriggerHandler] before insert');
//  }

  protected override void beforeUpdate()
  {
    validate( (List<Account>)Trigger.new );
  }

//  protected override void beforeDelete()
//  {
//    system.debug('[Account_TriggerHandler] before delete');
//  }

//  protected override void afterInsert()
//  {
//    system.debug('[Account_TriggerHandler] after insert');
//  }

//  protected override void afterUpdate()
//  {
//    system.debug('[Account_TriggerHandler] after update');
//  }

//  protected override void afterDelete()
//  {
//    system.debug('[Account_TriggerHandler] after delete');
//  }

//  protected override void afterUndelete()
//  {
//    system.debug('[Account_TriggerHandler] after undelete');
//  }

//  protected override void finalActions()
//  {
//    system.debug('[Account_TriggerHandler] final actions');
//  }

  private void validate( List<Account> listNew )
  {
    User user = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
    Id dealerRtId = LGND_Constants.accountRtId_Dealer;
    if( user.AccountId != null )
    {
      for( Account a : listNew )
      {
        if( a.Id != user.AccountId &&
            a.RecordTypeId == dealerRtId )
        {
          a.addError('You are not allowed to edit another Partners information');
        }
      }
    }
  }
}