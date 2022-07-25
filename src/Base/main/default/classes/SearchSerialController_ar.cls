public class SearchSerialController_ar {
  @AuraEnabled
  public static List<Map<String, String>> searchSerials(String searchString) {
    String searchStringMod = '%' + searchString + '%';
    List<Map<String, String>> listJSON = new List<Map<String, String>>();
    for (GMBLASERP__Serial_Number__c serial : [
      SELECT
        Id,
        Name,
        GMBLASERP__Inventory_Balance__c,
        GMBLASERP__Lot__c,
        GMBLASERP__Lot__r.Name,
        GMBLASERP__Product__c,
        GMBLASERP__Product__r.Name,
        GMBLASERP__Product__r.RecordType.Name,
        GMBLASERP__Product__r.ProductCode
      FROM GMBLASERP__Serial_Number__c
      WHERE Name = :searchString OR Name LIKE :searchStringMod
      ORDER BY CreatedDate DESC
      LIMIT 10
    ]) {
      Map<String, String> m = new Map<String, String>();
      m.put('idSerial', serial.Id);
      m.put('serialName', serial.Name);
      m.put('lotName', serial.GMBLASERP__Lot__r.Name);
      m.put('productName', serial.GMBLASERP__Product__r.Name);
      m.put('productCode', serial.GMBLASERP__Product__r.ProductCode);
      m.put('productType', serial.GMBLASERP__Product__r.RecordType.Name);
      listJSON.add(m);
    }
    return listJSON;
  }
}
