/**
 * Created by dave on 2020-01-03.
 */

@IsTest
private class SystemIssue_Controller_T
{

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  @IsTest
  static void initForm_Test()
  {
    String resultJSON = SystemIssue_Controller.initForm();
    Map<String, List<String>> result =
      (Map<String, List<String>>)JSON.deserialize( resultJSON, Map<String, List<String>>.class );
    System.assertEquals( 4, result.keyset().size() );
  }

  @IsTest
  static void createIssue_Test()
  {
    Test.setMock(HttpCalloutMock.class, new Factory_SystemIssue.JiraSuccessCalloutMock());
    System_Issue__c si = Factory_SystemIssue.buildIssue();
    si = SystemIssue_Controller.createIssue( si );
    System.assert( si.Id != null, 'Id should be set');
  }
}