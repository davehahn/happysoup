/**
 * Created by dave on 2020-01-21.
 */
@IsTest
public class Factory_TradeIn {
  public static Trade_In_Record__c insertTradeInRecordWithItems(Id oppId, Integer itemCount) {
    Trade_In_Record__c record = new Trade_In_Record__c(
      Opportunity__c = oppId,
      Lien_Amount__c = 5000,
      Total_Value__c = 10000,
      isSyncing__c = true
    );
    insert record;
    List<Trade_In_Item__c> items = new List<Trade_In_Item__c>();
    for (Integer i = 0; i < itemCount; i++) {
      items.add(
        new Trade_In_Item__c(
          Make__c = 'Test Make',
          Model__c = 'Test Model',
          Trade_In_Record__c = record.Id,
          Serial_Number__c = 'testserial' + String.valueOf(i)
        )
      );
    }
    insert items;
    return record;
  }
}
