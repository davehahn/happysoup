@isTest
public class TA_EmployeeWageRate_Legacy_T {
    static  List<Employee_Wage_Rate__c> lstEmployeeWageRate;
    private static List<Employee_Wage_Rate__c> getData(){
        return [SELECT id, Effective_Time_Card_Period__c, Benefits__c, Base__c,Employee__c FROM Employee_Wage_Rate__c];
    }
    @TestSetup
    static void testData(){
        new Factory_TestData();
        User u = Factory_User.buildUser('Fname', 'Lname', 'System Administrator');
        insert u;
        Id idGLV2 = [SELECT Id FROM AcctSeed__Accounting_Variable__c WHERE AcctSeed__Type__c = 'GL Account Variable 2' LIMIT 1][0].Id;
        Employee__c employee = new Employee__c(
                GL_Account_Variable_2__c = idGLV2,
                Name = 'Test Employee',
                User__c = u.Id
        );

        insert employee;

        AcctSeed__Accounting_Period__c period = [SELECT Id, AcctSeed__Start_Date__c, AcctSeed__End_Date__c
        FROM AcctSeed__Accounting_Period__c LIMIT 1];
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
                Base__c = 50);
        insert ewr;
    }
    @IsTest
    static void beforeInsertTest() {
        Test.startTest();
        lstEmployeeWageRate = getData();
        new TA_EmployeeWageRate_Legacy().beforeInsert(lstEmployeeWageRate);
        Test.stopTest();
    }
    @IsTest
    static void afterInsertTest() {
        Test.startTest();
        new TA_EmployeeWageRate_Legacy().afterInsert(getData());
        Test.stopTest();
    }
    @IsTest
    static void afterUpdateTest() {
        Test.startTest();
        lstEmployeeWageRate = getData();
        Employee_Wage_Rate__c empWagerateClone =lstEmployeeWageRate[0].clone(true, true, true, true);
        new TA_EmployeeWageRate_Legacy().afterUpdate(new List<Employee_Wage_Rate__c>{lstEmployeeWageRate[0]},new List<Employee_Wage_Rate__c>{empWagerateClone});
        Test.stopTest();
    }
    @IsTest
    static void beforeUpdateTest() {
        Test.startTest();
        lstEmployeeWageRate = getData();
        Employee_Wage_Rate__c empWagerateClone =lstEmployeeWageRate[0].clone(true, true, true, true);
        new TA_EmployeeWageRate_Legacy().beforeUpdate(new List<Employee_Wage_Rate__c>{lstEmployeeWageRate[0]},new List<Employee_Wage_Rate__c>{empWagerateClone});
        Test.stopTest();
    }
    @IsTest
    static void beforeDeleteTest() {
        Test.startTest();
        new TA_EmployeeWageRate_Legacy().beforeDelete(getData());
        Test.stopTest();
    }
    @IsTest
    static void afterDeleteTest() {
        Test.startTest();
        new TA_EmployeeWageRate_Legacy().afterDelete(getData());
        Test.stopTest();
    }

}