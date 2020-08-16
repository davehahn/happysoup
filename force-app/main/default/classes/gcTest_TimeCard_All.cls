@isTest
private class gcTest_TimeCard_All{

  static Date firstSunday;
  static Date actualDay;

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  static {
    firstSunday = Date.today().toStartOfMonth().toStartOfWeek();
    //add a week if "firstMonday" is in last month
    if(firstSunday < date.today().toStartOfmonth())
      firstSunday = firstSunday.addDays(7);
    actualDay = firstSunday.addDays(3);
  }

  static testMethod void coverage_Test()
  {
    gcTimeCard.coverage();
    gcTimeCard_Ext.coverage();
    gcTimeCard_Ext.coverage1();
    gcTimeCardLine.coverage();
    gcTimeCardDay.coverage();
    gcTimeCardEntry.coverage();
    gcTimeCardPeriod.coverage();
    gcTimeCardPeriod_Ext.coverage();
  }

  @isTest
  static void trigger_Test()
  {
    gcProject.disableTrigger = true;
    AcctSeed__Time_Card_Period__c tcp = insertTimeCardPeriod();
    AcctSeed__Time_Card__c tc = insertTimeCard( tcp );
    AcctSeed__Time_Card_Line__c tcl = insertTimeCardLine( tc );
    AcctSeed__Time_Card_Day__c tcd = insertTimeCardDay( tcl );
    Time_Card_Entry__c tce = insertTimeCardEntry( tcd );
  }


  private static AcctSeed__Time_Card__c insertTimeCard( AcctSeed__Time_Card_Period__c tcp )
  {
    User employee = Factory_User.newUser( 'TestFirst', 'TestLast', 'Standard User', null );
    insert employee;
    AcctSeed__Ledger__c ledger = [SELECT Id FROM AcctSeed__Ledger__c LIMIT 1];
    AcctSeed__Time_Card__c tc = new AcctSeed__Time_Card__c(
      AcctSeed__Ledger__c = ledger.Id,
      AcctSeed__Time_Card_Period__c = tcp.Id,
      AcctSeed__Employee__c = employee.Id
    );
    insert tc;
    return tc;
  }


  private static AcctSeed__Time_Card_Day__c insertTimeCardDay( AcctSeed__Time_Card_Line__c tcl )
  {
    AcctSeed__Time_Card_Day__c tcd = new AcctSeed__Time_Card_Day__c(
      AcctSeed__Hours__c = 2,
      AcctSeed__Time_Card_Line__c = tcl.Id,
      AcctSeed__Date__c = actualDay
    );
    insert tcd;
    return tcd;
  }


  private static Time_Card_Entry__c insertTimeCardEntry( AcctSeed__Time_Card_Day__c tcd )
  {
    Time_Card_Entry__c tce = new Time_Card_Entry__c(
      Time_Card_Day__c = tcd.Id,
      Time_In_Picklist__c = '7:00AM',
      Time_Out_Picklist__c = '9:00AM'
    );
    insert tce;
    return tce;
  }

  private static AcctSeed__Time_Card_Line__c insertTimeCardLine( AcctSeed__Time_Card__c tc )
  {
    GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertFullSerial('Boat', 'Pontoon', 'TEST7474');
    Account customer = Factory_Account.insertCustomerAccounts(1)[0];
    AcctSeedERP__Warehouse__c wh = [SELECT Id FROM AcctSeedERP__Warehouse__c WHERE Name Like '%Whitefish%' LIMIT 1];
    AcctSeed__Project__c erp = Factory_ERPOrder.insertServiceOrders( customer,
                                                                     wh,
                                                                     DateTime.now(),
                                                                     new List<GMBLASERP__Serial_Number__c>{ serial } )[0];
    AcctSeed__Project_Task__c task = Factory_ERPOrder.buildProjectTask( erp.Id, 'Test Task');
    insert task;
    AcctSeed__Time_Card_Line__c tcl = new AcctSeed__Time_Card_Line__c(
      AcctSeed__Time_Card__c = tc.Id,
      AcctSeed__Project__c = erp.Id,
      AcctSeed__Project_Task__c = task.Id
    );
    //gcTimeCardLine.disableTrigger = true;
    insert tcl;
    return tcl;
  }

  private static AcctSeed__Time_Card_Period__c insertTimeCardPeriod()
  {
    AcctSeed__Time_Card_Period__c tcp = new AcctSeed__Time_Card_Period__c(
      AcctSeed__Status__c = 'Open',
      AcctSeed__Start_Date__c = firstSunday,
      AcctSeed__End_Date__c = firstSunday.addDays(7)
    );
    insert tcp;
    return tcp;
  }

}