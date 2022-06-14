public class TA_SalesOrderLine_TaxSetup_BI_BU implements  TriggerAction.BeforeInsert,TriggerAction.BeforeUpdate{
	public void beforeInsert( List<AcctSeedERP__Sales_Order_Line__c> newList)
    { 
        SalesOrderLine_Service.setTaxes(newList);
    }
    public void beforeUpdate(List<AcctSeedERP__Sales_Order_Line__c> newList, List<AcctSeedERP__Sales_Order_Line__c> oldList) {
        SalesOrderLine_Service.setTaxes(newList);
  }
}