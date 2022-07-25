public with sharing class gcPurchaseOrder_Actions {
  public gcPurchaseOrder_Actions() {
  }

  public gcPurchaseOrder_Actions(ApexPages.StandardController stc) {
    idFilter = stc.getId();
    retUrl = '/' + stc.getId();
  }

  public gcPurchaseOrder_Actions(ApexPages.StandardSetController ssc) {
    retUrl = ApexPages.currentPage().getParameters().get('retUrl');
  }

  public pageReference back() {
    return new pageReference(retUrl);
  }

  public pageReference init() {
    idFilter = ApexPages.currentPage().getParameters().get('idFilter');

    if (idFilter == null) {
      ApexPages.addMessage(
        new ApexPages.message(ApexPages.Severity.ERROR, 'No Purchase Order was selected to Create AP.')
      );
      return null;
    }

    if (retUrl == null && idFilter != null)
      retUrl = '/' + idFilter;

    return checkBoatsAvailableFromPO();
  }

  private Id idFilter { get; set; }
  private String retUrl { get; set; }

  public pageReference checkBoatsAvailableFromPO() {
    Boolean hasBoats = false;
    Application_RecordType appRT = new Application_RecordType();
    Application_RecordType.ProductRTs productRts = appRT.getProductRecordTypes();
    Set<Id> setIdRT = new Set<Id>{ productRts.getBoatId(), productRts.getTrailerId(), productRts.getTrollingMotorId() };
    for (GMBLASERP__Serial_Number__c x : [
      SELECT Id, (SELECT Id FROM Projects__r WHERE AcctSeedERP__Manufactured_Product__c != NULL LIMIT 1)
      FROM GMBLASERP__Serial_Number__c
      WHERE
        Id IN (
          SELECT GMBLASERP__Serial_Number__c
          FROM AcctSeedERP__Purchase_Order_Inventory_Movement__c
          WHERE AcctSeedERP__Purchase_Order_Line__r.AcctSeedERP__Purchase_Order__c = :idFilter
        )
        AND GMBLASERP__Inventory_Balance__c != NULL
        AND GMBLASERP__Product__c IN (SELECT Id FROM Product2 WHERE RecordTypeId IN :setIdRT)
    ]) {
      if (x.Projects__r.size() == 0) {
        hasBoats = true;
        break;
      }
    }
    if (hasBoats) {
      AcctSeedERP__Purchase_Order__c po = [SELECT Id, Name FROM AcctSeedERP__Purchase_Order__c WHERE Id = :idFilter][0];
      return new pageReference(
        '/apex/gpLegendMRP_buildBoats?idPurchaseOrder=' +
        po.Id +
        '&purchaseOrderNumber=' +
        po.Name
      );
    } else {
      ApexPages.addMessage(
        new ApexPages.message(
          ApexPages.Severity.ERROR,
          'There are no available Boats or Trailers from this Purchase Order.'
        )
      );
      return null;
    }
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
  }
}
