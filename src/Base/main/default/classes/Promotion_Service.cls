/**
 * Created by dave on 2022-01-10.
 */

public inherited sharing class Promotion_Service
{
  public static void addPromotionItemsToERP( Map<String, String> promotionIdByErpId ){
    System.debug('Promotion_Service');
    System.debug(promotionIdByErpId);
    Promotion_Queueables.AddPromotionItems queue = new Promotion_Queueables.AddPromotionItems( promotionIdByErpId );
    System.enqueueJob( queue );
  }
}