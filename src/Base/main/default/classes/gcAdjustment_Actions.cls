public with sharing class gcAdjustment_Actions {
  public gcAdjustment_Actions() {
  }

  public gcAdjustment_Actions(ApexPages.StandardController stc) {
    idFilter = stc.getId();
    retUrl = '/' + stc.getId();
  }

  public gcAdjustment_Actions(ApexPages.StandardSetController ssc) {
    retUrl = ApexPages.currentPage().getParameters().get('retUrl');
  }

  public pageReference back() {
    return new pageReference(retUrl);
  }

  public pageReference init() {
    idFilter = ApexPages.currentPage().getParameters().get('idFilter');

    if (idFilter == null) {
      ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'No Adjustment has been selected.'));
      return null;
    }

    if (retUrl == null && idFilter != null)
      retUrl = '/' + idFilter;

    return createBlankAdjustment();
  }

  private Id idFilter { get; set; }
  private String retUrl { get; set; }

  public pageReference createBlankAdjustment() {
    for (GMBLASERP__Inventory_Adjustment__c adjustment : [
      SELECT
        Id,
        GMBLASERP__Adjustment_Type__c,
        GMBLASERP__Product__c,
        GMBLASERP__Product__r.AcctSeed__Inventory_Product__c,
        (SELECT Id FROM GMBLASERP__Inbound_Inventory_Movements__r LIMIT 1)
      FROM GMBLASERP__Inventory_Adjustment__c
      WHERE Id = :idFilter
    ]) {
      if (!adjustment.GMBLASERP__Inbound_Inventory_Movements__r.isEmpty()) {
        ApexPages.addMessage(
          new ApexPages.message(ApexPages.Severity.ERROR, 'Adjustment has already started. Cannot create blank line.')
        );
        return null;
      }
      if (adjustment.GMBLASERP__Adjustment_Type__c != 'Quantity') {
        ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'Adjustment type must be Quantity.'));
        return null;
      }
      if (adjustment.GMBLASERP__Product__c == null) {
        ApexPages.addMessage(
          new ApexPages.message(
            ApexPages.Severity.ERROR,
            'A product must be defined in Adjustment to create a blank adjustment.'
          )
        );
        return null;
      }
      if (!adjustment.GMBLASERP__Product__r.AcctSeed__Inventory_Product__c) {
        ApexPages.addMessage(
          new ApexPages.message(
            ApexPages.Severity.ERROR,
            'The product must be an inventory product to create a blank adjustment.'
          )
        );
        return null;
      }

      GMBLASERP.gcInventoryAdjustment_Ext.createAdjustment(adjustment.Id, adjustment.GMBLASERP__Product__c);
      return new pageReference(retUrl);
    }
    ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'Adjustment was not found.'));
    return null;
  }
}
