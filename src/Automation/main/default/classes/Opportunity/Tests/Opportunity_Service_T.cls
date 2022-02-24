@isTest
public class Opportunity_Service_T {
  @testSetup
  static void dataSetup() {
    TA_Opportunity_TestHelper.dataSetup();
  }
  @isTest
  static void taxUpdate_Test() {
    TA_Opportunity_TestHelper.init();
    Account personAccount = AccountFactory.insertPersonAccount();
    AcctSeed__Accounting_Variable__c quebecTaxZone = AcctSeed_Settings_Factory.createTaxZone('Quebec', false, 9.975);
    AcctSeed__Accounting_Variable__c othersTaxZone = AcctSeed_Settings_Factory.createTaxZone('Others', false, 0);
    Decimal defaultFedTaxRate = Legend_Settings__c.getOrgDefaults().FederalTaxRate__c;

    System.runAs(TA_Opportunity_TestHelper.whitefishUser) {
      TA_Opportunity_TestHelper.opp = OpportunityFactory.buildBasicRetail(personAccount.id);
      insert TA_Opportunity_TestHelper.opp;
      //Set new tax zone
      Opportunity oppOld = new Opportunity();
      oppOld = TA_Opportunity_TestHelper.getOldList()[0];
      List<Opportunity> oldlist = new List<Opportunity>{ oppOld };
      TA_Opportunity_TestHelper.opp.GL_Account_Variable_3__c = quebecTaxZone.Id;
      TA_Opportunity_TestHelper.opp.Probability = 1;
      update TA_Opportunity_TestHelper.opp;
      new TA_Opportunity_UpdateTax_BU().beforeUpdate(new List<Opportunity>{ TA_Opportunity_TestHelper.opp }, oldlist);

      System.assertEquals(quebecTaxZone.Id, TA_Opportunity_TestHelper.opp.GL_Account_Variable_3__c);
      System.assertEquals(defaultFedTaxRate, TA_Opportunity_TestHelper.opp.Tax_Rate_Federal__c);
      System.assertEquals(false, TA_Opportunity_TestHelper.opp.Tax_Override__c);

      //Override tax rates
      TA_Opportunity_TestHelper.opp.Tax_Override__c = true;
      TA_Opportunity_TestHelper.opp.Tax_Rate_Provincial__c = 1;
      TA_Opportunity_TestHelper.opp.Tax_Rate_Federal__c = 1;
      update TA_Opportunity_TestHelper.opp;
      TA_Opportunity_TestHelper.opp = [
        SELECT
          Id,
          GL_Account_Variable_3__c,
          Tax_is_Harmonized__c,
          Tax_Override__c,
          Tax_Rate_Provincial__c,
          Tax_Rate_Federal__c,
          Probability
        FROM Opportunity
        WHERE Id = :TA_Opportunity_TestHelper.opp.Id
      ];
      System.assertEquals(true, TA_Opportunity_TestHelper.opp.Tax_Override__c);
      System.assertEquals(quebecTaxZone.Id, TA_Opportunity_TestHelper.opp.GL_Account_Variable_3__c);
      System.assertEquals(1, TA_Opportunity_TestHelper.opp.Tax_Rate_Federal__c);

      //delete the taxZone
      TA_Opportunity_TestHelper.opp.Tax_Override__c = false;
      TA_Opportunity_TestHelper.opp.GL_Account_Variable_3__c = null;
      TA_Opportunity_TestHelper.opp.Probability = null;
      TA_Opportunity_TestHelper.opp.Pickup_Location__c = null;
      update TA_Opportunity_TestHelper.opp;
      new TA_Opportunity_UpdateTax_BU().beforeUpdate(new List<Opportunity>{ TA_Opportunity_TestHelper.opp }, oldlist);
      System.assertEquals(false, TA_Opportunity_TestHelper.opp.Tax_Override__c);
      System.assertEquals(defaultFedTaxRate, TA_Opportunity_TestHelper.opp.Tax_Rate_Federal__c);
    }
  }

  @isTest
  static void setPrimaryConInfo_Test() {
    TA_Opportunity_TestHelper.init();
    Test.startTest();
    Account personAccount = AccountFactory.insertPersonAccount();
    Decimal defaultFedTaxRate = Legend_Settings__c.getOrgDefaults().FederalTaxRate__c;
    System.runAs(TA_Opportunity_TestHelper.whitefishUser) {
      TA_Opportunity_TestHelper.opp = OpportunityFactory.buildBasicRetail(personAccount.id);
      TA_Opportunity_TestHelper.opp.ownerId = TA_Opportunity_TestHelper.whitefishUser.id;
      insert TA_Opportunity_TestHelper.opp;
      new TA_Opportunity_Before_Insert().beforeInsert(new List<Opportunity>{ TA_Opportunity_TestHelper.opp });
      new TA_Opportunity_setPrimaryContactInfo_AI().afterInsert(new List<Opportunity>{ TA_Opportunity_TestHelper.opp });
      List<OpportunityContactRole> oppContactRole = [
        SELECT id
        FROM OpportunityContactRole
        WHERE OpportunityId = :TA_Opportunity_TestHelper.opp.id
      ];
      System.assert(!oppContactRole.isEmpty());
    }
  }

  @isTest
  static void insertOpp_Test() {
    TA_Opportunity_TestHelper.init();
    Test.startTest();
    Account personAccount = AccountFactory.insertPersonAccount();
    Opportunity opp2;
    Decimal defaultFedTaxRate = Legend_Settings__c.getOrgDefaults().FederalTaxRate__c;
    System.runAs(TA_Opportunity_TestHelper.whitefishUser) {
      TA_Opportunity_TestHelper.opp = OpportunityFactory.buildBasicRetail(personAccount.id);
      TA_Opportunity_TestHelper.opp.ownerId = TA_Opportunity_TestHelper.whitefishUser.id;
      insert TA_Opportunity_TestHelper.opp;
      new TA_Opportunity_Before_Insert().beforeInsert(new List<Opportunity>{ TA_Opportunity_TestHelper.opp });
      System.assertEquals(TA_Opportunity_TestHelper.whitefishWarehouse.Id, TA_Opportunity_TestHelper.opp.Warehouse__c);
      System.assertEquals(defaultFedTaxRate, TA_Opportunity_TestHelper.opp.Tax_Rate_Federal__c);
    }
    Test.stopTest();
  }

  @isTest
  static void updateAccountToLegendCustomer_Test() {
    TA_Opportunity_TestHelper.init();
    Account customer = Factory_Account.insertFullPersonAccount('Testy', 'McTesterson');
    Account beforeAcct = [SELECT Id, Type FROM Account WHERE Id = :customer.Id];
    TA_Opportunity_TestHelper.opp = Factory_Opportunity.insertOpportunity(customer, Test.getStandardPricebookId());
    List<Opportunity> oldOpportunities = TA_Opportunity_TestHelper.getOldList();
    Test.startTest();
    TA_Opportunity_TestHelper.opp.Approved__c = true;
    update TA_Opportunity_TestHelper.opp;
    new TA_Opportunity_updateAccountsToCust_AU()
      .afterUpdate(new List<Opportunity>{ TA_Opportunity_TestHelper.opp }, oldOpportunities);
    Test.stopTest();

    Account afterAcct = [SELECT Id, Type FROM Account WHERE Id = :customer.Id];

    System.assert(
      beforeAcct.Type != 'Legend Customer',
      'Account type should not be Legend Customer Pending before Sales manager Approval'
    );
    System.assert(afterAcct.Type == 'Legend Customer', 'Account type should now be Legend Customer');
  }

  @isTest
  static void deleteOpportunityDocuments_Test() {
    TA_Opportunity_TestHelper.init();
    Account personAccount = AccountFactory.insertPersonAccount();
    TA_Opportunity_TestHelper.opp = OpportunityFactory.buildBasicRetail(personAccount.id);
    insert TA_Opportunity_TestHelper.opp;
    TA_Opportunity_TestHelper.opp = [
      SELECT
        Id,
        GL_Account_Variable_3__c,
        Tax_is_Harmonized__c,
        Tax_Override__c,
        Tax_Rate_Provincial__c,
        Tax_Rate_Federal__c,
        Warehouse__c
      FROM Opportunity
      WHERE Id = :TA_Opportunity_TestHelper.opp.Id
    ];
    Opportunity_Document__c document = new Opportunity_Document__c(
      Document_Id__c = '0157h000000clFFABY',
      Name = 'Test',
      Document_Type__c = 'Quote',
      Opportunity__c = TA_Opportunity_TestHelper.opp.id
    );
    insert document;
    new TA_Opportunity_DeleteOppDocuments_AD().afterDelete(new List<Opportunity>{ TA_Opportunity_TestHelper.opp });
    List<Opportunity_Document__c> documents = [
      SELECT id
      FROM Opportunity_Document__c
      WHERE Opportunity__c = :TA_Opportunity_TestHelper.opp.id
    ];
    System.assert(documents.isEmpty());
  }

  @isTest
  static void recalculateInsurance_Test() {
    TA_Opportunity_TestHelper.init();
    Account customer = Factory_Account.insertFullPersonAccount('Testy', 'McTesterson');
    Account beforeAcct = [SELECT Id, Type FROM Account WHERE Id = :customer.Id];
    TA_Opportunity_TestHelper.opp = Factory_Opportunity.insertOpportunity(customer,Test_Constants.idRetailPricebook);
    TA_Opportunity_TestHelper.createOpportunityLineItem();
    List<Opportunity> oldOpportunities = TA_Opportunity_TestHelper.getOldList();
    Test.startTest();
    TA_Opportunity_TestHelper.opp.Finance_Term__c = 7;
    TA_Opportunity_TestHelper.opp.Deposit__c = 1000;
    TA_Opportunity_TestHelper.opp.Finance_Annual_Interest__c = 10;
    TA_Opportunity_TestHelper.opp.Finance_Ammortization__c = 100;
    TA_Opportunity_TestHelper.opp.Insurance_Term__c = 9;
    TA_Opportunity_TestHelper.opp.amount = 100;
    TA_Opportunity_TestHelper.opp.amount = 100;
    TA_Opportunity_TestHelper.opp.Tax_Rate_Federal__c = 10;
    TA_Opportunity_TestHelper.opp.Tax_Rate_Retail__c = 10;
    TA_Opportunity_TestHelper.opp.GL_Account_Variable_3__c = gcConstants.idGlv3Ontario;
//    Trade_In_Record__c trade = new Trade_In_Record__c(
//      Lien_Amount__c = 1000,
//      Opportunity__c = TA_Opportunity_TestHelper.opp.id,
//      Total_Value__c = 10000
//    );
//    insert trade;

    update TA_Opportunity_TestHelper.opp;
    TA_Opportunity_TestHelper.opp = [
      SELECT
        id,
        Pre_Insurance_Total__c,
        Name,
        AccountId,
        Pricebook2Id,
        StageName,
        CloseDate,
        Finance_Term__c,
        Finance_Annual_Interest__c,
        Finance_Ammortization__c,
        Insurance_Term__c,
        Amount,
        Tax_Rate_Federal__c,
        Tax_Rate_Retail__c,
        TotalTaxes__c,
        Tax_Amount_Federal__c,
        Tax_Amount_Provincial__c,
        Tax_Amount_Retail__c,
        Insurance_Total__c,
        Trade_In_Value__c,
        Trade_In_Lien__c,
        Deposit__c,
        GL_Account_Variable_3__c
      FROM Opportunity
      WHERE id = :TA_Opportunity_TestHelper.opp.id
    ];
    new TA_Opportunity_RecalcInsuranceLines_AU()
      .afterUpdate(new List<Opportunity>{ TA_Opportunity_TestHelper.opp }, oldOpportunities);
    System.assertEquals(TA_Opportunity_TestHelper.opp.Insurance_Term__c, 9);
    System.assertEquals(TA_Opportunity_TestHelper.opp.Finance_Annual_Interest__c, 10);
    Test.stopTest();
  }
}
