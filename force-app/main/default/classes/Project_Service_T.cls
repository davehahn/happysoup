/**
 * Created by dave on 2020-01-21.
 */

@IsTest
private class Project_Service_T
{

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    buildOpp();
  }

  private static void buildOpp()
  {
    Account customer = Factory_Account.buildFullPersonAccount('TestF', 'TestL');
    insert customer;
    Factory_Opportunity.insertOpportunityForBoatSale( LGND_Constants.retailPricebookId, customer );
  }

  private static void addBusinessOfficeItems( Opportunity opp )
  {
    InsurancePlan__c plan =  new InsurancePlan__c(
      Name = 'Insurance Plan One',
      Profit_Percent__c = 50
    );
    insert plan;
    Set<Id> prodIds = new Set<Id>();
    prodIds.add( Factory_Product.createInsuranceProduct(
      'Life Insurance Coverage',
      'Life (One)',
      plan.Id,
      false,
      LGND_Constants.retailPricebookId ).Id );
    prodIds.add( Factory_Product.createInsuranceProduct(
      'Life Insurance Coverage',
      'Life (Two)',
      plan.Id,
      false,
      LGND_Constants.retailPricebookId ).Id );
    Product2 warranty = Factory_Product.buildNonSerializedProduct('Part', 'Extended Warranty');
    insert warranty;
    prodIds.add( warranty.Id );
    Factory_PricebookEntry.createStandardEntry( warranty.Id, 100);
    Factory_PricebookEntry.createStandardEntryInPricebook( warranty.Id, opp.Pricebook2Id, 100);

    List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
    for( PricebookEntry pbe : [SELECT Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id = :opp.Pricebook2Id AND Product2Id IN :prodIds ] )
    {
      OpportunityLineItem oli =  Factory_OpportunityLineItem.buildLineItem(
        pbe.Id,
        opp.Id,
        1000,
        1,
        null
      );
      if( pbe.Product2Id != warranty.Id )
      {
        oli.Insurance_Rate__c = 6;
        oli.InsuranceCoverage__c = 'Single';
      }
      olis.add(oli);
    }
    insert olis;
  }

  @IsTest
  static void newFromOpportunityId_SimpleTest()
  {
    Opportunity opp = [SELECT Id, Pricebook2Id FROM Opportunity LIMIT 1];
    Test.startTest();
    AcctSeed__Project__c project = Project_Service.newFromOpportunityId( opp.Id );
    Test.stopTest();
    checkResults( project.Id, 2, 9, 0 );
  }

  @IsTest
  static void newFromOpportunityId_wTradeInTest()
  {
    Opportunity opp = [SELECT Id, Pricebook2Id FROM Opportunity LIMIT 1];
    Factory_TradeIn.insertTradeInRecordWithItems( opp.Id, 3 );
    Test.startTest();
    AcctSeed__Project__c project = Project_Service.newFromOpportunityId( opp.Id );
    Test.stopTest();
    checkResults( project.Id, 2, 11, 0 );
  }

  @IsTest
  static void newFromOpportunityId_wInsuranceTest()
  {
    Opportunity opp = [SELECT Id, Pricebook2Id FROM Opportunity LIMIT 1];
    addBusinessOfficeItems( opp );
    Test.startTest();
    AcctSeed__Project__c project = Project_Service.newFromOpportunityId( opp.Id );
    Test.stopTest();
    checkResults( project.Id, 2, 9, 3 );
  }

  private static void checkResults( Id projectId,
                                    Integer taskSize,
                                    Integer retailSaleMatSize,
                                    Integer businessOfficeMatSize )
  {
    List<AcctSeed__Project_Task__c> tasks = [SELECT Id, Name FROM AcctSeed__Project_Task__c WHERE AcctSeed__Project__c = :projectId];
    AcctSeed__Project_Task__c retailSale;
    AcctSeed__Project_Task__c businessOffice;
    for( AcctSeed__Project_Task__c pt : tasks )
    {
      if( pt.Name.contains('Retail Sale') )
        retailSale = pt;
      if( pt.Name.contains('Business Office') )
        businessOffice = pt;
    }
    System.debug( businessOffice );
    for( AcctSeedERP__Material__c m :  [SELECT Id, AcctSeedERP__Project_Task__r.Name FROM AcctSeedERP__Material__c WHERE AcctSeedERP__Project__c = :projectId] )
    {
      System.debug( m.AcctSeedERP__Project_Task__r.Name );
    }
    List<AcctSeedERP__Material__c> retailMaterials = [ SELECT Id FROM AcctSeedERP__Material__c WHERE AcctSeedERP__Project_Task__c = :retailSale.Id ];
    List<AcctSeedERP__Material__c> boMaterials = [ SELECT Id FROM AcctSeedERP__Material__c WHERE AcctSeedERP__Project_Task__c = :businessOffice.Id ];

    System.assertEquals( taskSize, tasks.size(), 'There should be 2 Project Tasks' );
    System.assertEquals( retailSaleMatSize, retailMaterials.size(), 'There should be 9 Retail Sales materials' );
    System.assertEquals( businessOfficeMatSize, boMaterials.size(), 'There should be 2 Business Office materials' );
  }
}