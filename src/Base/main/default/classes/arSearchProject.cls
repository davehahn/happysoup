public class arSearchProject {
  @AuraEnabled
  public static List<Map<String, String>> searchProjects(String searchString) {
    Id idRtBoatSale = gcConstants.idRtProjectBoatSale;
    Id idRtPartnerBoatSale = gcConstants.idRtProjectPartnerBoatSale;
    Id idRtCounterSale = gcConstants.idRtProjectCounterSale;
    Id idRtService = gcConstants.idRtProjectService;
    Set<Id> setRTIds = new Set<Id>{ idRtBoatSale, idRtPartnerBoatSale, idRtCounterSale, idRtService };
    searchString = '%' + searchString + '%';
    List<Map<String, String>> listJSON = new List<Map<String, String>>();
    for (AcctSeed__Project__c project : [
      SELECT
        Id,
        Name,
        RecordType.Name,
        AcctSeed__Account__c,
        AcctSeed__Account__r.RecordType.Name,
        AcctSeed__Account__r.Name,
        AcctSeed__Account__r.FirstName,
        AcctSeed__Account__r.LastName,
        AcctSeed__Account__r.BillingStreet,
        CreatedDate
      FROM AcctSeed__Project__c
      WHERE
        RecordTypeId IN :setRTIds
        AND AcctSeed__Account__c != NULL
        AND (Name LIKE :searchString
        OR AcctSeed__Account__r.Name LIKE :searchString)
      ORDER BY CreatedDate DESC
      LIMIT 10
    ]) {
      Map<String, String> m = new Map<String, String>();
      m.put('idProject', project.Id);
      m.put('projectName', project.Name);
      m.put('projectCreated', project.CreatedDate.format());
      m.put('projectType', project.RecordType.Name);
      m.put('idAccount', project.AcctSeed__Account__c);
      m.put('accountName', project.AcctSeed__Account__r.Name);
      m.put('accountType', project.AcctSeed__Account__r.RecordType.Name);
      m.put('accountBillingStreet', project.AcctSeed__Account__r.BillingStreet);
      listJSON.add(m);
    }
    return listJSON;
  }
}
