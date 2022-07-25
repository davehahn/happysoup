/**
 * Created by dave on 2022-02-28.
 */
/*TODO: REQUIRES UNIT TEST */
public inherited sharing class TA_Project_CreateWOforPartnerBoatSale implements TriggerAction.AfterUpdate {
  public void afterUpdate(List<AcctSeed__Project__c> newList, List<AcctSeed__Project__c> oldList) {
    Id partnerBoatSaleId = new Application_RecordType().getERPOrderRecordTypes().getPartnerBoatSaleId();
    Set<Id> erpsNeedingWorkOrders = new Set<Id>();
    for (AcctSeed__Project__c erp : newList) {
      if (erp.RecordTypeId == partnerBoatSaleId && erp.Stage__c == 'Tagging Pending' && erp.Work_Order__c == null) {
        erpsNeedingWorkOrders.add(erp.Id);
      }
    }
    if (erpsNeedingWorkOrders.size() > 0)
      WorkOrder_Service.createFromPartnerBoatSaleErpIds(erpsNeedingWorkOrders);
  }
}
