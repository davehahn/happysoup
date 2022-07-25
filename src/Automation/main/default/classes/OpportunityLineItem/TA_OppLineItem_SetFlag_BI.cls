/**
 * Created by dhavalmacbook on 27/01/22.
 */

public without sharing class TA_OppLineItem_SetFlag_BI implements TriggerAction.BeforeInsert {
  public void beforeInsert(List<OpportunityLineItem> newList) {
    OpportunityLineItem_Service.setFlags(newList);
  }
}
