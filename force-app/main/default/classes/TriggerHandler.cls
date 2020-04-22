/**
 * Created by dave on 2019-10-07.
 */
public virtual class TriggerHandler {

  private static Set<String> bypassedHandlers;

  static {
    bypassedHandlers = new Set<String>();
  }

  protected User currentUser {
    get {
      if( currentUser == null )
      {
        currentUser = [ SELECT Id,
          Sales_Department__c,
          Warehouse__c
        FROM User
        WHERE Id = :UserInfo.getUserId() ];
      }
      return currentUser;
    }
    set{}
  }

  public void run() {
    if(!validateRun()) return;
    if(Trigger.isBefore) {
      this.bulkBefore();
    }
    if(Trigger.isAfter) {
      this.bulkAfter();
    }
    // dispatch to the correct handler method
    if(Trigger.isBefore && Trigger.isInsert) {
      this.beforeInsert();
    } else if(Trigger.isBefore && Trigger.isUpdate) {
      this.beforeUpdate();
    } else if(Trigger.isBefore && Trigger.isDelete) {
      this.beforeDelete();
    } else if(Trigger.isAfter && Trigger.isInsert) {
      this.afterInsert();
    } else if(Trigger.isAfter && Trigger.isUpdate) {
      this.afterUpdate();
    } else if(Trigger.isAfter && Trigger.isDelete) {
      this.afterDelete();
    } else if(Trigger.isAfter && Trigger.isUndelete) {
      this.afterUndelete();
    }
    this.finalActions();
  }

  /***************************************
  * context methods
  ***************************************/

  // context-specific methods for override
  //this method is used to get all records befor apply the business logic
  protected virtual void bulkBefore(){}
  protected virtual void bulkAfter(){}
  protected virtual void beforeInsert(){}
  protected virtual void beforeUpdate(){}
  protected virtual void beforeDelete(){}
  protected virtual void afterInsert(){}
  protected virtual void afterUpdate(){}
  protected virtual void afterDelete(){}
  protected virtual void afterUndelete(){}
  //this method is used to execute all DML actions
  protected virtual void finalActions(){}

  /***************************************
  * Recursion handler
  ***************************************/

  private static Map<Id,set<string>> m_ProcessPerName = new Map<Id,set<string>>();
  public static boolean DidProcessRan(string processName, Id parentObject)
  {
    boolean retVal = false;
    if(m_ProcessPerName.containsKey(parentObject))
    {
      if(m_ProcessPerName.get(parentObject).contains(processName))
      {
        retVal= true;
      }
    }
    return retVal;
  }
  public static void AddProcessRun(string processName, Id parentObject)
  {
    if(!m_ProcessPerName.containsKey(parentObject))
    {
      m_ProcessPerName.put(parentObject,new set<string>());
    }
    m_ProcessPerName.get(parentObject).add(processName);
  }

  /***************************************
   * public static methods - bypass API
   ***************************************/

  public static void bypass(String handlerName) {
    TriggerHandler.bypassedHandlers.add(handlerName);
  }

  public static void clearBypass(String handlerName) {
    TriggerHandler.bypassedHandlers.remove(handlerName);
  }

  public static Boolean isBypassed(String handlerName) {
    return TriggerHandler.bypassedHandlers.contains(handlerName);
  }

  public static void clearAllBypasses() {
    TriggerHandler.bypassedHandlers.clear();
  }


  @TestVisible
  private Boolean validateRun() {
    if(TriggerHandler.bypassedHandlers.contains(getHandlerName())) {
      return false;
    }
    return true;
  }

  @TestVisible
  private String getHandlerName() {
    return String.valueOf(this).substring(0,String.valueOf(this).indexOf(':'));
  }

}