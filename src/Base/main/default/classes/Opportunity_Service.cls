/**
 * Created by dhavalmacbook on 27/01/22.
 */

public  class Opportunity_Service {
    public static Map<String, LGND_Utilities.ProvincialTax> provincialTaxInfo;
    public static Decimal fedTaxRate;
    public static Map<Id, LGND_Utilities.ProvincialTax> provincialTaxMapById;
    public static Boolean disableAutoPricebookSet{
        get{
            if(disableAutoPricebookSet == null) return false;
            else return disableAutoPricebookSet;
        }
        set{
            if(value == null) disableAutoPricebookSet = false;
            else disableAutoPricebookSet = value;
        }
    }
    public static Boolean disableRecalcLineItems {
        get{
            if(disableRecalcLineItems == null) return false;
            else return disableRecalcLineItems;
        }
        set{
            if(value == null) disableRecalcLineItems = false;
            else disableRecalcLineItems = value;
        }
    }

    public static Boolean disableTrigger {
        get{
            if(disableTrigger == null) return false;
            else return disableTrigger;
        }
        set{
            if(value == null) disableTrigger = false;
            else disableTrigger = value;
        }
    }

	
    private static Map<String, String> warehouseProvinceMap = new Map<String, String>{
            'Barrie' => 'Ontario',
            'Montreal' => 'Quebec',
            'Whitefish' => 'Ontario'
    };

    private static void assignValues(){
            if( provincialTaxInfo == null)
                provincialTaxInfo = LGND_Utilities.fetchProvincialTaxInfo(); 
            if (fedTaxRate == null)
                fedTaxRate = Legend_Settings__c.getOrgDefaults().FederalTaxRate__c;
            if( provincialTaxMapById == null )
            {
                provincialTaxMapById = new Map<Id, LGND_Utilities.ProvincialTax>();
                for( LGND_Utilities.ProvincialTax pt : provincialTaxInfo.values() )
                {
                    provincialTaxMapById.put( pt.id, pt );
                }
            }
            
        } 
    public static void updateAccountsToCustomers( Set<Id> acctIds )
    {
        assignValues();
        List<Account> accts = [
                SELECT
                        Id,
                        Type
                FROM Account
                WHERE Id = :acctIds
        ];
        List<Account> toUpdate = new List<Account>();
        for( Account acct : accts )
        {
            if( acct.Type != 'Legend Customer' )
            {
                acct.Type = 'Legend Customer';
                toUpdate.add( acct );
            }
        }
        update toUpdate;
    }

    private static Set<Id> findQuebecAccts( Opportunity[] opps )
    {
       
        Set<Id> allAcctIds = new Set<Id>();
        for( Opportunity o : opps )
        {
            allAcctIds.add( o.AccountId );
        }
        Map<Id, Account> quebecs = new Map<Id, Account>([ SELECT Id
        FROM Account
        WHERE Id IN :allAcctIds
        AND BillingState = 'Quebec'] );
        return quebecs.keySet();
    }

    public static void setTaxes(Opportunity opp, Account acct, User owner)
    {
        assignValues();
        LGND_Utilities.ProvincialTax activeTaxZone;
        //Throw an exception if we do not have at least the tax zone for Ontario setup
        LGND_Utilities.ProvincialTax defaultTaxZone;
        try {
            defaultTaxZone = provincialTaxInfo.get('Ontario');
        }
        catch(Exception e) {
            throw new LGND_Utilities.LGND_Exception('Accounting Variable 3 (Tax Zone) does not appear to be setup correctly.  Please setup a Taxzone for at least Ontario');
        }
        /* for all Record Types we will try to derermine the tax Zone by the Account billing State */
        if( acct != null && provincialTaxInfo.containsKey( acct.BillingState ) )
        {
            activeTaxZone = provincialTaxInfo.get( acct.BillingState );
        }
        /* and if that fails */
        else
        {
            if( opp.RecordTypeId == LGND_Utilities.recordTypeIdFromName('Opportunity', 'Retail') )
            {
                if( owner != null && owner.Warehouse__c != null && warehouseProvinceMap.containsKey( owner.Warehouse__c) )
                {
                    activeTaxZone = provincialTaxInfo.get( warehouseProvinceMap.get( owner.Warehouse__c ) );
                }
            }
            if( opp.RecordTypeId == LGND_Utilities.recordTypeIdFromName('Opportunity', 'Partner Retail Boat Sale') )
            {
                activeTaxZone = provincialTaxInfo.get('Others');
            }
        }

        if( activeTaxZone == null )
            activeTaxZone = defaultTaxZone;

        opp.GL_Account_Variable_3__c = activeTaxZone.id;
        opp.Tax_is_Harmonized__c = activeTaxZone.isHarmonized;
        if( !opp.Tax_Override__c )
        {
            opp.Tax_Rate_Provincial__c = activeTaxZone.rate;
            opp.Tax_Rate_Retail__c = activeTaxZone.retailRate;
            opp.Tax_Rate_Federal__c = fedTaxRate;
        }
    }


    public static void updateTaxes(Opportunity opp, Opportunity oldOpp)
    {
		assignValues();
        LGND_Utilities.ProvincialTax defaultRetailTaxZone;
        LGND_Utilities.ProvincialTax defaultDealerTaxZone;
        LGND_Utilities.ProvincialTax activeTaxZone;
        try {
            defaultRetailTaxZone = provincialTaxInfo.get('Ontario');
            defaultDealerTaxZone = provincialTaxInfo.get('Others');
        }
        catch(Exception e) {
            throw new LGND_Utilities.LGND_Exception('Accounting Variable 3 (Tax Zone) does not appers to be setup correctly. One or both of the required Tax Zones "Ontario" or "Others" is missing');
        }
        /*
           If the Tax zone has changed and is not overriden
           OR
           Tax was prevously overriden but is now not
        */
        if( ( opp.GL_Account_Variable_3__c != oldOpp.GL_Account_Variable_3__c &&
                opp.Tax_Override__c == false ) ||
                ( opp.Tax_Override__c == false && oldOpp.Tax_Override__c == true ) )
        {
            try {
                activeTaxZone = provincialTaxMapById.get( opp.GL_Account_Variable_3__c );
            }
            catch(Exception e)
            {
                throw new LGND_Utilities.LGND_Exception('In valid Tax Zone specified');
            }
        }
        /* Set some defaults if tax zone not specified */
        if( opp.GL_Account_Variable_3__c == null )
        {
            activeTaxZone = defaultRetailTaxZone;
            opp.GL_Account_Variable_3__c = defaultRetailTaxZone.id;
        }
        if( activeTaxZone != null )
        {
            System.debug('111');
            opp.Tax_is_Harmonized__c = activeTaxZone.isHarmonized;
            if( !opp.Tax_Override__c )
            {
                System.debug('222');
                opp.Tax_Rate_Provincial__c = activeTaxZone.rate;
                opp.TAx_Rate_Retail__c = activeTaxZone.retailRate;
                opp.Tax_Rate_Federal__c = fedTaxRate;
            }
        }

    }

    public static void setPrimaryContactInformation(Opportunity[] opps)
    {
        assignValues();
        List<OpportunityContactRole> ocRoles = new List<OpportunityContactRole>();
        for( Opportunity o : opps ){
            if( o.Account.isPersonAccount ){
                o.ContactEmail__c = o.Account.PersonEmail;
                if( o.createdFromLeadConversion__c == false )
                {
                    ocRoles.add( new OpportunityContactRole(
                            ContactId = o.Account.PersonContactId,
                            OpportunityId = o.Id,
                            isPrimary = true,
                            Role = 'Buyer'
                    ));
                }
            }
            else {
                o.ContactEmail__c = o.Account.AccountEmail__c;
            }
        }
        MetadataTriggerHandler.bypass('Opportunity');
        update opps;
        MetadataTriggerHandler.clearBypass('Opportunity');
        System.debug('## oops='+opps );
        System.debug('## ocRoles= '+ocRoles);
        if( !ocRoles.isEmpty() ){
            upsert ocRoles;
        }
    }

    public static void deleteOpportunityDocuments(Set<Id> oppIds)
    {
        Opportunity_Document__c[] oppDocs = [SELECT Id FROM Opportunity_Document__c WHERE Opportunity__c IN : oppIds];
        delete oppDocs;
    }

    public static void recalcInsuranceLines( Map<Id, Map<String, String>> changeMap )
    {
        assignValues();
        System.debug('changeMap= '+changeMap);
        List<OpportunityLineItem> toUpdate = new List<OpportunityLineItem>();
        Map<Id, List<OpportunityLineItem>> oliMap = new Map<Id, List<OpportunityLineItem>>();
        for( OpportunityLineItem oli : [SELECT Id,
                OpportunityId,
                Opportunity.GL_Account_Variable_3__c,
                Product2Id,
                Product2.Name,
                Product2.Is_Residual_Insurance__c,
                Product2.Family,
                InsuranceCoverage__c,
                Insurance_Rate__c
        FROM OpportunityLineItem
        WHERE IsInsurance__c = true
        AND OpportunityId IN :changeMap.keySet() ] )
        {
            if( !oliMap.containsKey( oli.OpportunityId ) )
                oliMap.put( oli.OpportunityId, new List<OpportunityLineItem>() );
            oliMap.get( oli.OpportunityId ).add( oli );
        }
        Set<Id> prodIds = new Set<Id>();
        for( String oppId : changeMap.keySet() )
        {
            if( changeMap.get( oppId).get('termChanged') == 'true' &&
                    oliMap.containsKey( oppId ) )
            {
                for( OpportunityLineItem oli : oliMap.get( oppId) )
                {
                    prodIds.add( oli.Product2Id );
                }
            }
        }
        if( prodIds.size() > 0 )
        {
            Map<Id, Product2> prodMap = new Map<Id, Product2>( [SELECT Id,
            (SELECT Id,
                    Joint__c,
                    Joint_Factored_Result__c,
                    Single__c,
                    Tax_Zone__c,
                    Tax_Zone__r.Name,
                    Lower_Term__c,
                    Upper_Term__c,
                    Lower_Finance_Term__c,
                    Upper_Finance_Term__c
            FROM Insurance_Rates__r)
            FROM Product2
            WHERE Id IN :prodIds]);
            for( String oppId : changeMap.keySet() )
            {
                for( OpportunityLineItem oli : oliMap.get( oppId) )
                {
                    Boolean foundTerm = false;
                    System.debug('prodMap.get( oli.Product2Id).Insurance_Rates__r= '+prodMap.get( oli.Product2Id).Insurance_Rates__r);
                    for( Insurance_Rate__c ir : prodMap.get( oli.Product2Id).Insurance_Rates__r )
                    {
                        Decimal it = Decimal.valueOf( changeMap.get( oppId ).get('insTerm') );
                        Decimal ft = Decimal.valueOf( changeMap.get( oppId ).get('finTerm') );
                        System.debug('it= '+it);
                        System.debug('ft= '+ft);
                        if( ir.Tax_Zone__c == changeMap.get( oppId ).get('taxZone') &&
                                (
                                        (
                                                it >= ir.Lower_Term__c &&
                                                        it <= ir.Upper_Term__c &&
                                                        ft >= ir.Lower_Finance_Term__c &&
                                                        ft <= ir.Upper_Finance_Term__c
                                        )
                                                ||
                                                (
                                                        it >= ir.Lower_Term__c &&
                                                                it <= ir.Upper_Term__c &&
                                                                (
                                                                        ir.Lower_Finance_Term__c == null ||
                                                                                ir.Upper_Finance_Term__c == null
                                                                )
                                                )
                                )
                                )
                        {
                            foundTerm = true;
                            if( oli.InsuranceCoverage__c == 'Single' )
                                oli.Insurance_Rate__c = ir.Single__c;
                            if( oli.InsuranceCoverage__c == 'Joint' ) {
                                if (ir.Tax_Zone__r.Name == 'Quebec')
                                    oli.Insurance_Rate__c = ir.Joint_Factored_Result__c;
                                else
                                        oli.Insurance_Rate__c = ir.Joint__c;
                            }
                        }
                    }
                    if( !foundTerm )
                    {
                        oli.Insurance_Rate__c.addError( oli.Product2.Name + ' does not contain an insurance premium rate for term = ' + changeMap.get( oppId ).get('term') );
                    }
                }
            }
        }
        for( String oppId : changeMap.keySet() )
        {
            if( oliMap.containsKey( oppId ) )
                toUpdate.addAll( doInsuranceCalculation_perOpp( changeMap.get(oppId), oliMap.get(oppId) ) );
        }
        if( toUpdate.size() > 0 )
            update toUpdate;
    }

    private static List<OpportunityLineItem> doInsuranceCalculation_perOpp( Map<String, String> oppValues,
            OpportunityLineItem[] olis )
    {
        Map<Id, OpportunityLineItem> oliMap = new Map<Id, OpportunityLineItem>();
        List<Map<String, String>> lineData = new List<Map<String, String>>();
        for( OpportunityLineItem oli : olis )
        {
            oliMap.put( oli.Id, oli );
            Map<String, String> d = new Map<String, String>();
            d.put('recordId', oli.Id);
            d.put('isResidual', String.valueOf( oli.Product2.Is_Residual_Insurance__c ) );
            d.put('insuranceRate', String.valueOf( oli.Insurance_Rate__c ) );
            d.put('taxZone', String.valueOf(oli.Opportunity.GL_Account_Variable_3__c) );
            d.put('productFamily', String.valueOf(oli.Product2.Family) );
            lineData.add( d );
        }
        Map<String, Decimal> result = BusinessOffice_Controller.calculateInsurancePremiums_withTaxZoneId(
                lineData,
                Decimal.valueOf( oppValues.get('amount') ),
                Decimal.valueOf( oppValues.get('deposit') ),
                Decimal.valueOf( oppValues.get('insTerm') ),
                Decimal.valueOf( oppValues.get('amort') ),
                Decimal.valueOf( oppValues.get('intrestRate') ),
                Decimal.valueOf( oppValues.get('insuranceTaxRate') ),
                oppValues.get('taxZone') );
        for( Id oliId : result.keySet() )
        {
            oliMap.get(oliId).UnitPrice = result.get( oliId );
        }
        return oliMap.values();
    }

    public static void beforeInsert(List<Opportunity> newList){
            assignValues();
            Set<Id> acctIds = new Set<Id>();
            Set<Id> ownerIds = new Set<Id>();

            Id retailId = LGND_Utilities.recordTypeIdFromName('Opportunity', 'Retail');
            for(Opportunity opp : newList)
            {
                acctIds.add(opp.AccountId);
                ownerIds.add( opp.OwnerId );
            }
        	System.debug('acctIds : '+acctIds);
        	System.debug('ownerIds: '+ownerIds);
            Map<Id, Account> acctsMap = new Map<Id, Account>([
                    SELECT Id, BillingState FROM Account WHERE Id IN :acctIds
            ]);
            Map<String, AcctSeedERP__Warehouse__c> warehouseMap = new Map<String, AcctSeedERP__Warehouse__c>();
            for( AcctSeedERP__Warehouse__c wh : [SELECT Id,
                    Name,
                    GL_Account_Variable_3__c
            FROM AcctSeedERP__Warehouse__c] )
            {
                warehouseMap.put( wh.Name, wh );
            }
        System.debug('warehouseMap= '+warehouseMap);
            AcctSeedERP__Warehouse__c warehouseFallback;
            //try {
            //  warehouseFallback = warehouseMap.get('Whitefish');
            //}
            //catch(Exception e)
            //{
            //  throw new LGND_Utilities.LGND_Exception('A Warehouse for Whitefish must be setup.  Please contact your Administer or Developer');
            // }
            if( warehouseMap.containsKey('Whitefish') )
            {
                warehouseFallback = warehouseMap.get('Whitefish');
            }
            else
            {
                throw new LGND_Utilities.LGND_Exception('A Warehouse for Whitefish must be setup.  Please contact your Administer or Developer');
            }
            Map<Id, User> users = new Map<Id, User>([SELECT Id,
                    Name,
                    UserRole.DeveloperName,
                    Business_Office_Manager__c,
                    Sales_Department__c,
                    Warehouse__c
            FROM User
            WHERE ID IN :ownerIds]);
        	System.debug('users map= '+users);
            System.debug('ownerIds= '+ownerIds);
            for( Opportunity opp : newList )
            {
                
                opp.Tax_Rate_Federal__c = Opportunity_Service.fedTaxRate;
                if( users.containsKey( opp.OwnerId ) )
                    opp.Business_Manager__c = users.get( opp.OwnerId ).Business_Office_Manager__c;
                System.debug('users.get( opp.OwnerId )= '+users.get( opp.OwnerId ));
                System.debug('warehouseMap.containsKey( users.get( opp.OwnerId ).Warehouse__c ) = '+warehouseMap.containsKey( users.get( opp.OwnerId ).Warehouse__c ) );
                if( users.get( opp.OwnerId ).Warehouse__c == null )
                {
                    opp.Warehouse__c = warehouseFallback.Id;
                }
                else
                {
                    if( warehouseMap.containsKey( users.get( opp.OwnerId ).Warehouse__c ) )
                    {
                        opp.Warehouse__c = warehouseMap.get( users.get( opp.OwnerId ).Warehouse__c ).Id;
                    }
                    else
                    {
                        opp.Warehouse__c = warehouseFallback.id;
                    }
                }
                System.debug('opp.Warehouse__c= '+opp.Warehouse__c);
                User oppOwner = users.containsKey( opp.OwnerId ) ?
                        users.get( opp.OwnerId ) :
                        null;
                Opportunity_Service.setTaxes( opp,
                        acctsMap.get(opp.AccountId),
                        oppOwner );
                // Retail Opps
                if(opp.RecordTypeId == retailId && Opportunity_Service.disableAutoPricebookSet == false)
                {
                    opp.Pricebook2Id = LGND_Constants.retailPricebookId;
                }
            }

    }


}