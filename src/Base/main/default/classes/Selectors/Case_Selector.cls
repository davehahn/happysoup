/**
 * Created by dave on 2021-04-08.
 */

public virtual class Case_Selector extends Application_Selector {
  private final List<String> defaultFields = new List<String>{
    'Id',
    'AccountId',
    'Account.Name',
    'OwnerId',
    'CreatedById',
    'CreatedBy.IsActive',
    'Partner_Reference__c',
    'CaseNumber',
    'Status',
    'Erp_Order__c',
    'Parts_Order_Erp__c'
  };

  public Case_Selector() {
    this.sObjectName = 'Case';
    this.fields = defaultFields;
  }

  public static List<Case> allByIds(Set<Id> ids) {
    return new Case_Selector().addWhereIdIn(ids).query();
  }

  public static List<Case> allByErpOrderIdIncludingCasePartsWithMaterial(Id erpId, Set<Id> matIds) {
    CasePart_Selector cpSelector = new CasePart_Selector();
    cpSelector.addWhereIdInField(matIds, 'Material__c');
    return new Case_Selector().addWhere('ERP_Order__c = \'' + erpId + '\'').addChildQuery(cpSelector).query();
  }

  public static List<Case> allWithWarrantyErpById(Set<Id> ids) {
    return new Case_Selector()
      .addFields(new List<String>{ 'Warranty_Erp__c, Recoverable_Erp__c' })
      .addWhereIdIn(ids)
      .addWhere('Warranty_ERP__c <> null ', 'AND')
      .query();
  }
}
