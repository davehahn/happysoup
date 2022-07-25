/**
 * Created by dhavalmacbook on 16/06/21.
 */

@IsTest
private class gcProject_T {
  @TestSetup
  static void testData() {
  }

  @IsTest
  static void testProperties() {
    //disableTrigger Property
    gcProject.disableTrigger = null;
    Boolean retFlag1 = gcProject.disableTrigger;
    System.assertEquals(false, retFlag1);
    gcProject.disableTrigger = true;
    retFlag1 = gcProject.disableTrigger;
    system.assertEquals(true, retFlag1);

    //disableLockedCheck Property
    gcProject.disableLockedCheck = null;
    Boolean retFlag2 = gcProject.disableLockedCheck;
    System.assertEquals(false, retFlag2);
    gcProject.disableLockedCheck = true;
    retFlag2 = gcProject.disableLockedCheck;
    system.assertEquals(true, retFlag2);

    //disableCommission Property
    gcProject.disableCommission = null;
    Boolean retFlag3 = gcProject.disableCommission;
    System.assertEquals(false, retFlag3);
    gcProject.disableCommission = true;
    retFlag3 = gcProject.disableCommission;
    system.assertEquals(true, retFlag3);

    //disableRegistration Property
    gcProject.disableRegistration = null;
    Boolean retFlag4 = gcProject.disableRegistration;
    System.assertEquals(false, retFlag4);
    gcProject.disableRegistration = true;
    retFlag4 = gcProject.disableRegistration;
    system.assertEquals(true, retFlag4);

    //disableJob Property
    gcProject.disableJob = null;
    Boolean retFlag5 = gcProject.disableJob;
    System.assertEquals(false, retFlag5);
    gcProject.disableJob = true;
    retFlag5 = gcProject.disableJob;
    system.assertEquals(true, retFlag5);

    //disablePrepaid Property
    gcProject.disablePrepaid = null;
    Boolean retFlag6 = gcProject.disablePrepaid;
    System.assertEquals(false, retFlag6);
    gcProject.disablePrepaid = true;
    retFlag6 = gcProject.disablePrepaid;
    system.assertEquals(true, retFlag6);
  }
}
