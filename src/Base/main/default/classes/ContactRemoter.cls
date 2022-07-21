global with sharing class ContactRemoter {
  global ContactRemoter(ApexPages.StandardController stdController) {
  }

  @RemoteAction
  global static List<Contact> findContacts(String queryString, String jsonContactIdList) {
    List<Id> omit = (List<Id>) JSON.deserialize(jsonContactIdList, List<Id>.class);
    String s = '%' + queryString + '%';
    return [SELECT Id, Name FROM Contact WHERE Id NOT IN :omit AND (FirstName LIKE :s OR LastName LIKE :s)];
  }
}
