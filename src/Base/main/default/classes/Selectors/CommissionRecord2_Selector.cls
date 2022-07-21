/**
 * Created by dave on 2020-02-05.
 */

public with sharing class CommissionRecord2_Selector extends Application_Selector {
  public CommissionRecord2_Selector() {
    this.sObjectName = 'CommissionRecord2__c';
    this.fields = new List<String>{
      'Id',
      'Factory_Pricebook__c',
      'Calculation_Method__c',
      'TaxProvince__c',
      'Project__c',
      'Project__r.Stage__c',
      'Project_Task__c',
      'Project_Task__r.Name',
      'Status__c',
      'Approved_By__c',
      'Approved_By__r.Name'
    };
    this.childQueries = new List<String>{ '( SELECT Id, Owner__c FROM Commission_Payments__r )' };
  }

  public static List<CommissionRecord2__c> allById(Set<Id> crIds) {
    CommissionRecord2_Selector selector = new CommissionRecord2_Selector();
    selector.addWhere(
      whereInClauseBuilder('Id', (Set<String>) JSON.deserialize(JSON.serialize(crIds), Set<String>.class))
    );
    return (List<CommissionRecord2__c>) selector.query();
    //    return [ SELECT Id,
    //                    Factory_Pricebook__c,
    //                    Calculation_Method__c,
    //                    TaxProvince__c,
    //                    Project__c,
    //                    Project_Task__c,
    //                    Project_Task__r.Name,
    //                    Status__c,
    //                    Approved_By__c,
    //                    Approved_By__r.Name,
    //            ( SELECT Id,
    //              Owner__c
    //              FROM Commission_Payments__r )
    //              FROM CommissionRecord2__c
    //              WHERE Id IN :crIds ];
  }

  public static List<CommissionRecord2__c> allByIdIncludingPayments(Set<Id> crIds) {
    CommissionRecord2_Selector selector = new CommissionRecord2_Selector();
    selector.addWhere(
      whereInClauseBuilder('Id', (Set<String>) JSON.deserialize(JSON.serialize(crIds), Set<String>.class))
    );
    return (List<CommissionRecord2__c>) selector.query();
    //    return [ SELECT Id,
    //      Factory_Pricebook__c,
    //      Calculation_Method__c,
    //      TaxProvince__c,
    //      Project__c,
    //      Project_Task__c,
    //      Project_Task__r.Name,
    //      Status__c,
    //      Approved_By__c,
    //      Approved_By__r.Name,
    //    ( SELECT Id,
    //             Owner__c
    //      FROM Commission_Payments__r )
    //    FROM CommissionRecord2__c
    //    WHERE Id IN :crIds ];
  }

  public static List<CommissionRecord2__c> allByErpId(Id erpId) {
    CommissionRecord2_Selector selector = new CommissionRecord2_Selector();
    selector.addWhere('Project__c = \'' + erpId + '\'').addOrderBy('Project_Task__r.Name');
    return (List<CommissionRecord2__c>) selector.query();
    //    return [ SELECT Id,
    //                    Factory_Pricebook__c,
    //                    TaxProvince__c,
    //                    Project__c,
    //                    Project_Task__c,
    //                    Project_Task__r.Name,
    //                    Calculation_Method__c,
    //                    Status__c,
    //                    Approved_By__c,
    //                    Approved_By__r.Name,
    //              ( SELECT Id,
    //                Owner__c
    //              FROM Commission_Payments__r )
    //              FROM CommissionRecord2__c
    //              WHERE Project__c = :erpId
    //              ORDER BY Project_Task__r.Name ];
  }

  public static List<CommissionRecord2__c> allByProjectTaskId(String taskId) {
    CommissionRecord2_Selector selector = new CommissionRecord2_Selector();
    selector.addWhere('Project_Task__c = \'' + taskId + '\'').addOrderBy('Project_Task__r.Name');
    return (List<CommissionRecord2__c>) selector.query();
  }

  public static List<CommissionRecord2__c> allByProjectTaskIds(Set<Id> taskIds) {
    return new CommissionRecord2_Selector().addWhereIdInField(taskIds, 'Project_Task__c').query();
  }

  public static Map<Id, CommissionRecord2__c> mapOfAllById_IncludingProjectTask(Set<Id> crIds) {
    return new Map<Id, CommissionRecord2__c>(
      [
        SELECT
          Id,
          Total_Payment_Amount__c,
          Project_Task__c,
          Project_Task__r.Name,
          Project_Task__r.AcctSeed__GL_Account_Variable_2__c,
          Project_Task__r.AcctSeed__Project__r.Business_Manager__c,
          Project_Task__r.AcctSeed__Project__r.Business_Manager__r.ManagerId,
          Project_Task__r.AcctSeed__Project__r.Business_Manager__r.Commission_Manager_Business_Office__c,
          Project_Task__r.AcctSeed__Project__r.Business_Manager__r.Commission_Gross_Margin_Manager__c,
          Project_Task__r.AcctSeed__Project__r.Business_Manager__r.Commission_Revenue_Manager__c,
          Project_Task__r.AcctSeed__Project__r.Salesperson__r.Commission_Manager_Business_Office__c,
          Project_Task__r.AcctSeed__Project__r.Salesperson__r.Commission_Gross_Margin_Manager__c,
          Project_Task__r.AcctSeed__Project__r.Salesperson__r.Commission_Revenue_Manager__c,
          Project_Task__r.AcctSeed__Project__r.Salesperson__r.ManagerId,
          Project_Task__r.AcctSeed__Project__r.Salesperson__c
        FROM CommissionRecord2__c
        WHERE Id IN :crIds
      ]
    );
  }
}
