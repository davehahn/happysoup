/**
 * Created by dhavalmacbook on 27/01/22.
 */

public inherited sharing class  TA_Opportunity_RecalcInsuranceLines_AU implements TriggerAction.AfterUpdate{

    public void afterUpdate(List<Opportunity> newList, List<Opportunity> oldList) {

        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity> (oldList);
        Map<Id, Map<String, String>> preInsuranceChanged = new Map<Id, Map<String, String>>();
       // Set<Id> nowCustomerAccountIds = new Set<Id>();
        for( Opportunity opp : newList )
        {
            Opportunity oOpp = oldMap.get( opp.Id );
            if(
                    ( opp.Pre_Insurance_Total__c != oOpp.Pre_Insurance_Total__c ) ||
                            ( opp.Finance_Term__c != oOpp.Finance_Term__c ) ||
                            ( opp.Deposit__c != oOpp.Deposit__c ) ||
                            ( opp.Finance_Annual_Interest__c != oOpp.Finance_Annual_Interest__c ) ||
                            ( opp.Finance_Ammortization__c != oOpp.Finance_Ammortization__c ) ||
                            ( opp.Insurance_Term__c != oOpp.Insurance_Term__c )
                    )
            {
                System.debug('here opp= '+opp);
                System.debug('opp.Trade_In_Value__c= '+opp.Trade_In_Value__c);
                    System.debug('opp.Pre_Insurance_Total__c= '+opp.Pre_Insurance_Total__c);
                Map<String, String> data = new Map<String, String>();
                data.put('amount', String.ValueOf( opp.Pre_Insurance_Total__c) );
                data.put('deposit', opp.Deposit__c == null ? '0' : String.ValueOf( opp.Deposit__c) );
                data.put('finTerm', String.ValueOf( opp.Finance_Term__c) );
                data.put('amort', String.ValueOf( opp.Finance_Ammortization__c) );
                data.put('insTerm', String.ValueOf( opp.Insurance_Term__c) );
                data.put('intrestRate', String.ValueOf( opp.Finance_Annual_Interest__c) );
                data.put('taxZone', opp.GL_Account_Variable_3__c );
                data.put('insuranceTaxRate', String.ValueOf( opp.Tax_Rate_Retail__c ) );
                data.put('termChanged', (opp.Finance_Term__c != oOpp.Finance_Term__c || opp.Insurance_Term__c != oOpp.Insurance_Term__c) ? 'true' : 'false');
                preInsuranceChanged.put( opp.Id, data );
            }
//            if( opp.Approved__c  && !oOpp.Approved__c )
//            {
//                nowCustomerAccountIds.add( opp.AccountId );
//            }
        }
        if( preInsuranceChanged.size() > 0 )
        {
            Opportunity_Service.recalcInsuranceLines(preInsuranceChanged);
        }
//        if( nowCustomerAccountIds.size() > 0 )
//        {
//            updateAccountsToCustomers( nowCustomerAccountIds );
//        }
    }
}