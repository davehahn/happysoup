/**
 * Created by dave on 2020-02-05.
 */

@IsTest
private class CommissionRecord2_Controller_T
{
  static AcctSeed__Project__c project;

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Account customer = Factory_Account.insertCustomerAccounts(1)[0];
    AcctSeedERP__Warehouse__c warehouse = [ SELECT Id, Name, GL_Account_Variable_3__c FROM AcctSeedERP__Warehouse__c WHERE Name = 'Whitefish'];
    GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertFullSerial('Boat', 'Pontoon', 'test12345');
    Factory_ERPOrder.insertRetailBoatSale( customer, warehouse, DateTime.now().addMonths(1), serial );
  }

  private static Boolean checkCustomPermission() {
    CustomPermissionsReader cpr = new CustomPermissionsReader();
    Boolean hasCommissionCanSeeManagerValue = false;
    if(cpr.hasPermission('CommissionCanSeeManagerValue'))
      hasCommissionCanSeeManagerValue = true;
    return hasCommissionCanSeeManagerValue;
  }
  private static void addCustomPermission(){
    Boolean hasCommissionCanSeeManagerValue = checkCustomPermission();
    if(!hasCommissionCanSeeManagerValue){
      PermissionSet ps = new PermissionSet();
      ps.Name = 'ManagersPermissionForJE';
      ps.Label = 'ManagersPermissionForJE';
      insert ps;

      SetupEntityAccess sea = new SetupEntityAccess();
      sea.ParentId = ps.Id;
      sea.SetupEntityId = [select Id from CustomPermission where DeveloperName = 'CommissionCanSeeManagerValue'][0].Id;
      insert sea;
      PermissionSetAssignment psa = new PermissionSetAssignment();
      psa.AssigneeId = UserInfo.getUserId();
      psa.PermissionSetId = ps.Id;
      insert psa;
    }
  }

  private static void init()
  {
    project = [SELECT Id FROM AcctSeed__Project__c LIMIT 1];
  }

  private static void createPermissionSetForStatusField( Id userId)
  {
    PermissionSet pr = new PermissionSet(
      Label = 'Status PM',
      Name = 'Status_PM'
    );
    insert pr;
    FieldPermissions fp = new FieldPermissions(
      ParentId = pr.Id,
      Field = 'CommissionRecord2__c.Status__c',
      SobjectType = 'CommissionRecord2__c',
      PermissionsEdit = true,
      PermissionsRead = true
    );
    insert fp;
    PermissionSetAssignment pm = new PermissionSetAssignment(
      AssigneeId = userId,
      PermissionSetId = pr.Id
    );
    insert pm;
  }

  @IsTest
  static void fetchCommissionRecords_Test()
  {
    init();
    Test.startTest();
    List<CommissionWrapper.Record> records = CommissionRecord2_Controller.fetchCommissionRecords( project.Id );
    Test.stopTest();

    System.assertEquals( 1, records.size() );
  }

  @IsTest
  static void fetchCommissionRecord_FromProjectTask_Test()
  {
    init();
    AcctSeed__Project_Task__c task = [ SELECT Id FROM AcctSeed__Project_Task__c WHERE AcctSeed__Project__c = :project.Id LIMIT 1];
    Test.startTest();
    CommissionWrapper.Record record = CommissionRecord2_Controller.fetchCommissionRecord( task.Id );
    Test.stopTest();

    System.assertEquals( project.Id, record.projectId );
    System.assertEquals( task.Id, record.taskId );
  }

  @IsTest
  static void fetchCommissionRecord_FromCommissionRecordId_Test()
  {
    init();
    CommissionRecord2__c commissionRecord = [SELECT Id FROM CommissionRecord2__c WHERE Project__c = :project.Id LIMIT 1];
    Test.startTest();
    CommissionWrapper.Record record = CommissionRecord2_Controller.fetchCommissionRecord( commissionRecord.Id );
    Test.stopTest();

    System.assertEquals( project.Id, record.projectId );
    System.assertEquals( commissionRecord.Id, record.id );
  }

  @IsTest
  static void updateCommissionRecordStatus_Test()
  {
    init();
    User u = Factory_User.newuser('Test', 'User', 'System Administrator', null);
    insert u;
    createPermissionSetForStatusField( u.Id );
    System.runAs( u )
    {
      CommissionRecord2__c commissionRecord = [SELECT Id, Status__c FROM CommissionRecord2__c WHERE Project__c = :project.Id LIMIT 1];
      System.assertEquals('New', commissionRecord.Status__c);
      Test.startTest();
      CommissionWrapper.Record wrapper =
        CommissionRecord2_Controller.updateCommissionRecordStatus(
          commissionRecord.Id,
          'Reviewed'
        );
      Test.stopTest();

      commissionRecord = [SELECT Id, Status__c FROM CommissionRecord2__c WHERE Project__c = :project.Id LIMIT 1];
      System.assertEquals('Reviewed', commissionRecord.Status__c);
      System.assertEquals(wrapper.status, commissionRecord.Status__c);
    }
  }

  @IsTest
  static void fetchCommissionLineItems_Test()
  {
    init();
    CommissionRecord2__c commissionRecord = [SELECT Id, Status__c, Project_Task__c FROM CommissionRecord2__c WHERE Project__c = :project.Id LIMIT 1];
    List<AcctSeedERP__Material__c> materials = [SELECT Id
                                                FROM AcctSeedERP__Material__c
                                                WHERE AcctSeedERP__Project__c = :project.Id
                                                AND AcctSeedERP__Project_Task__c = :commissionRecord.Project_Task__c ];
    Test.startTest();
    List<CommissionWrapper.LineItem> lineItems = CommissionRecord2_Controller.fetchCommissionLineItems( commissionRecord.Id );
    Test.stopTest();

    System.assertEquals( materials.size(), lineItems.size() );
  }

  @IsTest
  static void fetchCommissionPayments_Test()
  {
    init();
    CommissionRecord2__c commissionRecord = [SELECT Id, Status__c, Project_Task__c FROM CommissionRecord2__c WHERE Project__c = :project.Id LIMIT 1];
    List<CommissionPayment2__c> payments = [SELECT Id FROM CommissionPayment2__c WHERE Commission_Record2__c = :commissionRecord.Id ];
    Test.startTest();
    List<CommissionWrapper.Payment> wrapPayments = CommissionRecord2_Controller.fetchCommissionPayments( commissionRecord.Id );
    Test.stopTest();

    System.assertEquals( payments.size(), 1 );
    System.assertEquals( wrapPayments.size(), 1);
  }

  @IsTest
  static void upsertLineItem_Test()
  {
    init();
    CommissionRecord2__c commissionRecord = [SELECT Id, Status__c, Project_Task__c FROM CommissionRecord2__c WHERE Project__c = :project.Id LIMIT 1];
    List<AcctSeedERP__Material__c> materials =
      [ SELECT Id
        FROM AcctSeedERP__Material__c
        WHERE AcctSeedERP__Project__c = :project.Id
        AND AcctSeedERP__Project_Task__c = :commissionRecord.Project_Task__c ];

    CommissionWrapper.LineItem li = new CommissionWrapper.LineItem();
    li.comment = 'Test Comment';
    li.description = 'Test Description';
    li.commissionRate = 0.05;
    li.salePrice = 100;
    li.labourCost = 0;
    li.unitCost = 0;
    li.quantity = 1;
    li.commissionRecordId = commissionRecord.Id;

    Test.startTest();
    CommissionRecord2_Controller.upsertLineItem( JSON.serialize( li ) );
    Test.stopTest();

    List<CommissionLineItem2__c> lineItems =
      [ SELECT Id
        FROM CommissionLineItem2__c
        WHERE CommissionRecord2__c = :commissionRecord.Id ];
//    if(!checkCustomPermission())
      System.assertEquals( materials.size() + 1, lineItems.size() );
//    else
//      System.assertEquals( materials.size(), lineItems.size() );
  }

  @IsTest
  static void deleteLineItem_Test()
  {
    init();
    CommissionRecord2__c commissionRecord =
    [
      SELECT Id, Status__c, Project_Task__c
      FROM CommissionRecord2__c
      WHERE Project__c = :project.Id LIMIT 1
    ];
    List<AcctSeedERP__Material__c> materials =
    [
      SELECT Id
      FROM AcctSeedERP__Material__c
      WHERE AcctSeedERP__Project__c = :project.Id
      AND AcctSeedERP__Project_Task__c = :commissionRecord.Project_Task__c
    ];
    CommissionLineItem2__c newLI = new CommissionLineItem2__c(
      CommissionRecord2__c = commissionRecord.Id,
      Comment__c = 'Test Comment',
      Description__c = 'Test Description',
      Commission_Rate__c = 0.05,
      Sale_Price__c = 100,
      Labour_Cost__c = 0,
      Cost__c = 0,
      Quantity__c = 1
    );
    insert newLI;

    List<CommissionLineItem2__c> lineItems =
    [
      SELECT Id
      FROM CommissionLineItem2__c
      WHERE CommissionRecord2__c = :commissionRecord.Id
    ];

    System.assertEquals( materials.size() + 1, lineItems.size() );

    Test.startTest();
    CommissionRecord2_Controller.deleteLineItem( newLI.Id );
    Test.stopTest();

    lineItems =
    [
      SELECT Id
      FROM CommissionLineItem2__c
      WHERE CommissionRecord2__c = :commissionRecord.Id
    ];

    System.assertEquals( materials.size(), lineItems.size() );

  }

  @IsTest
  static void upsertCommissionPayments_Test()
  {
    init();
    CommissionRecord2__c commissionRecord =
    [
      SELECT Id, Status__c, Project_Task__c
      FROM CommissionRecord2__c
      WHERE Project__c = :project.Id LIMIT 1
    ];
    List<CommissionWrapper.Payment> paymentWrappers = new List<CommissionWrapper.Payment>();
    for( CommissionPayment2__c p : CommissionPayment2_Selector.allByCommissionRecordId( commissionRecord.Id ) )
    {
      paymentWrappers.add( new CommissionWrapper.Payment( p ) );
    }
    User u = Factory_User.newuser('Test', 'User', 'System Administrator', null);
    insert u;

    CommissionWrapper.Payment newPaymentWrapper = new CommissionWrapper.Payment();
    newPaymentWrapper.ownerId = u.Id;
    newPaymentWrapper.status = 'New';
    newPaymentWrapper.commissionRecordId = commissionRecord.Id;
    newPaymentWrapper.split = 0.5;

    paymentWrappers[0].split = 0.5;

    paymentWrappers.add( newPaymentWrapper );

    Test.startTest();
    paymentWrappers = CommissionRecord2_Controller.upsertCommissionPayments( JSON.serialize( paymentWrappers ), null );
    Test.stopTest();

    List<CommissionPayment2__c> payments = CommissionPayment2_Selector.allByCommissionRecordId( commissionRecord.Id );

    System.assertEquals( paymentWrappers.size(), payments.size() );

  }

  @IsTest
  static void upsertCommissionPayments_wDelete_Test()
  {
    init();
    CommissionRecord2__c commissionRecord = [
      SELECT Id, Status__c, Project_Task__c
      FROM CommissionRecord2__c
      WHERE Project__c = :project.Id
      LIMIT 1
    ];
    List<CommissionWrapper.Payment> pre_paymentWrappers = new List<CommissionWrapper.Payment>();
    for( CommissionPayment2__c p : CommissionPayment2_Selector.allByCommissionRecordId( commissionRecord.Id ) )
    {
      pre_paymentWrappers.add( new CommissionWrapper.Payment( p ) );
    }

    User u = Factory_User.newuser('Test', 'User', 'System Administrator', null);
    insert u;

    CommissionPayment2__c payment = new CommissionPayment2__c(
      Commission_Record2__c = commissionRecord.Id,
      Owner__c = u.Id,
      Split_Percent__c = 0.02
    );
    insert payment;

    List<CommissionPayment2__c> payments =
    [
      SELECT Id
      FROM CommissionPayment2__c
      WHERE Commission_Record2__c = :commissionRecord.Id
    ];

    List<CommissionWrapper.Payment> deleteWrapper = new List<CommissionWrapper.Payment>{
      new CommissionWrapper.Payment(
        CommissionPayment2_Selector.allByIds(
          new Set<Id>{ payment.Id }
        )[0]
      )
    };

    System.assertEquals( pre_paymentWrappers.size(), 1);
    System.assertEquals(payments.size(), 2);

    Test.startTest();
    CommissionRecord2_Controller.upsertCommissionPayments(
      JSON.serialize( pre_paymentWrappers ),
      JSON.serialize( deleteWrapper )
    );
    Test.stopTest();

    payments =
    [
      SELECT Id
      FROM CommissionPayment2__c
      WHERE Commission_Record2__c = :commissionRecord.Id
    ];

    System.assertEquals( pre_paymentWrappers.size(), 1 );
    System.assertEquals( payments.size(), 1);
  }

  @IsTest
  static void paymentStatusChange_Test()
  {
    init();
    CommissionRecord2__c commissionRecord = [
      SELECT Id, Status__c, Project_Task__c
      FROM CommissionRecord2__c
      WHERE Project__c = :project.Id
      LIMIT 1
    ];
    List<CommissionPayment2__c> payments =
    [
      SELECT Id, Status__c
      FROM CommissionPayment2__c
      WHERE Commission_Record2__c = :commissionRecord.Id
    ];

    System.assertEquals('New', payments[0].Status__c );

    Test.startTest();
    CommissionRecord2_Controller.paymentStatusChange( payments[0].Id, 'Accepted', null );
    Test.stopTest();

    CommissionPayment2__c payment =
    [
      SELECT Id, Status__c
      FROM CommissionPayment2__c
      WHERE Id = :payments[0].Id
    ];

    System.assertEquals( 'Accepted', payment.Status__c );
  }

  @IsTest
  static void paymentStatusChange_Disputed_Test()
  {
    init();
    CommissionRecord2__c commissionRecord = [
      SELECT Id, Status__c, Project_Task__c
      FROM CommissionRecord2__c
      WHERE Project__c = :project.Id
      LIMIT 1
    ];
    List<CommissionPayment2__c> payments = [
      SELECT Id, Status__c
      FROM CommissionPayment2__c
      WHERE Commission_Record2__c = :commissionRecord.Id
    ];

    System.assertEquals('New', payments[0].Status__c);

    Test.startTest();
    CommissionRecord2_Controller.paymentStatusChange(payments[0].Id, 'Disputed', 'Disputed in unit Test');
    Test.stopTest();

    CommissionPayment2__c payment =
    [
      SELECT Id, Status__c
      FROM CommissionPayment2__c
      WHERE Id = :payments[0].Id
    ];

    commissionRecord = [
      SELECT Id, Status__c, Project_Task__c
      FROM CommissionRecord2__c
      WHERE Id = :commissionRecord.Id
      LIMIT 1
    ];

    System.assertEquals( 'Disputed', payment.Status__c );
    System.assertEquals( 'Disputed', commissionRecord.Status__c );
  }
}