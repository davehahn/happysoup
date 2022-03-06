/**
 * Created by dave on 2020-01-28.
 */
/* TODO: DELETE ME */
public without sharing class CommissionRecord2_TriggerHandler extends TriggerHandler
{
  public class CommissionRecord2_Exception extends Exception{}

//  protected override void bulkBefore()
//  {
//  }

//  protected override void bulkAfter()
//  {
//  }

//  protected override void beforeInsert()
//  {
//// 1    setValuesFromProjectTask( (List<CommissionRecord2__c>)Trigger.new );
//// 2    setFactoryPB( (List<CommissionRecord2__c>)Trigger.new );
//  }

//  protected override void beforeUpdate()
//  {
//// 1    handleStatusBefore( (List<CommissionRecord2__c>)Trigger.new, (Map<Id,CommissionRecord2__c>)Trigger.oldMap  );
//  }

//  protected override void beforeDelete()
//  {
//  }

//  protected override void afterInsert()
//  {
// // 1   CommissionPayment2_Service.createInitialPayments( Trigger.newMap.keySet(), 'Standard' );
// // 2   CommissionLineItem2_Service.createDefaultLineItems( (List<CommissionRecord2__c>)Trigger.new );
//  }

//  protected override void afterUpdate()
//  {
////    Map<Id, CommissionRecord2__c> oldMap = (Map<Id, CommissionRecord2__c>)Trigger.oldMap;
////    Set<Id> calcHasChanged = new Set<Id>();
////    Set<Id> approvalExpired = new Set<Id>();
////    for( CommissionRecord2__c rec : (List<CommissionRecord2__c>)Trigger.new )
////    {
////      CommissionRecord2__c oldRec = oldMap.get(rec.Id);
////      if (rec.Calculation_Method__c != oldRec.Calculation_Method__c)
////      {
////        calcHasChanged.add( rec.Id );
////      }
////      if( rec.Sales_Acceptable_Expired__c &&
////          !oldRec.Sales_Acceptable_Expired__c )
////      {
////        approvalExpired.add( rec.Id );
////      }
////    }
////    if( calcHasChanged.size() > 0 )
////    {
//// 1     CommissionLineItem2_Service service = new CommissionLineItem2_Service();
////      service.recalculate( calcHasChanged );
////    }
////    if( approvalExpired.size() > 0 )
////    {
//// 2     CommissionPayment2_Service.autoAcceptForCommissionRecords( approvalExpired );
////    }
//// 3  handleStatusAfter( (List<CommissionRecord2__c>)Trigger.new, oldMap );
//  }

//  protected override void afterDelete()
//  {
//  }

//  protected override void afterUndelete()
//  {
//  }

//  protected override void finalActions()
//  {
//  }

//  private static void setValuesFromProjectTask( List<CommissionRecord2__c> listNew )
//  {
//    Map<Id, CommissionRecord2__c> taskIdMap = new Map<Id, CommissionRecord2__c>();
//    for( CommissionRecord2__c cr : listNew )
//    {
//      taskIdMap.put( cr.Project_Task__c, cr );
//    }
//    for( AcctSeed__Project_Task__c task : [ SELECT Id,
//                                                    AcctSeed__Project__c,
//                                                    AcctSeed__Project__r.GMBLASERP__Pricebook__c,
//                                                    AcctSeed__GL_Account_Variable_2__c,
//                                                    Commission_Calculation_Method__c
//                                            FROM AcctSeed__Project_Task__c
//                                            WHERE Id IN :taskIdMap.keySet() ] )
//    {
//      taskIdMap.get( task.Id ).Project__c = task.AcctSeed__Project__c;
//      taskIdMap.get( task.Id ).Retail_Pricebook__c = task.AcctSeed__Project__r.GMBLASERP__Pricebook__c;
//      taskIdMap.get( task.Id ).Calculation_Method__c = task.Commission_Calculation_Method__c;
//      taskIdMap.get( task.Id ).Department_GLV2__c = task.AcctSeed__GL_Account_Variable_2__c;
//    }
//  }
//
//  private static void setFactoryPB( List<CommissionRecord2__c> listNew )
//  {
//    Map<Id, Id> retail2Factory_Map = Pricebook2_Service.getRetailToFactory_Map();
//    for( CommissionRecord2__c cr : listNew )
//    {
//      if( retail2Factory_Map.containsKey( cr.Retail_Pricebook__c ) )
//      {
//        cr.Factory_Pricebook__c = retail2Factory_Map.get( cr.Retail_Pricebook__c );
//      }
//    }
//  }
//
//  private static void handleStatusBefore( List<CommissionRecord2__c> listNew, Map<Id, CommissionRecord2__c> oldMap )
//  {
//    if( canUpdateStatus(listNew, oldMap) )
//    {
//      Set<Id> setId = new Set<Id>();
//      for (CommissionRecord2__c record : listNew)
//      {
//        CommissionRecord2__c oRecord = oldMap.get(record.Id);
//        if ( oRecord.Status__c != record.Status__c)
//        {
//          if( record.Status__c == 'Reviewed' )
//          {
//            record.Reviewed_By__c = UserInfo.getUserId();
//          }
//          if(record.Status__c == 'Approved')
//          {
//            record.Approved_By__c = UserInfo.getUserId();
//            record.Approved_On__c = DateTime.now();
//            setId.add(record.Id);
//          }
//          if(oRecord.Status__c == 'Reviewed' && record.Status__c != 'Approved' )
//          {
//            record.Reviewed_By__c = null;
//          }
//          if(oRecord.Status__c == 'Approved')
//          {
//            record.Approved_By__c = null;
//            record.Approved_On__c = null;
//            record.Previously_Approved_on__c = oRecord.Approved_On__c;
//          }
//        }
//      }
//    }
//  }
//
//  private static void handleStatusAfter( List<CommissionRecord2__c> listNew, Map<Id, CommissionRecord2__c> oldMap )
//  {
//    Set<Id> resolved = new Set<Id>();
//    Set<Id> approved = new Set<Id>();
//    Set<Id> approvedNow = new Set<Id>();
//    Set<Id> disApproved = new Set<Id>();
//    Set<Id> unApproved = new Set<Id>();
//    Map<Id, Id> wasReviewed = new Map<Id, Id>();
//    Map<Id, Id> wasApproved = new Map<Id, Id>();
//    Set<Id> setId = new Set<Id>();
//    for( CommissionRecord2__c record : listNew )
//    {
//      CommissionRecord2__c oldRecord = oldMap.get( record.Id );
//      if( oldRecord.Status__c != record.Status__c )
//      {
//        if( oldRecord.Status__c == 'Disputed')
//        {
//          resolved.add( record.Id );
//        }
//        if( oldRecord.Status__c == 'Approved' )
//        {
//          unApproved.add( record.Id );
//        }
//        if( record.Status__c == 'Approved' &&
//          oldRecord.Status__c != 'Disputed' )
//        {
//          approved.add( record.Id );
//        }
//        if( record.Status__c != 'Approved' &&
//            oldRecord.Status__c == 'Approved' )
//        {
//          disApproved.add( record.Id );
//        }
//        if( record.Status__c == 'Approved' &&
//            oldRecord.Status__c != 'Approved' )
//        {
//          approvedNow.add( record.Id );
//        }
//        if( record.Status__c == 'New' )
//        {
//          if( oldRecord.Status__c == 'Reviewed' )
//          {
//            wasReviewed.put( record.Id, oldRecord.Reviewed_By__c );
//          }
//          if( oldRecord.Status__c == 'Approved' )
//          {
//            wasApproved.put( record.Id, oldRecord.Approved_By__c );
//          }
//        }
//      }
//    }
//    CommissionPayment2_Service.propagateCommissionRecordStageChange(
//      resolved, unApproved
//    );
//    CommissionRecord2_Service.postRevertedMessage(
//      wasReviewed, wasApproved
//    );
//    if( approved.size() > 0 )
//    {
//      //CommissionRecord2_Service.postApprovedMessage( approved );
//    }
//    if( approvedNow.size() > 0 )
//    {
//      JournalEntry_Service.takeExpense(approvedNow);
//    }
//    if( disApproved.size() > 0 )
//    {
//      JournalEntry_Service.unTakeExpense(disApproved);
//    }
//  }
//
//  private static Boolean canUpdateStatus( List<CommissionRecord2__c> listNew,
//                                          Map<Id, CommissionRecord2__c> oldMap )
//  {
//    for( CommissionRecord2__c cr: listNew )
//    {
//      if( oldMap != null &&
//          oldMap.get(cr.Id).Status__c == 'Approved' &&
//          CommissionRecord2_Service.beforeApprovedStatuses.contains(cr.Status__c ) &&
//          !LGND_Utilities.CustomPermissions.canReOpenCommissionRecord )
//      {
//        cr.addError('You do not have permission to re-open an Approved Commission Record');
//      }
//    }
//    return true;
//  }
}