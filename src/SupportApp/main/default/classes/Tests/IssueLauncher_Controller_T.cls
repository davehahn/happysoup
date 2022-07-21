/**
 * Created by dave on 2021-07-15.
 */

@IsTest
private class IssueLauncher_Controller_T {
  @IsTest
  static void fetchIssueTypes_T() {
    List<Issue_Type__mdt> issueTypes = [SELECT Id FROM Issue_Type__mdt];

    Test.startTest();
    List<Issue_Type__mdt> result = IssueLauncher_Controller.fetchIssueTypes();
    Test.stopTest();

    System.assertEquals(issueTypes.size(), result.size());
  }
}
