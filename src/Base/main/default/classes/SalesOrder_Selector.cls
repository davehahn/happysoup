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
       .addWhere('AcctSeedERP__Status__c = \'Open\'')
       .addChildQuery( solSelector )
       .query();
  }

    public static List<AcctSeedERP__Sales_Order__c> byIdsIncludingSOL( Set<Id> recordIds )
    {
        SalesOrder_Selector selector = new SalesOrder_Selector();
        selector.addWhereIdIn( recordIds )
                .addWhere('AcctSeedERP__Status__c = \'Open\'')
                .addChildQuery(
                '(SELECT Id, ' +
                        '                        AcctSeedERP__GL_Account_Variable_1__c, ' +
                        '                        AcctSeedERP__GL_Account_Variable_2__c, ' +
                        '                        AcctSeedERP__GL_Account_Variable_3__c, ' +
                        '                        AcctSeedERP__Product__c, ' +
                        '                        AcctSeedERP__Product__r.RecordType.Name, ' +
                        '                        AcctSeedERP__Total__c, ' +
                        '                        AcctSeedERP__Unit_Price__c, ' +
                        '                        Taxable_Federal__c, ' +
                        '                        Taxable_Provincial__c, ' +
                        '                        Taxable_Retail__c, ' +
                        '                        GMBLASERP__Serial_Number__c, ' +
                        '                        GMBLASERP__Revenue__c, ' +
                        '                        Review_Price__c, ' +
                        '                        AcctSeedERP__Quantity_Ordered__c ' +
                        '                    FROM AcctSeedERP__Sales_Order_Line__r ' +
                        '                    ORDER BY CreatedDate)'
        );
        List<SObject> result = selector.query();
        if( result.size() == 0 )
        {
            throw new Application_Selector.SelectorException(
                    'No SO records found with supplied Ids'
            );
        }
        else
        {
            return result;
        }
    }

}