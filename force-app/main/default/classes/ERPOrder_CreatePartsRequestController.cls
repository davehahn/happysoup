public with sharing class ERPOrder_CreatePartsRequestController {

  public class PartWrapper implements Comparable {
    public String materialId;
    public String productId;
    public String productName;
    public Decimal quantityOrdered;
    public Decimal quantityAllocated;
    public Decimal quantityRequired;
    public String taskName;

    public PartWrapper( AcctSeedERP__Material__c mat )
    {
      this.materialId = mat.Id;
      this.productId = mat.AcctSeedERP__Product__c;
      this.productName = mat.AcctSeedERP__Product__r.Name;
      this.quantityOrdered = mat.AcctSeedERP__Quantity_Per_Unit__c;
      this.quantityAllocated = mat.AcctSeedERP__Quantity_Allocated__c;
      this.quantityRequired = this.quantityOrdered - this.quantityAllocated;
      this.taskName = mat.AcctSeedERP__Project_Task__r.Name;
    }

    public Integer compareTo(Object compareTo) {
      PartWrapper compareToData = (PartWrapper)compareTo;
      if( this.quantityRequired == compareToData.quantityRequired )
        return 0;
      if( this.quantityRequired < compareToData.quantityRequired )
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

    public CaseWrapper( Case c )
    {
      this.caseId = c.Id;
      this.caseNumber = c.CaseNumber;
      this.createdBy = c.CreatedBy.Name;
      this.status = c.Status;
      this.createdDate = c.CreatedDate.format('MMM d, yyyy');
      wrapCaseParts( c.Case_Parts__r );
    }

    private void wrapCaseParts( Case_Part__c[] cps )
    {
      this.caseParts = new List<Map<String, String>>();
      for( Case_Part__c cp : cps )
      {
        Map<String, String> p = new Map<String, String>();
        p.put('productName', cp.Product__r.Name );
        p.put('quantity', String.valueOf( cp.Quantity__c) );
        Date eta = cp.Purchase_Order_Line__r.AcctSeedERP__Purchase_Order__r.Estimated_Time_of_Arrival_ETA__c;
        String eta_string = eta == null ? '' : DateTime.newInstance( eta.year(), eta.month(), eta.day() ).format('MMM d, yyyy');
        p.put('eta', eta_string );
        this.caseParts.add( p );
      }
    }
  }

  @AuraEnabled
  public static String getInitialData( String recordId )
  {
    Map<String, String> result = new MAp<String, String>();
    AcctSeed__Project__c erp = [SELECT Id, Stage__c FROM AcctSeed__Project__c WHERE Id = :recordId];
    result.put('erp', JSON.serialize(erp) );
    Case[] cases = [SELECT Id, CaseNumber, CreatedBy.Name, CreatedDate, Status,
                    ( SELECT Product__R.Name, Quantity__c, Purchase_Order_Line__r.AcctSeedERP__Purchase_Order__r.Estimated_Time_of_Arrival_ETA__c
                      FROM Case_Parts__r)
                    FROM Case
                    WHERE ERP_Order__c = :recordId
                    AND IsClosed = false ];
    if( cases.size() > 0 )
    {
      CaseWrapper[] cwrappers = new List<CaseWrapper>();
      for( Case c : cases )
      {
        cwrappers.add( new CaseWrapper(c) );
      }
      result.put('cases', JSON.serialize( cwrappers ) );
    }

    return JSON.serialize(result);
  }

  @AuraEnabled
  public static String getMaterials( String erpId )
  {
    Set<String> ingnoreFamilies = new Set<String>{
      'Labour',
      'Premium Package',
      'Service Package',
      'Discount'
    };
    PartWrapper[] parts = new List<PartWrapper>();
    for( AcctSeedERP__Material__c mat : [SELECT Id,
                                                AcctSeedERP__Product__c,
                                                AcctSeedERP__Product__r.Name,
                                                AcctSeedERP__Quantity_Per_Unit__c,
                                                AcctSeedERP__Quantity_Allocated__c,
                                                AcctSeedERP__Project_Task__r.Name
                                         FROM AcctSeedERP__Material__c
                                         WHERE AcctSeedERP__Project__c = :erpId
                                         AND AcctSeedERP__Product__r.RecordTYpeId = :LGND_Constants.productRtId_Part
                                         AND AcctSeedERP__Product__r.Family NOT IN :ingnoreFamilies] )
    {
      parts.add( new PartWrapper( mat ) );
    }
    parts.sort();
    return JSON.serialize( parts );
  }

  @AuraEnabled
  public static String createPartsRequestCase( String casePartsJSON,
                                               String erpId,
                                               String notes)
  {
    Case_Part__c[] caseParts = (List<Case_Part__c>)JSON.deserialize( casePartsJSON, List<Case_Part__c>.class );
    AcctSeed__Project__c erp = [SELECT Id, AcctSeed__Account__c, RecordType.Name FROM AcctSeed__Project__c WHERE Id = :erpId];
    Id caseRtId = LGND_Utilities.recordTypeIdFromName('Case', 'Part Order Request');
    Case c = new Case(
      ERP_Order__c = erpId,
      AccountId = erp.AcctSeed__Account__c,
      RecordTypeId = caseRtId,
      Origin = erp.RecordType.Name,
      Parts_Request_Notes__c = notes
    );
    insert c;
    for( Case_Part__c cp : caseParts )
    {
      cp.Case__c = c.Id;
    }
    insert caseParts;
    c = [SELECT Id, CaseNumber FROM Case WHERE Id = :c.Id];
    return c.CaseNumber;
    //return 'test';
  }

}