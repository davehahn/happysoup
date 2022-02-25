/**
 * Created by dave on 2020-01-29.
 */
/* TODO: DELETE ME */
@IsTest
private class CommissionRecord2_TriggerHandler_T {
//  @testSetup
//  static void dataSetup() {
//    new Factory_TestData();
//    Factory_CustomSettings.setupInventorySettings();
//    Account customer = Factory_Account.insertCustomerAccounts(1)[0];
//    GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertFullSerial(
//      'Boat',
//      'Pontoon',
//      'test12345'
//    );
//    AcctSeed__Project__c project = Factory_ERPOrder.buildERP(
//      customer,
//      serial.Id,
//      gcConstants.idRtProjectBoatSale
//    );
//    project.GMBLASERP__Pricebook__c = Legend_Settings__c.getOrgDefaults()
//      .Default_Retail_Pricebook__c;
//    insert project;
//  }
//
//  private static void buildVersion2Pricebooks(Set<Id> pbIds) {
//    List<Pricebook2> pbs = [
//      SELECT Id, RecordTypeId, Sales_Year__c, Name
//      FROM Pricebook2
//      WHERE Id IN :pbIds
//    ];
//    List<Pricebook2> v2Pbs = new List<Pricebook2>();
//    for( Pricebook2 pb :  pbs ){
//      v2Pbs.add( new Pricebook2(
//        Name = pb.Name + ' V.2',
//        RecordTypeId = pb.RecordTypeId,
//        Sales_Year__c = pb.Sales_Year__c,
//        Version__c = 2,
//        IsActive = true
//      ));
//    }
//    insert v2Pbs;
//  }
//
//  @IsTest
//  static void beforeInsert_Test() {
//    AcctSeed__Project__c project = [
//      SELECT Id
//      FROM AcctSeed__Project__c
//      LIMIT 1
//    ];
//    List<AcctSeed__Project_Task__c> tasks = Factory_ERPOrderTask.insertDefaultRetailBoatSaleTasks(
//      project.Id
//    );
//    CommissionRecord2__c record = new CommissionRecord2__c(
//      Project_Task__c = tasks[0].Id
//    );
//    Test.startTest();
//    insert record;
//    Test.stopTest();
//
//    record = [
//      SELECT Id, Project__c, Retail_Pricebook__c, Factory_Pricebook__c
//      FROM CommissionRecord2__c
//      WHERE Id = :record.Id
//    ];
//    Legend_Settings__c settings = Legend_Settings__c.getOrgDefaults();
//    Id factoryPB = settings.Default_Factory_Pricebook__c;
//    Id retailPB = settings.Default_Retail_Pricebook__c;
//    System.assertEquals(
//      factoryPB,
//      record.Factory_Pricebook__c,
//      'Factory PB should be set'
//    );
//    System.assertEquals(
//      retailPB,
//      record.Retail_Pricebook__c,
//      'Retail PB should be set'
//    );
//    System.assertEquals(
//      project.Id,
//      record.Project__c,
//      'Project Id should be set'
//    );
//  }
//
//  @IsTest
//  static void beforeInsert_MultiplePricebooksOfTheSameYear_Test() {
//    AcctSeed__Project__c project = [
//      SELECT Id
//      FROM AcctSeed__Project__c
//      LIMIT 1
//    ];
//    List<AcctSeed__Project_Task__c> tasks = Factory_ERPOrderTask.insertDefaultRetailBoatSaleTasks(
//      project.Id
//    );
//    CommissionRecord2__c record = new CommissionRecord2__c(
//      Project_Task__c = tasks[0].Id
//    );
//    Legend_Settings__c settings = Legend_Settings__c.getOrgDefaults();
//    Id factoryPB = settings.Default_Factory_Pricebook__c;
//    Id retailPB = settings.Default_Retail_Pricebook__c;
//    Set<Id> pbIds = new Set<Id>{ factoryPB, retailPB };
//    buildVersion2Pricebooks(pbIds);
//    Test.startTest();
//    insert record;
//    Test.stopTest();
//
//    record = [
//      SELECT Id, Project__c, Retail_Pricebook__c, Factory_Pricebook__c
//      FROM CommissionRecord2__c
//      WHERE Id = :record.Id
//    ];
//    System.assertEquals(
//      factoryPB,
//      record.Factory_Pricebook__c,
//      'Factory PB should be set'
//    );
//    System.assertEquals(
//      retailPB,
//      record.Retail_Pricebook__c,
//      'Retail PB should be set'
//    );
//    System.assertEquals(
//      project.Id,
//      record.Project__c,
//      'Project Id should be set'
//    );
//  }
//
//  @IsTest
//  static void status_Tests() {
//    AcctSeed__Project__c project = [
//      SELECT Id
//      FROM AcctSeed__Project__c
//      LIMIT 1
//    ];
//    List<AcctSeed__Project_Task__c> tasks = Factory_ERPOrderTask.insertDefaultRetailBoatSaleTasks(
//      project.Id
//    );
//    User u = Factory_User.newUser(
//      'TestFirst',
//      'TestLast',
//      'System Administrator',
//      null
//    );
//    insert u;
//    System.runAs(u) {
//      CommissionRecord2__c record = new CommissionRecord2__c(
//        Project_Task__c = tasks[0].Id
//      );
//      insert record;
//      record = [
//        SELECT
//          Id,
//          Status__c,
//          Approved_on__c,
//          Approved_By__c,
//          Reviewed_By__c,
//          Previously_Approved_On__c
//        FROM CommissionRecord2__c
//        WHERE Id = :record.Id
//      ];
//      System.assertEquals('New', record.Status__c, 'Status should be New');
//      record.Status__c = 'Reviewed';
//      update record;
//      record = [
//        SELECT
//          Id,
//          Status__c,
//          Approved_on__c,
//          Approved_By__c,
//          Reviewed_By__c,
//          Previously_Approved_On__c
//        FROM CommissionRecord2__c
//        WHERE Id = :record.Id
//      ];
//      System.assertEquals(u.Id, record.Reviewed_By__c);
//      record.Status__c = 'Approved';
//      update record;
//      record = [
//        SELECT
//          Id,
//          Status__c,
//          Approved_on__c,
//          Approved_By__c,
//          Reviewed_By__c,
//          Previously_Approved_On__c,
//          Journal_Entry__c
//        FROM CommissionRecord2__c
//        WHERE Id = :record.Id
//      ];
//      System.assertEquals(u.Id, record.Reviewed_By__c);
//      System.assertEquals(u.Id, record.Approved_By__c);
//      System.assert(record.Approved_On__c != null);
//      System.assert(record.Journal_Entry__c != null);
//      record.Status__c = 'Disputed';
//      update record;
//      record = [
//        SELECT
//          Id,
//          Status__c,
//          Approved_on__c,
//          Approved_By__c,
//          Reviewed_By__c,
//          Previously_Approved_On__c,
//          Journal_Entry__c
//        FROM CommissionRecord2__c
//        WHERE Id = :record.Id
//      ];
//      System.assert(record.Approved_By__c == null);
//      System.assert(record.Approved_On__c == null);
//      System.assert(record.Previously_Approved_On__c != null);
//      System.assert(record.Journal_Entry__c == null);
//    }
//  }
}
