/**
 * Created by dave on 2022-06-06.
 */

public without sharing class TA_Project_R_B_SaleSetCompletedDate implements TriggerAction.BeforeUpdate {
  private final static Map<String, Integer> retailBoatSalesStageValueMap = new Map<String, Integer>{
    'Tagging Pending' => 1,
    'Pending Work Order' => 2,
    'Pending Pick and Pack' => 3,
    'Pending Rigging' => 4,
    'Pending Final Rigging' => 5,
    'Pending Inspection' => 6,
    'Pending Pickup' => 7,
    'Delivered' => 8,
    'Closed Lost' => 9
  };

  private final Id retailBoatSaleRecordTypeId = Application_RecordType.getInstance()
    .getERPOrderRecordTypes()
    .getRetailBoatSaleId();
  private final static Integer STAGE_VALUE_TARGET = 5;

  public static String getTriggeringStageName() {
    for (String stageName : retailBoatSalesStageValueMap.keySet()) {
      if (retailBoatSalesStageValueMap.get(stageName) == STAGE_VALUE_TARGET) {
        return stageName;
      }
    }
    return '';
  }

  public static String getBeforeTriggeringState() {
    for (String stageName : retailBoatSalesStageValueMap.keySet()) {
      if (retailBoatSalesStageValueMap.get(stageName) == (STAGE_VALUE_TARGET - 1)) {
        return stageName;
      }
    }
    return '';
  }

  public static String getAfterTriggeringState() {
    for (String stageName : retailBoatSalesStageValueMap.keySet()) {
      if (retailBoatSalesStageValueMap.get(stageName) == (STAGE_VALUE_TARGET + 1)) {
        return stageName;
      }
    }
    return '';
  }

  public void beforeUpdate(List<AcctSeed__Project__c> newList, List<AcctSeed__Project__c> oldList) {
    Map<Id, AcctSeed__Project__c> oldMap = new Map<Id, AcctSeed__Project__c>(oldList);
    for (AcctSeed__Project__c erp : newList) {
      if (erp.RecordTypeId == retailBoatSaleRecordTypeId) {
        Integer oldStageValue = oldMap.get(erp.Id).Stage__c == null
          ? 1
          : retailBoatSalesStageValueMap.get(oldMap.get(erp.Id).Stage__c);
        Integer newStageValue = retailBoatSalesStageValueMap.get(erp.Stage__c);
        System.debug('oldStage Value ' + oldStageValue);
        System.debug('newStageValue ' + newStageValue);
        if (oldStageValue == newStageValue)
          continue;
        System.debug('continue');
        if (oldStageValue < STAGE_VALUE_TARGET && newStageValue >= STAGE_VALUE_TARGET) {
          erp.Completed_Date__c = Datetime.now();
        }
        if (oldStageValue >= STAGE_VALUE_TARGET && newStageValue < STAGE_VALUE_TARGET) {
          erp.Completed_Date__c = null;
        }
      }
    }
  }
}
