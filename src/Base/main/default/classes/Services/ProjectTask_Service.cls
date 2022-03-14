/**
 * Created by dave on 2019-11-14.
 */

public with sharing class ProjectTask_Service {

  public static String warrantyPayableTaskName = 'Warranty Payable';
  public static String warrantyRecoverableTaskName = 'Warranty Recoverable';

  public static Boolean shouldDisplayOnInvoiceByDefault(String taskName) {
    ERPOrderTaskNames__c taskNameSetting = ERPOrderTaskNames__c.getInstance(taskName);
    return (taskNameSetting == null) ? false : taskNameSetting.Show_In_Invoice__c;
  }

  public static void insertWarrantyPayableTasksForProjects(List<AcctSeed__Project__c> erps)
  {
    List<AcctSeed__Project_Task__c> tasks = new List<AcctSeed__Project_Task__c>();
    for (AcctSeed__Project__c erp : erps)
    {
      tasks.add(
        new AcctSeed__Project_Task__c(
          AcctSeed__Project__c = erp.Id,
          Name = warrantyPayableTaskName,
          DisplayOnCustomerInvoice__c = shouldDisplayOnInvoiceByDefault(warrantyPayableTaskName)
        )
      );
    }
    insert tasks;
  }

  public static AcctSeed__Project_Task__c buildRetailSaleTask(Id projectId) {
    return new AcctSeed__Project_Task__c(
      Name = 'Retail Sale',
      DisplayOnCustomerInvoice__c = true,
      AcctSeed__Project__c = projectId,
      Is_Retail_Boat_Sale__c = true,
      AcctSeed__GL_Account_Variable_2__c = LGND_Constants.GLV2Id_Sales,
      Commission_Calculation_Method__c = 'Gross Margin'
    );
  }

  public static AcctSeed__Project_Task__c buildOnlineBoatSaleTask(Id projectId) {
    return new AcctSeed__Project_Task__c(
      Name = 'Online Sale',
      DisplayOnCustomerInvoice__c = true,
      AcctSeed__Project__c = projectId,
      AcctSeed__GL_Account_Variable_2__c = LGND_Constants.GLV2Id_Sales
    );
  }

  public static AcctSeed__Project_Task__c buildBusinessOfficeTask(Id projectId) {
    return new AcctSeed__Project_Task__c(
      Name = 'Business Office',
      DisplayOnCustomerInvoice__c = true,
      AcctSeed__Project__c = projectId,
      AcctSeed__GL_Account_Variable_2__c = LGND_Constants.GLV2Id_BusinessOffice,
      Commission_Calculation_Method__c = 'Revenue'
    );
  }

  public static AcctSeed__Project_Task__c buildRetailRigTask(Id projectId, Id commissionOverrideTaskId) {
    return new AcctSeed__Project_Task__c(
      Name = 'Retail Rig',
      DisplayOnCustomerInvoice__c = false,
      AcctSeed__Project__c = projectId,
      Is_Retail_Boat_Sale__c = true,
      AcctSeed__GL_Account_Variable_2__c = LGND_Constants.GLV2Id_Sales,
      Commission_Calculation_Method__c = 'Gross Margin',
      Commission_Override_Project_Task__c = commissionOverrideTaskId
    );
  }

  public static AcctSeed__Project_Task__c buildOnlineRigTask(Id projectId) {
    return new AcctSeed__Project_Task__c(
      Name = 'Online Rig',
      DisplayOnCustomerInvoice__c = false,
      AcctSeed__Project__c = projectId,
      AcctSeed__GL_Account_Variable_2__c = LGND_Constants.GLV2Id_Sales
    );
  }

  public static AcctSeed__Project_Task__c buildBackOrderTask(String taskName, String cause) {
    return new AcctSeed__Project_Task__c(
      Cause_dh__c = cause,
      Name = taskName,
      DisplayOnCustomerInvoice__c = true,
      Locked__c = true
    );
  }

  public static AcctSeed__Project_Task__c buildPromotionItemsTask(Id projectId) {
    return new AcctSeed__Project_Task__c(
      AcctSeed__Project__c = projectId,
      Name = 'Promotion Items',
      DisplayOnCustomerInvoice__c = true
    );
  }

  public static Map<String, AcctSeed__Project_Task__c> insertDefaultTasks(AcctSeed__Project__c project) {
    Application_RecordType.ERPOrderRTs rts = new Application_RecordType().getERPOrderRecordTypes();
    if (project.RecordTypeId == rts.getRetailBoatSaleId()) {
      return insertDefaultRetailBoatSaleTasks(project);
    }
    if (project.recordTypeId == rts.getPartnerRetailBoatSaleId()) {
      return insertDefaultPartnerRetailBoatSaleTasks(project);
    }
    return new Map<String, AcctSeed__Project_Task__c>();
  }

  public static Map<String, AcctSeed__Project_Task__c> insertDefaultRetailBoatSaleTasks(AcctSeed__Project__c project) {
    Map<String, AcctSeed__Project_Task__c> tasks = new Map<String, AcctSeed__Project_Task__c>{
      'Sale' => buildRetailSaleTask(project.Id),
      'Business Office' => buildBusinessOfficeTask(project.Id)
    };
    insert tasks.values();
    AcctSeed__Project_Task__c retailRig = buildRetailRigTask(project.Id, tasks.get('Sale').Id);
    insert retailRig;
    tasks.put('Rig', retailRig);
    return tasks;
  }

  public static Map<String, AcctSeed__Project_Task__c> insertDefaultPartnerRetailBoatSaleTasks(
    AcctSeed__Project__c project
  ) {
    Map<String, AcctSeed__Project_Task__c> tasks = new Map<String, AcctSeed__Project_Task__c>{
      'Sale' => buildRetailSaleTask(project.Id),
      'Business Office' => buildBusinessOfficeTask(project.Id),
      'Rig' => buildOnlineRigTask(project.Id)
    };
    Boolean commissionFlag = gcProjectTask.ignoreCommissions;
    gcProjectTask.ignoreCommissions = true;
    insert tasks.values();
    gcProjectTask.ignoreCommissions = commissionFlag;
    return tasks;
  }

}
