/**
 * Created by dave on 2021-07-15.
 */

public inherited sharing class IssueLauncher_Controller {
  @AuraEnabled(Cacheable=true)
  public static List<Issue_Type__mdt> fetchIssueTypes() {
    return Issue_Type__mdt.getAll().values();
  }
}
