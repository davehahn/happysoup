@isTest
public class TA_Opportunity_DeleteOppDocuments_AD_T {
     @testSetup static void dataSetup()
    {
        TA_Opportunity_TestHelper.dataSetup();
    }
    @isTest
	static void deleteOpportunityDocuments_Test()
  {
     TA_Opportunity_TestHelper.init();
     Account personAccount = AccountFactory.insertPersonAccount();
     TA_Opportunity_TestHelper.opp = OpportunityFactory.buildBasicRetail( personAccount.id );
     insert TA_Opportunity_TestHelper.opp;
     TA_Opportunity_TestHelper.opp = [SELECT Id,
                                       GL_Account_Variable_3__c,
                                       Tax_is_Harmonized__c,
                                       Tax_Override__c,
                                       Tax_Rate_Provincial__c,
                                       Tax_Rate_Federal__c,
                                       Warehouse__c
                                       FROM Opportunity
                                       WHERE Id = :TA_Opportunity_TestHelper.opp.Id]; 
     Opportunity_Document__c document = new Opportunity_Document__c(Document_Id__c = '0157h000000clFFABY',
                                                            Name = 'Test',
                                                             Document_Type__c = 'Quote',
                                                            Opportunity__c= TA_Opportunity_TestHelper.opp.id
                                                            );
     insert document; 
     new TA_Opportunity_DeleteOppDocuments_AD().afterDelete(new List<Opportunity>{TA_Opportunity_TestHelper.opp }); 
     List<Opportunity_Document__c>documents = [select id from Opportunity_Document__c where Opportunity__c = :TA_Opportunity_TestHelper.opp.id ]; 
  	 System.assert(documents.isEmpty())	;
  }

}