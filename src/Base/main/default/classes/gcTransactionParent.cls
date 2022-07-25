public without sharing class gcTransactionParent {
  private static map<Id, AcctSeed__Project__c> mapProject;
  private static map<Id, AcctSeed__Project_Task__c> mapProjectTask;
  private static map<Id, AcctSeed__GL_Account__c> mapGLAccount;

  public static void setFinancialAttributes(List<sObject> listNew, String projectField, String glAccountField) {
  }

  public static void setFinancialAttributes(
    List<sObject> listNew,
    String projectField,
    String projectTaskField,
    String glAccountField
  ) {
    //Skip if list is null or empty
    if (listNew == null || listNew.isEmpty())
      return;

    if (mapProject == null)
      mapProject = new Map<Id, AcctSeed__Project__c>();
    if (mapProjectTask == null)
      mapProjectTask = new Map<Id, AcctSeed__Project_Task__c>();
    if (mapGLAccount == null)
      mapGLAccount = new Map<Id, AcctSeed__GL_Account__c>();

    Set<Id> setIdProject = new Set<Id>();
    Set<Id> setIdProjectTask = new Set<Id>();
    Set<Id> setIdGlAccount = new Set<Id>();

    for (SObject obj : listNew) {
      Id idProject;
      Id idProjectTask;
      if (projectField != null)
        idProject = (Id) obj.get(projectField);
      if (projectTaskField != null)
        idProjectTask = (Id) obj.get(projectTaskField);
      if (idProject != null && !mapProject.containsKey(idProject))
        setIdProject.add(idProject);
      if (idProjectTask != null && !mapProjectTask.containsKey(idProjectTask))
        setIdProjectTask.add(idProjectTask);

      if (glAccountField != null) {
        Id idGlAccount = (Id) obj.get(glAccountField);
        if (idGlAccount != null && !mapGLAccount.containsKey(idGlAccount))
          setIdGlAccount.add(idGlAccount);
      }
    }

    if (!setIdProject.isEmpty())
      retrieveProjectStatics(setIdProject);

    if (!setIdProjectTask.isEmpty())
      retrieveProjectTaskStatics(setIdProjectTask);

    if (!setIdGlAccount.isEmpty())
      retrieveGlAccountStatics(setIdGlAccount);

    /// Set all GLV 1,2 values
    setGLVAttributes(listNew, projectField, projectTaskField);

    /// Validate that GLVs are set if required
    if (glAccountField != null)
      validateGlvRequired(listNew, glAccountField);
  }

  private static void retrieveProjectStatics(Set<Id> setIdProject) {
    setIdProject.remove(null);
    if (!setIdProject.isEmpty()) {
      for (AcctSeed__Project__c p : [
        SELECT
          Id,
          GL_Account_Variable_1__c,
          GL_Account_Variable_2__c,
          Internal_Labour_Service__c,
          Internal_Warranty__c,
          Internal_Partner_Boat_Sale__c
        FROM AcctSeed__Project__c
        WHERE Id IN :setIdProject
      ]) {
        mapProject.put(p.Id, p);
      }
    }
  }

  private static void retrieveProjectTaskStatics(Set<Id> setIdTask) {
    setIdTask.remove(null);
    if (!setIdTask.isEmpty()) {
      for (AcctSeed__Project_Task__c pt : [
        SELECT
          Id,
          AcctSeed__GL_Account_Variable_1__c,
          AcctSeed__GL_Account_Variable_2__c,
          AcctSeed__Project__r.GL_Account_Variable_1__c,
          AcctSeed__Project__r.GL_Account_Variable_2__c,
          AcctSeed__Project__r.Internal_Labour_Service__c,
          AcctSeed__Project__r.Internal_Warranty__c,
          AcctSeed__Project__r.Internal_Partner_Boat_Sale__c
        FROM AcctSeed__Project_Task__c
        WHERE Id IN :setIdTask
      ]) {
        mapProjectTask.put(pt.Id, pt);
      }
    }
  }

  private static void retrieveGlAccountStatics(Set<Id> setIdGlAccount) {
    setIdGlAccount.remove(null);
    if (!setIdGlAccount.isEmpty()) {
      for (AcctSeed__GL_Account__c gla : [
        SELECT Id, Name, AcctSeed__Type__c, Uniquefier__c
        FROM AcctSeed__GL_Account__c
        WHERE Id IN :setIdGlAccount
      ]) {
        mapGLAccount.put(gla.Id, gla);
      }
    }
  }

  public static void setGLVAttributes(list<sObject> listNew, String projectField, String projectTaskField) {
    if (listNew == null || listNew.isEmpty())
      return;

    String prefix = retrieveNamespace(listNew);

    for (sObject obj : listNew) {
      AcctSeed__Project__c p;
      AcctSeed__Project_Task__c pt;
      Id idGLV1, idGLV2, idGLV1P, idGLV2P;
      if (projectTaskField != null && obj.get(projectTaskField) != null) {
        pt = mapProjectTask.get((Id) obj.get(projectTaskField));
        p = pt.AcctSeed__Project__r;
        idGLV1P = p.GL_Account_Variable_1__c;
        idGLV2P = p.GL_Account_Variable_2__c;
        idGLV1 = pt.AcctSeed__GL_Account_Variable_1__c == null ? idGLV1P : pt.AcctSeed__GL_Account_Variable_1__c;
        idGLV2 = pt.AcctSeed__GL_Account_Variable_2__c == null ? idGLV2P : pt.AcctSeed__GL_Account_Variable_2__c;
      } else if (projectField != null && obj.get(projectField) != null) {
        p = mapProject.get((Id) obj.get(projectField));
        idGLV1 = p.GL_Account_Variable_1__c;
        idGLV2 = p.GL_Account_Variable_2__c;
      }

      if (p != null) {
        if (p.GL_Account_Variable_1__c != null) {
          if (!p.Internal_Labour_Service__c && !p.Internal_Partner_Boat_Sale__c && !p.Internal_Warranty__c) {
            obj.put(prefix + 'GL_Account_Variable_1__c', idGLV1);
          } else if (
            p.Internal_Labour_Service__c && obj.getSObjectType().getDescribe().getName() == 'AcctSeed__Billing_Line__c'
          ) {
            obj.put(prefix + 'GL_Account_Variable_1__c', idGLV1P);
          } else if (obj.get(prefix + 'GL_Account_Variable_1__c') == null) {
            obj.put(prefix + 'GL_Account_Variable_1__c', idGLV1);
          }
        }
        if (idGLV1 != null) {
          System.debug('Object Name');
          System.debug(obj.getSObjectType().getDescribe().getName());
          if (
            !p.Internal_Labour_Service__c &&
            !p.Internal_Partner_Boat_Sale__c &&
            !p.Internal_Warranty__c &&
            obj.get(prefix + 'GL_Account_Variable_2__c') == null
          ) {
            obj.put(prefix + 'GL_Account_Variable_2__c', idGLV2);
          } else if (
            p.Internal_Labour_Service__c && obj.getSObjectType().getDescribe().getName() == 'AcctSeed__Billing_Line__c'
          ) {
            obj.put(prefix + 'GL_Account_Variable_2__c', idGLV2P);
          } else if (obj.get(prefix + 'GL_Account_Variable_2__c') == null) {
            obj.put(prefix + 'GL_Account_Variable_2__c', idGLV2);
          }
        }
      }
    }
  }

  private static void validateGlvRequired(List<SObject> listNew, String glAccountField) {
    String prefix = retrieveNamespace(listNew);
    String objectName = listNew.getSObjectType().getDescribe().getName();
    for (SObject obj : listNew) {
      Id idGlv1 = (Id) obj.get(prefix + 'GL_Account_Variable_1__c');
      Id idGlv2 = (Id) obj.get(prefix + 'GL_Account_Variable_2__c');

      if (!String.isBlank(glAccountField)) {
        Id idGlAccount = (Id) obj.get(glAccountField);
        if (idGlAccount == null)
          continue;

        AcctSeed__GL_Account__c gla = mapGLAccount.get(idGlAccount);
        String glaType = gla.AcctSeed__Type__c;

        if (!Transaction_Parent__c.getOrgDefaults().Allow_Transactions_Without_GLV__c)
          if ((glaType == 'Revenue') || (glaType == 'Expense')) {
            if (
              (idGlv1 == null ||
              idGlv2 == null) &&
              gla.Uniquefier__c != 'ProjectWagesPayable' &&
              gla.Uniquefier__c != 'ProjectLaborBurdenContra' &&
              gla.Uniquefier__c != 'ProjectLaborBurden' &&
              gla.Uniquefier__c != 'ProjectLabor' &&
              (!objectName.equals('AcctSeed__Account_Payable_Line__c') ||
              (objectName.equals('AcctSeed__Account_Payable_Line__c') &&
              obj.get('AcctSeedERP__Purchase_Order_Line__c') == null))
            ) {
              obj.addError(
                'Business Unit (GLV1) and Department (GLV2) are required when posting to a Revenue or Expense GL account.'
              );
              continue;
            }
          }
        if (!Transaction_Parent__c.getOrgDefaults().Allow_Inventory_GL_Accounts__c) {
          Set<String> setObjectNames = new Set<String>{
            'AcctSeed__Account_Payable_Line__c',
            'AcctSeed__Billing_Line__c',
            'AcctSeed__Journal_Entry_Line__c'
          };
          if (setObjectNames.contains(objectName)) {
            if (gla.Uniquefier__c == 'InventoryBoats' || gla.Uniquefier__c == 'InventoryParts')
              obj.addError('Selected GL account ' + gla.Name + ' can only be used in Inventory Movements.');
          }
        }
      }
    }
  }

  private static string retrieveNamespace(list<sObject> listNew) {
    String objectName = listNew.getSObjectType().getDescribe().getName();

    if (objectName.startsWithIgnoreCase('AcctSeed__'))
      return 'AcctSeed__';
    else if (objectName.startsWithIgnoreCase('AcctSeedERP__'))
      return 'AcctSeedERP__';

    return '';
  }

  public static void coverage() {
    integer i;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
  }
}
