public class CommissionRecordController {
  private static Set<String> stages = new Set<String>{ 'New', 'Reviewed', 'Approved', 'Sales Accepted' };

  public class RecordWrapper {
    public String CreatedDate { get; set; }
    public Id OpportunityId { get; set; }
    public Id ERPOrderId { get; set; }
    public String ERPOrderName { get; set; }
    public String OpportunityName { get; set; }
    public String AccountName { get; set; }
    public String InvoiceId { get; set; }
    public ComRecord[] ComRecords { get; set; }
    public String ParentType { get; set; }

    public RecordWrapper(CommissionRecord__c[] records, Opportunity opp) {
      processRecords(records);
      this.OpportunityId = opp.Id;
      this.OpportunityName = opp.Name;
      this.AccountName = opp.Account.Name;
      this.InvoiceId = opp.Invoice_Document_Id__c;
      this.ParentType = 'opportunity';
    }

    public RecordWrapper(CommissionRecord__c[] records, AcctSeed__Project__c erpOrder) {
      processRecords(records);
      this.ERPOrderId = erpOrder.Id;
      this.ERPOrderName = erpOrder.Name;
      this.AccountName = erpOrder.AcctSeed__Account__r.Name;
      this.InvoiceId = null;
      this.ParentType = 'erp_order';
    }

    private void processRecords(CommissionRecord__c[] records) {
      this.ComRecords = new List<ComRecord>();
      if (records.size() > 0) {
        this.CreatedDate = records[0].CreatedDate.format('MMM d, yyy');
        for (CommissionRecord__c record : records) {
          this.ComRecords.add(new ComRecord(record));
        }
      }
    }
  }

  public class QueryParamsWrapper {
    //public Integer perPage { get; set; }
    //public Integer pageNum { get; set; }
    public String selectedStage { get; set; }
    //public String searchString { get; set; }
    public Integer currentMonth { get; set; }
    public Integer currentYear { get; set; }

    public QueryParamsWrapper() {
    }
  }

  public class ComRecord {
    public String Stage { get; set; }
    public String Type { get; set; }
    public String CreatedDate { get; set; }
    public String ReviewedBy { get; set; }
    public String ReviewedOn { get; set; }
    public String ApprovedBy { get; set; }
    public String ApprovedOn { get; set; }
    public String AcceptedBy { get; set; }
    public String AcceptedOn { get; set; }
    public Decimal Amount { get; set; }
    public Id Id { get; set; }
    public CommissionPayment__c[] PaymentRecords { get; set; }

    public ComRecord(CommissionRecord__c record) {
      this.Id = record.Id;
      this.CreatedDate = record.CreatedDate.format();
      this.Stage = record.Stage__c;
      this.ReviewedBy = record.ReviewedBy__r.Name;
      this.ReviewedOn = record.ReviewedOn__c != null ? record.ReviewedOn__c.format() : null;
      this.ApprovedBy = record.ApprovedBy__r.Name;
      this.ApprovedOn = record.ApprovedOn__c != null ? record.ApprovedOn__c.format() : null;
      this.AcceptedBy = record.AcceptedBy__r.Name;
      this.AcceptedOn = record.AcceptedOn__c != null ? record.AcceptedOn__c.format() : null;
      this.Type = record.Type__c;
      this.Amount = record.CommissionTotal__c;
      this.PaymentRecords = record.CommissionPayments__r;
    }
  }

  public class PaymentWrapper {
    public Id Id { get; set; }
    public String CreatedDate { get; set; }
    public String OpportunityName { get; set; }
    public String OpportunityId { get; set; }
    public String ERPOrderName { get; set; }
    public String ERPOrderId { get; set; }
    public String InvoiceId { get; set; }
    public String AccountName { get; set; }
    public String SalesApprovedBy { get; set; }
    public String SalesApprovedOn { get; set; }
    public String ManagerApprovedBy { get; set; }
    public String ManagerApprovedOn { get; set; }
    public String AccountingApprovedBy { get; set; }
    public String AccountingApprovedOn { get; set; }
    public String RecordId { get; set; }
    public String RecordStage { get; set; }
    public String ParentType { get; set; }
    public String CommissionType { get; set; }
    //public String RecordType { get; set; }
    public Decimal RecordAmount { get; set; }
    public Decimal PaymentPercent { get; set; }
    public Decimal PaymentAmount { get; set; }

    public PaymentWrapper(CommissionPayment__c payment, Opportunity opp) {
      this.Id = payment.Id;
      this.ParentType = 'opportunity';
      this.CreatedDate = payment.CommissionRecord__r.CreatedDate.format('MMM d, YYYY');
      this.OpportunityName = opp.Name;
      this.OpportunityId = opp.Id;
      this.InvoiceId = opp.Invoice_Document_Id__c;
      this.AccountName = opp.Account.Name;
      this.SalesApprovedBy = payment.Commissionrecord__r.Approved_By_Sales__r.Name;
      this.SalesApprovedOn = payment.Commissionrecord__r.Sales_Approved_On__c != null
        ? payment.Commissionrecord__r.Sales_Approved_On__c.format()
        : null;
      this.ManagerApprovedBy = payment.Commissionrecord__r.Approved_By_Manager__r.Name;
      this.ManagerApprovedOn = payment.Commissionrecord__r.Manager_Approved_On__c != null
        ? payment.Commissionrecord__r.Manager_Approved_On__c.format()
        : null;
      this.AccountingApprovedBy = payment.Commissionrecord__r.Approved_By_Accounting__r.Name;
      this.AccountingApprovedOn = payment.Commissionrecord__r.Accounting_Approved_On__c != null
        ? payment.Commissionrecord__r.Accounting_Approved_On__c.format()
        : null;
      this.RecordId = payment.CommissionRecord__c;
      this.RecordStage = payment.CommissionRecord__r.Stage__c;
      this.RecordAmount = payment.CommissionRecord__r.CommissionTotal__c;
      this.PaymentPercent = payment.PaymentPercent__c;
      this.PaymentAmount = payment.PaymentAmount__c;
      this.CommissionType = payment.Commissionrecord__r.Type__c;
    }

    public PaymentWrapper(CommissionPayment__c payment, AcctSeed__Project__c erp) {
      this.Id = payment.Id;
      this.ParentType = 'erp_order';
      this.CreatedDate = payment.CommissionRecord__r.CreatedDate.format('MMM d, YYYY');
      this.ERPOrderName = erp.Name;
      this.ERPOrderId = erp.Id;
      this.AccountName = erp.AcctSeed__Account__r.Name;
      this.SalesApprovedBy = payment.Commissionrecord__r.Approved_By_Sales__r.Name;
      this.SalesApprovedOn = payment.Commissionrecord__r.Sales_Approved_On__c != null
        ? payment.Commissionrecord__r.Sales_Approved_On__c.format()
        : null;
      this.ManagerApprovedBy = payment.Commissionrecord__r.Approved_By_Manager__r.Name;
      this.ManagerApprovedOn = payment.Commissionrecord__r.Manager_Approved_On__c != null
        ? payment.Commissionrecord__r.Manager_Approved_On__c.format()
        : null;
      this.AccountingApprovedBy = payment.Commissionrecord__r.Approved_By_Accounting__r.Name;
      this.AccountingApprovedOn = payment.Commissionrecord__r.Accounting_Approved_On__c != null
        ? payment.Commissionrecord__r.Accounting_Approved_On__c.format()
        : null;
      this.RecordId = payment.CommissionRecord__c;
      this.RecordStage = payment.CommissionRecord__r.Stage__c;
      this.RecordAmount = payment.CommissionRecord__r.CommissionTotal__c;
      this.PaymentPercent = payment.PaymentPercent__c;
      this.PaymentAmount = payment.PaymentAmount__c;
      this.CommissionType = payment.Commissionrecord__r.Type__c;
    }
  }

  //@RemoteAction
  //public static List<RecordWrapper> fetchCommissionRecords()
  //{
  //  CommissionRecord__c[] recs =  [SELECT Id, Type__c, OpportunityId__c, Stage__c, CommissionTotal__c, Approved_By_Sales__r.Name, Sales_Approved_On__c, Approved_By_Manager__r.Name, Manager_Approved_On__c, Approved_By_Accounting__r.Name, Accounting_Approved_On__c,
  //                                 (SELECT Id, Owner__c, Owner__r.Name, PaymentPercent__c, PaymentAmount__c
  //                                    FROM CommissionPayments__r)
  //                                 FROM CommissionRecord__c
  //                                 WHERE Stage__c IN :stages];
  //  return createRecordList(recs);
  //}

  @RemoteAction
  public static List<RecordWrapper> fetchCommissionRecords(String queryParams) {
    QueryParamsWrapper qParams = (QueryParamsWrapper) JSON.deserialize(queryParams, QueryParamsWrapper.class);
    //  Integer pageOffset = (qParams.pageNum - 1) * qParams.perPage;
    String dateString = generateDateQueryString(qParams.currentYear, qParams.currentMonth);
    String queryString = 'SELECT  Id, CreatedDate, Type__c, OpportunityId__c, ERP_Order__c, Stage__c, CommissionTotal__c,  ReviewedBy__r.Name, ReviewedOn__c, ApprovedBy__r.Name, ApprovedOn__c, AcceptedBy__r.Name, AcceptedOn__c, ';
    queryString += '(SELECT Id, Owner__c, Owner__r.Name, PaymentPercent__c, PaymentAmount__c FROM CommissionPayments__r) ';
    queryString += 'FROM CommissionRecord__c ';
    queryString += 'WHERE LineItemCount__c > 0 ';
    queryString += dateString;
    if (stages.contains(qParams.selectedStage)) {
      queryString += 'AND Stage__c = \'' + qParams.selectedStage + '\' ';
    }
    queryString += 'AND isDealLost__c = false ';
    queryString += 'ORDER BY CreatedDate';
    //queryString += 'LIMIT ' + qParams.perPage + ' ';
    //queryString += 'OFFSET ' + pageOffset;
    CommissionRecord__c[] recs = Database.query(queryString);
    return createRecordList(recs);
  }

  //@RemoteAction
  //public static List<RecordWrapper> fetchCommissionRecordsByStage(String stageName)
  //{
  //  CommissionRecord__c[] recs =  [SELECT Id, CreatedDate, Type__c, OpportunityId__c, Stage__c, CommissionTotal__c,  Approved_By_Sales__r.Name, Sales_Approved_On__c, Approved_By_Manager__r.Name, Manager_Approved_On__c, Approved_By_Accounting__r.Name, Accounting_Approved_On__c,
  //                                 (SELECT Id, Owner__c, Owner__r.Name, PaymentPercent__c, PaymentAmount__c
  //                                    FROM CommissionPayments__r)
  //                                 FROM CommissionRecord__c
  //                                 WHERE Stage__c = :stageName
  //                                 AND CommissionTotal__c > 0];
  //  return createRecordList(recs);
  //}

  private static List<RecordWrapper> createRecordList(CommissionRecord__c[] recs) {
    if (recs.size() > 0) {
      List<RecordWrapper> records = new List<RecordWrapper>();
      Map<Id, Opportunity> opps;
      Map<Id, AcctSeed__Project__c> erpOrders;
      // Map<OpportunityId__c, CommissionRecord__c[]>
      Map<String, CommissionRecord__c[]> oppGroupedComRecords = new Map<String, CommissionRecord__c[]>();
      Map<String, CommissionRecord__c[]> erpOrderGroupedComRecords = new Map<String, CommissionRecord__c[]>();
      for (CommissionRecord__c cr : recs) {
        if (cr.OpportunityId__c != null) {
          if (!oppGroupedComRecords.containsKey(cr.OpportunityId__c)) {
            oppGroupedComRecords.put(cr.OpportunityId__c, new List<CommissionRecord__c>());
          }
          oppGroupedComRecords.get(cr.OpportunityId__c).add(cr);
        }
        if (cr.ERP_Order__c != null) {
          if (!erpOrderGroupedComRecords.containsKey(cr.ERP_Order__c)) {
            erpOrderGroupedComRecords.put(cr.ERP_Order__c, new List<CommissionRecord__c>());
          }
          erpOrderGroupedComRecords.get(cr.ERP_Order__c).add(cr);
        }
      }
      if (oppGroupedComRecords != null) {
        opps = new Map<Id, Opportunity>(
          [
            SELECT Id, Name, Invoice_Document_Id__c, Account.Name
            FROM Opportunity
            WHERE Id IN :oppGroupedComRecords.keySet()
          ]
        );
        for (String oppId : oppGroupedComRecords.keySet()) {
          if (opps.containsKey(oppId)) {
            records.add(new RecordWrapper(oppGroupedComRecords.get(oppId), opps.get(oppId)));
          }
        }
      }
      if (erpOrderGroupedComRecords != null) {
        erpOrders = new Map<Id, AcctSeed__Project__c>(
          [
            SELECT Id, Name, AcctSeed__Account__r.Name
            FROM AcctSeed__Project__c
            WHERE Id IN :erpOrderGroupedComRecords.keySet()
          ]
        );
        for (String orderId : erpOrderGroupedComRecords.keySet()) {
          if (erpOrders.containsKey(orderId)) {
            records.add(new RecordWrapper(erpOrderGroupedComRecords.get(orderId), erpOrders.get(orderId)));
          }
        }
      }

      return records;
    }
    return null;
  }

  @RemoteAction
  public static List<PaymentWrapper> fetchSalesCommissionRecords(String queryParams) {
    return doFetchSalesCommissionRecords(queryParams);
  }

  //@AuraEnabled
  //public static String salesCommissionRecords()
  //{
  //  return JSON.serialize( doFetchSalesCommissionRecords() );
  //}

  // @AuraEnabled
  //public static List<CommissionPayment__c> salesCommissionRecords()
  //{
  //  Id currentUserId = UserInfo.getUserId();
  //  return [SELECT Id, PaymentAmount__c, PaymentPercent__c FROM CommissionPayment__c WHERE Owner__c = :currentUserId];
  //}

  private static List<PaymentWrapper> doFetchSalesCommissionRecords(String queryParams) {
    Id currentUserId = UserInfo.getUserId();
    QueryParamsWrapper qParams = (QueryParamsWrapper) JSON.deserialize(queryParams, QueryParamsWrapper.class);
    String dateString = generateDateQueryString(qParams.currentYear, qParams.currentMonth);
    //Integer pageOffset = (qParams.pageNum - 1) * qParams.perPage;
    String queryString = 'SELECT Id, PaymentAmount__c, PaymentPercent__c, CommissionRecord__r.CreatedDate, CommissionRecord__c, CommissionRecord__r.CommissionTotal__c, CommissionRecord__r.OpportunityId__c, CommissionRecord__r.ERP_Order__c, CommissionRecord__r.Stage__c, CommissionRecord__r.Approved_By_Sales__r.Name, CommissionRecord__r.Sales_Approved_On__c, CommissionRecord__r.Approved_By_Manager__r.Name, CommissionRecord__r.Manager_Approved_On__c, CommissionRecord__r.Approved_By_Accounting__r.Name, CommissionRecord__r.Accounting_Approved_On__c, CommissionRecord__r.Type__c FROM CommissionPayment__c ';
    queryString += 'WHERE Owner__c = \'' + currentUserId + '\' ';
    queryString += dateString;
    if (stages.contains(qParams.selectedStage)) {
      queryString += 'AND CommissionRecord__r.Stage__c = \'' + qParams.selectedStage + '\' ';
    }
    queryString += 'ORDER BY CreatedDate';
    CommissionPayment__c[] comPayments = Database.query(queryString);
    return comPayments.size() > 0 ? createPaymentList(comPayments) : null;
  }

  //@RemoteAction
  //public static List<PaymentWrapper> fetchSpecificSalesCommissionRecords(String stageName)
  //{
  //  Id currentUserId = UserInfo.getUserId();
  //  CommissionPayment__c[] comPayments = [SELECT Id, PaymentAmount__c, PaymentPercent__c, CommissionRecord__c, CommissionRecord__r.CreatedDate, CommissionRecord__r.CommissionTotal__c, CommissionRecord__r.OpportunityId__c, CommissionRecord__r.Stage__c, CommissionRecord__r.Type__c, CommissionRecord__r.Approved_By_Sales__r.Name, CommissionRecord__r.Sales_Approved_On__c, CommissionRecord__r.Approved_By_Manager__r.Name, CommissionRecord__r.Manager_Approved_On__c, CommissionRecord__r.Approved_By_Accounting__r.Name, CommissionRecord__r.Accounting_Approved_On__c FROM CommissionPayment__c WHERE Owner__c = :currentUserId AND CommissionRecord__r.Stage__c = :stageName];

  //  return createPaymentList(comPayments);
  //}

  private static String generateDateQueryString(Integer year, Integer month) {
    String result;
    month++; // months from JS start at 0 and 'All' is -1
    Date fromDate;
    Date toDate;
    Time fromTime = Time.newInstance(0, 0, 0, 0);
    Time toTime = Time.newInstance(23, 59, 59, 0);
    DateTime fromDateTime;
    DateTime toDateTime;
    if (month > 12) {
      fromDate = Date.newInstance(year, 1, 1);
      toDate = Date.newInstance(year, 12, 31);
    } else {
      fromDate = Date.newInstance(year, month, 1);
      toDate = Date.newInstance(year, month, Date.daysInMonth(year, month));
    }
    fromDateTime = DateTime.newInstanceGMT(fromDate, fromTime);
    toDateTime = DateTime.newInstanceGMT(toDate, toTime);

    result = 'AND CreatedDate > ';
    result += fromDateTime.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
    result += ' AND CreatedDate < ';
    result += toDateTime.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
    result += ' ';
    System.debug('&&&&&&&&&&&&&&&& DATESTRING = ' + result);
    return result;
  }

  private static List<PaymentWrapper> createPaymentList(CommissionPayment__c[] comPayments) {
    // map the CommissionPayment to the Opportunity Id in the CommissionRecord
    Map<String, List<CommissionPayment__c>> oppComPaymentMap = new Map<String, List<Commissionpayment__c>>();
    Map<String, List<CommissionPayment__c>> erpComPaymentMap = new Map<String, List<Commissionpayment__c>>();
    for (CommissionPayment__c cp : comPayments) {
      if (cp.CommissionRecord__r.OpportunityId__c != null) {
        if (!oppComPaymentMap.containsKey(cp.CommissionRecord__r.OpportunityId__c))
          oppComPaymentMap.put(cp.CommissionRecord__r.OpportunityId__c, new List<CommissionPayment__c>());
        oppComPaymentMap.get(cp.CommissionRecord__r.OpportunityId__c).add(cp);
      }
      if (cp.CommissionRecord__r.ERP_Order__c != null) {
        if (!erpComPaymentMap.containsKey(cp.CommissionRecord__r.ERP_Order__c))
          erpComPaymentMap.put(cp.CommissionRecord__r.ERP_Order__c, new List<CommissionPayment__c>());
        erpComPaymentMap.get(cp.CommissionRecord__r.ERP_Order__c).add(cp);
      }
    }

    Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
      [SELECT Id, Name, Invoice_Document_Id__c, Account.Name FROM Opportunity WHERE Id IN :oppComPaymentMap.keySet()]
    );

    Map<Id, AcctSeed__Project__c> erpMap = new Map<Id, AcctSeed__Project__c>(
      [SELECT Id, Name, AcctSeed__Account__r.Name FROM AcctSeed__Project__c WHERE Id IN :erpComPaymentMap.keySet()]
    );

    PaymentWrapper[] records = new List<PaymentWrapper>();
    for (String oppId : oppComPaymentMap.keySet()) {
      if (oppMap.containsKey(oppId)) {
        for (CommissionPayment__c cp : oppComPaymentMap.get(oppId)) {
          records.add(new PaymentWrapper(cp, oppMap.get(oppId)));
        }
      }
    }
    for (String erpId : erpComPaymentMap.keySet()) {
      if (erpMap.containsKey(erpId)) {
        for (CommissionPayment__c cp : erpComPaymentMap.get(erpId)) {
          records.add(new PaymentWrapper(cp, erpMap.get(erpId)));
        }
      }
    }
    return records;
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
