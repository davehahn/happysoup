/**
 * Created by dave on 2022-01-21.
 */

public inherited sharing class PathFromPicklist_Controller {
  @AuraEnabled
  public static Object init(String recordId, String fieldName) {
    Id rId = Id.valueOf(recordId);
    Schema.SObjectType sObjectType = rId.getSobjectType();
    Schema.SObjectField field = sObjectType.getDescribe().fields.getMap().get(fieldName);
    Schema.sObjectField controlToken = field.getDescribe().getController();
    if (controlToken == null)
      return false;
    Map<String, Object> result = new Map<String, Object>();
    result.put('controlFieldName', controlToken.getDescribe().getName());
    result.put('valueMap', LGND_Utilities.getDependentPicklistValues(field));
    return result;
  }
}
