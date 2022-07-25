@IsTest(SeeAllData=false)
private class gcEmployee_Ext_T {
  static Date firstSunday;
  static Date actualDay;

  static {
    firstSunday = Date.today().toStartOfMonth().toStartOfWeek();
    //add a week if "firstMonday" is in last month
    if (firstSunday < date.today().toStartOfmonth())
      firstSunday = firstSunday.addDays(7);
    actualDay = firstSunday.addDays(3);
  }

  @TestSetup
  static void testData() {
    Test.startTest();
    new Factory_TestData();
    gcTimeCardLine.disableTrigger = true;
    Factory_CustomSettings.setupInventorySettings();
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

    User employeeUser = Factory_User.newUser('TestFirst', 'TestLast', 'Standard User', null);
    insert employeeUser;

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

    AcctSeed__Ledger__c ledger = [SELECT Id FROM AcctSeed__Ledger__c LIMIT 1];
    AcctSeed__Time_Card__c tc = new AcctSeed__Time_Card__c(
      AcctSeed__Ledger__c = ledger.Id,
      AcctSeed__Time_Card_Period__c = tcp.Id,
      AcctSeed__Employee__c = employeeUser.Id
    );
    insert tc;

    GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertFullSerial('Boat', 'Pontoon', 'TEST7474');
    Account customer = Factory_Account.insertCustomerAccounts(1)[0];
    AcctSeedERP__Warehouse__c wh = [SELECT Id FROM AcctSeedERP__Warehouse__c WHERE Name LIKE '%Whitefish%' LIMIT 1];
    AcctSeed__Project__c erp = Factory_ERPOrder.insertServiceOrders(
      customer,
      wh,
      DateTime.now(),
      new List<GMBLASERP__Serial_Number__c>{ serial }
    )[0];
    AcctSeed__Project_Task__c task = Factory_ERPOrder.buildProjectTask(erp.Id, 'Test Task');
    insert task;
    AcctSeed__Time_Card_Line__c tcl = new AcctSeed__Time_Card_Line__c(
      AcctSeed__Time_Card__c = tc.Id,
      AcctSeed__Project__c = erp.Id,
      AcctSeed__Project_Task__c = task.Id
    );
    //gcTimeCardLine.disableTrigger = true;
    insert tcl;

    AcctSeed__Time_Card_Day__c tcd = new AcctSeed__Time_Card_Day__c(
      AcctSeed__Hours__c = 2,
      AcctSeed__Time_Card_Line__c = tcl.Id,
      AcctSeed__Date__c = period.AcctSeed__Start_Date__c.toStartOfWeek().addDays(7) //actualDay
    );
    insert tcd;

    Time_Card_Entry__c tce = new Time_Card_Entry__c(
      Time_Card_Day__c = tcd.Id,
      Time_In_Picklist__c = '7:00AM',
      Time_Out_Picklist__c = '9:00AM'
    );
    insert tce;
    Test.stopTest();
  }

  @IsTest
  static void testRetrieveTimeCardPeriods() {
    test.startTest();
    Employee__c employee = [SELECT Id FROM Employee__c LIMIT 1];
    AcctSeed__Time_Card__c timeCard = [SELECT Id FROM AcctSeed__Time_Card__c LIMIT 1];

    list<map<string, string>> retunMap = gcEmployee_Ext.retrieveTimeCardPeriods(employee.ID, timeCard.id);

    test.stopTest();
  }

  @IsTest
  static void testRetrieveTimeCardPeriodsTimeCardNull() {
    test.startTest();
    Employee__c employee = [SELECT Id FROM Employee__c LIMIT 1];
    AcctSeed__Time_Card__c timeCard = [SELECT Id FROM AcctSeed__Time_Card__c LIMIT 1];

    list<map<string, string>> retunMap = gcEmployee_Ext.retrieveTimeCardPeriods(employee.ID, null);

    test.stopTest();
  }

  @IsTest
  static void testFindOrCreateTimeCard() {
    Test.startTest();
    Employee__c employee = [SELECT Id FROM Employee__c LIMIT 1];
    AcctSeed__Time_Card_Period__c tcp = [SELECT Id FROM AcctSeed__Time_Card_Period__c LIMIT 1];
    String strResult = gcEmployee_Ext.findOrCreateTimeCard(employee.ID, tcp.Id);
    system.debug('### strResult: ' + strResult);
    Test.stopTest();
  }

  //    @IsTest
  //    static void testRetrieveTimeCardPeriods(){
  //        Test.startTest();
  //        Employee__c employee = [SELECT Id FROM Employee__c LIMIT 1];
  //        AcctSeed__Time_Card_Period__c tcp = [SELECT Id FROM AcctSeed__Time_Card_Period__c LIMIT 1];
  //        list<map<string,string>> lstResult = gcEmployee_Ext.retrieveTimeCardPeriods(employee.ID, tcp.Id);
  //        system.debug('### lstResult: ' + lstResult);
  //        Test.stopTest();
  //    }
}
