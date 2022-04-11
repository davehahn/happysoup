/**
 * Created by dave on 2022-01-18.
 */

public without sharing class TA_CommLI2_ChatterAboutChanges implements TriggerAction.AfterInsert, TriggerAction.AfterUpdate, TriggerAction.AfterDelete {
  public void afterInsert(List<CommissionLineItem2__c> newList) {
    buildChangeMap(newList, null, 'insert');
  }
  public void afterUpdate(List<CommissionLineItem2__c> newList, List<CommissionLineItem2__c> oldList) {
    Map<Id, CommissionLineItem2__c> oldMap = new Map<Id, CommissionLineItem2__c>(oldList);
    buildChangeMap(newList, oldMap, 'update');
  }
  public void afterDelete(List<CommissionLineItem2__c> oldList) {
    buildChangeMap(oldList, null, 'delete');
  }

  @TestVisible
  private Map<Id, List<String>> buildChangeMap(
    List<CommissionLineItem2__c> newList,
    Map<Id, CommissionLineItem2__c> oldMap,
    String scope
  ) {
    Map<Id, List<String>> changeMap = new Map<Id, List<String>>();
    for (CommissionLineItem2__c cli : newList) {
      List<String> changes = new List<String>();
      switch on scope {
        when 'insert' {
          changes.add(handleInsertChanges(cli));
        }
        when 'update' {
          changes.addAll(handleUpdateChanges(cli, oldMap.get(cli.Id)));
        }
        when 'delete' {
          changes.add(handleDeleteChanges(cli));
        }
      }
      if (!changeMap.containsKey(cli.CommissionRecord2__c)) {
        changeMap.put(cli.CommissionRecord2__c, new List<String>());
      }
      changeMap.get(cli.CommissionRecord2__c).addAll(changes);
    }
    CommissionLineItem2_Service.makeChatterPostsAboutChanges( changeMap );
    CommissionRecord2_Service.openIfClosed( changeMap.keySet() );
    return changeMap;
  }

  private String handleInsertChanges(CommissionLineItem2__c newLine) {
    return String.valueOf(newLine.Quantity__c) + ' X ' + newLine.Descriptor__c + ' has been added';
  }

  private List<String> handleUpdateChanges(CommissionLineItem2__c newLine, CommissionLineItem2__c oldLine) {
    List<String> changes = new List<String>();
    if (newLine.Quantity__c != oldLine.Quantity__c) {
      changes.add(
        'Quantity of ' +
        newLine.Descriptor__c +
        ' has changed from ' +
        oldLine.Quantity__c +
        ' to ' +
        newLine.Quantity__c
      );
    }
    if (newLine.Sale_Price__c != oldLine.Sale_Price__c) {
      changes.add(
        'The Sale Price on ' +
        newLine.Descriptor__c +
        ' has changed from $' +
        oldLine.Sale_Price__c +
        ' to $' +
        newLine.Sale_Price__c
      );
    }
    return changes;
  }

  private String handleDeleteChanges(CommissionLineItem2__c oldLine) {
    return oldLine.Descriptor__c + ' has been removed';
  }
}
