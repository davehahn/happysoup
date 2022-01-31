/**
 * Created by dave on 2022-01-10.
 */

public with sharing class Promotion_Queueables {
  public class AddPromotionItems implements Queueable {
    public Map<String, String> erpToPromoMap;

    public AddPromotionItems() {
      this.erpToPromoMap = new Map<String, String>();
    }

    public AddPromotionItems(Map<String, String> erpToPromoMap) {
      this.erpToPromoMap = erpToPromoMap;
    }

    public void execute(QueueableContext context) {
      if (this.erpToPromoMap == null || this.erpToPromoMap.size() == 0)
        return;

      Map<Id, Promotion__c> promotions = new Map<Id, Promotion__c>(
        [
          SELECT Id, Name, (SELECT Id, Product__c, Quantity__c FROM Promotion_Incentive_Products__r)
          FROM Promotion__c
          WHERE Id IN :this.erpToPromoMap.values()
        ]
      );
      Map<Id, AcctSeed__Project_Task__c> erpToTaskMap = new Map<Id, AcctSeed__Project_Task__c>();
      for (String erpId : this.erpToPromoMap.keySet()) {
        String promoId = this.erpToPromoMap.get(erpId);
        if (promotions.get(promoId).Promotion_Incentive_Products__r.size() > 0) {
          erpToTaskMap.put(erpId, ProjectTask_Service.buildPromotionItemsTask(erpId));
        }
      }
      if (erpToTaskMap.values().size() > 0) {
        insert erpToTaskMap.values();
        List<AcctSeedERP__Material__c> mats = new List<AcctSeedERP__Material__c>();
        for (String erpId : this.erpToPromoMap.keySet()) {
          String promoId = this.erpToPromoMap.get(erpId);
          if (erpToTaskMap.containsKey(erpId)) {
            mats.addAll(
              Material_Service.buildFromPromotionalIncentiveProducts(
                promotions.get(promoId).Promotion_Incentive_Products__r,
                erpId,
                erpToTaskMap.get(erpId).Id,
                promotions.get(promoId).Name
              )
            );
          }
        }
        insert mats;
      }
    }
  }
}
