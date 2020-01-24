/**
 * Created by dave on 2020-01-30.
 */

public with sharing class CommissionRecord2_Service
{
  public List<AcctSeed__Project_Task__c> tasks;
  public List<AcctSeed__Project_Task__c> tasksToRemove;
  public List<CommissionRecord2__c> commissionRecords;
  private Map<Id, Id> task2CommissionRecord_Map;

  public CommissionRecord2_Service()
  {
    this.tasks = new List<AcctSeed__Project_Task__c>();
    this.tasksToRemove = new List<AcctSeed__Project_Task__c>();
    this.commissionRecords = new List<CommissionRecord2__c>();
  }

  public void addTask( AcctSeed__Project_Task__c task )
  {
    this.tasks.add( task );
  }

  public void addTaskToRemove( AcctSeed__Project_Task__c task )
  {
    this.tasksToRemove.add( task );
  }

  public void addTasksToRemove( List<AcctSeed__Project_Task__c> tasks )
  {
    this.tasksToRemove.addAll( tasks );
  }

  public void addTasks( List<AcctSeed__Project_Task__c> tasks )
  {
    this.tasks.addAll( tasks );
  }

  public void saveRecords()
  {
    if( this.tasks.isEmpty() )
      return;

    for( AcctSeed__Project_Task__c task : this.tasks )
    {
      this.commissionRecords.add( new CommissionRecord2__c(
        Id = getCommissionRecordId( task.Id ),
        Project_Task__c = task.Id,
        Calculation_Method__c = task.Commission_Calculation_Method__c
      ));
    }
    upsert this.commissionRecords;
  }

  public void deleteRecords()
  {
    if( this.tasksToRemove.isEmpty() )
      return;
    Set<Id> taskIds = LGND_Utilities.getIdSetFromList( (List<SObject>)this.tasksToRemove );
    delete [ SELECT Id FROM CommissionRecord2__c WHERE Project_Task__c IN :taskIds];
  }

  private Id getCommissionRecordId( Id taskId )
  {
    if( this.task2CommissionRecord_Map == null )
    {
      populateTask2CommissionRecordMap();
    }
    if( this.task2CommissionRecord_Map.containsKey( taskId ) )
      return this.task2CommissionRecord_Map.get( taskId );
    return null;
  }

  private void populateTask2CommissionRecordMap()
  {
    this.task2CommissionRecord_Map = new Map<Id, Id>();
    Set<Id> taskIds = LGND_Utilities.getIdSetFromList( (List<sObject>)this.tasks );
    for( CommissionRecord2__c cr : [SELECT Id, Project_Task__c FROM CommissionRecord2__c WHERE Project_Task__c IN : taskIds ] )
    {
      this.task2CommissionRecord_Map.put( cr.Project_Task__c, cr.Id );
    }

  }

  public static void postApprovedMessage( Set<Id> commissionRecordIds )
  {

    Map<Id, Set<Id>> recordId_paymentOwners_map = new Map<Id, Set<Id>>();
    String msg = ' Good News! This Commission Record has been Approved by Accounting. Please review and accept this Commission. The commission will be automatically accepted on your behalf after 7 days.';
    for( CommissionRecord2__c cr : CommissionRecord2_Selector.allByIdIncludingPayments( commissionRecordIds ) )
    {
      recordId_paymentOwners_map.put( cr.Id, new Set<Id>() );
      for( CommissionPayment2__c payment : cr.Commission_Payments__r )
      {
        recordId_paymentOwners_map.get( cr.Id ).add( payment.Owner__c );
      }
    }
    if( recordId_paymentOwners_map.size() > 0 )
    {
      doPost( buildPosts( recordId_paymentOwners_map, msg ) );
    }
  }

  public static void postRevertedMessage( Map<Id, Id> wasReviewed,
                                          Map<Id, Id> wasApproved )
  {
    List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();
    String wasReviewedMsg = 'This Commission Record was previously Reviewed by you, but the underlying ERP Order has changed and all approvals have been reset';
    String wasApprovedMsg = 'This Commission Record was previously Approved by you, but the underlying ERP Order has changed and all approvals have been reset';
    Map<Id, Set<Id>> reviewedMap = new Map<Id, Set<Id>>();
    Map<Id, Set<Id>> approvedMap = new Map<Id, Set<Id>>();
    for( Id comRecId : wasReviewed.keySet() )
    {
      reviewedMap.put( comRecId, new Set<Id>{ wasReviewed.get( comRecId ) } );
    }
    for( Id comRecId : wasApproved.keySet() )
    {
      approvedMap.put( comRecId, new Set<Id>{ wasApproved.get( comRecId ) } );
    }
    batchInputs.addAll( buildPosts( reviewedMap, wasReviewedMsg ) );
    batchInputs.addAll( buildPosts( approvedMap, wasApprovedMsg ) );
    doPost( batchInputs );
  }

  public static void openIfClosed( Set<Id> commissionRecordIds )
  {
    List<CommissionRecord2__c> records = new List<CommissionRecord2__c>();
    for( CommissionRecord2__c record : CommissionRecord2_Selector.allById( commissionRecordIds ) )
    {
      if( record.Status__c != 'New' )
      {
        record.Status__c = 'New';
        records.add(record);
      }
    }
    update records;
  }

  public static void postResolveMessage( Map<Id, Set<Id>> comRec_paymentOwnersMap )
  {
    String msg = ' Commission record dispute has been Resolved. Please review and accept this Commission. The commission will be automatically accepted on your behalf after 7 days.';
    doPost( buildPosts(comRec_paymentOwnersMap, msg ) );
  }

  public static void makeDisputedChatter( CommissionRecord2__c comRecord,
                                           String message )
  {
    List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();

    ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
    ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
    ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
    ConnectApi.MarkupBeginSegmentInput markupBeginSegment;
    ConnectApi.MarkupEndSegmentInput markupEndSegment;
    ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();

    messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

    /* HEADER */
    markupBeginSegment = new ConnectApi.MarkupBeginSegmentInput();
    markupBeginSegment.markupType = ConnectApi.MarkupType.Bold;
    messageBodyInput.messageSegments.add(markupBeginSegment);

    if( comRecord.Approved_By__c != null )
    {
      mentionSegmentInput.id = comRecord.Approved_By__c;
      messageBodyInput.messageSegments.add(mentionSegmentInput);
    }

    textSegment = new ConnectApi.TextSegmentInput();
    textSegment.text = '\n\n This Commission has been disputed for the following reason.';
    messageBodyInput.messageSegments.add( textSegment );

    markupEndSegment = new ConnectApi.MarkupEndSegmentInput();
    markupEndSegment.markupType = ConnectApi.MarkupType.Bold;
    messageBodyInput.messageSegments.add(markupEndSegment);

    /* BLANK LINE */
    markupBeginSegment = new ConnectApi.MarkupBeginSegmentInput();
    markupBeginSegment.markupType = ConnectApi.MarkupType.Paragraph;
    messageBodyInput.messageSegments.add(markupBeginSegment);

    textSegment = new ConnectApi.TextSegmentInput();
    textSegment.text = '&nbsp;';
    messageBodyInput.messageSegments.add( textSegment );

    markupEndSegment = new ConnectApi.MarkupEndSegmentInput();
    markupEndSegment.markupType = ConnectApi.MarkupType.Paragraph;
    messageBodyInput.messageSegments.add(markupEndSegment);

    /* ACTUAL NOTES */
    markupBeginSegment = new ConnectApi.MarkupBeginSegmentInput();
    markupBeginSegment.markupType = ConnectApi.MarkupType.Paragraph;
    messageBodyInput.messageSegments.add(markupBeginSegment);

    textSegment = new ConnectApi.TextSegmentInput();
    textSegment.text = message;
    messageBodyInput.messageSegments.add( textSegment );

    markupEndSegment = new ConnectApi.MarkupEndSegmentInput();
    markupEndSegment.markupType = ConnectApi.MarkupType.Paragraph;
    messageBodyInput.messageSegments.add(markupEndSegment);


    feedItemInput.body = messageBodyInput;
    feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
    feedItemInput.subjectId = comRecord.Id;

    ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(feedItemInput);
    batchInputs.add(batchInput);

    ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), batchInputs);

  }

  private static List<ConnectApi.BatchInput> buildPosts( Map<Id, Set<Id>> record_ownersMap, String msg )
  {
    System.debug('buildPosts');
    List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();
    for( Id comRecId : record_ownersMap.keySet() )
    {
      System.debug('CommissionRecordId = ' + comRecId );
      System.debug( record_ownersMap.get( comRecId ) );
      ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(
        LGND_Utilities.makeChatterPost(
          new List<Id>( record_ownersMap.get( comRecId ) ),
          msg,
          comRecId
        )
      );
      batchInputs.add( batchInput );
    }
    return batchInputs;
  }

  private static void doPost(List<ConnectApi.BatchInput> batchInputs )
  {
    if( batchInputs.size() > 0 && !Test.isRunningTest() )
    {
      System.debug('DOPOST');
      System.debug( batchInputs.size() );
      ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), batchInputs);
    }
  }
}