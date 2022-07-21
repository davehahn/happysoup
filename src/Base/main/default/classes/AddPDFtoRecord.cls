/* ----------------------------------------------------------------------------

  Contributors: Mario
  Last Modified By: Mario
  Created: July 30, 2018
  Last Modified: September 7, 2018

---------------------------------------------------------------------------- */

global with sharing class AddPDFtoRecord {
  global static ContentDocumentLink[] doPost(list<String> accountIdList, String documentName, String recType) {
    System.debug('++++++++++++++++ AddPDFtoRecord.doPost ++++++++++++++++');

    Map<String, ContentVersion> docAcctMap = new Map<String, ContentVersion>();
    Id rtId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get(recType).getRecordTypeId();

    for (String accId : accountIdList) {
      ContentVersion doc = new ContentVersion();
      PageReference pr = new PageReference('/apex/' + documentName + '?Account=' + accId);
      Blob body;
      if (!test.isRunningTest()) {
        body = pr.getContent();
      } else {
        body = blob.valueOf('TEST');
      }
      doc.Title = documentName + '-' + System.Today().year() + System.Today().month() + System.Today().day() + '.pdf';
      doc.VersionData = body;
      doc.PathOnClient = '/' + doc.Title;
      doc.RecordTypeId = rtId;
      doc.Visibility__c = 'Public';
      docAcctMap.put(accId, doc);
    }
    insert docAcctMap.values();

    Set<Id> docIds = new Set<Id>();
    for (ContentVersion doc : docAcctMap.values()) {
      docIds.add(doc.Id);
    }

    ContentDocumentLink[] links = new List<ContentDocumentLink>();

    Map<Id, ContentVersion> cvMap = new Map<Id, ContentVersion>();

    for (ContentVersion v : [
      SELECT Id, ContentDocumentId, ExternalDataSourceId, Title
      FROM ContentVersion
      WHERE Id IN :docIds
    ]) {
      cvMap.put(v.Id, v);
    }

    for (ContentVersion doc : docAcctMap.values()) {
      docIds.add(doc.Id);
    }

    for (Id key : docAcctMap.keySet()) {
      ContentVersion doc = docAcctMap.get(key);
      if (docAcctMap.values().size() > 0) {
        ContentDocumentLink link = new ContentDocumentLink();
        link.ContentDocumentId = cvMap.get(doc.Id).ContentDocumentId;
        link.LinkedEntityId = key;
        link.ShareType = 'V';
        link.Visibility = 'AllUsers'; //'InternalUsers'; //
        links.add(link);
      }
    }

    insert links;

    update docAcctMap.values();
    return links;
  }
}
