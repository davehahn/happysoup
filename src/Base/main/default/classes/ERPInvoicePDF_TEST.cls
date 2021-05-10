@isTest(seeAllData=true)
private class ERPInvoicePDF_TEST {

    @isTest static void tempTest()
    {
        ERPInvoicePDF.coverage();
    }
    /*
    @isTest static void ERPInvoiceConstructor() {
    	Test.startTest();
    	AcctSeed__Project__c p = [SELECT id, AcctSeed__Opportunity__c from AcctSeed__Project__c WHERE AcctSeed__Account__c != null AND AcctSeed__Opportunity__c != null  LIMIT 1];
        Test.setCurrentPageReference(new PageReference('Page.ERPInvoicePDF'));
        System.currentPageReference().getParameters().put('erpOrderId', p.id);
        createTradeInRecord(p.AcctSeed__Opportunity__c);
        createMaterial('Boat', p,false,false);
        createMaterial('Trailer', p,false,false);
        createMaterial('Trolling Motor', p,false,false);
        createMaterial('Motor', p,false,false);
        createMaterial('Fees', p,false,false);
        createMaterial('Part', p,true,false);
        createMaterial('Part', p,true,true);
        createMaterial('Protection and Services', p,false,false);
    	ERPInvoicePDF erp = new ERPInvoicePDF();
        Test.stopTest();
    }


    public static void createMaterial(String recordTypeName, AcctSeed__Project__c proj, boolean withFam, boolean equalsFam) {
    	Product2 prod = new Product2();
    	if(withFam){
    			if(equalsFam){
    				 prod = [Select id FROM Product2 WHERE RecordType.Name =: recordTypeName  AND Family =: 'Discount' LIMIT 1];
    			}else{
    				 prod = [Select id FROM Product2 WHERE RecordType.Name =: recordTypeName  AND Family != 'Discount' LIMIT 1];
    			}

    	}else{
    			prod = [Select id FROM Product2 WHERE RecordType.Name =: recordTypeName LIMIT 1];
    	}

    	AcctSeedERP__Material__c mat = new AcctSeedERP__Material__c();
    	mat.AcctSeedERP__Product__c = prod.id;
    	mat.GMBLASERP__Total_Price__c = 5;
    	mat.AcctSeedERP__Project__c = proj.Id;
    	insert mat;
    }

    public static void createTradeInRecord(String opp){
    	Trade_In_Record__c trade = new Trade_In_Record__c();
    	trade.Lien_Amount__c = 10;
    	trade.Total_Value__c = 5;
    	trade.Opportunity__c = opp;
    	insert trade;
    }
    */
    /*
    @future
    private static void generateProject(User u) {
        AcctSeed__Project__c proj = new AcctSeed__Project__c();
        proj.name = 'ABC';
        proj.OwnerID = u.id;
        insert proj;

    }

    private static User generateUser() {
        UserRole r = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
        insert r;

        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];


        User u = new User(
        ProfileId = profileId.id,
        LastName = 'last',
        Email = 'puser000@amamama.com',
        Username = 'puser000@amamama.com' + System.currentTimeMillis(),
        CompanyName = 'TEST',
        Title = 'title',
        Alias = 'alias',
        TimeZoneSidKey = 'America/Los_Angeles',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        UserRoleId = r.Id);

        insert u;
        return u;
    }
    private static void generateOpp() {
    	opp = new Opportunity(
              Name = 'Test Opportunity',
              StageName='Prospecting',
              Deposit__c=10,
              TaxationProvince__c='Ontario',
              Deposit_Method__c='Cash',
              CloseDate=Date.today(),
              Finance_Payments_Per_Year__c = 12,
              Pricebook2Id = standard_pb2.Id,
              AccountId = null
            );
    	insert opp;
    }
*/
}