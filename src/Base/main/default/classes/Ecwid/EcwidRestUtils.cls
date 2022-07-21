global without sharing class EcwidRestUtils {
  public final String WAREHOUSE = 'Wholesale';
  public final String GLV1 = 'Wholesale';
  public final String GLV2 = 'Sales';

  public static Ecwid_API_Setting__mdt setting;
  public static Map<String, EcwidAPI__mdt> ApiSettingMap;
  public static Map<String, List<Ecwid_Query_Field_Mapping__mdt>> dynamicQueryFieldMap;
  public static Map<String, List<Ecwid_Field_Mapping__mdt>> dynamicFielddMap;
  public static map<String, String> dynamicQueryMap = new Map<String, String>();
  public static String storeId;
  public static String wareHouseId;
  public static String glv1Id;
  public static String glv2Id;

  public static boolean verifySignature(String signatureFromEcwid, EcwidRestCommon.RequestPayloadBody requestBody) {
    System.debug('signatureFromEcwid= ' + signatureFromEcwid);
    if (signatureFromEcwid != null)
      return signatureFromEcwid.equals(generateSignature(requestBody));

    return false;
  }
  public static void init() {
    setting = getDataFromSetting();
    getEcwidApiConfiguration();
    getEwidDynamicQuery();
    getGLV1AndGLV2Values();
    getWarehouse();
  }
  private static void getWarehouse() {
    List<AcctSeedERP__Warehouse__c> warehouse = [
      SELECT id
      FROM AcctSeedERP__Warehouse__c
      WHERE Name = :setting.GLV1__c
    ];
    if (!warehouse.isEmpty()) {
      wareHouseId = String.valueOf(warehouse[0].Id);
    }
  }
  private static void getGLV1AndGLV2Values() {
    List<AcctSeed__Accounting_Variable__c> acVariable_list = [
      SELECT Id, Name, AcctSeed__Type__c
      FROM AcctSeed__Accounting_Variable__c
      WHERE
        (Name = :setting.GLV1__c
        AND AcctSeed__Type__c = 'GL Account Variable 1')
        OR (Name = :setting.GLV2__c
        AND AcctSeed__Type__c = 'GL Account Variable 2')
    ];
    for (AcctSeed__Accounting_Variable__c acc : acVariable_list) {
      if (acc.AcctSeed__Type__c == 'GL Account Variable 1') {
        glv1Id = acc.id;
      } else if (acc.AcctSeed__Type__c == 'GL Account Variable 2') {
        glv2Id = acc.id;
      }
    }
  }
  private static String generateSignature(EcwidRestCommon.RequestPayloadBody requestBody) {
    setting = getDataFromSetting();
    getEcwidApiConfiguration();
    getEwidDynamicQuery();
    String keyData = requestBody.eventCreated + '.' + requestBody.eventId;
    Blob data = crypto.generateMac('HmacSHA256', Blob.valueOf(keyData), Blob.valueOf(setting.Verification_Key__c));
    return EncodingUtil.base64Encode(data);
  }

  public static Ecwid_API_Setting__mdt getDataFromSetting() {
    setting = [
      SELECT
        Public_Key__c,
        Secret_Key__c,
        Base_URL__c,
        Store_Id__c,
        Verification_Key__c,
        Freight_Purolator_SKU__c,
        GLV1__c,
        GLV2__c
      FROM Ecwid_API_Setting__mdt
      WHERE Store_Id__c = :storeId
    ];

    return setting;
  }
  private static void getEcwidApiConfiguration() {
    ApiSettingMap = new Map<String, EcwidAPI__mdt>();
    List<EcwidAPI__mdt> ecwidAPISettingList = [
      SELECT Method__c, Require_Public_Key__c, Require_Secret_Key__c, URL__c, DeveloperName
      FROM EcwidAPI__mdt
      WHERE Ecwid_API_Setting__c = :setting.Id
    ];

    for (EcwidAPI__mdt api : ecwidAPISettingList) {
      ApiSettingMap.put(api.DeveloperName, api);
    }
  }

  public static void getEwidDynamicQuery() {
    dynamicQueryFieldMap = new Map<String, List<Ecwid_Query_Field_Mapping__mdt>>();
    dynamicFielddMap = new Map<String, List<Ecwid_Field_Mapping__mdt>>();
    List<Ecwid_Object_Mapping__mdt> ecwidDynamicQueriesList = [
      SELECT
        DeveloperName,
        MasterLabel,
        Query__c,
        (SELECT DeveloperName, Field_Name__c, MasterLabel FROM Ecwid_Query_Field_Mapping__r WHERE Is_Active__c = TRUE)
      FROM Ecwid_Object_Mapping__mdt
      WHERE Is_Active__c = TRUE
    ];
    for (Ecwid_Object_Mapping__mdt query : ecwidDynamicQueriesList) {
      List<Ecwid_Query_Field_Mapping__mdt> fieldList = new List<Ecwid_Query_Field_Mapping__mdt>();
      for (Ecwid_Query_Field_Mapping__mdt field : query.Ecwid_Query_Field_Mapping__r) {
        fieldList.add(field);
      }
      dynamicQueryMap.put(query.MasterLabel, query.Query__c);
      dynamicQueryFieldMap.put(query.MasterLabel, fieldList);
    }
  }

  public static EcwidRestCommon.RequestPayloadBody parseRequest(String requestBody) {
    return (EcwidRestCommon.RequestPayloadBody) JSON.deserialize(
      (EncodingUtil.base64Decode(requestBody).toString()),
      EcwidRestCommon.RequestPayloadBody.class
    );
  }
  public static String parseHeader(String request) {
    List<Object> result = (List<Object>) JSON.deserializeUntyped('[' + request + ']');
    for (Object obj : result) {
      Map<String, Object> mapRequestParam = (Map<String, Object>) obj;
      for (String key : mapRequestParam.keyset()) {
        if (key.equalsIgnoreCase('headers')) {
          List<Object> resultHeader = (List<Object>) JSON.deserializeUntyped(
            '[' +
            JSON.serialize(mapRequestParam.get(key)) +
            ']'
          );
          for (Object keyHeader : resultHeader) {
            Map<String, Object> mapHeaderParam = (Map<String, Object>) keyHeader;
            for (String mapHeaderkey : mapHeaderParam.keyset()) {
              if (mapHeaderkey.equals('X-Ecwid-Webhook-Signature')) {
                return (String) mapHeaderParam.get(mapHeaderkey);
              }
            }
          }
        }
      }
    }
    return null;
  }
  public static Rest_Service_Log__c ServiceLog(RestRequest request, EcwidRestCommon.RequestPayloadBody body) {
    Rest_Service_Log__c serviceLog = new Rest_Service_Log__c();
    serviceLog.Request__c = JSON.serializePretty(request);
    serviceLog.Event_Id__c = body.eventId;
    serviceLog.Event_Type__c = body.eventType;
    serviceLog.Entity_Id__c = body.entityId;
    serviceLog.recordTypeId = Schema.SObjectType.Rest_Service_Log__c.getRecordTypeInfosByDeveloperName()
      .get('Ecwid_Inbound')
      .getRecordTypeId();
    serviceLog.Store_Id__c = body.storeId;
    insert serviceLog;

    return serviceLog;
  }
  public static string getExceptionDetail(Exception ex) {
    String errorMsg = '';
    errorMsg += 'Message: ' + ex.getMessage() + '\n';
    errorMsg += 'Cause: ' + ex.getCause() + '\n';
    errorMsg += 'Line: ' + ex.getLineNumber() + '\n';
    errorMsg += 'Stack Trace: ' + ex.getStackTraceString() + '\n';
    errorMsg += 'Type: ' + ex.getTypeName() + '\n';

    return errorMsg + '\n';
  }
}
