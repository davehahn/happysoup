public with sharing class Partner_Customer_Trigger_Handler {
  public static void doHandle(
    Map<Id, Partner_Customer__c> oldMap,
    Map<Id, Partner_Customer__c> newMap,
    List<Partner_Customer__c> listNew,
    Boolean boolIsBefore,
    Boolean boolIsInsert,
    Boolean boolIsUpdate,
    Boolean boolIsDelete
  ) {
    if (oldMap == null)
      oldMap = new Map<Id, Partner_Customer__c>();
    if (newMap == null)
      newMap = new Map<Id, Partner_Customer__c>();
    if (listNew == null)
      listNew = new List<Partner_Customer__c>();

    if (boolIsBefore /* &&&&&&&   BEFORE    &&&&&&& */) {
      if (boolIsInsert) {
        for (Partner_Customer__c pc : listNew) {
          pc.Uniqueifier__c = pc.Partner__c + '-' + pc.Customer__c;
        }
      }
      if (boolIsUpdate) {
      }
      if (boolIsDelete) {
      }
    } else {
      /* &&&&&&&   AFTER   &&&&&&& */
      if (boolIsInsert) {
      }
      if (boolIsUpdate) {
      }
      if (boolIsDelete) {
      }
    }
  }
}
