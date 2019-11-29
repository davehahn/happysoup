/**
 * Created by dave on 2019-11-14.
 */

public with sharing class ProjectTask_Service
{

  public static String warrantyPayableTaskName = 'Warranty Payable';
  public static String warrantyRecoverableTaskName = 'Warranty Recoverable';

  public static Boolean shouldDisplayOnInvoiceByDefault( String taskName )
  {
    ERPOrderTaskNames__c taskNameSetting = ERPOrderTaskNames__c.getInstance(taskName);
    return (taskNameSetting == null) ? false : taskNameSetting.Show_In_Invoice__c;
  }

  public static void insertWarrantyPayableTasksForProjects( List<AcctSeed__Project__c> erps )
  {
    List<AcctSeed__Project_Task__c> tasks = new List<AcctSeed__Project_Task__c>();
    for( AcctSeed__Project__c erp : erps )
    {
      tasks.add( new AcctSeed__Project_Task__c(
        AcctSeed__Project__c = erp.Id,
        Name = warrantyPayableTaskName,
        DisplayOnCustomerInvoice__c = shouldDisplayOnInvoiceByDefault( warrantyPayableTaskName )
      ));
    }
    insert tasks;
  }


}