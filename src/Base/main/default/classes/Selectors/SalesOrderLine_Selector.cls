public inherited sharing class SalesOrderLine_Selector extends Application_Selector {
  private final List<String> defaultFields = new List<String>{
    'Id',
    'AcctSeedERP__GL_Account_Variable_1__c',
    'AcctSeedERP__GL_Account_Variable_2__c',
    'AcctSeedERP__GL_Account_Variable_3__c',
    'AcctSeedERP__Product__c',
    'AcctSeedERP__Product__r.RecordType.Name',
    'AcctSeedERP__Total__c',
    'AcctSeedERP__Unit_Price__c',
    'Taxable_Federal__c',
    'Taxable_Provincial__c',
    'Taxable_Retail__c',
    'GMBLASERP__Serial_Number__c',
    'GMBLASERP__Revenue__c',
    'Review_Price__c',
    'AcctSeedERP__Quantity_Ordered__c'
  };

  public SalesOrderLine_Selector() {
    this.sObjectName = 'AcctSeedERP__Sales_Order_Line__c';
    this.fields = defaultFields;
  }
}
