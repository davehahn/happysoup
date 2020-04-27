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

  public static AcctSeed__Project_Task__c buildRetailSaleTask( Id projectId )
  {
    return new AcctSeed__Project_Task__c(
      Name = 'Retail Sale',
      DisplayOnCustomerInvoice__c = true,
      AcctSeed__Project__c = projectId,
      Is_Retail_Boat_Sale__c = true,
      AcctSeed__GL_Account_Variable_2__c = LGND_Constants.GLV2Id_Sales,
      Commission_Calculation_Method__c = 'Gross Margin'
    );
  }

  public static AcctSeed__Project_Task__c buildBusinessOfficeTask( Id projectId )
  {
    return new AcctSeed__Project_Task__c(
      Name = 'Business Office',
      DisplayOnCustomerInvoice__c = true,
      AcctSeed__Project__c = projectId,
      AcctSeed__GL_Account_Variable_2__c = LGND_Constants.GLV2Id_BusinessOffice,
      Commission_Calculation_Method__c = 'Revenue'
    );
  }

  public static Map<String, AcctSeed__Project_Task__c> insertDefaultRetailBoatSaleTasks( AcctSeed__Project__c project )
  {
    Map<String, AcctSeed__Project_Task__c> tasks = new Map<String, AcctSeed__Project_Task__c>{
      'Retail Sale' => buildRetailSaleTask( project.Id ),
      'Business Office' => buildBusinessOfficeTask( project.Id )
    };
    insert tasks.values();
    AcctSeed__Project_Task__c retailRig = new AcctSeed__Project_Task__c(
      Name = 'Retail Rig',
      DisplayOnCustomerInvoice__c = false,
      AcctSeed__Project__c = project.Id,
      Is_Retail_Boat_Sale__c = true,
      AcctSeed__GL_Account_Variable_2__c = LGND_Constants.GLV2Id_Sales,
      Commission_Calculation_Method__c = 'Gross Margin',
      Commission_Override_Project_Task__c = tasks.get('Retail Sale').Id );
    insert retailRig;
    tasks.put('Retail Rig', retailRig );
    return tasks;
  }


}