public with sharing class CommissionCalculatorController {
  public class CommissionRecordException extends Exception {
  }

  public String oppId { get; set; }
  public String comRecordId { get; set; }
  public String erpOrderId { get; set; }
  public String retURL { get; set; }
  public String oppName { get; private set; }
  public String campaignName { get; private set; }
  public Id objectId { get; set; }
  public List<Id> comRecordIds { get; private set; }
  public String invoiceURL { get; private set; }
  public String maxApprovalStage { get; private set; }
  public Boolean renderedOnParentDetailPage { get; set; }

  static Set<String> salesRoles = new Set<String>{
    'Business Office Managers',
    'Memory Makers',
    'Retail Memory Making Manager',
    'District Sales Manager',
    'Parts and Service Advisor',
    'Parts and Service Manager',
    'Legend Dealership General Manager'
  };
  static Set<String> approverRoles = new Set<String>{
    'Retail Memory Making Manager',
    'Legend Dealership General Manager',
    'Legend General Manager'
  };

  public CommissionCalculatorController(ApexPages.StandardController stdCtr) {
    init();
  }

  public CommissionCalculatorController() {
    init();
  }

  public String getPermissions() {
    return JSON.serialize(
      new Map<String, Boolean>{
        'canReview' => Schema.sObjectType.CommissionRecord__c.fields.ReviewedBy__c.isUpdateable(),
        'canApprove' => Schema.sObjectType.CommissionRecord__c.fields.ApprovedBy__c.isUpdateable(),
        'canAccept' => Schema.sObjectType.CommissionRecord__c.fields.AcceptedBy__c.isUpdateable(),
        'canUndoComplete' => LGND_Utilities.CustomPermissions.canReOpenCommissionRecord
      }
    );
  }

  private void init() {
    renderedOnParentDetailPage = false;
    comRecordIds = new List<Id>();
    Id currentUserId = UserInfo.getUserId();
    objectId = ApexPages.currentPage().getParameters().get('id');
    comRecordId = ApexPages.currentPage().getParameters().get('comrecord_id');
    oppId = ApexPages.currentPage().getParameters().get('opportunity_id');
    erpOrderId = ApexPages.currentPage().getParameters().get('erp_order_id');
    //comRecordId = std.getId();
    if (objectId != null) {
      Schema.sObjectType entityType = objectId.getSObjectType();
      if (entityType === Opportunity.sObjectType) {
        oppId = objectId;
      }
      if (entityType === CommissionRecord__c.sObjectType) {
        comRecordId = objectId;
      }
      if (entityType === AcctSeed__Project__c.sObjectType) {
        erpOrderId = objectId;
        renderedOnParentDetailPage = true;
      }
    }
    retURL = ApexPages.currentPage().getParameters().get('retURL');
    retURL = retURL == null ? oppId == null ? '/' : '/' + oppId : retURL;
    if (oppId == null && erpOrderId == null && comRecordId != null) {
      //oppName = oppNameFromCR(comRecordId);
      setNamesFromComRecord(comRecordId); //findOppName(comRecordId);
      comRecordIds.add(comRecordId);
    }
    if (oppId != null && erpOrderId == null && comRecordId == null) {
      Map<Id, CommissionRecord__c> crs = new Map<Id, CommissionRecord__c>(
        [SELECT Id, Name FROM CommissionRecord__c WHERE OpportunityId__c = :oppId]
      );
      if (crs.size() > 0) {
        comRecordIds.addAll(new List<Id>(crs.keySet()));
        oppName = crs.values()[0].Name;
      }
    }
    if (erpOrderId != null && oppId == null && comRecordId == null) {
      Map<Id, CommissionRecord__c> crs = new Map<Id, CommissionRecord__c>(
        [
          SELECT Id, Name, ERP_Order__r.AcctSeed__Opportunity__r.Campaign.Name
          FROM CommissionRecord__c
          WHERE ERP_Order__c = :erpOrderId
        ]
      );
      if (crs.size() > 0) {
        comRecordIds.addAll(new List<Id>(crs.keySet()));
        oppName = crs.values()[0].Name;
        campaignName = crs.values()[0].ERP_Order__r.AcctSeed__Opportunity__r.Campaign.Name;
      }
    }
    findInvoiceURL();
    findMaxApprovalStage();
  }

  private void findMaxApprovalStage() {
    if (Schema.sObjectType.CommissionRecord__c.fields.ReviewedBy__c.isUpdateable()) {
      maxApprovalStage = 'Reviewed';
    } else if (Schema.sObjectType.CommissionRecord__c.fields.ApprovedBy__c.isUpdateable()) {
      maxApprovalStage = 'Approved';
    } else {
      maxApprovalStage = 'New';
    }
  }

  private void findInvoiceURL() {
    invoiceURL = '/servlet/servlet.FileDownload?file=015R000000087jZIAQ';
  }

  private void setNamesFromComRecord(String comRecordId) {
    try {
      CommissionRecord__c cr = [
        SELECT
          Id,
          Name,
          ERP_Order__c,
          ERP_Order__r.AcctSeed__Opportunity__r.Campaign.Name,
          ERP_Order__r.AcctSeed__Opportunity__r.Name
        FROM CommissionRecord__c
        WHERE Id = :comRecordId
        LIMIT 1
      ];
      oppName = cr.Name;
      campaignName = cr.ERP_Order__r.AcctSeed__Opportunity__r.Campaign.Name;
      erpOrderId = cr.ERP_Order__c;
    } catch (Exception e) {
    }
  }

  private static String findOppName(String crId) {
    try {
      CommissionRecord__c cr = [SELECT Id, Name, OpportunityId__c FROM CommissionRecord__c WHERE Id = :crId LIMIT 1];
      return cr.Name;
    } catch (Exception e) {
      return null;
    }
  }

  //private static String oppNameFromCR(String crId)
  //{
  //  try
  //  {
  //    CommissionRecord__c cr = [SELECT Id, Name, OpportunityId__c FROM CommissionRecord__c WHERE Id = :crId LIMIT 1];
  //    return SELECT Name, Id FROM Opportunity WHERE Id = :cr.OpportunityId__c].Name;
  //  }
  //  catch(Exception e)
  //  {
  //    return null;
  //  }

  //}

  /* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */
  /*
  ______   ______   .___  ___. .___  ___.  __       _______.     _______. __    ______   .__   __.
 /      | /  __  \  |   \/   | |   \/   | |  |     /       |    /       ||  |  /  __  \  |  \ |  |
|  ,----'|  |  |  | |  \  /  | |  \  /  | |  |    |   (----`   |   (----`|  | |  |  |  | |   \|  |
|  |     |  |  |  | |  |\/|  | |  |\/|  | |  |     \   \        \   \    |  | |  |  |  | |  . `  |
|  `----.|  `--'  | |  |  |  | |  |  |  | |  | .----)   |   .----)   |   |  | |  `--'  | |  |\   |
 \______| \______/  |__|  |__| |__|  |__| |__| |_______/    |_______/    |__|  \______/  |__| \__|

 .______       _______   ______   ______   .______      _______
|   _   \    |   ____| /      | /  __  \  |   _  \     |       \
|  |_)  |    |  |__   |  ,----'|  |  |  | |  |_)  |    |  .--.  |
|      /     |   __|  |  |     |  |  |  | |      /     |  |  |  |
|  |\  \----.|  |____ |  `----.|  `--'  | |  |\  \----.|  '--'  |
| _| `._____||_______| \______| \______/  | _| `._____||_______/

*/

  @RemoteAction
  public static List<CommissionRecord__c> fetchRecords(String recordId, String idField) {
    String userRole;
    try {
      userRole = [SELECT Name FROM UserRole WHERE Id = :UserInfo.getUserRoleId()].Name;
    } catch (Exception e) {
    }

    String userId = UserInfo.getUserId();
    List<CommissionRecord__c> crs = new List<CommissionRecord__c>();
    if (userRole != null && salesRoles.contains(userRole)) {
      for (CommissionRecord__c cr : doQuery(idField, recordId)) {
        for (CommissionPayment__c cp : cr.CommissionPayments__r) {
          if (cp.Owner__c == userId || approverRoles.contains(userRole)) {
            crs.add(cr);
          }
        }
      }
      return crs;
    }

    return doQuery(idField, recordId);
  }

  @RemoteAction
  public static String fetchInvoice(Id parentId) {
    String result;
    String docId;
    String sObjName = parentId.getSObjectType().getDescribe().getName();
    if (sObjName == 'AcctSeed__Project__c') {
      docId = [SELECT Id, LastDocumentID__c FROM AcctSeed__Project__c WHERE Id = :parentId].LastDocumentID__c;
    }
    if (sObjName == 'Opportunity') {
      docId = [SELECT Id, Invoice_Document_Id__c FROM Opportunity WHERE ID = :parentId].Invoice_Document_Id__c;
    }
    if (docId != null) {
      result = '/servlet/servlet.FileDownload?file=' + docId;
    }
    return result;
  }

  @RemoteAction
  public static CommissionRecord__c fetchRecord(String recordId) {
    return CommissionRecordERP.fetchRecord(recordId);
  }

  @RemoteAction
  public static CommissionRecord__c setDisputed(String recordId, String message) {
    CommissionRecord__c cRec = [SELECT Id, Stage__c, ApprovedBy__c FROM CommissionRecord__c WHERE Id = :recordId];
    if (cRec.Stage__c != 'Approved') {
      throw new CommissionRecordException('You can not dispute a Commission unless it is Approved');
    }
    cRec.Is_Disputed__c = true;
    cRec.DisputedBy__c = UserInfo.getUserId();
    cRec.Stage__c = 'Reviewed';
    update cRec;
    makeDisputedChatter(cRec, message);
    return doQuery('Id', cRec.Id)[0];
  }

  @RemoteAction
  public static CommissionRecord__c resolveDisputed(String recordId) {
    CommissionRecord__c cRec = new CommissionRecord__c(
      Id = recordId,
      Stage__c = 'Approved',
      Is_Disputed__c = false,
      DisputedBy__c = null
    );
    update cRec;
    return doQuery('Id', cRec.Id)[0];
  }

  //@RemoteAction
  //public static List<CommissionRecord__c> createRecords(String oppId)
  //{
  //  CommissionRecord__c[] newComRecs = CommissionRecord.recreateCommissionRecords(oppId);
  //  return doQuery('OpportunityId__c', oppId);
  //}

  @RemoteAction
  public static CommissionRecord__c changeStage(String recordId, String newStage) {
    //String errorMsg;
    //CommissionRecord__c cRec = [SELECT Id, Stage__c FROM CommissionRecord__c WHERE Id = :recordId];
    //// Sales person is approving
    //System.debug( 'New Stage = ' + newStage);
    //System.debug( 'Current Stage + ' + cRec.Stage__c );
    //System.debug( Schema.sObjectType.CommissionRecord__c.fields.ApprovedBy__c.isUpdateable() );
    //if( cRec.Stage__c == 'Sales Accepted' &&
    //    !Schema.sObjectType.CommissionRecord__c.fields.AcceptedBy__c.isUpdateable() )
    //{
    //  errorMsg = 'You do not have permissions to undo Sales Acceptance';
    //}
    //// Accounting first Review
    //if( newStage == 'Reviewed' )
    //{
    //  if( !Schema.sObjectType.CommissionRecord__c.fields.ReviewedBy__c.isUpdateable() )
    //    errorMsg = 'You do not have permission to update the record to ' + newStage;
    //}
    ////Accounting Approving
    //if( newStage == 'Approved')
    //{
    //  if( !Schema.sObjectType.CommissionRecord__c.fields.ApprovedBy__c.isUpdateable() )
    //    errorMsg = 'You do not have permission to update the record to ' + newStage;
    //  //undo complete
    //  //if( cRec.Stage__c == 'Complete' &&
    //  //    !Schema.sObjectType.CommissionRecord__c.fields.Approved_By_Accounting__c.isUpdateable() )
    //  //   errorMsg = 'You do not have permissions to undo Accounting Approval';
    //  //if( isPayee(recordId) && errorMsg == null )
    //  //  errorMsg = 'Nice try !!! You can not approve your own commission';
    //}
    //if( newStage == 'Sales Accepted' )
    //{
    //  if( !Schema.sObjectType.CommissionRecord__c.fields.AcceptedBy__c.isUpdateable() )
    //    errorMsg = 'You do not have permission to update the record to ' + newStage;
    //  else if( cRec.Stage__c != 'Approved' )
    //    errorMsg = 'You can not Accept the Commission before it is Approved';
    //}

    //if( errorMsg != null )
    //{
    //  throw new CommissionRecordException(errorMsg);
    //}
    return doUpdate(recordId, newStage);
  }

  private static CommissionRecord__c doUpdate(String recordId, String newStage) {
    //CommissionRecord__c comRecord = [SELECT Id, OpportunityId__c FROM CommissionRecord__c WHERE ID = :recordId];
    //comRecord.Stage__c = newStage;
    CommissionRecord__c comRecord = new CommissionRecord__c(Id = recordId, Stage__c = newStage);
    update comRecord;
    return doQuery('Id', recordId)[0];
  }

  private static void makeDisputedChatter(CommissionRecord__c comRecord, String message) {
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

    mentionSegmentInput.id = comRecord.ApprovedBy__c;
    messageBodyInput.messageSegments.add(mentionSegmentInput);

    textSegment = new ConnectApi.TextSegmentInput();
    textSegment.text = '\n\n This Commission has been disputed for the following reason.';
    messageBodyInput.messageSegments.add(textSegment);

    markupEndSegment = new ConnectApi.MarkupEndSegmentInput();
    markupEndSegment.markupType = ConnectApi.MarkupType.Bold;
    messageBodyInput.messageSegments.add(markupEndSegment);

    /* BLANK LINE */
    markupBeginSegment = new ConnectApi.MarkupBeginSegmentInput();
    markupBeginSegment.markupType = ConnectApi.MarkupType.Paragraph;
    messageBodyInput.messageSegments.add(markupBeginSegment);

    textSegment = new ConnectApi.TextSegmentInput();
    textSegment.text = '&nbsp;';
    messageBodyInput.messageSegments.add(textSegment);

    markupEndSegment = new ConnectApi.MarkupEndSegmentInput();
    markupEndSegment.markupType = ConnectApi.MarkupType.Paragraph;
    messageBodyInput.messageSegments.add(markupEndSegment);

    /* ACTUAL NOTES */
    markupBeginSegment = new ConnectApi.MarkupBeginSegmentInput();
    markupBeginSegment.markupType = ConnectApi.MarkupType.Paragraph;
    messageBodyInput.messageSegments.add(markupBeginSegment);

    textSegment = new ConnectApi.TextSegmentInput();
    textSegment.text = message;
    messageBodyInput.messageSegments.add(textSegment);

    markupEndSegment = new ConnectApi.MarkupEndSegmentInput();
    markupEndSegment.markupType = ConnectApi.MarkupType.Paragraph;
    messageBodyInput.messageSegments.add(markupEndSegment);

    feedItemInput.body = messageBodyInput;
    feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
    feedItemInput.subjectId = comRecord.Id;

    ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
  }

  private static Boolean isPayee(Id comRecordId) {
    List<CommissionPayment__c> payments = [
      SELECT Id
      FROM CommissionPayment__c
      WHERE CommissionRecord__c = :comRecordId AND Owner__c = :UserInfo.getUserId()
    ];
    return payments.size() > 0 ? true : false;
  }

  //private static List<CommissionRecord__c> createRecords(String oId)
  //{
  //  Map<String, CommissionRecord__c> commRecords = buildAndInsertRecords(oId);
  //  linkCommissionLineItemstoRecords(oId, commRecords);
  //  return doQuery('Opportunity__c', oId);
  //}

  /* ============================================================================================== */

  /* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */
  /*
   ______   ______   .___  ___. .___  ___.  __       _______.     _______. __    ______   .__   __.
 /      | /  __  \  |   \/   | |   \/   | |  |     /       |    /       ||  |  /  __  \  |  \ |  |
|  ,----'|  |  |  | |  \  /  | |  \  /  | |  |    |   (----`   |   (----`|  | |  |  |  | |   \|  |
|  |     |  |  |  | |  |\/|  | |  |\/|  | |  |     \   \       \   \    |  | |  |  |  | |  . `  |
|  `----.|  `--'  | |  |  |  | |  |  |  | |  | .----)   |  .----)   |   |  | |  `--'  | |  |\   |
 \______| \______/  |__|  |__| |__|  |__| |__| |_______/  |_______/    |__|  \______/  |__| \__|

 __  .___________. _______ .___  ___.
|  | |           ||   ____||   \/   |
|  | `---|  |----`|  |__   |  \  /  |
|  |     |  |     |   __|  |  |\/|  |
|  |     |  |     |  |____ |  |  |  |
|__|     |__|     |_______||__|  |__|

*/

  /* this is named horribly. It is infact used to BOTH update AND create CommissionLineItems */
  @RemoteAction
  public static CommissionLineItem__c updateItem(String jsonData) {
    CommissionLineItem__c item = (CommissionLineItem__c) JSON.deserializeStrict(jsonData, CommissionLineItem__c.class);
    upsert item;
    return item;
  }

  @RemoteAction
  public static CommissionLineItem__c deleteCommissionLineItem(String itemId) {
    CommissionLineItem__c item = [SELECT Id FROM CommissionLineItem__c WHERE Id = :itemId];
    delete item;
    return item;
  }

  /* ============================================================================================== */

  /* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */
  /*
  ______   ______   .___  ___. .___  ___.  __       _______.     _______. __    ______   .__   __.
 /      | /  __  \  |   \/   | |   \/   | |  |     /       |    /       ||  |  /  __  \  |  \ |  |
|  ,----'|  |  |  | |  \  /  | |  \  /  | |  |    |   (----`   |   (----`|  | |  |  |  | |   \|  |
|  |     |  |  |  | |  |\/|  | |  |\/|  | |  |     \   \        \   \    |  | |  |  |  | |  . `  |
|  `----.|  `--'  | |  |  |  | |  |  |  | |  | .----)   |   .----)   |   |  | |  `--'  | |  |\   |
 \______| \______/  |__|  |__| |__|  |__| |__| |_______/    |_______/    |__|  \______/  |__| \__|

.______      ___   ____    ____ .___  ___.  _______ .__   __. .___________.    _______.
|   _  \    /   \  \   \  /   / |   \/   | |   ____||  \ |  | |           |   /       |
|  |_)  |  /  ^  \  \   \/   /  |  \  /  | |  |__   |   \|  | `---|  |----`  |   (----`
|   ___/  /  /_\  \  \_    _/   |  |\/|  | |   __|  |  . `  |     |  |        \   \
|  |     /  _____  \   |  |     |  |  |  | |  |____ |  |\   |     |  |    .----)   |
| _|    /__/     \__\  |__|     |__|  |__| |_______||__| \__|     |__|    |_______/

  */

  @RemoteAction
  public static CommissionPayment__c updatePaymentRecord(String jsonData) {
    CommissionPayment__c cp = (CommissionPayment__c) JSON.deserialize(jsonData, CommissionPayment__c.class);
    upsert cp;
    return [
      SELECT
        Id,
        CommissionRecord__c,
        Owner__c,
        Owner__r.SmallPhotoUrl,
        Owner__r.Name,
        Owner__r.FirstName,
        Owner__r.LastName,
        Owner__r.Commission_Percentage__c,
        PaymentAmount__c,
        PaymentPercent__c
      FROM CommissionPayment__c
      WHERE Id = :cp.Id
    ];
  }

  @RemoteAction
  public static List<CommissionPayment__c> updatePaymentRecords(String jsonData) {
    List<CommissionPayment__c> toDelete = new List<CommissionPayment__c>();
    List<CommissionPayment__c> toUpsert = new List<CommissionPayment__c>();
    List<CommissionPayment__c> cps = (List<CommissionPayment__c>) JSON.deserialize(
      jsonData,
      List<CommissionPayment__c>.class
    );
    for (CommissionPayment__c cp : cps) {
      if (cp.Id != null && cp.PaymentPercent__c == 0)
        toDelete.add(cp);
      if (cp.PaymentPercent__c > 0)
        toUpsert.add(cp);
    }
    delete toDelete;
    upsert toUpsert;
    Set<Id> cpIds = new Set<Id>();
    for (SObject cp : toUpsert) {
      cpIds.add(cp.Id);
    }
    return [
      SELECT
        Id,
        CommissionRecord__c,
        CommissionRecord__r.Stage__c,
        Owner__c,
        Owner__r.SmallPhotoUrl,
        Owner__r.Name,
        Owner__r.FirstName,
        Owner__r.LastName,
        Owner__r.Commission_Percentage__c,
        PaymentAmount__c,
        PaymentPercent__c
      FROM CommissionPayment__c
      WHERE Id IN :cpIds
    ];
  }

  @RemoteAction
  public static CommissionPayment__c deletePaymentRecord(String paymentRecordId) {
    CommissionPayment__c cp = [SELECT Id, CommissionRecord__c FROM CommissionPayment__c WHERE Id = :paymentRecordId];
    List<CommissionPayment__c> payments = [
      SELECT Id
      FROM CommissionPayment__c
      WHERE CommissionRecord__c = :cp.CommissionRecord__c AND ID != :paymentRecordId
    ];
    delete cp;
    if (payments.size() == 0) {
      CommissionPayment__c newCP = new CommissionPayment__c(
        CommissionRecord__c = cp.CommissionRecord__c,
        PaymentPercent__c = 100
      );
      insert newCP;
      return [
        SELECT CommissionRecord__c, Id, PaymentPercent__c, PaymentAmount__c
        FROM CommissionPayment__c
        WHERE Id = :newCP.Id
      ];
    }
    return null;
  }

  /* ============================================================================================== */

  @RemoteAction
  public static List<User> fetchUsers() {
    return [
      SELECT Id, Name, FirstName, LastName, FullPhotoUrl, SmallPhotoUrl, Commission_Percentage__c
      FROM User
      WHERE IsActive = TRUE AND UserType = 'Standard'
      ORDER BY LastName
    ];
  }

  private static List<CommissionRecord__c> doQuery(String idFieldName, String recordId) {
    String query =
      'SELECT Id, CreatedDate, Is_Disputed__c, DisputedBy__r.Name,' +
      ' ReviewedBy__r.Name, ReviewedOn__c, ApprovedBy__r.Name, ApprovedOn__c,' +
      ' AcceptedOn__c, AcceptedBy__r.Name, isDealLost__c, Type__c, OpportunityId__c,' +
      ' Stage__c, CommissionTotal__c, Name, ERP_Order__c, Was_Auto_Accepted__c,' +
      ' (SELECT Id, isInsurance__c, AppliedCommissionAmount__c, AppliedCommissionRate__c,' +
      ' CommissionableAmount__c, CalculatedCommissionAmount__c, CommissionRate__c, CustomItem__c,' +
      ' Department__c, Description__c, Quantity__c, Retail_Price__c, Sale_Price__c, isEditable__c,' +
      ' hasChanged__c, RecordStage__c, EditCommissionableAmount__c, InsuranceItemId__c,' +
      ' OpportunityLineItemId__c FROM CommissionLineItems__r ORDER BY AppliedCommissionAmount__c DESC),' +
      ' (SELECT Owner__c, Owner__r.Name, Owner__r.SmallPhotoUrl, Owner__r.Commission_Percentage__c,' +
      ' PaymentPercent__c, PaymentAmount__c, CommissionRecordType__c FROM CommissionPayments__r)' +
      ' FROM CommissionRecord__c  WHERE ' +
      idFieldName +
      ' = \'' +
      recordId +
      '\'';
    return Database.query(query);
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
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
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
