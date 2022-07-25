@isTest
public class TA_Opportunity_RecalcInsuranceLines_AU_T {
  @testSetup
  static void dataSetup() {
    TA_Opportunity_TestHelper.dataSetup();
  }

  @isTest
  static void recalculateInsurance_Test() {
    TA_Opportunity_TestHelper.init();
    Account customer = Factory_Account.insertFullPersonAccount('Testy', 'McTesterson');
    Account beforeAcct = [SELECT Id, Type FROM Account WHERE Id = :customer.Id];
    TA_Opportunity_TestHelper.opp = Factory_Opportunity.insertOpportunity(customer, Test_Constants.idRetailPricebook);
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
