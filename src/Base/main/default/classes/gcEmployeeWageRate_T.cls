@IsTest(SeeAllData=false)
public class gcEmployeeWageRate_T {
  @TestSetup
  static void testData() {
    new Factory_TestData();
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

  @IsTest
  static void testUpdateEWR() {
    Test.startTest();
    List<Employee_Wage_Rate__c> lstEmployeeWageRate = [
      SELECT id, Effective_Time_Card_Period__c, Benefits__c, Base__c
      FROM Employee_Wage_Rate__c
    ];
    lstEmployeeWageRate[0].Base__c = 100;
    update lstEmployeeWageRate[0];
    lstEmployeeWageRate = [
      SELECT id, Effective_Time_Card_Period__c, Benefits__c, Base__c
      FROM Employee_Wage_Rate__c
      LIMIT 1
    ];
    System.assertEquals(100, lstEmployeeWageRate[0].Base__c);
    Test.stopTest();
  }
  @IsTest
  static void testUpdateEmployWageRateForBaseNull() {
    Test.startTest();
    List<Employee_Wage_Rate__c> lstEmployeeWageRate = [
      SELECT id, Effective_Time_Card_Period__c, Benefits__c, Base__c
      FROM Employee_Wage_Rate__c
    ];
    lstEmployeeWageRate[0].Base__c = null;
    try {
      update lstEmployeeWageRate[0];
    } catch (Exception e) {
      System.assert(null != e.getMessage());
    }
    Test.stopTest();
  }

  @IsTest
  static void testUpdateEmployWageRateForTimePeriodNull() {
    Test.startTest();
    List<Employee_Wage_Rate__c> lstEmployeeWageRate = [
      SELECT id, Effective_Time_Card_Period__c, Benefits__c, Base__c
      FROM Employee_Wage_Rate__c
    ];
    lstEmployeeWageRate[0].Effective_Time_Card_Period__c = null;
    try {
      update lstEmployeeWageRate[0];
    } catch (Exception e) {
      System.assert(null != e.getMessage());
    }
    Test.stopTest();
  }

  @IsTest
  static void testUpdateEmployWageRateForTimeCardPeriodNull() {
    Test.startTest();
    //  List<AcctSeed__Accounting_Period__c> lstTCP = [SELECT id FROM AcctSeed__Time_Card_Period__c ];
    List<Employee_Wage_Rate__c> lstEmployeeWageRate = [
      SELECT id, Effective_Time_Card_Period__c, Benefits__c, Base__c
      FROM Employee_Wage_Rate__c
    ];
    lstEmployeeWageRate[0].Effective_Time_Card_Period__c = null;
    try {
      update lstEmployeeWageRate[0];
    } catch (Exception e) {
      System.assert(null != e.getMessage());
    }
    Test.stopTest();
  }

  @IsTest
  static void testUpdateEmployWageRateForTCPStatusOpen() {
    Test.startTest();
    List<AcctSeed__Time_Card_Period__c> lstTCP = [
      SELECT id, AcctSeed__Status__c
      FROM AcctSeed__Time_Card_Period__c
      LIMIT 1
    ];
    lstTCP[0].AcctSeed__Status__c = 'Closed';
    update lstTCP[0];

    List<Employee_Wage_Rate__c> lstEmployeeWageRate = [
      SELECT id, Effective_Time_Card_Period__c, Benefits__c, Base__c
      FROM Employee_Wage_Rate__c
    ];
    lstEmployeeWageRate[0].Effective_Time_Card_Period__c = lstTCP[0].id;
    try {
      update lstEmployeeWageRate[0];
    } catch (Exception e) {
      System.assert(null != e.getMessage());
    }
    Test.stopTest();
  }

  @IsTest
  static void testDeleteEWR() {
    Test.startTest();
    List<Employee_Wage_Rate__c> lstEmployeeWageRate = [
      SELECT id, Effective_Time_Card_Period__c, Benefits__c, Base__c
      FROM Employee_Wage_Rate__c
    ];
    Id EWRId = lstEmployeeWageRate[0].id;
    delete lstEmployeeWageRate[0];
    lstEmployeeWageRate = [
      SELECT id, Effective_Time_Card_Period__c, Benefits__c, Base__c
      FROM Employee_Wage_Rate__c
      WHERE id = :EWRId
    ];
    System.assert(lstEmployeeWageRate.size() == 0);
    Test.stopTest();
  }

  @IsTest
  static void testDeleteEWRStatusClosed() {
    Test.startTest();
    List<AcctSeed__Time_Card_Period__c> lstTCP = [
      SELECT id, AcctSeed__Status__c
      FROM AcctSeed__Time_Card_Period__c
      LIMIT 1
    ];
    lstTCP[0].AcctSeed__Status__c = 'Closed';
    update lstTCP[0];

    List<Employee_Wage_Rate__c> lstEmployeeWageRate = [
      SELECT id, Effective_Time_Card_Period__c, Benefits__c, Base__c
      FROM Employee_Wage_Rate__c
    ];
    lstEmployeeWageRate[0].Effective_Time_Card_Period__c = lstTCP[0].id;
    try {
      delete lstEmployeeWageRate[0];
    } catch (Exception e) {
      System.assert(null != e.getMessage());
    }
    Test.stopTest();
  }

  @IsTest
  static void testInsertEWRStatusClosed() {
    Test.startTest();
    List<AcctSeed__Time_Card_Period__c> lstTCP = [
      SELECT id, AcctSeed__Status__c
      FROM AcctSeed__Time_Card_Period__c
      LIMIT 1
    ];
    lstTCP[0].AcctSeed__Status__c = 'Closed';
    update lstTCP[0];
    List<Employee__c> lstEmployee = [SELECT id, User__c FROM Employee__c LIMIT 1];
    Employee_Wage_Rate__c ewr = new Employee_Wage_Rate__c(
      Employee__c = lstEmployee[0].Id,
      Effective_Time_Card_Period__c = lstTCP[0].Id,
      Benefits__c = 10,
      Base__c = 50
    );

    try {
      insert ewr;
    } catch (Exception e) {
      System.assert(null != e.getMessage());
    }
    Test.stopTest();
  }
  @IsTest
  static void testUpdateEWRForTCPStatusOpen() {
    Test.startTest();
    List<AcctSeed__Time_Card_Period__c> lstTCP = [
      SELECT id, AcctSeed__Status__c
      FROM AcctSeed__Time_Card_Period__c
      LIMIT 1
    ];
    lstTCP[0].AcctSeed__Status__c = 'Closed';
    update lstTCP[0];

    List<Employee_Wage_Rate__c> lstEmployeeWageRate = [
      SELECT id, Effective_Time_Card_Period__c, Benefits__c, Base__c
      FROM Employee_Wage_Rate__c
    ];
    lstEmployeeWageRate[0].Effective_Time_Card_Period__c = lstTCP[0].id;
    lstEmployeeWageRate[0].Base__c = 100;
    try {
      update lstEmployeeWageRate[0];
    } catch (Exception e) {
      System.assert(null != e.getMessage());
    }
    Test.stopTest();
  }
}
