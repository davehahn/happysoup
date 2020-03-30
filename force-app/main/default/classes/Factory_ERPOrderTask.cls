/**
 * Created by dave on 2020-01-29.
 */

public with sharing class Factory_ERPOrderTask
{
  public static AcctSeed__Project_Task__c buildProjectTask( Id erpId, String taskName )
  {
    return new AcctSeed__Project_Task__c(
      AcctSeed__Project__c = erpId,
      DisplayOnCustomerInvoice__c = true,
      Name = taskName
    );
  }

  public static AcctSeed__Project_Task__c buildRetailSaleTask( Id erpId )
  {
    AcctSeed__Project_Task__c task = buildProjectTask( erpId, 'Retail Sale' );
    task.AcctSeed__GL_Account_Variable_2__c = LGND_Constants.GLV2Id_Sales;
    task.Commission_Calculation_Method__c = 'Gross Margin';
    return task;
  }

  public static AcctSeed__Project_Task__c buildBusinessOfficeTask( Id erpId )
  {
    AcctSeed__Project_Task__c task = buildProjectTask( erpId, 'Business Office' );
    task.AcctSeed__GL_Account_Variable_2__c = LGND_Constants.GLV2Id_BusinessOffice;
    task.Commission_Calculation_Method__c = 'Revenue';
    return task;
  }

  public static List<AcctSeed__Project_Task__c> insertDefaultRetailBoatSaleTasks( Id erpId )
  {
    List<AcctSeed__Project_Task__c> tasks = new List<AcctSeed__Project_Task__c>{
      buildRetailSaleTask( erpId ),
      buildBusinessOfficeTask( erpId )
    };
    insert tasks;
    return tasks;
  }
}