public with sharing class LeadSourceSelectorController_mp {
  @AuraEnabled
  public static List<String> getLeadSources() {
    return LGND_Utilities.getPicklistValues('Lead', 'LeadSource');
  }
}
