@isTest
private class Case_TriggerHandler_Test {

		public static Case c;
		public static User partner;
		public static Account dealer;

	@testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

	static void init() {
			c = new Case();
	}

	static void initForWarranty()
	{
		dealer = AccountFactory.buildDealerAccount('Testy McDealer');
		insert dealer;
		partner = Factory_User.createPartnerUser( dealer );
	}
	

		@isTest
		static void partnerWarrantyCreate_Test()
		{
			initForWarranty();
			System.runAs( partner )
			{
				Test.startTest();
				c = Factory_Case.buildWarrantyCase( dealer );
				c.Partner_Reference__c = 'Test Ref';
				insert c;
				Test.stopTest();
				c = [SELECT CaseNumber,
									  Partner_Reference__c,
										Price_Book__c,
										ContactId,
										Warranty_ERP__c
						FROM Case
						WHERE Id = :c.Id];
				AcctSeed__Project__c erp = [ SELECT Id, Customer_Notes__c
																		 FROM AcctSeed__Project__c
																		 WHERE Id = :c.Warranty_ERP__c ];
				String comment = 'Warranty Case # ' + c.CaseNumber;
				comment += '<br> Partner Reference # ' + c.Partner_Reference__c;
				System.assertNotEquals( null, c.Price_Book__c );
				System.assertEquals( Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c, c.Price_Book__c);
				System.assertEquals( partner.ContactId, c.ContactId );
				System.assertNotEquals( null, c.Warranty_ERP__c );
				System.assertEquals( comment, erp.Customer_Notes__c );
			}
		}


		// test contact is not automatically set for new case when user is not a Partner Community User
		@isTest
		static void newCaseSetByLegendHasContactSetManually() {
			init();
			Test.startTest();
			insert c;
			Test.stopTest();
			c = [SELECT ContactId FROM Case WHERE Id = :c.Id];
			System.assertEquals(NULL, c.ContactId);
		}

		// test trigger can handle bulk
		@isTest
		static void bulkNewCasesCreated() {
				List<Case> cases = new List<Case>();
				Integer numberOfCases = 10;
				for (Integer i = 0; i < numberOfCases; i++) {
						cases.add(new Case());
				}

				Test.startTest();

				insert cases;

				List<Id> insertedCaseIds = new List<Id>();
				for (Integer i = 0; i < numberOfCases; i++) {
						insertedCaseIds.add(cases[i].Id);
				}
				cases = [SELECT ContactId FROM Case WHERE Id IN :insertedCaseIds];
				System.AssertEquals(numberOfCases, cases.size());

				Test.stopTest();
		}

		@isTest
		static void warrantySubletInfo_Create_Test()
		{

				initForWarranty();
				System.runAs( partner )
				{
					c = Factory_Case.buildWarrantyCase( dealer );
					c.Sublet_Company__c = 'AngrySlothBrewing';
					c.Sublet_Price__c = 400;
					Test.startTest();
					insert c;
					Test.stopTest();
					c = [ SELECT Id, Warranty_ERP__c FROM Case WHERE Id = :c.Id ];
					AcctSeedERP__Material__c[] mats = [SELECT Id,
																										AcctSeedERP__Comment__c,
																										GMBLASERP__Unit_Price__c
																						 FROM AcctSeedERP__Material__c
																						 WHERE AcctSeedERP__Project__c = :c.Warranty_ERP__c];
					System.assertEquals( 1, mats.size() );
					//will be negative do to a warrantyERP changing all values to negative
					System.assertEquals( -400, mats[0].GMBLASERP__Unit_Price__c );
					System.assertEquals( 'AngrySlothBrewing', mats[0].AcctSeedERP__Comment__c );

//					c.Sublet_Company__c = 'CrappyAssBrewing';
//					c.Sublet_Price__c = 500;
//					update c;
//
//					mats = [SELECT Id, AcctSeedERP__Comment__c, GMBLASERP__Unit_Price__c
//								  FROM AcctSeedERP__Material__c
//								  WHERE AcctSeedERP__Project__c = :c.Warranty_ERP__c];
//
//					//will be negative do to a warrantyERP changing all values to negative
//					System.assertEquals( -500, mats[0].GMBLASERP__Unit_Price__c );
//					System.assertEquals( 'CrappyAssBrewing', mats[0].AcctSeedERP__Comment__c );
//
//					c.Sublet_Company__c = null;
//					c.Sublet_Price__c = null;
//					update c;
//
//					mats = [SELECT Id, AcctSeedERP__Comment__c, GMBLASERP__Unit_Price__c
//								  FROM AcctSeedERP__Material__c
//								  WHERE AcctSeedERP__Project__c = :c.Warranty_ERP__c];
//
//					System.assertEquals( 0, mats.size() );
				}
		}

	@isTest
	static void warrantySubletInfo_AddOnUpdate_Test()
	{

		initForWarranty();
		System.runAs(partner)
		{
			c = Factory_Case.buildWarrantyCase(dealer);
			insert c;
			Test.startTest();
			c.Sublet_Company__c = 'AngrySlothBrewing';
			c.Sublet_Price__c = 400;
			update c;
			Test.stopTest();
			c = [SELECT Id, Warranty_ERP__c FROM Case WHERE Id = :c.Id];
			AcctSeedERP__Material__c[] mats = [ SELECT Id,
																								 AcctSeedERP__Comment__c,
																								 GMBLASERP__Unit_Price__c
																					FROM AcctSeedERP__Material__c
																					WHERE AcctSeedERP__Project__c = :c.Warranty_ERP__c ];
			System.assertEquals(1, mats.size());
			//will be negative do to a warrantyERP changing all values to negative
			System.assertEquals(-400, mats[0].GMBLASERP__Unit_Price__c);
			System.assertEquals('AngrySlothBrewing', mats[0].AcctSeedERP__Comment__c);
		}
	}

	@isTest
	static void warrantySubletInfo_ChangeOnUpdate_Test()
	{

		initForWarranty();
		System.runAs(partner)
		{
			c = Factory_Case.buildWarrantyCase(dealer);
			c.Sublet_Company__c = 'AngrySlothBrewing';
			c.Sublet_Price__c = 400;
			insert c;
			Test.startTest();
			c.Sublet_Company__c = 'BadAssBrewing';
			c.Sublet_Price__c = 800;
			update c;
			Test.stopTest();
			c = [SELECT Id, Warranty_ERP__c FROM Case WHERE Id = :c.Id];
			AcctSeedERP__Material__c[] mats = [ SELECT Id,
																								 AcctSeedERP__Comment__c,
																								 GMBLASERP__Unit_Price__c
																					FROM AcctSeedERP__Material__c
																					WHERE AcctSeedERP__Project__c = :c.Warranty_ERP__c ];
			System.assertEquals(1, mats.size());
			//will be negative do to a warrantyERP changing all values to negative
			System.assertEquals(-800, mats[0].GMBLASERP__Unit_Price__c);
			System.assertEquals('BadAssBrewing', mats[0].AcctSeedERP__Comment__c);
		}
	}

	@isTest
	static void warrantySubletInfo_DeleteOnUpdate_Test()
	{

		initForWarranty();
		System.runAs(partner)
		{
			c = Factory_Case.buildWarrantyCase(dealer);
			c.Sublet_Company__c = 'AngrySlothBrewing';
			c.Sublet_Price__c = 400;
			insert c;
			Test.startTest();
			c.Sublet_Company__c = null;
			c.Sublet_Price__c = null;
			update c;
			Test.stopTest();
			c = [SELECT Id, Warranty_ERP__c FROM Case WHERE Id = :c.Id];
			AcctSeedERP__Material__c[] mats = [ SELECT Id,
																								 AcctSeedERP__Comment__c,
																								 GMBLASERP__Unit_Price__c
																					FROM AcctSeedERP__Material__c
																					WHERE AcctSeedERP__Project__c = :c.Warranty_ERP__c ];
			System.assertEquals(0, mats.size());
		}
	}

	@isTest
	static void partnerPartsOrderCreate_OnApproved_Test()
	{

		initForWarranty();
		System.runAs(partner)
		{
			c = Factory_Case.createWarrantyCase(dealer);
			List<Case_Part__c> cParts = Factory_CasePart.create( c, 3 );
			Test.startTest();
			c.Partner_Reference__c = 'Unit Test';
			c.Status = 'Approved';
			update c;
			Test.stopTest();
			c = [SELECT Id, Parts_Order_ERP__c, Partner_Reference__c, CaseNumber FROM Case WHERE Id = :c.Id ];
			AcctSeed__Project__c erp = [ SELECT Id, Partner_External_PO_Number__c, Customer_Notes__c,
																	( SELECT Id FROM AcctSeedERP__Project_Materials__r )
																	 FROM AcctSeed__Project__c
																	 WHERE Id = :c.Parts_Order_ERP__c ];
			System.assert( c.Parts_Order_ERP__c != null, 'Case Parts Order lookup should be populated' );
			System.assertEquals( c.Parts_Order_ERP__c, erp.Id );
			System.assertEquals( erp.Customer_Notes__c, 'Warranty Case # ' + c.CaseNumber);
			System.assertEquals( erp.Partner_External_PO_Number__c, c.Partner_Reference__c );
			System.assertEquals( cParts.size(), erp.AcctSeedERP__Project_Materials__r.size() );
		}
	}

	@isTest
	static void warrantyDelete_Test()
	{
		initForWarranty();
		c = Factory_Case.createWarrantyCase( dealer );
		c = [SELECT Id, Warranty_Erp__c, ContactId FROM Case WHERE Id = :c.Id];
		Id erpId = c.Warranty_ERP__c;
		Test.startTest();
		delete c;
		Test.stopTest();

		AcctSeed__Project__c[] erps = [SELECT Id FROM AcctSeed__Project__c WHERE Id = :erpId];
		System.assertEquals( 0, erps.size() );
	}

	@isTest
	static void relatedERPsUpdatedToClosedLost_OnDenied_Test()
	{

		initForWarranty();
		System.runAs(partner)
		{
			c = Factory_Case.createWarrantyCase(dealer);
			AcctSeed__Project__c recoverable = Factory_ERPOrder.createWarrantyERP(dealer, c.Serial_Number__c, 2);
			Id ppOrderRtId = LGND_Utilities.recordTypeIdFromName('AcctSeed__Project__c', 'Legend Partner Parts Order');
			AcctSeed__Project__c partsOrder = Factory_ERPOrder.buildERP(dealer, c.Serial_Number__c, ppOrderRtId);
			insert partsOrder;
			c.Recoverable_ERP__c = recoverable.Id;
			c.Parts_Order_ERP__c = partsOrder.Id;
			TriggerHandler.byPass('Case_TriggerHandler');
			update c;
			TriggerHandler.clearByPass('Case_TriggerHandler');
			Test.startTest();
			String[] deniedReasons = LGND_Utilities.getPicklistValues( 'Case', 'Denied_Reasons__c');
			c.Status = 'Denied';
			c.Denied_Reasons__c = deniedReasons[0];
			update c;
			Test.stopTest();
			Set<Id> erpIds = new Set<Id>{
				c.Warranty_ERP__c,
				recoverable.Id,
				partsOrder.Id
			};
			for( AcctSeed__Project__c p : [SELECT Id, Stage__c FROM AcctSeed__Project__c WHERE Id IN :erpIds] )
			{
				System.assertEquals( 'Closed Lost', p.Stage__c );
			}
		}
	}

	@IsTest
	static void addPromotionalProductsToERP_Test()
	{
		initForWarranty();
		partner = [SELECT Id, ContactId, AccountId FROM USer WHERE Id = :partner.Id ];
		Product2 boat = Factory_Product.createSerializedProducts('Boat', 'Pontoon', 1)[0];
		Product2 part = Factory_Product.createNonSerializedProduct('Part', 'Electronics');
		AcctSeed__Project__c erp = Factory_ERPOrder.createPartnerBoatSales( dealer, new List<Product2>{boat}, 1)[0];
		Promotion__c promo = Factory_Promotion.buildPromotions(1)[0];
		promo.Available_On__c = 'Reservation';
		insert promo;
		Promotion_Item__c promoItem = Factory_Promotion.buildPromoItem( promo, boat, 1000);
		insert promoItem;
		Promotion_Incentive_Product__c iProd = new Promotion_Incentive_Product__c(
			Product__c = part.Id,
			Promotion__c = promo.Id,
			Quantity__c = 1
		);
		insert iProd;
		Case promoCase = new Case(
			RecordTypeId = LGND_Constants.caseRtId_Promotion,
			ContactId = partner.ContactId,
			AccountId = partner.AccountId,
			Promotion_Item__c = promoItem.Id,
			Promotion_Erp__c = erp.Id,
			Status = 'Pending documentation'
		);
		TriggerHandler.bypass('Case_TriggerHandler');
		insert promoCase;
		TriggerHandler.clearBypass('Case_TriggerHandler');

		erp = [
			SELECT
				Id,
			(SELECT
				Id
			FROM AcctSeedERP__Project_Materials__r),
			(SELECT
				Id
			FROM AcctSeed__Project_Tasks__r)
			FROM AcctSeed__Project__c
			WHERE Id = :erp.Id
		];

		System.assertEquals( 1, erp.AcctSeedERP__Project_Materials__r.size() );
		System.assertEquals( 1, erp.AcctSeed__Project_Tasks__r.size() );

		Test.startTest();
		promoCase.Status = 'Complete';
		update promoCase;
		Test.stopTest();

		erp = [
			SELECT
				Id,
			(SELECT
				Id
			 FROM AcctSeedERP__Project_Materials__r),
			(SELECT
				Id
			 FROM AcctSeed__Project_Tasks__r)
			FROM AcctSeed__Project__c
			WHERE Id = :erp.Id
		];

		System.assertEquals( 2, erp.AcctSeedERP__Project_Materials__r.size() );
		System.assertEquals( 2, erp.AcctSeed__Project_Tasks__r.size() );
	}
}