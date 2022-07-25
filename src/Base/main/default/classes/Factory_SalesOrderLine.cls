/**
 * Created by Legend on 16/5/22.
 */
@isTest
public class Factory_SalesOrderLine {
  public static AcctSeedERP__Sales_Order_Line__c buildSOL(Id soId, Id prodId) {
    return new AcctSeedERP__Sales_Order_Line__c(
      AcctSeedERP__Product__c = prodId,
      AcctSeedERP__Unit_Price__c = 100,
      AcctSeedERP__Quantity_Ordered__c = 1,
      AcctSeedERP__Sales_Order__c = soId
    );
  }
}
