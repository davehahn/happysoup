/**
 * Created by dave on 2021-07-26.
 */
@IsTest
public class Factory_InventoryBalance
{

  public static AcctSeedERP__Inventory_Balance__c createBalance(
    Id acctSeedLocationId,
    Id productId
  )
  {
    AcctSeedERP__Inventory_Balance__c balance = new AcctSeedERP__Inventory_Balance__c(
      AcctSeedERP__Ledger__c = Test_Constants.idLedger,
      AcctSeedERP__Product__c = productId,
      AcctSeedERP__Warehouse__c = Test_Constants.idWarehouse,
      AcctSeedERP__Location__c = acctSeedLocationId
    );
    insert balance;
    return balance;
  }
}