/**
 * Created by dave on 2022-03-03.
 */

public inherited sharing class TA_ProductConsumed_Validate implements TriggerAction.BeforeInsert {
  public void beforeInsert(List<ProductConsumed> newList) {
    ProductConsumed_CreationControl.creationControl(newList);
  }
}
