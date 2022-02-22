@isTest
public class TA_Opportunity_UpdateTax_BU_T {

    @testSetup static void dataSetup()
    {
        TA_Opportunity_TestHelper.dataSetup();
    }

    @isTest
    static void taxUpdate_Test()
    {
        TA_Opportunity_TestHelper.init();
        Account personAccount = AccountFactory.insertPersonAccount();
        AcctSeed__Accounting_Variable__c quebecTaxZone = AcctSeed_Settings_Factory.createTaxZone('Quebec', false, 9.975);
        AcctSeed__Accounting_Variable__c othersTaxZone = AcctSeed_Settings_Factory.createTaxZone('Others', false, 0);
        Decimal defaultFedTaxRate = Legend_Settings__c.getOrgDefaults().FederalTaxRate__c;

        System.runAs(TA_Opportunity_TestHelper.whitefishUser)
        {
            TA_Opportunity_TestHelper.opp = OpportunityFactory.buildBasicRetail( personAccount.id );
            insert TA_Opportunity_TestHelper.opp;
            //Set new tax zone
            Opportunity oppOld = new   Opportunity();
            oppOld = TA_Opportunity_TestHelper.getOldList()[0];
            List<Opportunity> oldlist = new List<Opportunity>{oppOld};
            TA_Opportunity_TestHelper.opp.GL_Account_Variable_3__c = quebecTaxZone.Id;
            TA_Opportunity_TestHelper.opp.Probability = 1;
            update TA_Opportunity_TestHelper.opp;
            new TA_Opportunity_UpdateTax_BU().beforeUpdate(new List<Opportunity>{TA_Opportunity_TestHelper.opp},oldlist);
             
            System.assertEquals( quebecTaxZone.Id, TA_Opportunity_TestHelper.opp.GL_Account_Variable_3__c );
            System.assertEquals( defaultFedTaxRate, TA_Opportunity_TestHelper.opp.Tax_Rate_Federal__c );
            System.assertEquals( false, TA_Opportunity_TestHelper.opp.Tax_Override__c);

            //Override tax rates
            TA_Opportunity_TestHelper.opp.Tax_Override__c = true;
            TA_Opportunity_TestHelper.opp.Tax_Rate_Provincial__c = 1;
            TA_Opportunity_TestHelper.opp.Tax_Rate_Federal__c = 1;
            update TA_Opportunity_TestHelper.opp;
            TA_Opportunity_TestHelper.opp = [SELECT Id,
                    GL_Account_Variable_3__c,
                    Tax_is_Harmonized__c,
                    Tax_Override__c,
                    Tax_Rate_Provincial__c,
                    Tax_Rate_Federal__c,
                    Probability 
            FROM Opportunity
            WHERE Id = :TA_Opportunity_TestHelper.opp.Id];
            System.assertEquals( true, TA_Opportunity_TestHelper.opp.Tax_Override__c);
            System.assertEquals( quebecTaxZone.Id, TA_Opportunity_TestHelper.opp.GL_Account_Variable_3__c );
            System.assertEquals( 1, TA_Opportunity_TestHelper.opp.Tax_Rate_Federal__c );

            //delete the taxZone
            TA_Opportunity_TestHelper.opp.Tax_Override__c = false;
            TA_Opportunity_TestHelper.opp.GL_Account_Variable_3__c = null;
            TA_Opportunity_TestHelper.opp.Probability = null;
            TA_Opportunity_TestHelper.opp.Pickup_Location__c = null;
            update TA_Opportunity_TestHelper.opp;
            new TA_Opportunity_UpdateTax_BU().beforeUpdate(new List<Opportunity>{TA_Opportunity_TestHelper.opp},oldlist);
			System.assertEquals( false, TA_Opportunity_TestHelper.opp.Tax_Override__c);
            System.assertEquals( defaultFedTaxRate, TA_Opportunity_TestHelper.opp.Tax_Rate_Federal__c );
        }
    }
}