public with sharing class ERPOrder_CreatePartsRequestController {
  public class PartWrapper implements Comparable {
    @AuraEnabled
    public String materialId;
    @AuraEnabled
    public String productId;
    @AuraEnabled
    public String productName;
    @AuraEnabled
    public Decimal quantityOrdered;
    @AuraEnabled
    public Decimal quantityAllocated;
    @AuraEnabled
    public Decimal quantityRequired;
    @AuraEnabled
    public String taskName;
    @AuraEnabled
    public String uniqueProductCode;

    public PartWrapper(AcctSeedERP__Material__c mat) {
      this.materialId = mat.Id;
      this.productId = mat.AcctSeedERP__Product__c;
      this.productName = mat.AcctSeedERP__Product__r.Name;
      this.quantityOrdered = mat.AcctSeedERP__Quantity_Per_Unit__c;
      this.quantityAllocated = mat.AcctSeedERP__Quantity_Allocated__c;
      this.quantityRequired = this.quantityOrdered - this.quantityAllocated;
      this.taskName = mat.AcctSeedERP__Project_Task__r.Name;
      this.uniqueProductCode = mat.AcctSeedERP__Product__r.ProductCode;
    }

    public Integer compareTo(Object compareTo) {
      PartWrapper compareToData = (PartWrapper) compareTo;
      if (this.quantityRequired == compareToData.quantityRequired)
        return 0;
      if (this.quantityRequired < compareToData.quantityRequired)
        return 1;
      return -1;
    }
  }

  public class CaseWrapper {
    public String caseNumber;
    public String caseId;
    public String createdBy;
    public String createdDate;
    public String status;
    public Date eta;

    public List<Map<String, String>> caseParts;

    public CaseWrapper(Case c) {
      this.caseId = c.Id;
      this.caseNumber = c.CaseNumber;
      this.createdBy = c.CreatedBy.Name;
      this.status = c.Status;
      this.createdDate = c.CreatedDate.format('MMM d, yyyy');
      wrapCaseParts(c.Case_Parts__r);
    }

    private void wrapCaseParts(Case_Part__c[] cps) {
      this.caseParts = new List<Map<String, String>>();
      for (Case_Part__c cp : cps) {
        Map<String, String> p = new Map<String, String>();
        p.put('productName', cp.Product__r.Name);
        p.put('uniqueProductCode', cp.Product__r.ProductCode);
        p.put('quantity', String.valueOf(cp.Quantity__c));
        Date eta = cp.Purchase_Order_Line__r.deliverDate__c == null
          ? cp.Purchase_Order_Line__r.AcctSeedERP__Purchase_Order__r.Estimated_Time_of_Arrival_ETA__c
          : cp.Purchase_Order_Line__r.deliverDate__c;
        String eta_string = eta == null
          ? ''
          : DateTime.newInstance(eta.year(), eta.month(), eta.day()).format('MMM d, yyyy');
        p.put('eta', eta_string);
        this.caseParts.add(p);
      }
    }
  }

  @AuraEnabled
  public static String getInitialData(String recordId) {
    Map<String, String> result = new Map<String, String>();
    result.put('canCreate', 'false');
    AcctSeed__Project__c erp = [SELECT Id, Stage__c, RecordTypeId FROM AcctSeed__Project__c WHERE Id = :recordId];
    result.put('erp', JSON.serialize(erp));
    Case[] cases = [
      SELECT
        Id,
        CaseNumber,
        CreatedBy.Name,
        CreatedDate,
        Status,
        (
          SELECT
            Product__r.Name,
            Product__r.ProductCode,
            Quantity__c,
            Purchase_Order_Line__r.deliverDate__c,
            Purchase_Order_Line__r.AcctSeedERP__Purchase_Order__r.Estimated_Time_of_Arrival_ETA__c
          FROM Case_Parts__r
        )
      FROM Case
      WHERE ERP_Order__c = :recordId AND IsClosed = FALSE
    ];

    if (cases.size() > 0) {
      CaseWrapper[] cwrappers = new List<CaseWrapper>();
      for (Case c : cases) {
        cwrappers.add(new CaseWrapper(c));
      }
      result.put('cases', JSON.serialize(cwrappers));
    }

    //determine if the Create Button should be displayed
    Application_RecordType appRT = new Application_RecordType();
    Set<String> validRetailStages = new Set<String>{
      'Tagging Pending',
      'Pending Work Order',
      'Pending Pick and Pack',
      'Parts Required'
    };
    if (
      erp.RecordTypeId == appRT.getERPOrderRecordTypes().getRetailBoatSaleId() &&
      validRetailStages.contains(erp.Stage__c)
    ) {
      result.put('canCreate', 'true');
    } else if (erp.Stage__c == 'Parts Required') {
      result.put('canCreate', 'true');
    }

    return JSON.serialize(result);
  }

  @AuraEnabled
  public static String getMaterials(String erpId) {
    List<PartWrapper> parts = buildMaterialsList(erpId);
    return JSON.serialize(parts);
  }

  public static List<PartWrapper> buildMaterialsList(String erpId) {
    Set<String> ingnoreFamilies = new Set<String>{ 'Labour', 'Premium Package', 'Service Package', 'Discount' };
    Id partRtId = new Application_RecordType().getProductRecordTypes().getPartId();
    PartWrapper[] parts = new List<PartWrapper>();
    for (AcctSeedERP__Material__c mat : [
      SELECT
        Id,
        AcctSeedERP__Product__c,
        AcctSeedERP__Product__r.Name,
        AcctSeedERP__Product__r.ProductCode,
        AcctSeedERP__Quantity_Per_Unit__c,
        AcctSeedERP__Quantity_Allocated__c,
        AcctSeedERP__Project_Task__r.Name
      FROM AcctSeedERP__Material__c
      WHERE
        AcctSeedERP__Project__c = :erpId
        AND AcctSeedERP__Product__r.RecordTypeId = :partRtId
        AND AcctSeedERP__Product__r.Family NOT IN :ingnoreFamilies
    ]) {
      parts.add(new PartWrapper(mat));
    }
    System.debug('parts: ' + parts);
    parts.sort();
    return parts;
  }

  @AuraEnabled
  public static String createPartsRequestCase(String casePartsJSON, String erpId, String notes) {
    Case_Part__c[] caseParts = (List<Case_Part__c>) JSON.deserialize(casePartsJSON, List<Case_Part__c>.class);
    AcctSeed__Project__c erp = [
      SELECT Id, AcctSeed__Account__c, RecordType.Name
      FROM AcctSeed__Project__c
      WHERE Id = :erpId
    ];
    Id caseRtId = LGND_Utilities.recordTypeIdFromName('Case', 'Part Order Request');
    Case c = new Case(
      ERP_Order__c = erpId,
      AccountId = erp.AcctSeed__Account__c,
      RecordTypeId = caseRtId,
      Origin = erp.RecordType.Name,
      Parts_Request_Notes__c = notes
    );
    insert c;
    for (Case_Part__c cp : caseParts) {
      cp.Case__c = c.Id;
    }
    insert caseParts;
    c = [SELECT Id, CaseNumber FROM Case WHERE Id = :c.Id];
    return c.CaseNumber;
    //return 'test';
  }
}
