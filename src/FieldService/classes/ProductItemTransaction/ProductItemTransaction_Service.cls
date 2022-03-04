/**
 * Created by dave on 2022-03-04.
 */
/* TODO: REQUIRES UNIT TEST */
public inherited sharing class ProductItemTransaction_Service
{
  public static void createTransactions( List<SObject> movements ){
    List<AcctSeedMovementWrapper_FSL> listWrapPOL = AcctSeedMovementWrapper_FSL.generateMovementWrapperVoid(movements);
    Inventory_Service.createPI_FSL(listWrapPOL, 'Inbound');
  }

  public static void bypassFslTransactions(){
    MetadataTriggerHandler.bypass('TA_Inbound_CreateInvTransactionsFSL');
    MetadataTriggerHandler.bypass('TA_Outbound_CreateInvTransactionsFSL');
    MetadataTriggerHandler.bypass('TA_Purchase_Order_CreateInvTransactionsFSL');
  }

  public static void clearFslTransactionsBypass(){
    MetadataTriggerHandler.clearBypass('TA_Inbound_CreateInvTransactionsFSL');
    MetadataTriggerHandler.clearBypass('TA_Outbound_CreateInvTransactionsFSL');
    MetadataTriggerHandler.clearBypass('TA_Purchase_Order_CreateInvTransactionsFSL');
  }
}