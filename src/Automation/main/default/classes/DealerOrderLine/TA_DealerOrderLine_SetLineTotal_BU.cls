public inherited sharing class TA_DealerOrderLine_SetLineTotal_BU implements TriggerAction.BeforeUpdate{

  public void beforeUpdate(List<SObject> newList, List<SObject> oldList) {
        DealerOrderLine_Service.setLineTotal(newList);
    }
}