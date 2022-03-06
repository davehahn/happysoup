/**
 * Created by dave on 2021-07-26.
 */
@IsTest
public class Factory_PurchaseOrderInventoryMovement
{

  public static AcctSeedERP__Purchase_Order_Inventory_Movement__c createMovement(
    Id purchaseOrderLineId,
    Decimal quantity,
    Id erpId,
    Id erpTaskId,
    Id balanceId,
    Decimal unitCost
  )
  {

    AcctSeedERP__Purchase_Order_Inventory_Movement__c movement = new AcctSeedERP__Purchase_Order_Inventory_Movement__c(
      AcctSeedERP__Purchase_Order_Line__c = purchaseOrderLineId,
      AcctSeedERP__Ledger__c = Test_Constants.idLedger,
      AcctSeedERP__Quantity__c = quantity,
      AcctSeedERP__Project_Task__c = erpTaskId,
      AcctSeedERP__Project__c = erpId,
      AcctSeedERP__Unit_Cost__c = unitCost,
      AcctSeedERP__Movement_Date__c = Date.today(),
      AcctSeedERP__Inventory_Balance__c = balanceId
    );
    GMBLASERP.gcPurchaseOrderInventoryMovement.disableTrigger = true;
    gcPurchaseOrderInventoryMovement.disableTrigger = true;
    insert movement;
    return movement;
  }
}