/**
 * Created by dave on 2020-01-29.
 */

@IsTest
private class CommissionLineItem2_TriggerHandler_T
{
  static Id retailPbId = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
  static Id factoryPbId = Legend_Settings__c.getOrgDefaults().Default_Factory_Pricebook__c;

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Account customer = Factory_Account.insertCustomerAccounts(1)[0];
    AcctSeed__Project__c project = Factory_ERPOrder.buildERP( customer, null, gcConstants.idRtProjectBoatSale );
    project.GMBLASERP__Pricebook__c = retailPbId;
    insert project;
  }

  @IsTest
  static void beforeInsert_Insurance_Test()
  {
    AcctSeed__Project__c project = [SELECT Id FROM AcctSeed__Project__c LIMIT 1];
    AcctSeed__Project_Task__c bo_task = Factory_ERPOrderTask.buildBusinessOfficeTask( project.Id );
    insert bo_task;
    CommissionRecord2__c record = new CommissionRecord2__c(
      Project_Task__c = bo_task.Id
    );
    insert record;
    InsurancePlan__c iPlan = new InsurancePlan__c(
      Name = 'Test Insurance Plan',
      Profit_Percent__c = 25
    );
    insert iPlan;
    Product2 insuranceProduct = Factory_Product.createInsuranceProduct( 'Insurance',
                                                                        'Test Insurance Product',
                                                                        iPlan.Id,
                                                                        false,
                                                                        retailPbId );
    AcctSeedERP__Material__c mat = new AcctSeedERP__Material__c(
      AcctSeedERP__Project_Task__c = bo_task.Id,
      AcctSeedERP__Project__c = project.Id,
      AcctSeedERP__Product__c = insuranceProduct.Id,
      AcctSeedERP__Quantity_Per_Unit__c = 1,
      GMBLASERP__Unit_Price__c = 1000
    );
    insert mat;
    CommissionLineItem2__c cli = new CommissionLineItem2__c(
      CommissionRecord2__c = record.Id,
      Material__c = mat.Id,
      Product__c = mat.AcctSeedERP__Product__c,
      Quantity__c = mat.AcctSeedERP__Quantity_Per_Unit__c,
      Sale_Price__c = mat.GMBLASERP__Unit_Price__c
    );
    Test.startTest();
    insert cli;
    Test.stopTest();

    cli = [ SELECT Id,
                    Cost__c,
                    Profit__c,
                    Commission_Rate__c,
                    Payment_Amount__c,
                    Sale_Price__c
                  FROM CommissionLineItem2__c WHERE Id = :cli.Id ];
    System.assertEquals( 750, cli.Cost__c, 'Commission Line Item should have a Cost of 750' );
    System.assertEquals( 1000, cli.Sale_Price__c, 'Commission Line Item should have a Sale Price of 1000' );
    System.assertEquals( 250, cli.Profit__c, 'Commission Line Profit should be 250' );
    System.assertEquals( 0.30, cli.Commission_Rate__c, 'Commission Line, Commission Rate should be 30');
    System.assertEquals( 250 * 0.3, cli.Payment_Amount__c );
  }

  @IsTest
  static void beforeInsert_FeeCosting_Test()
  {
    AcctSeed__Project__c project = [SELECT Id, GL_Account_Variable_3__r.Name FROM AcctSeed__Project__c LIMIT 1];
    AcctSeed__Project_Task__c task = Factory_ERPOrderTask.buildRetailSaleTask( project.Id );
    insert task;
    CommissionRecord2__c record = new CommissionRecord2__c(
      Project_Task__c = task.Id
    );
    insert record;

    Product2 feeProduct = Factory_Product.createNonSerializedProduct( 'Fees', 'Factory Freight');
    Product_Fee_Amount__c pfa = new Product_Fee_Amount__c(
      Fee_Product__c = feeProduct.Id,
      Price_Book__c = factoryPbId,
      Province__c = project.GL_Account_Variable_3__r.Name,
      Amount__c = 500
    );
    insert pfa;
    AcctSeedERP__Material__c mat = new AcctSeedERP__Material__c(
      AcctSeedERP__Project_Task__c = task.Id,
      AcctSeedERP__Project__c = project.Id,
      AcctSeedERP__Product__c = feeProduct.Id,
      AcctSeedERP__Quantity_Per_Unit__c = 1,
      GMBLASERP__Unit_Price__c = 0
    );
    insert mat;
    CommissionLineItem2__c cli = new CommissionLineItem2__c(
      CommissionRecord2__c = record.Id,
      Material__c = mat.Id,
      Product__c = mat.AcctSeedERP__Product__c,
      Quantity__c = mat.AcctSeedERP__Quantity_Per_Unit__c,
      Sale_Price__c = mat.GMBLASERP__Unit_Price__c
    );
    Test.startTest();
    insert cli;
    Test.stopTest();

    cli = [ SELECT Id,
                    Cost__c,
                    Profit__c,
                    Commission_Rate__c,
                    Payment_Amount__c,
                    Sale_Price__c
                  FROM CommissionLineItem2__c WHERE Id = :cli.Id ];
    System.assertEquals( 500, cli.Cost__c, 'Commission Line Item should have a Cost of 500' );
    System.assertEquals( 0, cli.Sale_Price__c, 'Commission Line Item should have a Sale Price of 0' );
    System.assertEquals( -500, cli.Profit__c, 'Commission Line Profit should be -500' );
    System.assertEquals( 0.10, cli.Commission_Rate__c, 'Commission Line, Commission Rate should be 10');
    System.assertEquals( -500 * 0.1, cli.Payment_Amount__c );
  }

  @IsTest
  static void beforeInsert_Test()
  {
    Decimal riggingTime = 2;
    AcctSeed__Project__c project = [SELECT Id FROM AcctSeed__Project__c LIMIT 1];
    List<AcctSeed__Project_Task__c> tasks = Factory_ERPOrderTask.insertDefaultRetailBoatSaleTasks( project.Id );
    CommissionRecord2__c record = new CommissionRecord2__c(
      Project_Task__c = tasks[0].Id
    );
    insert record;
    Product2 part = Factory_Product.buildNonSerializedProduct('Part', 'Hardware');
    part.Rigging_Time__c = riggingTime;
    insert part;
    Factory_PricebookEntry.createAllDefaultEntriesEntries( part.Id, 10000 );
    AcctSeedERP__Material__c mat = new AcctSeedERP__Material__c(
      AcctSeedERP__Product__c = part.Id,
      AcctSeedERP__Quantity_Per_Unit__c = 1,
      AcctSeedERP__Project__c = project.Id,
      AcctSeedERP__Project_Task__c = tasks[0].Id,
      GMBLASERP__Unit_Price__c = 20000
    );
    insert mat;
    CommissionLineItem2__c cli = new CommissionLineItem2__c(
      CommissionRecord2__c = record.Id,
      Material__c = mat.Id,
      Product__c = mat.AcctSeedERP__Product__c,
      Quantity__c = mat.AcctSeedERP__Quantity_Per_Unit__c,
      Sale_Price__c = mat.GMBLASERP__Unit_Price__c
    );
    Test.startTest();
    insert cli;
    Test.stopTest();

    cli = [ SELECT Id,
                  Cost__c,
                  Profit__c,
                  Sale_Price__c,
                  Commission_Rate__c,
                  Payment_Amount__c
                FROM CommissionLineItem2__c WHERE Id = :cli.Id ];
    Labour_Rate__mdt lr = [SELECT DeveloperName, Hourly_Rate__c FROM Labour_Rate__mdt WHERE DeveloperName = 'Retail' LIMIT 1];
    System.assertEquals( 10000, cli.Cost__c, 'Commission Line Item should have a Cost of 10000' );
    System.assertEquals( 20000, cli.Sale_Price__c, 'Commission Line Item should have a Sale Price of 20000' );
    System.assertEquals( 10000 - ( lr.Hourly_Rate__c * riggingTime ), cli.Profit__c );
    System.assertEquals( 0.10, cli.Commission_Rate__c );
    System.assertEquals( 0.10 * (10000 - ( lr.Hourly_Rate__c * riggingTime )), cli.Payment_Amount__c );
  }
}