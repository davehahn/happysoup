/**
 * Created by dave on 2020-02-18.
 */

public with sharing class CommissionPayment2_Service
{
  public static Decimal defaultGrossMarginPaymentPercent = 10;
  public static Decimal defaultGrossMarginPaymentPercentManager = 0;

  public static List<CommissionPayment2__c> createInitialPayments( Set<Id> commissionRecordIds, String cpType )
  {
    List<CommissionPayment2__c> payments = new List<CommissionPayment2__c>();
    for( Id crId : commissionRecordIds )
    {
      payments.add( new CommissionPayment2__c(
          Commission_Record2__c = crId,
          Type__c = cpType
      ));
    }
    insert payments;
    return payments;
  }
  @Future
  public static void createManagersCommissionFuture(Set<Id> commissionPaymentIds){
    createManagersCommission(commissionPaymentIds);
  }
  public static void createManagersCommission(Set<Id> commissionPaymentIds){
    System.debug('I am here...');
    System.debug(commissionPaymentIds);
    List<CommissionPayment2__c> listCP = new List<CommissionPayment2__c>();
    Set<Id> setIdCommissionRecord = new Set<Id>();
    for(CommissionPayment2__c cp : [SELECT Id, Commission_Record2__c FROM CommissionPayment2__c WHERE Id IN:commissionPaymentIds]){
      listCP.add(cp);
      setIdCommissionRecord.add(cp.Commission_Record2__c);
    }
    /////
    Map<Id,CommissionPayment2__c> managerCP = new Map<Id,CommissionPayment2__c>();
    // Checking for Manages Payment
    Set<Id> setIdCRWithManagers = checkManagersCommission(setIdCommissionRecord);
    System.debug('setIdCRWithManagers');
    System.debug(setIdCRWithManagers);
    // loop and validate
    for(CommissionPayment2__c cp : listCP){
      /// Creating false Managers list to check and validate
      if(!setIdCRWithManagers.contains(cp.Commission_Record2__c))
        managerCP.put(cp.Commission_Record2__c, new CommissionPayment2__c(Commission_Record2__c = cp.Commission_Record2__c, Type__c = 'Manager'));
    }
    // Check with false records
    setInitialValues(managerCP.values());
    // now lets check to see if any payments have zero amount. Then we will discard those
    // List<CommissionPayment2__c> cpManagersListTOInsert = new List<CommissionPayment2__c>();
    Set<Id> setIdManagersCP = new Set<Id>();
    for(CommissionPayment2__c cp : managerCP.values()){
      if(cp.Gross_Margin_Payment_Percent__c != 0 && cp.Gross_Margin_Payment_Percent__c != null){
        setIdManagersCP.add(cp.Commission_Record2__c);
      }
    }
    // Now do the actual managers payments
    if(!setIdManagersCP.isEmpty())
      createInitialPayments( setIdCommissionRecord, 'Manager' );
  }

  public static Set<Id> checkManagersCommission(Set<Id> commissionRecordIds){
    Set<Id> idWithManagers = new Set<Id>();
    for(CommissionPayment2__c cp : [SELECT Id, Commission_Record2__c FROM CommissionPayment2__c WHERE Commission_Record2__c IN:commissionRecordIds AND Type__c = 'Manager']){
      idWithManagers.add(cp.Commission_Record2__c);
    }
    return idWithManagers;
  }

  public static void setInitialValues( List<CommissionPayment2__c> payments )
  {
    setInitialOwner( payments );
    setPaymentPercentages( payments );
  }

  public static void setInitialOwner( List<CommissionPayment2__c> payments )
  {
    Set<Id> cRecIds = new Set<Id>();
    Set<Id> ownerIds = new Set<Id>();
    Id managerId = [Select Id, ManagerId FROM User WHERE Id = :UserInfo.getUserId()].ManagerId;
    for( CommissionPayment2__c payment : payments )
    {
      cRecIds.add( payment.Commission_Record2__c );
    }
    Map<Id, CommissionRecord2__c> commRecMap = CommissionRecord2_Selector.mapOfAllById_IncludingProjectTask( cRecIds );
    for( CommissionPayment2__c payment : payments )
    {
      if( commRecMap.containsKey( payment.Commission_Record2__c ) )
      {
        CommissionRecord2__c cr = commRecMap.get( payment.Commission_Record2__c );
        if( payment.Owner__c == null) {
          if (payment.Type__c == 'Standard' || payment.Type__c == null) {
            if (cr.Project_Task__r.AcctSeed__GL_Account_Variable_2__c == LGND_Constants.GLV2Id_BusinessOffice) {
              payment.Owner__c = cr.Project_Task__r.AcctSeed__Project__r.Business_Manager__c;
            } else if (cr.Project_Task__r.AcctSeed__GL_Account_Variable_2__c == LGND_Constants.GLV2Id_Sales &&
                cr.Project_Task__r.Name.contains('Retail Sale')) {
              payment.Owner__c = cr.Project_Task__r.AcctSeed__Project__r.Salesperson__c;
            }
            if (payment.Owner__c == null) {
              payment.Owner__c = UserInfo.getUserId();
            }
          } else if (payment.Type__c == 'Manager'){
            if (cr.Project_Task__r.AcctSeed__GL_Account_Variable_2__c == LGND_Constants.GLV2Id_BusinessOffice) {
              payment.Owner__c = cr.Project_Task__r.AcctSeed__Project__r.Business_Manager__r.ManagerId;
            } else if (cr.Project_Task__r.AcctSeed__GL_Account_Variable_2__c == LGND_Constants.GLV2Id_Sales &&
                cr.Project_Task__r.Name.contains('Retail Sale')) {
              payment.Owner__c = cr.Project_Task__r.AcctSeed__Project__r.Salesperson__r.ManagerId;
            }
            if (payment.Owner__c == null) {
              payment.Owner__c = managerId;
            }
          }
        }
      }
    }
  }

  public static void setPaymentPercentages( List<CommissionPayment2__c> payments )
  {
    Set<Id> ownerIds = new Set<Id>();
    Map<Id,AcctSeed__Project_Task__c> mapTaskDetailByCRId = new Map<Id,AcctSeed__Project_Task__c>();
    for( CommissionPayment2__c cp : payments )
    {
      ownerIds.add( cp.Owner__c );
      mapTaskDetailByCRId.put(cp.Commission_Record2__c,null);
    }
    Map<Id, User> owners = new Map<Id, User>(
      [SELECT Id, Commission_Gross_Margin_Percent_Override__c, Commission_Gross_Margin_Manager__c, Commission_Manager_Business_Office__c, Commission_Revenue_Manager__c FROM User WHERE Id IN :ownerIds]
    );

    /// Search for tasks
    Id idGLV2BusinessOffice = LGND_Constants.GLV2Id_BusinessOffice;
    Id idGLV2Sales = LGND_Constants.GLV2Id_Sales;
    for(CommissionRecord2__c cr : [SELECT Id, Project_Task__c, Project_Task__r.AcctSeed__GL_Account_Variable_2__c, Project_Task__r.Commission_Calculation_Method__c FROM CommissionRecord2__c WHERE Id IN:mapTaskDetailByCRId.keySet()]){
      mapTaskDetailByCRId.put(cr.Id,cr.Project_Task__r);
    }

    for( CommissionPayment2__c cp : payments )
    {
      if(Test.isRunningTest() && cp.Owner__c == null)
        cp.Owner__c = UserInfo.getUserId();
      if(cp.Owner__c != null) {
        if (cp.Type__c == 'Standard') {
          cp.Gross_Margin_Payment_Percent__c =
              owners.get(cp.Owner__c).Commission_Gross_Margin_Percent_Override__c != null ?
                  owners.get(cp.Owner__c).Commission_Gross_Margin_Percent_Override__c :
                  defaultGrossMarginPaymentPercent;
        } else if(owners.get(cp.Owner__c) != null
            && owners.get(cp.Owner__c) != null){
          AcctSeed__Project_Task__c pt = mapTaskDetailByCRId.get(cp.Commission_Record2__c);
          if(pt.Commission_Calculation_Method__c == 'Gross Margin' && pt.AcctSeed__GL_Account_Variable_2__c == idGLV2Sales) {
            cp.Gross_Margin_Payment_Percent__c =
                owners.get(cp.Owner__c).Commission_Gross_Margin_Manager__c != null ?
                    owners.get(cp.Owner__c).Commission_Gross_Margin_Manager__c :
                    defaultGrossMarginPaymentPercentManager;
            cp.Manager_Commission_Type__c = 'Gross Margin';
          }else if(pt.Commission_Calculation_Method__c == 'Revenue' && pt.AcctSeed__GL_Account_Variable_2__c == idGLV2BusinessOffice){
            cp.Gross_Margin_Payment_Percent__c =
                owners.get(cp.Owner__c).Commission_Manager_Business_Office__c != null ?
                    owners.get(cp.Owner__c).Commission_Manager_Business_Office__c :
                    defaultGrossMarginPaymentPercentManager;
            cp.Manager_Commission_Type__c = 'Business Revenue';
          }else if(pt.Commission_Calculation_Method__c == 'Revenue' && pt.AcctSeed__GL_Account_Variable_2__c != idGLV2BusinessOffice){
            cp.Gross_Margin_Payment_Percent__c =
                owners.get(cp.Owner__c).Commission_Revenue_Manager__c != null ?
                    owners.get(cp.Owner__c).Commission_Revenue_Manager__c :
                    defaultGrossMarginPaymentPercentManager;
            cp.Manager_Commission_Type__c = 'Revenue';
          }
        }
      }else{
        throw new gcException('Owner not found');
      }
    }

  }

  public static void propagateCommissionRecordStageChange( Set<Id> resolved, Set<Id> unApproved )
  {
    Set<Id> commissionRecordIds = new Set<Id>();
    commissionRecordIds.addAll( resolved );
    commissionRecordIds.addAll( unApproved );
    if( commissionRecordIds.size() > 0 )
    {
      List<CommissionPayment2__c> payments = CommissionPayment2_Selector.allByCommissionRecordIds(commissionRecordIds);
      for (CommissionPayment2__c payment : payments)
      {
        if (resolved.contains(payment.Commission_Record2__c) &&
          payment.Status__c == 'Disputed')
        {
          payment.Status__c = 'New';
        }
        if (unApproved.contains(payment.Commission_Record2__c) &&
          payment.Commission_Record2__r.Status__c != 'Disputed')
        {
          payment.Status__c = 'New';
        }
      }
      update payments;
    }
  }

  @Future
  public static void autoAcceptForCommissionRecords( Set<Id> commissionRecordId )
  {
    List<CommissionPayment2__c> payments = CommissionPayment2_Selector.allNewByCommissionRecordIds( commissionRecordId );
    for( CommissionPayment2__c p : payments )
    {
      p.Status__c = 'Accepted';
      p.Auto_Accepted__c = true;
    }
    update payments;
  }

}