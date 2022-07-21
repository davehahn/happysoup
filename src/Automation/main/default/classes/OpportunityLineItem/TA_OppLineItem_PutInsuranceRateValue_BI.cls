/**
 * Created by dhavalmacbook on 27/01/22.
 */

public without sharing class TA_OppLineItem_PutInsuranceRateValue_BI implements TriggerAction.BeforeInsert {
  public void beforeInsert(List<OpportunityLineItem> newList) {
    OpportunityLineItem_Service.putInsuranceRateValueOnLineItem(newList);
  }
}
