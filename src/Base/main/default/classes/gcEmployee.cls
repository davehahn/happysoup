public with sharing class gcEmployee {
  public static Boolean disableTrigger {
    get {
      if (disableTrigger == null)
        return false;
      else
        return disableTrigger;
    }
    set {
      if (value == null)
        disableTrigger = false;
      else
        disableTrigger = value;
    }
  }

  public static void triggerHandler(
    map<Id, Employee__c> oldMap,
    map<Id, Employee__c> newMap,
    list<Employee__c> listNew,
    Boolean boolIsBefore,
    Boolean boolIsInsert,
    Boolean boolIsUpdate,
    Boolean boolIsDelete
  ) {
    if (oldMap == null)
      oldMap = new Map<Id, Employee__c>();
    if (newMap == null)
      newMap = new Map<Id, Employee__c>();
    if (listNew == null)
      listNew = new List<Employee__c>();

    updateAndValidate(oldMap, newMap, listNew, boolIsBefore, boolIsInsert, boolIsUpdate, boolIsDelete);

    if (boolIsBefore) {
      if (boolIsInsert) {
      }
      if (boolIsUpdate) {
      }
      if (boolIsDelete) {
        validateDelete(oldMap);
      }
    } else //i.e. trigger.isAfter
    {
      if (boolIsInsert) {
      }
      if (boolIsUpdate) {
      }
      if (boolIsDelete) {
      }
    }
  }

  private static void updateAndValidate(
    map<Id, Employee__c> oldMap,
    map<Id, Employee__c> newMap,
    list<Employee__c> listNew,
    Boolean boolIsBefore,
    Boolean boolIsInsert,
    Boolean boolIsUpdate,
    Boolean boolIsDelete
  ) {
    if (boolIsBefore) {
      if (boolIsInsert) {
        Map<Id, String> mapUserName = new Map<Id, String>();
        for (Employee__c e : listNew) {
          if (e.User__c == null)
            e.addError('User cannot be left blank.');

          e.Uniquefier__c = e.User__c;
          mapUserName.put(e.User__c, null);
        }
        /// Collect the user name from user object
        /// Only put the username if there is no employee already for the user
        /// We already did this with Uniquefier, so can avoid checking for employee
        for (User u : [
          SELECT Name, Id, (SELECT Name, Id FROM Employees__r)
          FROM User
          WHERE Id IN :mapUserName.keySet()
        ]) {
          if (u.Employees__r.size() == 0)
            mapUserName.put(u.Id, u.Name);
        }

        /// Now loop through the list new again to put the Employee name
        for (Employee__c e : listNew) {
          if (mapUserName.containsKey(e.User__c) && mapUserName.get(e.User__c) != null)
            e.Name = mapUserName.get(e.User__c);
          else
            e.addError('The user is not available to be an employee.');
        }
      }

      if (boolIsUpdate) {
        /// Cannot change the user of an already created employee.
        for (Employee__c e : listNew) {
          if (e.User__c == null)
            e.addError('User cannot be left blank.');
          else if (e.User__c != oldMap.get(e.Id).User__c)
            e.addError('User cannot be changed. If necessary please create a new employee.');
        }
      }
    }

    set<Id> setIdUserUpdateTc = new Set<Id>();
    if (!boolIsBefore && boolIsUpdate) {
      for (Employee__c e : listNew) {
        if (e.GL_Account_Variable_2__c != oldMap.get(e.Id).GL_Account_Variable_2__c)
          setIdUserUpdateTc.add(e.User__c);
      }

      if (!setIdUserUpdateTc.isEmpty()) {
        Date dateEarliestOpen = GMBLASERP.gcAccountingPeriod.dateEarliestOpen();

        update [
          SELECT Id
          FROM AcctSeed__Time_Card__c
          WHERE
            AcctSeed__Employee__c IN :setIdUserUpdateTc
            AND AcctSeed__Time_Card_Period__r.AcctSeed__Start_Date__c >= :dateEarliestOpen
            AND AcctSeed__Time_Card_Period__r.AcctSeed__Status__c = 'Open'
        ];
      }
    }
  }

  private static void validateDelete(Map<Id, Employee__c> mapOld) {
    //Get the users for the deleted employees
    Set<Id> setEmployeeUser = new Set<Id>();
    for (Id key : mapOld.keySet()) {
      Employee__c objEmp = mapOld.get(key);
      setEmployeeUser.add(objEmp.User__c);
    }
    setEmployeeUser.remove(null);

    //Get any time cards for the users above
    Set<Id> setHasTimeCard = new Set<Id>();
    for (AcctSeed__Time_Card__c tc : [
      SELECT AcctSeed__Employee__c
      FROM AcctSeed__Time_Card__c
      WHERE AcctSeed__Employee__c IN :setEmployeeUser
    ]) {
      setHasTimeCard.add(tc.AcctSeed__Employee__c);
    }
    setHasTimeCard.remove(null);

    for (Id key : mapOld.keySet()) {
      Employee__c objEmp = mapOld.get(key);
      if (setHasTimeCard.contains(objEmp.User__c)) {
        objEmp.addError('An employee with time cards cannot be deleted.');
      }
    }
  }

  public static void updateEmployeeName(Set<Id> setIdUser) {
    List<Employee__c> listEmployee = new List<Employee__c>();
    for (Employee__c e : [SELECT Id, Name, User__r.Name FROM Employee__c WHERE User__c IN :setIdUser]) {
      if (e.Name != e.User__r.Name) {
        e.Name = e.User__r.Name;
        listEmployee.add(e);
      }
    }
    /// Update the names of the employees
    if (!listEmployee.isEmpty())
      update listEmployee;
  }
}
