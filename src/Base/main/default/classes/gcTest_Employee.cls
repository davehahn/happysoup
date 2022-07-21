@isTest
private class gcTest_Employee {
  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  static testMethod void coverage_Test() {
    //  gcEmployee.coverage();
    // gcEmployee_Ext.coverage();
    // gcEmployeeWageRate.coverage();
  }

  static testMethod void trigger_Test() {
    User u = Factory_User.buildUser('Fname', 'Lname', 'System Administrator');
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
}
