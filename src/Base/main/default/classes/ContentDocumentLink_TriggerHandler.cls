/**
 * Created by dave on 2019-12-31.
 */

public without sharing class ContentDocumentLink_TriggerHandler extends TriggerHandler {
  //  protected override void bulkBefore()
  //  {
  //  }

  //  protected override void bulkAfter()
  //  {
  //  }

  //  protected override void beforeInsert()
  //  {
  //  }

  //  protected override void beforeUpdate()
  //  {
  //  }

  //  protected override void beforeDelete()
  //  {
  //  }

  protected override void afterInsert() {
    new JiraConnect(Trigger.new, Trigger.oldMap).updateIssues();
  }

  //  protected override void afterUpdate()
  //  {
  //  }

  //  protected override void afterDelete()
  //  {
  //  }

  //  protected override void afterUndelete()
  //  {
  //  }

  //  protected override void finalActions()
  //  {
  //  }
}
