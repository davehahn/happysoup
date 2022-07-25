@IsTest
private class gcEmployee_T {
  @TestSetup
  static void testData() {
    new Factory_TestData();
    User u = Factory_User.buildUser(
      LGND_Utilities.generateRandomString(5),
      LGND_Utilities.generateRandomString(5),
      'System Administrator'
    );
    insert u;
    Id idGLV2 = [
      SELECT Id
      FROM AcctSeed__Accounting_Variable__c
      WHERE AcctSeed__Type__c = 'GL Account Variable 2'
      LIMIT 1
    ][0]
    .Id;
    Employee__c employee = new Employee__c(GL_Account_Variable_2__c = idGLV2, Name = 'Test Employee', User__c = u.Id);

    insert employee;

    AcctSeed__Accounting_Period__c period = [
      SELECT Id, AcctSeed__Start_Date__c, AcctSeed__End_Date__c
      FROM AcctSeed__Accounting_Period__c
      LIMIT 1
    ];
    AcctSeed__Time_Card_Period__c tcp = new AcctSeed__Time_Card_Period__c(
      AcctSeed__End_Date__c = period.AcctSeed__End_Date__c,
      AcctSeed__Start_Date__c = period.AcctSeed__Start_Date__c.toStartOfWeek().addDays(7),
      AcctSeed__Status__c = 'Open'
    );
    insert tcp;
    Employee_Wage_Rate__c ewr = new Employee_Wage_Rate__c(
      Employee__c = employee.Id,
      Effective_Time_Card_Period__c = tcp.Id,
      Benefits__c = 10,
      Base__c = 50
    );
    insert ewr;
  }

  @IsTest
  static void testUpdateEmployeeName() {
    Test.startTest();

    Employee__c employee = [SELECT Name, User__c, GL_Account_Variable_2__c FROM Employee__c LIMIT 1];
    employee.Name = employee.Name + 'updated';
    update employee;

    List<User> users = [SELECT Id FROM User];
    Set<Id> setUserIds = new Set<Id>();

    for (User u : users) {
      setUserIds.add(u.id);
    }

    gcEmployee.updateEmployeeName(setUserIds);

    Test.stopTest();
  }

  @IsTest
  static void testUpdateUser() {
    Test.startTest();
    Employee__c employee = [SELECT Name, User__c, GL_Account_Variable_2__c FROM Employee__c LIMIT 1];

    User u = Factory_User.buildUser(
      LGND_Utilities.generateRandomString(5),
      LGND_Utilities.generateRandomString(5),
      'System Administrator'
    );
    insert u;

    employee.User__c = u.Id;

    try {
      update employee;
    } catch (Exception e) {
      system.debug('###testUpdateUser: ' + e.getMessage());
    }
    Test.stopTest();
  }

  @isTest
  static void testUpdateWithoutUser() {
    Test.startTest();

    Employee__c employee = [SELECT Name, User__c, GL_Account_Variable_2__c FROM Employee__c LIMIT 1];

    employee.User__c = null;
    try {
      update employee;
    } catch (Exception e) {
      system.debug('###testUpdateWithoutUser: ' + e.getMessage());
    }

    Test.stopTest();
  }

  @isTest
  static void testInsertWithoutUser() {
    Test.startTest();

    Employee__c employee = [SELECT Name, User__c, GL_Account_Variable_2__c FROM Employee__c LIMIT 1];

    Employee__c cloneEmp = employee.clone();
    cloneEmp.User__c = null;

    try {
      insert cloneEmp;
    } catch (Exception e) {
      system.debug('###testInsertWithoutUser: ' + e.getMessage());
    }

    Test.stopTest();
  }

  @isTest
  static void testDeleteEmployee() {
    Test.startTest();

    Employee__c employee = [SELECT Id, Name, User__c, GL_Account_Variable_2__c FROM Employee__c LIMIT 1];

    delete employee;

    List<Employee__c> employees = [
      SELECT Name, User__c, GL_Account_Variable_2__c
      FROM Employee__c
      WHERE Id = :employee.Id
    ];
    System.assertEquals(0, employees.size());

    Test.stopTest();
  }

  @isTest
  static void testUpdateGLV2() {
    Test.startTest();
    Employee__c employee = [SELECT Name, User__c, GL_Account_Variable_2__c FROM Employee__c LIMIT 1];
    Factory_AccountingVariables factoryAV = new Factory_AccountingVariables();

    employee.GL_Account_Variable_2__c = factoryAV.glv2s.get('Production').Id;
    update employee;
    Test.stopTest();
  }

  @IsTest
  static void testProperty() {
    gcEmployee.disableTrigger = null;
    boolean flag = gcEmployee.disableTrigger;
    System.assertEquals(false, flag);

    gcEmployee.disableTrigger = true;
    flag = gcEmployee.disableTrigger;
    System.assertEquals(true, flag);
  }
}
