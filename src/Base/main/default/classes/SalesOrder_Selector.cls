public inherited sharing class SalesOrder_Selector extends Application_Selector {
    private final List<String> defaultFields = new List<String>{
        'Id',
        'GL_Account_Variable_3__c',
        'Tax_is_Harmonized__c',
        'Tax_Rate_Federal__c',
        'Tax_Rate_Provincial__c',
        'Tax_Rate_Retail__c',
        'Revenue__c',
        'Expense__c',
        'Profit__c'
    };
        
    public SalesOrder_Selector(){
        this.sObjectName = 'AcctSeedERP__Sales_Order__c';
        this.fields = defaultFields;
    }  
    
 public static List<AcctSeedERP__Sales_Order__c> allBySalesOrderIdIncludingLineItems(set<Id> salesOrder_Set)
  {
    SalesOrderLine_Selector solSelector = new SalesOrderLine_Selector();
    return new SalesOrder_Selector()
       .addWhere('Id IN ' + salesOrder_Set )
       .addWhere('AcctSeed__Status__c != \'Posted\'')
       .addChildQuery( solSelector )
       .query();
  }    

}