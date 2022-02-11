/**
 * Created by dave on 2021-07-27.
 */

public inherited sharing class TA_POL_UpdateProductLotReservation implements TriggerAction.AfterUpdate {
  public void afterUpdate(
    List<AcctSeedERP__Purchase_Order_Line__c> newList,
    List<AcctSeedERP__Purchase_Order_Line__c> oldList
  ) {
    Map<Id, AcctSeedERP__Purchase_Order_Line__c> oldMap = new Map<Id, AcctSeedERP__Purchase_Order_Line__c>(oldList);

    Map<String, Integer> pl_q_map = new Map<String, Integer>();
    Set<Id> prodIds = new Set<Id>();

    for (AcctSeedERP__Purchase_Order_Line__c pol : newList) {
      /*
       map to hold product-lot ids together with the value to change the
       productlotReservation reservedForRetail field by
     */
      AcctSeedERP__Purchase_Order_Line__c oldPol = oldMap.get(pol.Id);
      String idString;
      if (
        pol.AcctSeedERP__Product__c != null &&
        (pol.Reserved__c < oldPol.Reserved__c || oldPol.Reserved__c == null && pol.Reserved__c != null)
      ) {
        prodIds.add(pol.AcctSeedERP__Product__c);
        idString = pol.AcctSeedERP__Product__c;

        if (pol.GMBLASERP__Lot__c != null) {
          idString += ('-' + pol.GMBLASERP__Lot__c);
        }
        pl_q_map.put(
          idString,
          Integer.valueOf((oldPol.Reserved__c == null ? 0 : oldPol.Reserved__c) - pol.Reserved__c)
        );
      }
    }

    if (pl_q_map.size() > 0) {
      updateProductLotReservation(pl_q_map, prodIds);
    }
  }

  private static void updateProductLotReservation(Map<String, Integer> pl_q_map, Set<Id> prodIds) {
    List<ProductLotReservation__c> plrs = [
      SELECT Id, Product__c, Lot__c, Reserved_For_Retail_Sale__c
      FROM ProductLotReservation__c
      WHERE Product__c IN :prodIds
    ];
    for (ProductLotReservation__c plr : plrs) {
      String idString = plr.Product__c;
      if (plr.Lot__c != null)
        idString += ('-' + plr.Lot__c);
      if (pl_q_map.containsKey(idString)) {
        if (plr.Reserved_For_Retail_Sale__c == null)
          plr.Reserved_For_Retail_Sale__c = 0;
        plr.Reserved_For_Retail_Sale__c += pl_q_map.get(idString);
      }
    }
    update plrs;
  }
}
