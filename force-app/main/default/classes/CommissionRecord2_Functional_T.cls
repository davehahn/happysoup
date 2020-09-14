/**
 * Created by dave on 2020-02-04.
 */

@IsTest
private class CommissionRecord2_Functional_T
{

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Account customer = Factory_Account.insertCustomerAccounts(1)[0];
    GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertFullSerial('Boat', 'Pontoon', 'test12345');
    AcctSeed__Project__c project = Factory_ERPOrder.buildERP( customer, serial.Id, gcConstants.idRtProjectBoatSale );
    project.GMBLASERP__Pricebook__c = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
    insert project;
  }

  private static AcctSeed__Project__c project;
  private static AcctSeed__Project_Task__c task;
  private static List<Product2> products;

  private static void setup_Project_Task_Products(String calcMethod,
                                                  Decimal retailPrice,
                                                  Decimal factoryPrice)
  {
    Legend_Settings__c settings = Legend_Settings__c.getOrgDefaults();
    project = [SELECT Id FROM AcctSeed__Project__c LIMIT 1];
    task = new AcctSeed__Project_Task__c(
      AcctSeed__Project__c = project.Id,
      DisplayOnCustomerInvoice__c = true,
      Commission_Calculation_Method__c = calcMethod,
      Name = 'Commission Task'
    );
    insert task;

    setupPB(retailPrice,factoryPrice);
  }

  private static void setup_Project_Task_Products(String calcMethod, Decimal retailPrice, Decimal factoryPrice, Id idGLV2)
  {
    Legend_Settings__c settings = Legend_Settings__c.getOrgDefaults();
    project = [SELECT Id FROM AcctSeed__Project__c LIMIT 1];
    task = new AcctSeed__Project_Task__c(
        AcctSeed__Project__c = project.Id,
        DisplayOnCustomerInvoice__c = true,
        Commission_Calculation_Method__c = calcMethod,
        Name = 'Commission Task',
        AcctSeed__GL_Account_Variable_2__c = idGLV2
    );
    insert task;
    setupPB(retailPrice,factoryPrice);
  }

  private static void setupPB(Decimal retailPrice, Decimal factoryPrice){
    Legend_Settings__c settings = Legend_Settings__c.getOrgDefaults();
    products = Factory_Product.createNonSerializedProducts( 'Part', 'Electronics', 10 );
    Factory_PricebookEntry.insertStandardEntries( products, 100 );
    List<PricebookEntry> pbes = new List<PricebookEntry>();
    pbes.addAll(
        Factory_PricebookEntry.buildEntries(
            products,
            settings.Default_Retail_Pricebook__c,
            retailPrice
        )
    );
    pbes.addAll(
        Factory_PricebookEntry.buildEntries(
            products,
            settings.Default_Factory_Pricebook__c,
            factoryPrice
        )
    );
    insert pbes;
  }

  @IsTest
  static void taskInsert_Test()
  {
    /* When a project Task is inserted AND DisplayOnCustomerInvoice is true,
       a Commission Record should be created
    */
    project = [SELECT Id FROM AcctSeed__Project__c LIMIT 1];
    List<AcctSeed__Project_Task__c> tasks = new List<AcctSeed__Project_Task__c>();
    tasks.add( Factory_ERPOrderTask.buildRetailSaleTask( project.Id ) );
    tasks.add( new AcctSeed__Project_Task__c(
      AcctSeed__Project__c = project.Id,
      DisplayOnCustomerInvoice__c = false,
      Name = 'No Commission Task'
    ));

    Test.startTest();
    insert tasks;
    Test.stopTest();

    List<CommissionRecord2__c> commissionRecords = [SELECT Id FROM CommissionRecord2__c WHERE Project__c = :project.Id];
    System.assertEquals( 1, commissionRecords.size() );
  }

  @IsTest
  static void taskUpdate_woPreviousCommissionRecord()
  {
    project = [SELECT Id FROM AcctSeed__Project__c LIMIT 1];
    task = new AcctSeed__Project_Task__c(
      AcctSeed__Project__c = project.Id,
      DisplayOnCustomerInvoice__c = false,
      Name = 'No Commission Task'
    );
    insert task;

    List<CommissionRecord2__c> commissionRecords = [SELECT Id FROM CommissionRecord2__c WHERE Project__c = :project.Id];
    System.assertEquals( 0 , commissionRecords.size() );

    task.DisplayOnCustomerInvoice__c = true;
    update task;

    commissionRecords = [SELECT Id, Calculation_Method__c FROM CommissionRecord2__c WHERE Project__c = :project.Id];
    System.assertEquals( 1 , commissionRecords.size() );
    System.assertEquals( 'Revenue', commissionRecords[0].Calculation_Method__c );
  }

  @IsTest
  static void taskUpdate_wPreviousCommissionRecord()
  {
    project = [SELECT Id FROM AcctSeed__Project__c LIMIT 1];
    task = new AcctSeed__Project_Task__c(
      AcctSeed__Project__c = project.Id,
      DisplayOnCustomerInvoice__c = true,
      Name = 'Commission Task'
    );
    insert task;

    List<CommissionRecord2__c> commissionRecords = [SELECT Id, Calculation_Method__c FROM CommissionRecord2__c WHERE Project__c = :project.Id];
    System.assertEquals( 1 , commissionRecords.size() );
    System.assertEquals( 'Revenue', commissionRecords[0].Calculation_Method__c );

    task.Commission_Calculation_Method__c = 'Gross Margin';
    update task;

    commissionRecords = [SELECT Id, Calculation_Method__c FROM CommissionRecord2__c WHERE Project__c = :project.Id];
    System.assertEquals( 1 , commissionRecords.size() );
    System.assertEquals( 'Gross Margin', commissionRecords[0].Calculation_Method__c );
  }

  @IsTest
  static void taskUpdate_removeDisplayOnCustomerInvoice()
  {
    project = [SELECT Id FROM AcctSeed__Project__c LIMIT 1];
    task = new AcctSeed__Project_Task__c(
      AcctSeed__Project__c = project.Id,
      DisplayOnCustomerInvoice__c = true,
      Name = 'Commission Task'
    );
    insert task;

    List<CommissionRecord2__c> commissionRecords = [SELECT Id, Calculation_Method__c FROM CommissionRecord2__c WHERE Project__c = :project.Id];
    System.assertEquals( 1 , commissionRecords.size() );

    task.DisplayOnCustomerInvoice__c = false;
    update task;

    commissionRecords = [SELECT Id, Calculation_Method__c FROM CommissionRecord2__c WHERE Project__c = :project.Id];
    System.assertEquals( 0 , commissionRecords.size() );
  }

  @isTest
  static void deleteTask_Test()
  {
    project = [SELECT Id FROM AcctSeed__Project__c LIMIT 1];
    List<AcctSeed__Project_Task__c> tasks = Factory_ERPOrderTask.insertDefaultRetailBoatSaleTasks( project.Id );

    List<CommissionRecord2__c> commissionRecords = [SELECT Id FROM CommissionRecord2__c WHERE Project__c = :project.Id ];
    System.assertEquals( 2, commissionRecords.size() );

    delete tasks[0];

    commissionRecords = [SELECT Id FROM CommissionRecord2__c WHERE Project__c = :project.Id ];
    System.assertEquals( 1, commissionRecords.size() );
  }

  @isTest
  static void insertMaterials_Revenue_Test()
  {
    setup_Project_Task_Products('Revenue', 1000, 1000);
    List<AcctSeedERP__Material__c> materials = new List<AcctSeedERP__Material__c>();
    for( Product2 p : products )
    {
      materials.add( new AcctSeedERP__Material__c(
        AcctSeedERP__Product__c = p.Id,
        AcctSeedERP__Project__c = project.Id,
        AcctSeedERP__Project_Task__c = task.Id,
        AcctSeedERP__Quantity_Per_Unit__c = 1,
        GMBLASERP__Unit_Price__c = 1000,
        AcctSeedERP__Comment__c = 'From Unit Test'
      ));
    }

    Test.startTest();
    insert materials;
    Test.stopTest();

    List<CommissionRecord2__c> commissionRecords = [ SELECT Id FROM CommissionRecord2__c WHERE Project_Task__c = :task.Id ];
    List<CommissionLineItem2__c> commissionLineItems = [ SELECT Id, Sale_Price__c, Profit__c, Cost__c, Commission_Rate__c, Comment__c, Payment_Amount__c, Quantity__c FROM CommissionLineItem2__c WHERE CommissionRecord2__c = :commissionRecords[0].Id ];
    System.assertEquals( 1, commissionRecords.size() );
    System.assertEquals( 10, commissionLineItems.size() );
    System.assertEquals( 1000, commissionLineItems[0].Sale_Price__c );
    System.assertEquals( 0, commissionLineItems[0].Profit__c );
    System.assertEquals( 1000, commissionLineItems[0].Cost__c );
    System.assertEquals( 'From Unit Test', commissionLineItems[0].Comment__c );
    System.assertEquals( 1, commissionLineItems[0].Quantity__c );
    System.assertEquals( CommissionLineItem2_Service.partsRate, commissionLineItems[0].Commission_Rate__c );
    System.assertEquals( ( 1000 * CommissionLineItem2_Service.partsRate ), commissionLineItems[0].Payment_Amount__c );

  }

  @IsTest
  static void insertMaterials_GrossMargin_Test()
  {
    setup_Project_Task_Products('Gross Margin', 1000, 500 );
    List<AcctSeedERP__Material__c> materials = new List<AcctSeedERP__Material__c>();
    for( Product2 p : products )
    {
      materials.add( new AcctSeedERP__Material__c(
        AcctSeedERP__Product__c = p.Id,
        AcctSeedERP__Project__c = project.Id,
        AcctSeedERP__Project_Task__c = task.Id,
        AcctSeedERP__Quantity_Per_Unit__c = 1,
        GMBLASERP__Unit_Price__c = 1000,
        AcctSeedERP__Comment__c = 'From Unit Test'
      ));
    }

    Test.startTest();
    insert materials;
    Test.stopTest();

    List<CommissionRecord2__c> commissionRecords = [ SELECT Id FROM CommissionRecord2__c WHERE Project_Task__c = :task.Id ];
    List<CommissionLineItem2__c> commissionLineItems = [ SELECT Id, Sale_Price__c, Profit__c, Cost__c, Commission_Rate__c, Comment__c, Payment_Amount__c, Quantity__c FROM CommissionLineItem2__c WHERE CommissionRecord2__c = :commissionRecords[0].Id ];
    System.assertEquals( 1, commissionRecords.size() );
    System.assertEquals( 10, commissionLineItems.size() );
    System.assertEquals( 1000, commissionLineItems[0].Sale_Price__c );
    System.assertEquals( 500, commissionLineItems[0].Cost__c );
    System.assertEquals( 500, commissionLineItems[0].Profit__c );
    System.assertEquals( 'From Unit Test', commissionLineItems[0].Comment__c );
    System.assertEquals( 1, commissionLineItems[0].Quantity__c );
    System.assertEquals( CommissionLineItem2_Service.grossMarginRate, commissionLineItems[0].Commission_Rate__c );
    System.assertEquals( ( 500 * CommissionLineItem2_Service.grossMarginRate ), commissionLineItems[0].Payment_Amount__c );

  }

  @IsTest
  static void newTaskThatAppliesToRetailSale_Test()
  {
    setup_Project_Task_Products('Gross Margin', 1000, 500 );
    task.Is_Retail_Boat_Sale__c = true;
    Boolean orig = gcProjectTask.disableTrigger;
    gcProjectTask.disableTrigger = true;
    update task;
    gcProjectTask.disableTrigger = orig;
    List<AcctSeedERP__Material__c> materials = new List<AcctSeedERP__Material__c>();
    for( Product2 p : products )
    {
      materials.add( new AcctSeedERP__Material__c(
        AcctSeedERP__Product__c = p.Id,
        AcctSeedERP__Project__c = project.Id,
        AcctSeedERP__Project_Task__c = task.Id,
        AcctSeedERP__Quantity_Per_Unit__c = 1,
        GMBLASERP__Unit_Price__c = 1000,
        AcctSeedERP__Comment__c = 'From Unit Test'
      ));
    }

    AcctSeed__Project_Task__c retailRigTask = new AcctSeed__Project_Task__c(
      AcctSeed__Project__c = project.Id,
      DisplayOnCustomerInvoice__c = false,
      Commission_Calculation_Method__c = 'Revenue',
      Name = 'Retail Rig',
      Commission_Override_Project_Task__c = task.Id
    );

    insert retailRigTask;

    for( Product2 p : Factory_Product.createNonSerializedProducts( 'Part', 'Electronics', 2 ) )
    {
      materials.add( new AcctSeedERP__Material__c(
        AcctSeedERP__Product__c = p.Id,
        AcctSeedERP__Project__c = project.Id,
        AcctSeedERP__Project_Task__c = retailRigTask.Id,
        AcctSeedERP__Quantity_Per_Unit__c = 1,
        GMBLASERP__Unit_Price__c = 1000,
        AcctSeedERP__Comment__c = 'From Unit Test'
      ));
    }

    Test.startTest();
    insert materials;
    Test.stopTest();

    List<CommissionRecord2__c> commissionRecords = [ SELECT Id FROM CommissionRecord2__c WHERE Project_Task__c = :task.Id ];
    List<CommissionLineItem2__c> commissionLineItems = [ SELECT Id, Sale_Price__c, Profit__c, Cost__c, Commission_Rate__c, Comment__c, Payment_Amount__c, Quantity__c FROM CommissionLineItem2__c WHERE CommissionRecord2__c = :commissionRecords[0].Id ];
    System.assertEquals( 1, commissionRecords.size() );
    System.assertEquals( 12, commissionLineItems.size() );
    System.assertEquals( 1000, commissionLineItems[0].Sale_Price__c );
    System.assertEquals( 500, commissionLineItems[0].Cost__c );
    System.assertEquals( 500, commissionLineItems[0].Profit__c );
    System.assertEquals( 'From Unit Test', commissionLineItems[0].Comment__c );
    System.assertEquals( 1, commissionLineItems[0].Quantity__c );
    System.assertEquals( CommissionLineItem2_Service.grossMarginRate, commissionLineItems[0].Commission_Rate__c );
    System.assertEquals( ( 500 * CommissionLineItem2_Service.grossMarginRate ), commissionLineItems[0].Payment_Amount__c );

  }

  @IsTest
  static void insertMaterials_InsuranceProducts_Test()
  {
    project = [SELECT Id FROM AcctSeed__Project__c LIMIT 1];
    task = new AcctSeed__Project_Task__c(
      AcctSeed__Project__c = project.Id,
      DisplayOnCustomerInvoice__c = true,
      Commission_Calculation_Method__c = 'Revenue',
      Name = 'Commission Task'
    );
    insert task;

    InsurancePlan__c iPlan = new InsurancePlan__c(
      Name = 'Test Insurance Plan',
      Profit_Percent__c = 25
    );
    insert iPlan;

    products = new List<Product2>();
    for( Integer i=0; i<10; i++ )
    {
      products.add( Factory_Product.buildInsuranceProduct(
        'Accidental Coverage',
        'Insurance ' + String.valueOf(i),
        iPlan.Id,
        false
      ));
    }
    products[0].Insurance_Profit_Percent_Override__c = 15;
    insert products;

    List<AcctSeedERP__Material__c> materials = new List<AcctSeedERP__Material__c>();
    for( Product2 p : products )
    {
      materials.add( new AcctSeedERP__Material__c(
        AcctSeedERP__Product__c = p.Id,
        AcctSeedERP__Project__c = project.Id,
        AcctSeedERP__Project_Task__c = task.Id,
        AcctSeedERP__Quantity_Per_Unit__c = 1,
        GMBLASERP__Unit_Price__c = 1000,
        AcctSeedERP__Comment__c = 'From Unit Test'
      ));
    }

    Test.startTest();
    insert materials;
    Test.stopTest();

    List<CommissionRecord2__c> commissionRecords = [ SELECT Id FROM CommissionRecord2__c WHERE Project_Task__c = :task.Id ];
    List<CommissionLineItem2__c> commissionLineItems = [ SELECT Id, Sale_Price__c, Profit__c, Cost__c, Commission_Rate__c, Comment__c, Payment_Amount__c, Quantity__c FROM CommissionLineItem2__c WHERE CommissionRecord2__c = :commissionRecords[0].Id ];
    System.assertEquals( 1, commissionRecords.size() );
    System.assertEquals( 10, commissionLineItems.size() );
    System.assertEquals( 1000, commissionLineItems[0].Sale_Price__c );
    System.assertEquals( 1000, commissionLineItems[1].Sale_Price__c );
    /* cost is the sale price - (sale price * the Profit Percent Override on Insurance Product ) */
    System.assertEquals( 850, commissionLineItems[0].Cost__c );
    System.assertEquals( 150, commissionLineItems[0].Profit__c );
    /* cost is the sale price - (sale price * the Profit Percent on the insurance Plan ) */
    System.assertEquals( 750, commissionLineItems[1].Cost__c );
    System.assertEquals( 250, commissionLineItems[1].Profit__c );
    System.assertEquals( 'From Unit Test', commissionLineItems[0].Comment__c );
    System.assertEquals( 1, commissionLineItems[0].Quantity__c );
    System.assertEquals( CommissionLineItem2_Service.insuranceRate, commissionLineItems[0].Commission_Rate__c );
    System.assertEquals( ( 150 * CommissionLineItem2_Service.insuranceRate ), commissionLineItems[0].Payment_Amount__c );
    System.assertEquals( ( 250 * CommissionLineItem2_Service.insuranceRate ), commissionLineItems[1].Payment_Amount__c );
  }

  @IsTest
  static void deleteMaterial_Test()
  {
    setup_Project_Task_Products('Revenue', 1000, 1000);
    List<AcctSeedERP__Material__c> materials = new List<AcctSeedERP__Material__c>();
    for( Product2 p : products )
    {
      materials.add( new AcctSeedERP__Material__c(
        AcctSeedERP__Product__c = p.Id,
        AcctSeedERP__Project__c = project.Id,
        AcctSeedERP__Project_Task__c = task.Id,
        AcctSeedERP__Quantity_Per_Unit__c = 1,
        GMBLASERP__Unit_Price__c = 1000,
        AcctSeedERP__Comment__c = 'From Unit Test'
      ));
    }
    insert materials;

    Test.startTest();
    delete materials[0];
    Test.stopTest();

    List<CommissionRecord2__c> commissionRecords = [ SELECT Id FROM CommissionRecord2__c WHERE Project_Task__c = :task.Id ];
    List<CommissionLineItem2__c> commissionLineItems = [ SELECT Id, Sale_Price__c, Profit__c, Cost__c, Commission_Rate__c, Comment__c, Payment_Amount__c, Quantity__c FROM CommissionLineItem2__c WHERE CommissionRecord2__c = :commissionRecords[0].Id ];
    System.assertEquals( 1, commissionRecords.size() );
    System.assertEquals( 9, commissionLineItems.size() );
  }

  @isTest
  static void taskCalculationMethodChange_Test()
  {
    setup_Project_Task_Products('Revenue', 1000, 500);
    List<AcctSeedERP__Material__c> materials = new List<AcctSeedERP__Material__c>();
    for( Product2 p : products )
    {
      materials.add( new AcctSeedERP__Material__c(
        AcctSeedERP__Product__c = p.Id,
        AcctSeedERP__Project__c = project.Id,
        AcctSeedERP__Project_Task__c = task.Id,
        AcctSeedERP__Quantity_Per_Unit__c = 1,
        GMBLASERP__Unit_Price__c = 1000,
        AcctSeedERP__Comment__c = 'From Unit Test'
      ));
    }

    insert materials;

    List<CommissionRecord2__c> commissionRecords = [ SELECT Id, Calculation_Method__c FROM CommissionRecord2__c WHERE Project_Task__c = :task.Id ];
    List<CommissionLineItem2__c> commissionLineItems = [ SELECT Id, Sale_Price__c, Profit__c, Cost__c, Commission_Rate__c, Comment__c, Payment_Amount__c, Quantity__c FROM CommissionLineItem2__c WHERE CommissionRecord2__c = :commissionRecords[0].Id ];
    System.assertEquals( 1, commissionRecords.size() );
    System.assertEquals( 'Revenue', commissionRecords[0].Calculation_Method__c );
    System.assertEquals( 10, commissionLineItems.size() );
    System.assertEquals( 1000, commissionLineItems[0].Sale_Price__c );
    System.assertEquals( 500, commissionLineItems[0].Profit__c );
    System.assertEquals( 500, commissionLineItems[0].Cost__c );
    System.assertEquals( 'From Unit Test', commissionLineItems[0].Comment__c );
    System.assertEquals( 1, commissionLineItems[0].Quantity__c );
    System.assertEquals( CommissionLineItem2_Service.partsRate, commissionLineItems[0].Commission_Rate__c );
    System.assertEquals( ( 1000 * CommissionLineItem2_Service.partsRate ), commissionLineItems[0].Payment_Amount__c );

    task.Commission_Calculation_Method__c = 'Gross Margin';

    Test.startTest();
    update task;
    Test.stopTest();

    CommissionRecord2__c commissionRecord = [ SELECT Id, Calculation_Method__c FROM CommissionRecord2__c WHERE Id = :commissionRecords[0].Id ];
    commissionLineItems = [ SELECT Id, Sale_Price__c, Profit__c, Cost__c, Commission_Rate__c, Comment__c, Payment_Amount__c, Quantity__c FROM CommissionLineItem2__c WHERE CommissionRecord2__c = :commissionRecords[0].Id ];
    System.assertEquals('Gross Margin', commissionRecord.Calculation_Method__c );
    System.assertEquals( 1000, commissionLineItems[0].Sale_Price__c );
    System.assertEquals( 500, commissionLineItems[0].Cost__c );
    System.assertEquals( 500, commissionLineItems[0].Profit__c );
    System.assertEquals( 'From Unit Test', commissionLineItems[0].Comment__c );
    System.assertEquals( 1, commissionLineItems[0].Quantity__c );
    System.assertEquals( CommissionLineItem2_Service.grossMarginRate, commissionLineItems[0].Commission_Rate__c );
    System.assertEquals( ( 500 * CommissionLineItem2_Service.grossMarginRate ), commissionLineItems[0].Payment_Amount__c );
  }

  @IsTest
  static void payments_Test()
  {
    List<User> users = new List<User>();
    User userUser = Factory_User.newUser('USR_Test', 'User1', 'System Administrator', null);
    userUser.ManagerId = UserInfo.getUserId();
    User boUser = Factory_User.newUser('BO_Test', 'User1', 'System Administrator', null);
    boUser.ManagerId = UserInfo.getUserId();
    User salesUser = Factory_User.newUser('SAL_Test', 'User2', 'System Administrator', null);
    salesUser.ManagerId = UserInfo.getUserId();
    users.add( boUser );
    users.add( salesUser );
    users.add( userUser );
    insert users;
    project = [SELECT Id FROM AcctSeed__Project__c LIMIT 1];
    project.Business_Manager__c = boUser.Id;
    project.Salesperson__c = salesUser.Id;
    gcProject.disableTrigger = true;
    update project;
    List<AcctSeed__Project_Task__c> tasks = new List<AcctSeed__Project_Task__c>();
    AcctSeed__Project_Task__c boTask = Factory_ERPOrderTask.buildBusinessOfficeTask( project.Id );
    tasks.add( boTask );
    AcctSeed__Project_Task__c salesTask = Factory_ERPOrderTask.buildRetailSaleTask( project.Id );
    tasks.add( salesTask );
    System.runAs( userUser )
    {
      Test.startTest();
      insert tasks;
      Test.stopTest();

      CommissionRecord2__c[] boCommRecords = [
        SELECT Id, (SELECT Id, Owner__c, Owner__r.FirstName FROM Commission_Payments__r)
        FROM CommissionRecord2__c
        WHERE Project_Task__c = :boTask.Id
      ];
      CommissionRecord2__c[] salesCommRecords = [
        SELECT Id, (SELECT Id, Owner__c, Owner__r.FirstName FROM Commission_Payments__r)
          FROM CommissionRecord2__c
        WHERE Project_Task__c = :salesTask.Id
      ];

      System.assert( LGND_Constants.GLV2Id_Sales == salesTask.AcctSeed__GL_Account_Variable_2__c );
      System.assert( LGND_Constants.GLV2Id_BusinessOffice == boTask.AcctSeed__GL_Account_Variable_2__c );
      System.assertEquals(1, salesCommRecords.size());
      System.assertEquals(1, boCommRecords.size());
      System.assertEquals(1, boCommRecords[0].Commission_Payments__r.size());
      System.assertEquals(1, salesCommRecords[0].Commission_Payments__r.size());
      System.assertEquals(boUser.Id, boCommRecords[0].Commission_Payments__r[0].Owner__c);
      System.assertEquals(salesUser.Id, salesCommRecords[0].Commission_Payments__r[0].Owner__c);
    }
  }

  @IsTest
  static void payments_DefaultOwner_Test()
  {
    User userUser = Factory_User.newUser('USR_Test', 'User1', 'System Administrator', null);
    userUser.ManagerId = UserInfo.getUserId();
    insert userUser;
    project = [SELECT Id FROM AcctSeed__Project__c LIMIT 1];
    //Salesperson get set to Current User be default in gcProject triggerHandler
    project.Salesperson__c = null;
    Boolean orig = gcProject.disableTrigger;
    gcProject.disableTrigger = true;
    update project;
    gcProject.disableTrigger = orig;
    List<AcctSeed__Project_Task__c> tasks = new List<AcctSeed__Project_Task__c>();
    AcctSeed__Project_Task__c boTask = Factory_ERPOrderTask.buildBusinessOfficeTask( project.Id );
    tasks.add( boTask );
    AcctSeed__Project_Task__c salesTask = Factory_ERPOrderTask.buildRetailSaleTask( project.Id );
    tasks.add( salesTask );
    System.runAs( userUser )
    {
      Test.startTest();
      insert tasks;
      Test.stopTest();

      CommissionRecord2__c[] boCommRecords = [
        SELECT Id, (SELECT Id, Owner__c, Owner__r.FirstName FROM Commission_Payments__r)
        FROM CommissionRecord2__c
        WHERE Project_Task__c = :boTask.Id
      ];
      CommissionRecord2__c[] salesCommRecords = [
        SELECT Id, (SELECT Id, Owner__c, Owner__r.FirstName FROM Commission_Payments__r)
        FROM CommissionRecord2__c
        WHERE Project_Task__c = :salesTask.Id
      ];
      System.assert( LGND_Constants.GLV2Id_Sales == salesTask.AcctSeed__GL_Account_Variable_2__c );
      System.assert( LGND_Constants.GLV2Id_BusinessOffice == boTask.AcctSeed__GL_Account_Variable_2__c );
      System.assertEquals(1, salesCommRecords.size());
      System.assertEquals(1, boCommRecords.size());
      System.assertEquals(1, boCommRecords[0].Commission_Payments__r.size());
      System.assertEquals(1, salesCommRecords[0].Commission_Payments__r.size());
      System.assertEquals(userUser.Id, boCommRecords[0].Commission_Payments__r[0].Owner__c);
      System.assertEquals(userUser.Id, salesCommRecords[0].Commission_Payments__r[0].Owner__c);
    }
  }

  @IsTest
  static void paymentAmount_GrossMarginDefault_Test()
  {
    User u = Factory_User.newUser( 'tster', 'lastname', 'System Administrator', null );
    u.ManagerId = UserInfo.getUserId();
    insert u;
    System.runAs( u )
    {
      setup_Project_Task_Products('Gross Margin', 1000, 500);
      List<AcctSeedERP__Material__c> materials = new List<AcctSeedERP__Material__c>();
      for (Product2 p : products)
      {
        materials.add(new AcctSeedERP__Material__c(
          AcctSeedERP__Product__c = p.Id,
          AcctSeedERP__Project__c = project.Id,
          AcctSeedERP__Project_Task__c = task.Id,
          AcctSeedERP__Quantity_Per_Unit__c = 1,
          GMBLASERP__Unit_Price__c = 1000,
          AcctSeedERP__Comment__c = 'From Unit Test'
        ));
      }

      insert materials;

      CommissionRecord2__c commRec = [
        SELECT Id
        FROM CommissionRecord2__c
        WHERE Project_Task__c = :task.Id
      ];
      CommissionPayment2__c[] commPayments = [
        SELECT Id,
          Gross_Margin_Payment_Percent__c,
          Owner__c,
          Split_Percent__c,
          Use_Gross_Margin_Calculation__c,
          Amount__c
        FROM CommissionPayment2__c
        WHERE Commission_Record2__c = :commRec.Id
      ];
      // 10 parts * $500 profit * default gross margin commission payment percent
      Decimal expectedAmount = 10 * 500 * (CommissionPayment2_Service.defaultGrossMarginPaymentPercent / 100);
      System.assertEquals(1, commPayments.size());
      System.assertEquals(true, commPayments[0].Use_Gross_Margin_Calculation__c);
      System.assertEquals(100, commPayments[0].Split_Percent__c);
      System.assertEquals(CommissionPayment2_Service.defaultGrossMarginPaymentPercent, commPayments[0].Gross_Margin_Payment_Percent__c);
      System.assertEquals(expectedAmount, commPayments[0].Amount__c);
    }
  }

  //// Commission Manager Test
  @IsTest
  static void paymentAmount_GrossMarginManager_Test()
  {
    User managerUser = Factory_User.newUser( 'Test', 'Manager', 'System Administrator', null );
    managerUser.Commission_Gross_Margin_Manager__c = 15;
    insert managerUser;
    User u = Factory_User.newUser( 'tester', 'Salesman', 'System Administrator', null );
    u.ManagerId = managerUser.Id;
    u.Commission_Gross_Margin_Percent_Override__c = 10;
    insert u;
    System.runAs( u )
    {
      Test.startTest();
      setup_Project_Task_Products('Gross Margin', 1000, 500);
      List<AcctSeedERP__Material__c> materials = new List<AcctSeedERP__Material__c>();
      for (Product2 p : products)
      {
        materials.add(new AcctSeedERP__Material__c(
            AcctSeedERP__Product__c = p.Id,
            AcctSeedERP__Project__c = project.Id,
            AcctSeedERP__Project_Task__c = task.Id,
            AcctSeedERP__Quantity_Per_Unit__c = 1,
            GMBLASERP__Unit_Price__c = 1000,
            AcctSeedERP__Comment__c = 'From Unit Test'
        ));
      }

      insert materials;
      Test.stopTest();
      CommissionRecord2__c commRec = [
          SELECT Id
          FROM CommissionRecord2__c
          WHERE Project_Task__c = :task.Id
      ];
      CommissionPayment2__c[] commPayments = [
          SELECT Id,
              Gross_Margin_Payment_Percent__c,
              Owner__c,
              Split_Percent__c,
              Use_Gross_Margin_Calculation__c,
              Amount__c
          FROM CommissionPayment2__c
          WHERE Commission_Record2__c = :commRec.Id
      ];
      // 10 parts * $500 profit * default gross margin commission payment percent
      System.debug('Payments Size');
      System.debug(commPayments.size());
      System.debug('Commission');
      System.debug(commPayments[0].Amount__c);
      System.debug('Manager Commission');
      System.debug(commPayments[1].Amount__c);
      Decimal expectedAmount = 10 * 500 * (u.Commission_Gross_Margin_Percent_Override__c / 100);
      System.debug('Commission AMount');
      System.debug(expectedAmount);
      Decimal expectedAmountManager = 10 * 500 * (managerUser.Commission_Gross_Margin_Manager__c / 100);
      System.debug('Manager Commission AMount');
      System.debug(expectedAmountManager);
      System.assertEquals(2, commPayments.size());
      System.assertEquals(true, commPayments[0].Use_Gross_Margin_Calculation__c);
      System.assertEquals(100, commPayments[0].Split_Percent__c);
      System.assertEquals(10, commPayments[0].Gross_Margin_Payment_Percent__c);
      System.assertEquals(15, commPayments[1].Gross_Margin_Payment_Percent__c);
      System.assertEquals(expectedAmount, commPayments[0].Amount__c);
      System.assertEquals(expectedAmountManager, commPayments[1].Amount__c);
    }
  }

  //// Commission Manager Test
  @IsTest
  static void paymentAmount_BusinessOfficeManager_Test()
  {
    User managerUser = Factory_User.newUser( 'Test', 'Manager', 'System Administrator', null );
    managerUser.Commission_Manager_Business_Office__c = 2.5;
    insert managerUser;
    User u = Factory_User.newUser( 'tester', 'Salesman', 'System Administrator', null );
    u.ManagerId = managerUser.Id;
    u.Commission_Gross_Margin_Percent_Override__c = 10;
    insert u;
    System.runAs( u )
    {
      Test.startTest();
      setup_Project_Task_Products('Revenue', 1000, 500, gcConstants.idGLV2BusinessOffice);
      List<AcctSeedERP__Material__c> materials = new List<AcctSeedERP__Material__c>();
      for (Product2 p : products)
      {
        materials.add(new AcctSeedERP__Material__c(
            AcctSeedERP__Product__c = p.Id,
            AcctSeedERP__Project__c = project.Id,
            AcctSeedERP__Project_Task__c = task.Id,
            AcctSeedERP__Quantity_Per_Unit__c = 1,
            GMBLASERP__Unit_Price__c = 1000,
            AcctSeedERP__Comment__c = 'From Unit Test'
        ));
      }

      insert materials;
      Test.stopTest();
      CommissionRecord2__c commRec = [
          SELECT Id, Total_Payment_Amount__c
          FROM CommissionRecord2__c
          WHERE Project_Task__c = :task.Id
      ];
      CommissionPayment2__c[] commPayments = [
          SELECT Id,
              Gross_Margin_Payment_Percent__c,
              Owner__c,
              Split_Percent__c,
              Use_Gross_Margin_Calculation__c,
              Manager_Commission_Type__c,
              Amount__c
          FROM CommissionPayment2__c
          WHERE Commission_Record2__c = :commRec.Id
      ];
      // 10 parts * $500 profit * default gross margin commission payment percent
      System.debug('CommRec');
      System.debug(commRec.Total_Payment_Amount__c);
      System.debug('Payments Size');
      System.debug(commPayments.size());
      System.debug('Commission');
      System.debug(commPayments[0].Amount__c);
      System.debug('Manager Commission');
      System.debug(commPayments[1].Amount__c);
      Decimal expectedAmount = commRec.Total_Payment_Amount__c * (commPayments[0].Split_Percent__c / 100);
      System.debug('Commission AMount');
      System.debug(expectedAmount);
      Decimal expectedAmountManager = commRec.Total_Payment_Amount__c * (managerUser.Commission_Manager_Business_Office__c / 100);
      System.debug('Manager Commission AMount');
      System.debug(expectedAmountManager);
      System.assertEquals(2, commPayments.size());
      System.assertEquals(false, commPayments[0].Use_Gross_Margin_Calculation__c);
      System.assertEquals(100, commPayments[0].Split_Percent__c);
      System.assertEquals(10, commPayments[0].Gross_Margin_Payment_Percent__c);
      System.assertEquals(2.5, commPayments[1].Gross_Margin_Payment_Percent__c);
      System.assertEquals('Business Revenue', commPayments[1].Manager_Commission_Type__c);
      System.assertEquals(expectedAmount, commPayments[0].Amount__c);
      System.assertEquals(expectedAmountManager.setScale(2), commPayments[1].Amount__c);
    }
  }

  //// Commission Manager Test
  @IsTest
  static void paymentAmount_RevenueManager_Test()
  {
    User managerUser = Factory_User.newUser( 'Test', 'Manager', 'System Administrator', null );
    managerUser.Commission_Revenue_Manager__c = 2.5;
    insert managerUser;
    User u = Factory_User.newUser( 'tester', 'Salesman', 'System Administrator', null );
    u.ManagerId = managerUser.Id;
    u.Commission_Gross_Margin_Percent_Override__c = 10;
    insert u;
    System.runAs( u )
    {
      Test.startTest();
      setup_Project_Task_Products('Revenue', 1000, 500, gcConstants.idGlv2Sales);
      List<AcctSeedERP__Material__c> materials = new List<AcctSeedERP__Material__c>();
      for (Product2 p : products)
      {
        materials.add(new AcctSeedERP__Material__c(
            AcctSeedERP__Product__c = p.Id,
            AcctSeedERP__Project__c = project.Id,
            AcctSeedERP__Project_Task__c = task.Id,
            AcctSeedERP__Quantity_Per_Unit__c = 1,
            GMBLASERP__Unit_Price__c = 1000,
            AcctSeedERP__Comment__c = 'From Unit Test'
        ));
      }

      insert materials;
      Test.stopTest();
      CommissionRecord2__c commRec = [
          SELECT Id, Total_Payment_Amount__c
          FROM CommissionRecord2__c
          WHERE Project_Task__c = :task.Id
      ];
      CommissionPayment2__c[] commPayments = [
          SELECT Id,
              Gross_Margin_Payment_Percent__c,
              Owner__c,
              Split_Percent__c,
              Use_Gross_Margin_Calculation__c,
              Manager_Commission_Type__c,
              Amount__c
          FROM CommissionPayment2__c
          WHERE Commission_Record2__c = :commRec.Id
      ];
      // 10 parts * $500 profit * default gross margin commission payment percent
      System.debug('CommRec');
      System.debug(commRec.Total_Payment_Amount__c);
      System.debug('Payments Size');
      System.debug(commPayments.size());
      System.debug('Commission');
      System.debug(commPayments[0].Amount__c);
      System.debug('Manager Commission');
      System.debug(commPayments[1].Amount__c);
      Decimal expectedAmount = commRec.Total_Payment_Amount__c * (commPayments[0].Split_Percent__c / 100);
      System.debug('Commission AMount');
      System.debug(expectedAmount);
      Decimal expectedAmountManager = commRec.Total_Payment_Amount__c * (managerUser.Commission_Revenue_Manager__c / 100);
      System.debug('Manager Commission AMount');
      System.debug(expectedAmountManager);
      System.assertEquals(2, commPayments.size());
      System.assertEquals(false, commPayments[0].Use_Gross_Margin_Calculation__c);
      System.assertEquals(100, commPayments[0].Split_Percent__c);
      System.assertEquals(10, commPayments[0].Gross_Margin_Payment_Percent__c);
      System.assertEquals(2.5, commPayments[1].Gross_Margin_Payment_Percent__c);
      System.assertEquals(expectedAmount, commPayments[0].Amount__c);
      System.assertEquals('Revenue', commPayments[1].Manager_Commission_Type__c);
      System.assertEquals(expectedAmountManager.setScale(2), commPayments[1].Amount__c);
    }
  }

  @IsTest
  static void paymentAmount_GrossMarginOverRide_Test()
  {
    User specialUser = Factory_User.newUser('SPE_Test', 'User1', 'System Administrator', null);
    specialUser.ManagerId = UserInfo.getUserId();
    specialUser.Commission_Gross_Margin_Percent_Override__c = 13;
    insert specialUser;
    project = [SELECT Id FROM AcctSeed__Project__c LIMIT 1];
    project.Salesperson__c = specialUser.Id;
    Boolean orig = gcProject.disableTrigger;
    gcProject.disableTrigger = true;
    update project;
    gcProject.disableTrigger = orig;
    System.runAs( specialUser )
    {
      setup_Project_Task_Products('Gross Margin', 1000, 500);
      List<AcctSeedERP__Material__c> materials = new List<AcctSeedERP__Material__c>();
      for (Product2 p : products)
      {
        materials.add(new AcctSeedERP__Material__c(
          AcctSeedERP__Product__c = p.Id,
          AcctSeedERP__Project__c = project.Id,
          AcctSeedERP__Project_Task__c = task.Id,
          AcctSeedERP__Quantity_Per_Unit__c = 1,
          GMBLASERP__Unit_Price__c = 1000,
          AcctSeedERP__Comment__c = 'From Unit Test'
        ));
      }

      insert materials;

      CommissionRecord2__c commRec = [
        SELECT Id
        FROM CommissionRecord2__c
        WHERE Project_Task__c = :task.Id
      ];
      CommissionPayment2__c[] commPayments = [
        SELECT Id,
          Gross_Margin_Payment_Percent__c,
          Owner__c,
          Split_Percent__c,
          Use_Gross_Margin_Calculation__c,
          Amount__c
        FROM CommissionPayment2__c
        WHERE Commission_Record2__c = :commRec.Id
      ];
      // 10 parts * $500 profit * user override percentage
      Decimal expectedAmount = 10 * 500 * (13.0 / 100.0);
      System.debug( expectedAmount );
      System.debug( 0 == expectedAmount );
      System.assertEquals(1, commPayments.size());
      System.assertEquals(true, commPayments[0].Use_Gross_Margin_Calculation__c);
      System.assertEquals(100, commPayments[0].Split_Percent__c);
      System.assertEquals(13, commPayments[0].Gross_Margin_Payment_Percent__c);
      System.assertEquals(expectedAmount, commPayments[0].Amount__c);
    }
  }

  @IsTest
  static void paymentAmount_Revenue_Test()
  {
    setup_Project_Task_Products('Revenue', 1000, 500);
    List<AcctSeedERP__Material__c> materials = new List<AcctSeedERP__Material__c>();
    for (Product2 p : products)
    {
      materials.add(new AcctSeedERP__Material__c(
        AcctSeedERP__Product__c = p.Id,
        AcctSeedERP__Project__c = project.Id,
        AcctSeedERP__Project_Task__c = task.Id,
        AcctSeedERP__Quantity_Per_Unit__c = 1,
        GMBLASERP__Unit_Price__c = 1000,
        AcctSeedERP__Comment__c = 'From Unit Test'
      ));
    }

    insert materials;

    CommissionRecord2__c commRec = [
      SELECT Id
      FROM CommissionRecord2__c
      WHERE Project_Task__c = :task.Id
    ];
    CommissionPayment2__c[] commPayments = [
      SELECT Id,
        Gross_Margin_Payment_Percent__c,
        Owner__c,
        Split_Percent__c,
        Use_Gross_Margin_Calculation__c,
        Amount__c
      FROM CommissionPayment2__c
      WHERE Commission_Record2__c = :commRec.Id
    ];
    // 10 parts * $1000 sale * partsRate
    Decimal expectedAmount = 10 * 1000 * ( CommissionLineItem2_Service.partsRate );
    System.assertEquals( 1, commPayments.size() );
    System.assertEquals( false, commPayments[0].Use_Gross_Margin_Calculation__c );
    System.assertEquals( 100, commPayments[0].Split_Percent__c );
    System.assertEquals( expectedAmount, commPayments[0].Amount__c );
  }

  @IsTest
  static void materialChangeSync_Test()
  {
    setup_Project_Task_Products('Revenue', 1000, 500);
    List<AcctSeedERP__Material__c> materials = new List<AcctSeedERP__Material__c>();

    materials.add(new AcctSeedERP__Material__c(
      AcctSeedERP__Product__c = products[0].Id,
      AcctSeedERP__Project__c = project.Id,
      AcctSeedERP__Project_Task__c = task.Id,
      AcctSeedERP__Quantity_Per_Unit__c = 1,
      GMBLASERP__Unit_Price__c = 1000,
      AcctSeedERP__Comment__c = 'From Unit Test'
    ));
    insert materials;

    CommissionRecord2__c commRec = [
      SELECT Id,
      ( SELECT Id,
        Gross_Margin_Payment_Percent__c,
        Owner__c,
        Split_Percent__c,
        Use_Gross_Margin_Calculation__c,
        Amount__c
        FROM Commission_Payments__r ),
      ( SELECT Id, Quantity__c FROM Commission_Line_Items__r)
      FROM CommissionRecord2__c
      WHERE Project_Task__c = :task.Id
    ];
    // 1 parts * $1000 sale * partsRate
    Decimal expectedAmount = 1 * 1000 * ( CommissionLineItem2_Service.partsRate );
    System.assertEquals( 1, commRec.Commission_Payments__r.size() );
    System.assertEquals( 1, commRec.Commission_Line_Items__r.size() );
    System.assertEquals( 1, commRec.Commission_Line_Items__r[0].Quantity__c );
    System.assertEquals( false, commRec.Commission_Payments__r[0].Use_Gross_Margin_Calculation__c );
    System.assertEquals( 100, commRec.Commission_Payments__r[0].Split_Percent__c );
    System.assertEquals( expectedAmount, commRec.Commission_Payments__r[0].Amount__c );

    materials[0].AcctSeedERP__Quantity_Per_Unit__c = 10;

    Test.startTest();
    update materials[0];
    Test.stopTest();

    commRec = [
      SELECT Id,
      ( SELECT Id,
        Gross_Margin_Payment_Percent__c,
        Owner__c,
        Split_Percent__c,
        Use_Gross_Margin_Calculation__c,
        Amount__c
      FROM Commission_Payments__r ),
      ( SELECT Id, Quantity__c FROM Commission_Line_Items__r)
      FROM CommissionRecord2__c
      WHERE Project_Task__c = :task.Id
    ];

    System.assertEquals( 1, commRec.Commission_Line_Items__r.size() );
    System.assertEquals( 10, commRec.Commission_Line_Items__r[0].Quantity__c );
  }

}