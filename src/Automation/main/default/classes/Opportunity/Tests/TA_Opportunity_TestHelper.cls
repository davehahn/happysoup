/**
 * Created by dhavalmacbook on 30/01/22.
 */
@isTest
public with sharing class TA_Opportunity_TestHelper {

    public static User whitefishUser;
    public static User blankUser;
    public static AcctSeedERP__Warehouse__c whitefishWarehouse;
    public static Opportunity opp;

    @testSetup
    public static void dataSetup()
    {
        new Factory_TestData();
        Factory_CustomSettings.setupInventorySettings();
    }
    public static void init() {
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
    public static void createOpportunityLineItem(){
    List<OpportunityLineItem>olis = new List<OpportunityLineItem>();
    Trade_In_Record__c trade = new Trade_In_Record__c(Lien_Amount__c=1000,Opportunity__c=opp.id,Total_Value__c=10000);    
    insert trade;
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
    Product2 warranty = Factory_Product.buildNonSerializedProduct('Part', 'Extended Warranty');
            insert warranty;
            prodIds.add( warranty.Id );
            Factory_PricebookEntry.createStandardEntry( warranty.Id, 100);
        
    		Insurance_Rate__c insuranceRate = new Insurance_Rate__c(Dump_Id__c='111111',
                                                           Joint__c=1,
                                                           Joint_Factor__c=10,
                                                           Product__c =warranty.id,
                                                           Lower_Term__c=5,
                                                           Lower_Finance_Term__c=5,
                                                           Single__c=3,
                                                           Upper_Finance_Term__c=10,
                                                           Upper_Term__c=10,
                                                           Tax_Zone__c = gcConstants.idGlv3Ontario);
        insert insuranceRate;
        
    		//Factory_PricebookEntry.createStandardEntryInPricebook( warranty.Id, opp.Pricebook2Id, 100);
    for( PricebookEntry pbe : [SELECT Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id = :opp.Pricebook2Id AND Product2Id IN :prodIds ] )
    {
      OpportunityLineItem oli =  Factory_OpportunityLineItem.buildLineItem(
        pbe.Id,
        opp.Id,
        1000,
        1,
        null
      );
      oli.IsInsurance__c=true;
      oli.Insurance_Rate__c =10;
      oli.InsuranceCoverage__c = 'Joint';
      olis.add(oli);
    }
    insert olis;
    
    }

    public static List<Opportunity> getOldList() {
        Opportunity c = opp.clone(true, true, true, true);
        return new List<Opportunity>{ c };
    }
}