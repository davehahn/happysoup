@isTest
private class arInsuranceDocuments_Test {
	static Opportunity opp;
	static AcctSeed__Project__c erp;
	static AcctSeed__Project_task__c orderTask;
	static Account personAccount;
	static Pricebook2 customPb;
	static InsurancePlan__c[] insurancePlans;
	static Map<Id, List<Product2>> insuranceProductsByPlanId;

	 @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

	static {
		customPb = new Pricebook2( Name = 'CustomPb', isActive = true );
		insert customPb;
		personAccount = AccountFactory.insertPersonAccount();
	}

	private static void oppInit()
	{
		OpportunityTriggerHandler.disableAutoPricebookSet = true;
		opp = OpportunityFactory.buildBasicRetail( personAccount.Id );
		OpportunityTriggerHandler.disableAutoPricebookSet = true;
		insert opp;
	}

	private static void erpInit()
	{
		GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertFullSerial( 'Boat', 'Pontoon', '1234567890');
		erp = Factory_ERPOrder.buildERP( personAccount, serial.Id, gcConstants.idRtProjectBoatSale );
		erp.GMBLASERP__Pricebook__c = customPb.Id;
		gcProject.disableTrigger = true;
		insert erp;
	}

	private static void erp2Oppy()
	{
		if(erp.Id != null && opp.Id != null)
		{
			erp.AcctSeed__Opportunity__c = opp.Id;
			update erp;
		}
	}

	private static void oppyContactRoles()
	{
		if(opp != null)
		{
			Contact buyer = new Contact(LastName = 'Buyer');
			Contact coBuyer = new Contact(LastName = 'Co-Buyer');
			List<Contact> listContacts = new List<Contact>{buyer,coBuyer};
			insert listContacts;

			List<OpportunityContactRole> listOCR = new List<OpportunityContactRole>{
				new OpportunityContactRole(OpportunityId = opp.Id, ContactId = buyer.Id, Role = 'Buyer'),
				new OpportunityContactRole(OpportunityId = opp.Id, ContactId = coBuyer.Id, Role = 'Co-Buyer')
			};
			insert listOCR;
		}
	}

	private static void insuranceInit4erp( List<Product2> insuranceProducts )
	{
		erpInit();
		oppInit();
		erp2Oppy();
		oppyContactRoles();
		if( insuranceProducts != null && insuranceProducts.size() > 0 )
		{
		  orderTask = Factory_ERPOrder.buildProjectTask( erp.Id, 'Insurance Items');
		  orderTask.isInsurance__c = true;
		  insert orderTask;
		  AcctSeedERP__Material__c[] mats = new List<AcctSeedERP__Material__c>();
		  for( Product2 p : insuranceProducts )
		  {
			mats.add( new AcctSeedERP__Material__c(
			  AcctSeedERP__Project__c = erp.Id,
			  AcctSeedERP__Project_Task__c = orderTask.Id,
			  AcctSeedERP__Product__c = p.Id,
			  GMBLASERP__Unit_Price__c = 100,
			  GMBLASERP__Price_Override__c = true,
			  Insurance_Rate__c = 6,
			  Insurance_Coverage__c = 'Single',
			  AcctSeedERP__Quantity_Per_Unit__c = 1
			));
		  }
		  insert mats;
		}
	}

	private static void insuranceTestInit()
	{
		insuranceProductsByPlanId = new Map<Id, List<Product2>>();
		insurancePlans = new List<InsurancePlan__c>();
		insurancePlans.add( new InsurancePlan__c(
		  Name = 'Insurance Plan One'
		));
		insert insurancePlans;
		insuranceProductsByPlanId.put( insurancePlans[0].Id, new List<Product2>() );
		insuranceProductsByPlanId.get( insurancePlans[0].Id ).add(
		  Factory_Product.createInsuranceProduct( 'Life Insurance Coverage',
												  'Life (One)',
												  insurancePLans[0].Id,
												  false,
												  customPb.Id )
		);
		insuranceProductsByPlanId.get( insurancePlans[0].Id ).add(
		  Factory_Product.createInsuranceProduct( 'Life Insurance Coverage',
												  'Life Residual (One)',
												  insurancePLans[0].Id,
												  true,
												  customPb.Id )
		);
		insuranceProductsByPlanId.get( insurancePlans[0].Id ).add(
		  Factory_Product.createInsuranceProduct( 'Critical Illness Coverage',
												  'Critical Illness (One)',
												  insurancePLans[0].Id,
												  false,
												  customPb.Id )
		);
		insuranceProductsByPlanId.get( insurancePlans[0].Id ).add(
		  Factory_Product.createInsuranceProduct( 'Critical Illness Coverage',
												  'Critical Illness Residual (One)',
												  insurancePLans[0].Id,
												  true,
												  customPb.Id )
		);
		insuranceProductsByPlanId.get( insurancePlans[0].Id ).add(
		  Factory_Product.createInsuranceProduct( 'Disability Insurance Coverage',
												  'Disability Insurance (One)',
												  insurancePLans[0].Id,
												  false,
												  customPb.Id )
		);
		insuranceProductsByPlanId.get( insurancePlans[0].Id ).add(
		  Factory_Product.createInsuranceProduct( 'Accidental Coverage',
												  'Accidental Coverage (One)',
												  insurancePLans[0].Id,
												  false,
												  customPb.Id )
		);
	}

	@isTest
	static void insurance_init_erp_Test()
	{
		insuranceTestInit();
		insuranceInit4erp( insuranceProductsByPlanId.get( insurancePlans[0].Id ) );
		Test.startTest();
		PageReference pageRef = Page.InsurancePDFComp_Maxum;
		pageRef.getParameters().put('id', erp.Id);
		Test.setCurrentPage(pageRef);
		InsurancePDFComp_Controller controller = new InsurancePDFComp_Controller();

		//controller.init();

		Test.stopTest();
		arInsuranceDocuments.retrieveERPDetails(erp.Id);
		String jsonResult = arInsuranceDocuments.generateInsurancePDF(erp.Id, 'Companion Maxum', DateTime.now().format('dd-MMM-yyyy') );
		List<Map<String,String>> result = (List<Map<String,String>>)JSON.deserialize( jsonResult, List<Map<String,String>>.class );
		System.assertEquals(result.size() , 1);
		arInsuranceDocuments.deleteDocument(erp.Id,result[0].get('idErpDoc'),result[0].get('idDoc'));
	}
}