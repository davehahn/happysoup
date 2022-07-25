/**
 * Created by dave on 2021-03-10.
 */

public virtual class PurchaseOrderLine_Selector extends Application_Selector {
  private final List<String> defaultFields = new List<String>{
    'Id',
    'AcctSeedERP__Product__c',
    'AcctSeedERP__Product__r.RecordTypeId',
    'AcctSeedERP__Product__r.Pre_Rig_Work_Type__c',
    'AcctSeedERP__Project__c',
    'AcctSeedERP__Project__r.RecordTypeId',
    'deliverDate__c'
  };

  public PurchaseOrderLine_Selector() {
    this.sObjectName = 'AcctSeedERP__Purchase_Order_Line__c';
    this.fields = defaultFields;
  }

  public static List<AcctSeedERP__Purchase_Order_Line__c> allWithPartnerErps_LinkedToRetail(Set<Id> polIds) {
    Id partnerErpRtId = new Application_RecordType().getERPOrderRecordTypes().getPartnerBoatSaleId();
    List<String> additionalFields = new List<String>{ 'AcctSeedERP__Project__r.Retail_Erp__c' };
    return new PurchaseOrderLine_Selector()
      .addFields(additionalFields)
      .addWhereIdIn(polIds)
      .addWhere('AcctSeedERP__Project__r.RecordTypeId =\'' + partnerErpRtId + '\'')
      .addWhere('AcctSeedERP__Project__r.Retail_ERP__c <> null')
      .query();
  }

  public static List<AcctSeedERP__Purchase_Order_Line__c> allByProjectId(Set<Id> erpIds) {
    return new PurchaseOrderLine_Selector().addWhereIdInField(erpIds, 'AcctSeedERP__Project__c').query();
  }
}
