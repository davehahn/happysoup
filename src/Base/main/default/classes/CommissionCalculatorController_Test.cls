//@isTest(seeAllData=true)
@isTest
private class CommissionCalculatorController_Test {

  static AcctSeed__Project__c project;
  static AcctSeed__Project__c boatSale;

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  @isTest static void test_coverage()
  {
    project = ProjectTestFactory.insertCounterSale();
    CommissionCalculatorController.fetchInvoice(project.Id);
    CommissionCalculatorController.fetchUsers();
    CommissionCalculatorController.coverage();
  }

  @isTest static void project_constructor_Test()
  {
    User u = User_TestFactory.newCommissionAllUser('fname', 'lName');
    insert u;
    System.runAs( u )
    {
      project = ProjectTestFactory.insertCounterSale();
      CommissionRecordERP.createRecords( new Set<Id>{ project.Id } );
      CommissionLineItemERP.createRecordsFromERPs( new Set<Id>{ project.Id } );
      PageReference pageRef = Page.CommissionCalculator;
      pageRef.getParameters().put('erp_order_id', project.Id);
      Test.setCurrentPage(pageRef);
      CommissionCalculatorController ccc = new CommissionCalculatorController();

      System.assertEquals(project.Id, ccc.erpOrderId);

      CommissionRecord__c cRec;
      CommissionRecord__c[] comRecords = [SELECT Id FROM CommissionRecord__c WHERE ERP_Order__c = :project.Id];
      if( comRecords.size() > 0 )
      {
        cRec = comRecords[0];
      }
      pageRef.getParameters().put('comrecord_id', cRec.id);
      pageRef.getParameters().remove('erp_order_id');
      Test.setCurrentPage(pageRef);
      ccc = new CommissionCalculatorController();
      //System.assertEquals(project.Name, ccc.OppName);
    }
  }

  @isTest static void project_recordTest()
  {
    User u = User_TestFactory.newCommissionAllUser('fname', 'lName');
    insert u;
    System.runAs( u )
    {
      project = ProjectTestFactory.insertCounterSale();
      CommissionRecordERP.createRecords( new Set<Id>{ project.Id } );
      CommissionLineItemERP.createRecordsFromERPs( new Set<Id>{ project.Id } );
      List<CommissionRecord__c> recs = [SELECT Id FROM CommissionRecord__c WHERE ERP_Order__c = :project.Id];
      System.assertEquals(1, recs.size() );
      List<CommissionRecord__c> comRecords = CommissionCalculatorController.fetchRecords(project.Id, 'ERP_Order__c');
      CommissionRecord__c counterSaleRecord = comRecords[0];
      System.assert( comRecords.size() == 1);
      System.assertEquals( counterSaleRecord.Id, CommissionCalculatorController.fetchRecord(counterSaleRecord.Id ).Id );
      System.assertEquals('New', counterSaleRecord.Stage__c);

      counterSaleRecord = CommissionCalculatorController.changeStage(counterSaleRecord.Id, 'Reviewed');
      System.assertEquals('Reviewed', counterSaleRecord.Stage__c);

      Integer salesCommissionItemsCount = counterSaleRecord.CommissionLineItems__r.size();
      Map<String, String> jsonComItem = new Map<String, String>{
        'Department__c' => counterSaleRecord.Type__c,
        'CommissionRecord__c' => counterSaleRecord.Id,
        'CustomItem__c' => 'true',
        'Description__c' => 'This was added by test',
        'AppliedCommissionAmount__c' => '200'
      };

      CommissionLineItem__c newLI = CommissionCalculatorController.updateItem( JSON.serialize(jsonComItem) );
      List<CommissionLineItem__c> salesLI = [SELECT Id
                                            FROM CommissionLineItem__c
                                            WHERE CommissionRecord__c = :counterSaleRecord.Id];

      System.assertEquals( salesLI.size(), (salesCommissionItemsCount + 1) );

      CommissionCalculatorController.deleteCommissionLineItem(newLI.Id);
      salesLI = [SELECT Id
                 FROM CommissionLineItem__c
                 WHERE CommissionRecord__c = :counterSaleRecord.Id];

      System.assertEquals( salesLI.size(), salesCommissionItemsCount );
    }
  }

  @isTest static void payments_test()
  {
    project = ProjectTestFactory.insertCounterSale();
    boatSale = ProjectTestFactory.insertBoatSale();
    Set<Id> erpIds = new Set<Id>{ project.Id, boatSale.Id };
    CommissionRecordERP.createRecords( erpIds );
    CommissionLineItemERP.createRecordsFromERPs( erpIds );
    List<CommissionRecord__c> comRecords = CommissionCalculatorController.fetchRecords(boatSale.Id, 'Erp_Order__c');
    CommissionRecord__c salesRecord;
    CommissionRecord__c boRecord;
    for(CommissionRecord__c cr :comRecords)
    {
      if( cr.Type__c == 'Retail Sales' ) salesRecord = cr;
      if( cr.Type__c == 'Business Office' ) boRecord = cr;
    }

    List<CommissionPayment__c> sales_paymentRecords = [SELECT Id, PaymentPercent__c
                                                       FROM CommissionPayment__c
                                                       WHERE CommissionRecord__c = :salesRecord.Id];

    System.assertEquals(1, sales_paymentRecords.size() );
    CommissionPayment__c spr = sales_paymentRecords[0];
    System.assertEquals(100, spr.PaymentPercent__c);

    Map<String,String> data = new Map<String,String>{'Id' => spr.Id, 'PaymentPercent__c' => '80'};
    spr = CommissionCalculatorController.updatePaymentRecord( JSON.serialize(data) );
    System.assertEquals(80, spr.PaymentPercent__c);

    Profile standardLegendUser = [SELECT id, name FROM Profile WHERE name = 'Legend Standard User - New'];
    User standardLU = new User(alias = 'standt',
      email='standarduser@testorg.com',
      emailencodingkey='UTF-8',
      lastname='Testing',
      languagelocalekey='en_US',
      localesidkey='en_US',
      profileid = standardLegendUser.Id,
      timezonesidkey='America/New_York',
      username='standardlegenduser@testorg.com');

    insert standardLU;
    List<Map<String, String>> dataList = new List<Map<String,String>>();
    dataList.add( new Map<String,String>{
      'Id' => spr.Id, 'PaymentPercent__c' => '60', 'CommissionRecord__c' => spr.CommissionRecord__c
      } );
    dataList.add( new Map<String,String>{
      'PaymentPercent__c' => '40', 'CommissionRecord__c' => spr.CommissionRecord__c
    } );

    sales_paymentRecords = CommissionCalculatorController.updatePaymentRecords( JSON.serialize(dataList) );
    System.assertEquals( 2, sales_paymentRecords.size() );

    CommissionCalculatorController.deletePaymentRecord(sales_paymentRecords[1].Id);
    sales_paymentRecords = [SELECT Id, PaymentPercent__c
                            FROM CommissionPayment__c
                            WHERE CommissionRecord__c = :salesRecord.Id];

    System.assertEquals( 1, sales_paymentRecords.size() );

    CommissionCalculatorController.deletePaymentRecord(sales_paymentRecords[0].Id);
    sales_paymentRecords = [SELECT Id, PaymentPercent__c, Owner__c
                            FROM CommissionPayment__c
                            WHERE CommissionRecord__c = :salesRecord.Id];
     System.assertEquals( 1, sales_paymentRecords.size() );
     System.assertEquals(null, sales_paymentRecords[0].Owner__c);
  }

}