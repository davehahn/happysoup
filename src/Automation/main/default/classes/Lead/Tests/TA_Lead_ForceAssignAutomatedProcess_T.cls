/**
 * Created by dave on 2022-10-28.
 */

@IsTest
private class TA_Lead_ForceAssignAutomatedProcess_T {
  //  @testSetup static void dataSetup()
  //  {
  //    new Factory_TestData();
  //    Factory_CustomSettings.setupInventorySettings();
  //  }

  @IsTest
  static void Lead_ForceAssignAutomatedProcess_TA() {
    String fName = 'Automated';
    String lName = 'Process';
    User autoProc = Factory_User.newUser(fName, lName, 'Standard User', null);
    autoProc.FirstName = fName;
    autoProc.LastName = lName;
    insert autoProc;
    System.runAs(autoProc) {
      Lead l = Factory_Lead.constructBasicLead('UnitTest', 'LastName');
      l.OwnerId = autoProc.Id;
      insert l;

      Test.startTest();
      new TA_Lead_ForceAssignAutomatedProcess().afterInsert( new List<Lead>{l} );
      Test.stopTest();

    }

  }
}
