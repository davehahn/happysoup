@isTest
private class OpportunityTrigger_Test {

  static User whitefishUser;
  static User blankUser;
  static AcctSeedERP__Warehouse__c whitefishWarehouse;

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void init() {
    whitefishWarehouse = [SELECT Id,
                                 Name,
                                 GL_Account_Variable_3__c,
                                 GL_Account_Variable_3__r.Name,
                                 GL_Account_Variable_3__r.Tax_is_Harmonized__c,
                                 GL_Account_Variable_3__r.Tax_Rate_Provincial__c
                          FROM AcctSeedERP__Warehouse__c
                          WHERE Name = 'Whitefish'
                          LIMIT 1];
    User[] users = new List<User>();
    whitefishUser = Factory_User.newUser('whitefish', 'mcTesterson', 'System Administrator', whitefishWarehouse );
    blankUser = User_TestFactory.newUser( 'Jjjjjj', 'Hhhhh', 'System Administrator' );
    users.add( whitefishUser );
    users.add( blankUser );
    insert users;
  }

  @isTest
  static void coverage_Test()
  {
    OpportunityTriggerHandler.coverage();
  }

  @isTest
  static void retailWarehouseTaxSetup_Test()
  {
    init();
    Test.startTest();

    Account personAccount = AccountFactory.insertPersonAccount();
    Opportunity opp1;
    Opportunity opp2;
    Decimal defaultFedTaxRate = Legend_Settings__c.getOrgDefaults().FederalTaxRate__c;

    System.runAs(whitefishUser)
    {
      opp1 = OpportunityFactory.buildBasicRetail( personAccount.id );
      insert opp1;
      opp1 = [SELECT Id,
                    GL_Account_Variable_3__c,
                    Tax_is_Harmonized__c,
                    Tax_Override__c,
                    Tax_Rate_Provincial__c,
                    Tax_Rate_Federal__c,
                    Warehouse__c
             FROM Opportunity
             WHERE Id = :opp1.Id];
    }

    System.runAs(blankUser)
    {
      opp2 = OpportunityFactory.buildBasicRetail( personAccount.id );
      insert opp2;

      opp2 = [SELECT Id,
                    GL_Account_Variable_3__c,
                    Tax_is_Harmonized__c,
                    Tax_Override__c,
                    Tax_Rate_Provincial__c,
                    Tax_Rate_Federal__c,
                    Warehouse__c
             FROM Opportunity
             WHERE Id = :opp2.Id];
    }

    Test.stopTest();

    System.assertEquals( whitefishWarehouse.Id, opp1.Warehouse__c );
    //System.assertEquals( wh1.GL_Account_Variable_3__c, opp1.GL_Account_Variable_3__c);
    //System.assertEquals( wh1.GL_Account_Variable_3__r.Tax_is_Harmonized__c, opp1.Tax_is_Harmonized__c );
    //System.assertEquals( wh1.GL_Account_Variable_3__r.Tax_Rate_Provincial__c, opp1.Tax_Rate_Provincial__c );
    System.assertEquals( defaultFedTaxRate, opp1.Tax_Rate_Federal__c);

    System.assertEquals( whitefishWarehouse.Id, opp2.Warehouse__c );
    //System.assertEquals( wh2.GL_Account_Variable_3__c, opp2.GL_Account_Variable_3__c);
    //System.assertEquals( wh2.GL_Account_Variable_3__r.Tax_is_Harmonized__c, opp2.Tax_is_Harmonized__c );
    //System.assertEquals( wh2.GL_Account_Variable_3__r.Tax_Rate_Provincial__c, opp2.Tax_Rate_Provincial__c );
    System.assertEquals( defaultFedTaxRate, opp2.Tax_Rate_Federal__c);
  }

  @isTest
  static void taxUpdate_Test()
  {
    init();
    Account personAccount = AccountFactory.insertPersonAccount();
    Opportunity opp;
    AcctSeed__Accounting_Variable__c quebecTaxZone = AcctSeed_Settings_Factory.createTaxZone('Quebec', false, 9.975);
    AcctSeed__Accounting_Variable__c othersTaxZone = AcctSeed_Settings_Factory.createTaxZone('Others', false, 0);
    Decimal defaultFedTaxRate = Legend_Settings__c.getOrgDefaults().FederalTaxRate__c;

    System.runAs(whitefishUser)
    {
      opp = OpportunityFactory.buildBasicRetail( personAccount.id );
      insert opp;
      //Set new tax zone
      opp.GL_Account_Variable_3__c = quebecTaxZone.Id;
      update opp;
      opp = [SELECT Id,
                    GL_Account_Variable_3__c,
                    Tax_is_Harmonized__c,
                    Tax_Override__c,
                    Tax_Rate_Provincial__c,
                    Tax_Rate_Federal__c
            FROM Opportunity
            WHERE Id = :opp.Id];
      System.assertEquals( quebecTaxZone.Id, opp.GL_Account_Variable_3__c );
      //System.assertEquals( quebecTaxZone.Tax_is_Harmonized__c, opp.Tax_is_Harmonized__c );
      //System.assertEquals( quebecTaxZone.Tax_Rate_Provincial__c, opp.Tax_Rate_Provincial__c );
      System.assertEquals( defaultFedTaxRate, opp.Tax_Rate_Federal__c );
      System.assertEquals( false, opp.Tax_Override__c);

      //Override tax rates
      opp.Tax_Override__c = true;
      opp.Tax_Rate_Provincial__c = 1;
      opp.Tax_Rate_Federal__c = 1;
      update opp;
      opp = [SELECT Id,
                    GL_Account_Variable_3__c,
                    Tax_is_Harmonized__c,
                    Tax_Override__c,
                    Tax_Rate_Provincial__c,
                    Tax_Rate_Federal__c
            FROM Opportunity
            WHERE Id = :opp.Id];
      System.assertEquals( true, opp.Tax_Override__c);
      System.assertEquals( quebecTaxZone.Id, opp.GL_Account_Variable_3__c );
      //System.assertEquals( quebecTaxZone.Tax_is_Harmonized__c, opp.Tax_is_Harmonized__c );
      //System.assertEquals( 1, opp.Tax_Rate_Provincial__c );
      System.assertEquals( 1, opp.Tax_Rate_Federal__c );

      //delete the taxZone
      opp.Tax_Override__c = false;
      opp.GL_Account_Variable_3__c = null;
      update opp;
      opp = [SELECT Id,
                    GL_Account_Variable_3__c,
                    Tax_is_Harmonized__c,
                    Tax_Override__c,
                    Tax_Rate_Provincial__c,
                    Tax_Rate_Federal__c
            FROM Opportunity
            WHERE Id = :opp.Id];
      System.assertEquals( false, opp.Tax_Override__c);
     // System.assertEquals( wh.GL_Account_Variable_3__c, opp.GL_Account_Variable_3__c );
      //System.assertEquals( wh.GL_Account_Variable_3__r.Tax_is_Harmonized__c, opp.Tax_is_Harmonized__c );
      //System.assertEquals( wh.GL_Account_Variable_3__r.Tax_Rate_Provincial__c, opp.Tax_Rate_Provincial__c );
      System.assertEquals( defaultFedTaxRate, opp.Tax_Rate_Federal__c );
    }
  }

  @IsTest
  static void updateAccountToLegendCustomer_Test()
  {
    Account customer = Factory_Account.insertFullPersonAccount('Testy', 'McTesterson');
    Account beforeAcct = [SELECT Id, Type FROM Account WHERE Id = :customer.Id];
    Opportunity opp = Factory_Opportunity.insertOpportunity( customer, Test.getStandardPricebookId() );

    Test.startTest();
    opp.Approved__c = true;
    update opp;
    Test.stopTest();

    Account afterAcct = [SELECT Id, Type FROM Account WHERE Id = :customer.Id];

    System.assert( beforeAcct.Type != 'Legend Customer', 'Account type should not be Legend Customer Pending before Sales manager Approval' );
    System.assert( afterAcct.Type == 'Legend Customer', 'Account type should now be Legend Customer');
  }

}