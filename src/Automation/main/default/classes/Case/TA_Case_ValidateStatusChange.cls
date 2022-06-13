/**
 * Created by dave on 2022-01-04.
 */

public without sharing class TA_Case_ValidateStatusChange implements TriggerAction.BeforeUpdate {
  public void beforeUpdate(List<Case> newList, List<Case> oldList) {
    Map<Id, Case> oldMap = new Map<Id, Case>(oldList);
    for (Case newRecord : newList) {
      Case oldRecord = oldmap.get(newRecord.Id);
      if (preventChangeIfPartsOrderExists(newRecord, oldRecord))
        continue;
      if (preventWarrantyApprovalIfOwnerByQueue(newRecord, oldRecord))
        continue;
      //      if( c.Can_Add_Parts__c &&
      //        !oldMap.get(c.Id).Can_Add_Parts__c &&
      //        c.Parts_Order_ERP__c != null )
      //      {
      //        c.Status.addError('This case has a related parts order. Please remove the parts order first to change status.');
      //      }
    }
  }

  private Boolean preventChangeIfPartsOrderExists(Case newRecord, Case oldRecord) {
    if (newRecord.Can_Add_Parts__c && !oldRecord.Can_Add_Parts__c && newRecord.Parts_Order_ERP__c != null) {
      newRecord.Status.addError(
        'This case has a related parts order. Please remove the parts order first to change status.'
      );
      return true;
    }
    return false;
  }

  private Boolean preventWarrantyApprovalIfOwnerByQueue(Case newRecord, Case oldRecord) {
    Id warrantyRtId = Application_RecordType.getInstance().getCaseRecordTypes().getWarrantyId();
    String ownerType = LGND_Utilities.sObjectNameFromId(newRecord.OwnerId);
    if (
      newRecord.recordTypeId == warrantyRtId &&
      newRecord.Status != oldRecord.Status &&
      newRecord.Status != 'New' &&
      ownerType != 'User'
    ) {
      newRecord.Status.addError('Status change is not allowed until the Case is Owned by a Person');
      return true;
    }
    return false;
  }
}
