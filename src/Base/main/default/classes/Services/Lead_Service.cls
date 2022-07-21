/**
 * Created by dave on 2021-04-21.
 */

public inherited sharing class Lead_Service {
  public static String NEW_STATUS = 'New';
  public static String ACCEPTED_STATUS = 'Accepted';
  public static List<Lead_Source_Assignment__mdt> leadSourceAssignments {
    get {
      if (leadSourceAssignments == null) {
        leadSourceAssignments = Lead_Source_Assignment__mdt.getAll().values();
      }
      return leadSourceAssignments;
    }
    set;
  }

  public static Map<String, String> factoryAccountIdByLeadSource {
    get {
      if (factoryAccountIdByLeadSource == null) {
        factoryAccountIdByLeadSource = new Map<String, String>();
        Legend_Settings__c settings = Legend_Settings__c.getOrgDefaults();
        for (Lead_Source_Assignment__mdt assignment : leadSourceAssignments) {
          factoryAccountIdByLeadSource.put(
            assignment.Lead_Source__c,
            String.valueOf(settings.get(assignment.Custom_Settings_Name__c))
          );
        }
      }
      return factoryAccountIdByLeadSource;
    }
    set;
  }

  public class LeadSaveResult {
    public Boolean isSuccess;
    public Lead record;
    public List<String> errorMessages;

    public LeadSaveResult() {
      this.isSuccess = false;
      this.errorMessages = new List<String>();
    }

    public Lead getRecord() {
      return this.record;
    }

    public Boolean isSuccess() {
      return this.isSuccess;
    }

    public List<String> getErrors() {
      return this.errorMessages;
    }

    public void addError(String errorMessage) {
      this.errorMessages.add(errorMessage);
    }
  }

  public Lead theLead;
  public List<SObjectField> leadFields {
    get {
      if (leadFields == null) {
        leadFields = Schema.getGlobalDescribe().get('Lead').getDescribe().fields.getMap().values();
      }
      return leadFields;
    }
    set;
  }

  public Lead_Service(Lead l) {
    this.theLead = l;
  }

  public LeadSaveResult insertOrUpdateDuplicate() {
    Database.DMLOptions dml = new Database.DMLOptions();
    dml.optAllOrNone = false;
    return handleSaveResult(Database.insert(this.theLead, dml));
  }

  private LeadSaveResult handleSaveResult(Database.SaveResult sr) {
    if (sr.isSuccess()) {
      return handleSuccess(sr.getId());
    }
    return handleError(sr);
  }

  private LeadSaveResult handleSuccess(Id leadId) {
    LeadSaveResult result = new LeadSaveResult();
    result.isSuccess = true;
    result.record = Lead_Selector.allByIds(new Set<Id>{ leadId })[0];
    return result;
  }

  private LeadSaveResult handleError(Database.SaveResult sr) {
    LeadSaveResult result = new LeadSaveResult();
    List<SObject> dups = new List<SObject>();
    List<Database.Error> errors = sr.getErrors();
    for (Database.Error error : errors) {
      if (error instanceof Database.DuplicateError) {
        /* The Error */
        Database.DuplicateError duplicateError = (Database.DuplicateError) error;
        Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();

        /* Matched Records */
        Datacloud.MatchResult[] matchResults = duplicateResult.getMatchResults();
        Datacloud.MatchResult matchResult = matchResults[0];
        Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();
        for (Datacloud.MatchRecord matchRecord : matchRecords) {
          dups.add(matchRecord.getRecord());
        }
      } else {
        result.addError(error.getMessage());
      }
    }
    if (dups.size() == 0) {
      return result;
    }
    return mergeDuplicates(dups);
  }

  private LeadSaveResult mergeDuplicates(List<SObject> dups) {
    Map<String, Object> mergeResult = mergeExistingDups((List<Lead>) dups);
    Lead originalLead = (Lead) mergeResult.get('mergedLead');
    List<Lead> deleteLeads = (List<Lead>) mergeResult.get('deleteLeads');
    System.Savepoint savePoint = Database.setSavePoint();
    try {
      originalLead = mergeLeads(originalLead, this.theLead);
      update originalLead;
      delete deleteLeads;
      return handleSuccess(originalLead.Id);
    } catch (Exception e) {
      Database.rollBack(savePoint);
      LeadSaveResult result = new LeadSaveResult();
      result.addError(e.getMessage());
      result.record = originalLead;
      return result;
    }
  }

  private Map<String, Object> mergeExistingDups(List<Lead> dupLeads) {
    Map<String, Object> result = new Map<String, Object>();
    List<Lead> deleteLeads = new List<Lead>();
    if (dupLeads.size() == 1) {
      result.put('mergedLead', dupLeads[0]);
      result.put('deleteLeads', deleteLeads);
      return result;
    }
    /* first we sort the Leads oldest to newest but for what ever reason
       Duplicate matched records do not return the CreatedDate so we need
       to re-query all the duplicate records
    */
    String idsString = '';
    for (Lead l : dupLeads) {
      idsString += '\'' + l.Id + '\', ';
    }
    idsString = idsString.removeEnd(', ');
    String query = 'SELECT ';
    for (SObjectField field : leadFields) {
      query += field.getDescribe().getName() + ', ';
    }
    query = query.removeEnd(', ');
    query += ' FROM Lead WHERE Id IN (' + idsString + ')';
    query += ' ORDER BY CreatedDate ASC';
    dupLeads = Database.query(query);

    //The fist is the Oldest and then we merge each of the newer Leads into it
    Lead oldestLead = dupLeads[0];
    for (Integer i = 1; i < dupLeads.size(); i++) {
      oldestLead = mergeLeads(oldestLead, dupLeads[i]);
      deleteLeads.add(dupLeads[i]);
    }
    result.put('mergedLead', oldestLead);
    result.put('deleteLeads', deleteLeads);
    return result;
  }

  public Lead mergeLeads(Lead originalLead, Lead newLead) {
    for (SObjectField field : leadFields) {
      if (newLead.get(field) != null && field.getDescribe().isUpdateable()) {
        originalLead.put(field, newLead.get(field));
      }
    }
    return originalLead;
  }

  public static Boolean setClosestPartnerByLeadSource(Lead l) {
    if (factoryAccountIdByLeadSource.containsKey(l.LeadSource)) {
      l.Closest_Partner__c = factoryAccountIdByLeadSource.get(l.LeadSource);
      return true;
    }
    return false;
  }
}
