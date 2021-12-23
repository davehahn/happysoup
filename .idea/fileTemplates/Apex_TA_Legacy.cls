#parse("Apex File Header.cls")

public inherited sharing class ${NAME}
  implements
      TriggerAction.BeforeInsert,
      TriggerAction.BeforeUpdate,
      TriggerAction.BeforeDelete,
      TriggerAction.AfterInsert,
      TriggerAction.AfterUpdate,
      TriggerAction.AfterDelete
{

  public void beforeInsert(
    List<${SOBJECT}> newList
  )
  {
    if( !${LEGACY_CLASS_NAME}.disableTrigger )
    {

      ${LEGACY_CLASS_NAME}.triggerHandler(
        null,
        null,
        newList,
        true,
        true,
        false,
        false
      );
    }
  }

  public void afterInsert(
    List<${SOBJECT}> newList
  )
  {
    if( !${LEGACY_CLASS_NAME}.disableTrigger )
    {
      Map<Id, ${SOBJECT}> newMap =
        new Map<Id, ${SOBJECT}>( newList );
      ${LEGACY_CLASS_NAME}.triggerHandler(
        null,
        newMap,
        newList,
        false,
        true,
        false,
        false
      );
    }
  }

  public void beforeUpdate(
    List<${SOBJECT}> newList,
    List<${SOBJECT}> oldList
  )
  {
    if( !${LEGACY_CLASS_NAME}.disableTrigger )
    {
      Map<Id, ${SOBJECT}> newMap =
        new Map<Id, ${SOBJECT}>( newList );
      Map<Id, ${SOBJECT}> oldMap =
        new Map<Id, ${SOBJECT}>( oldList );
      ${LEGACY_CLASS_NAME}.triggerHandler(
        oldMap,
        newMap,
        newList,
        true,
        false,
        true,
        false
      );
    }
  }

  public void afterUpdate(
    List<${SOBJECT}> newList,
    List<${SOBJECT}> oldList
  )
  {
    if( !${LEGACY_CLASS_NAME}.disableTrigger )
    {
      Map<Id, ${SOBJECT}> newMap =
        new Map<Id, ${SOBJECT}>( newList );
      Map<Id, ${SOBJECT}> oldMap =
        new Map<Id, ${SOBJECT}>( oldList );
      ${LEGACY_CLASS_NAME}.triggerHandler(
        oldMap,
        newMap,
        newList,
        false,
        false,
        true,
        false
      );
    }
  }

  public void beforeDelete(
    List<${SOBJECT}> oldList
  )
  {
    if( !${LEGACY_CLASS_NAME}.disableTrigger )
    {
      Map<Id, ${SOBJECT}> oldMap =
        new Map<Id, ${SOBJECT}>( oldList );
      ${LEGACY_CLASS_NAME}.triggerHandler(
        oldMap,
        null,
        null,
        true,
        false,
        false,
        true
      );
    }
  }

  public void afterDelete(
    List<${SOBJECT}> oldList
  )
  {
    if( !${LEGACY_CLASS_NAME}.disableTrigger )
    {
      Map<Id, ${SOBJECT}> oldMap =
        new Map<Id, ${SOBJECT}>( oldList );
      ${LEGACY_CLASS_NAME}.triggerHandler(
        oldMap,
        null,
        null,
        false,
        false,
        false,
        true
      );
    }
  }

}