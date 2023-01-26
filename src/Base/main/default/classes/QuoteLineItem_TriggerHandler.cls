public with sharing class QuoteLineItem_TriggerHandler {
  public static void doHandle(
    Map<Id, QuoteLineItem> oldMap,
    Map<Id, QuoteLineItem> newMap,
    List<QuoteLineItem> listNew,
    Boolean boolIsBefore,
    Boolean boolIsInsert,
    Boolean boolIsUpdate,
    Boolean boolIsDelete
  ) {
    if (oldMap == null)
      oldMap = new Map<Id, QuoteLineItem>();
    if (newMap == null)
      newMap = new Map<Id, QuoteLineItem>();
    if (listNew == null)
      listNew = new List<QuoteLineItem>();

    //Things to do BEFORE
    if (boolIsBefore) {
      if (boolIsInsert) {
        setFlags(listNew);
        calcTotalAmount(listNew);
      }
      if (boolIsUpdate) {
        calcTotalAmount(listNew);
      }
      if (boolIsDelete) {
      }
    } else // well.. if it is not before it has to be AFTER
    {
      if (boolIsInsert) {
      }
      if (boolIsUpdate) {
      }
      if (boolIsDelete) {
      }
    }
  }

  private static void setFlags(List<QuoteLineItem> listNew) {
    Set<Id> pbeIds = new Set<Id>();
    for (QuoteLineItem qli : listNew) {
      pbeIds.add(qli.PricebookEntryId);
    }
    Map<Id, PricebookEntry> pbEntries = new Map<Id, PricebookEntry>(
      [
        SELECT Id, Product2.RecordType.Name, Product2.Family, Product2.Taxable__c
        FROM PricebookEntry
        WHERE Id IN :pbeIds
      ]
    );
    for (QuoteLineItem qli : listNew) {
      PricebookEntry pb = pbEntries.get(qli.PricebookEntryId);
      qli.Taxable_Federal__c = pb.Product2.Taxable__c;
      qli.Taxable_Provincial__c = pb.Product2.Taxable__c;
      if (pb.Product2.RecordType.Name == 'Insurance') {
        qli.Taxable_Federal__c = false;
        qli.Taxable_Provincial__c = false;
        qli.Taxable_Retail__c = true;
        qli.isInsurance__c = true;
      }
      if (pb.Product2.Family == 'Discount')
        qli.isDiscount__c = true;
    }
  }

  private static void calcTotalAmount(List<QuoteLineItem> listNew) {
    for (QuoteLineItem qli : listNew) {
      qli.Total_Amount__c = qli.Quantity * qli.UnitPrice;
    }
  }
}
