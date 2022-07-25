@isTest
public class TA_User_Legacy_T {
  static List<User> users;
  private static List<User> getData() {
    return [
      SELECT
        id,
        username,
        emailencodingkey,
        firstname,
        lastname,
        languagelocalekey,
        localesidkey,
        profileid,
        timezonesidkey,
        GL_Account_Variable_1__c,
        Warehouse__c
      FROM User
    ];
  }
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    User u = Factory_User.buildUser('Test-Fname', 'Test-Lname', 'System Administrator');
    insert u;
  }
  @IsTest
  static void beforeInsertTest() {
    Test.startTest();
    users = getData();
    new TA_User_Legacy().beforeInsert(users);
    Test.stopTest();
  }
  @IsTest
  static void afterInsertTest() {
    Test.startTest();
    new TA_User_Legacy().afterInsert(getData());
    Test.stopTest();
  }
  @IsTest
  static void afterUpdateTest() {
    Test.startTest();
    users = getData();
    User userClone = users[0].clone(true, true, true, true);
    new TA_User_Legacy().afterUpdate(new List<User>{ users[0] }, new List<User>{ userClone });
    Test.stopTest();
  }
  @IsTest
  static void beforeUpdateTest() {
    Test.startTest();
    users = getData();
    User userClone = users[0].clone(true, true, true, true);
    new TA_User_Legacy().beforeUpdate(new List<User>{ users[0] }, new List<User>{ userClone });
    Test.stopTest();
  }
  @IsTest
  static void beforeDeleteTest() {
    Test.startTest();
    new TA_User_Legacy().beforeDelete(getData());
    Test.stopTest();
  }
  @IsTest
  static void afterDeleteTest() {
    Test.startTest();
    new TA_User_Legacy().afterDelete(getData());
    Test.stopTest();
  }
}
