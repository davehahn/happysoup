/**
 * Created by dave on 2021-04-06.
 */

public virtual class ProjectTask_Selector extends Application_Selector
{

  private final List<String> defaultFields = new List<String>
  {
    'Id',
    'Name',
    'Cause_dh__c',
    'Commission_Calculation_Method__c',
    'Commission_Override_Project_Task__c',
    'Complaint_dh__c',
    'Correction_dh__c',
    'DisplayOnCustomerInvoice__c',
    'IsInsurance__c',
    'Is_Retail_Boat_Sale__c',
    'Is_Return_Task__c',
    'Locked__c',
    'AcctSeed__Project__c'
  };

  public ProjectTask_Selector()
  {
    this.sObjectName = 'AcctSeed__Project_Task__c';
    this.fields = defaultFields;
  }
}