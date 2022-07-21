@isTest
public class TA_OpportunityLine_TestHelper {
  public static List<OpportunityLineItem> olis;
  @testSetup
  public static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }
  public static void init() {
    init(null);
  }
  public static void init(String productRecordType) {
    Account customer = Factory_Account.buildFullPersonAccount('TestF', 'TestL');
    insert customer;
    Factory_Opportunity.insertOpportunityForBoatSale(LGND_Constants.retailPricebookId, customer);
    Opportunity opp = [SELECT Id, Pricebook2Id FROM Opportunity LIMIT 1];
    opp.Finance_Term__c = 7;
    opp.Deposit__c = 1000;
    opp.Finance_Annual_Interest__c = 10;
    opp.Finance_Ammortization__c = 100;
    opp.Insurance_Term__c = 9;
    opp.amount = 100;
    opp.Deposit__c = 50;
    opp.Tax_Rate_Federal__c = 10;
    opp.Tax_Rate_Retail__c = 10;
    opp.GL_Account_Variable_3__c = gcConstants.idGlv3Ontario;
    Trade_In_Record__c trade = new Trade_In_Record__c(
      Lien_Amount__c = 1000,
      Opportunity__c = opp.id,
      Total_Value__c = 10000
    );
    insert trade;

    update opp;
    opp = [
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
        GL_Account_Variable_3__c,
        Calculate_Insurance_Amount__c
      FROM Opportunity
      WHERE id = :opp.id
    ];

    InsurancePlan__c plan = new InsurancePlan__c(Name = 'Insurance Plan One', Profit_Percent__c = 50);
    insert plan;
    Set<Id> prodIds = new Set<Id>();
    prodIds.add(
      Factory_Product.createInsuranceProduct(
          'Life Insurance Coverage',
          'Life (One)',
          plan.Id,
          false,
          LGND_Constants.retailPricebookId
        )
        .Id
    );
    prodIds.add(
      Factory_Product.createInsuranceProduct(
          'Life Insurance Coverage',
          'Life (Two)',
          plan.Id,
          false,
          LGND_Constants.retailPricebookId
        )
        .Id
    );
    Product2 warranty;
    Product2 boat;
    if (productRecordType != null && productRecordType.endsWithIgnoreCase('Boat')) {
      boat = Factory_Product.buildNonSerializedProduct('Boat', 'Extended Warranty');
      insert boat;
      prodIds.add(boat.Id);
      Factory_PricebookEntry.createStandardEntry(boat.Id, 100);
      Factory_PricebookEntry.createStandardEntryInPricebook(boat.Id, opp.Pricebook2Id, 100);
    } else {
      warranty = Factory_Product.buildNonSerializedProduct('Part', 'Extended Warranty');
      insert warranty;
      prodIds.add(warranty.Id);
      Factory_PricebookEntry.createStandardEntry(warranty.Id, 100);
      Factory_PricebookEntry.createStandardEntryInPricebook(warranty.Id, opp.Pricebook2Id, 100);
    }

    Insurance_Rate__c insuranceRate = new Insurance_Rate__c(
      Dump_Id__c = '111111',
      Joint__c = 1,
      Joint_Factor__c = 10,
      Product__c = warranty != null ? warranty.id : boat.id,
      Lower_Term__c = 5,
      Lower_Finance_Term__c = 5,
      Single__c = 3,
      Upper_Finance_Term__c = 10,
      Upper_Term__c = 10,
      Tax_Zone__c = gcConstants.idGlv3Ontario
    );
    insert insuranceRate;

    olis = new List<OpportunityLineItem>();
    for (PricebookEntry pbe : [
      SELECT Id, Product2Id
      FROM PricebookEntry
      WHERE Pricebook2Id = :opp.Pricebook2Id AND Product2Id IN :prodIds
    ]) {
      OpportunityLineItem oli = Factory_OpportunityLineItem.buildLineItem(pbe.Id, opp.Id, 1000, 1, null);
      if ((warranty != null && pbe.Product2Id != warranty.Id) || (boat != null && pbe.Product2Id != boat.Id)) {
        oli.Insurance_Rate__c = 6;
        oli.InsuranceCoverage__c = 'Single';
      }
      oli.IsInsurance__c = true;
      oli.Insurance_Rate__c = 10;
      oli.InsuranceCoverage__c = 'Joint';
      //oli.Opp_Calculate_Insurance_Amount__c=2332;

      olis.add(oli);
    }
    insert olis;
    olis = [
      SELECT
        id,
        UnitPrice,
        Quantity,
        ParentProductId__c,
        PricebookEntryId,
        Opp_Tax_Zone__c,
        Insurance_Term__c,
        Finance_Term__c,
        OpportunityId,
        Product2Id,
        Insurance_Rate__c,
        InsuranceCoverage__c,
        IsInsurance__c,
        Opp_Calculate_Insurance_Amount__c
      FROM OpportunityLineItem
    ];
  }

  public static List<OpportunityLineItem> getOldList() {
    OpportunityLineItem c = olis[0].clone(true, true, true, true);
    return new List<OpportunityLineItem>{ c };
  }
}
