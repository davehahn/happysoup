/* ----------------------------------------------------------------------------

	Contributors: Mario
	Last Modified By: Mario
	Created: April 2018, maybe? Somewhere around there?
	Last Modified: September 14, 2018

	This test covers:			Expected Coverage:
	1) Promotion_mp				97%

---------------------------------------------------------------------------- */

@isTest
private class Promotion_Test {

	static Product2 product;
	static Account dealer;
	static Contact contact;
	static Account customerAccount;
	static Promotion__c promo;
	static Promotion_Item__c promoItem;
	static Id recordTypeId;
	static GMBLASERP__Serial_Number__c serialNumber;
	static Set<Id> regIds;
	static User user;
	static Registration__c reg;

  private static void init() {
		product = Factory_Product.createSerializedProduct('Boat','Pontoon');
		dealer = AccountFactory.buildDealerAccountWithEmail(
							'Promo Test Dealer',
							'mparise+test@legendboats.com'
						 );
		insert dealer;
		user = User_TestFactory.createPartnerUser(dealer);
		DateTime startDate = DateTime.now().addDays(-3);
		DateTime endDate = startDate.addMonths(1);
		promo = Factory_Promotion.createPromotion('Fantastic February',
																							startDate, endDate);
		promoItem = Factory_Promotion.createPromoItem(promo, product, 850.00);
		serialNumber = Factory_SerialNumber.insertFullSerialWithProduct(
										'Boat',
										'Pontoon',
										'1234567890',
										product
									 );
		reg = Factory_Registration.createRegistration(dealer.Id, serialNumber.Id);
		customerAccount = Factory_Account.insertFullPersonAccount('Testy','McTester');
	}

	@isTest static void getAccountId() {
		Id accountId = Promotion_mp.getAccountId();
	}

	@isTest static void getPromoCases() {
		init();
		System.runAs(user) {
			insert Promotion_mp.buildPromoCase(dealer.Id,
																				 null,
																				 promoItem.Id,
																				 serialNumber.Id,
																				 reg.Id);
			String promos = Promotion_mp.getPromoCases();
			System.debug(promos);
			Promotion_mp.PromoRegistrationWrapper[] promoList =
				(List<Promotion_mp.PromoRegistrationWrapper>)System.JSON.deserialize(
					promos, List<Promotion_mp.PromoRegistrationWrapper>.class);
			System.assert(promoList.size() > 0);
		}
	}

	@isTest static void buildPromoCase() {
		init();
		Test.startTest();

		recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(
										'Promotion'
									 ).getRecordTypeId();

		// Create Promo Case
		Case c = Promotion_mp.buildPromoCase(dealer.Id,
																				 null,
																				 promoItem.Id,
																				 serialNumber.Id,
																				 reg.Id);
		insert c;

		// Grab full case
		Case fullCase = [SELECT Id,
														AccountId,
														Promotion_Item__c,
														Promotion__c,
														Promotion_Amount__c,
														Product_Name__c,
														Serial_Number_Name__c,
														RecordTypeId,
														Status
											 FROM Case
											WHERE Id = :c.Id];

		//invocations = Limits.getEmailInvocations();
		Test.stopTest();

		// Verify results
		System.assert(fullCase.RecordTypeId == recordTypeId);
		System.assert(fullCase.Promotion_Item__c == promoItem.Id);
		System.assert(fullCase.Promotion__c == 'Fantastic February');
		System.assert(fullCase.Promotion_Amount__c == 850.00);
		System.assert(fullCase.Product_Name__c != null);
		System.assert(fullCase.Serial_Number_Name__c == serialNumber.Name);
		System.assert(fullCase.Status == 'Pending documentation');
		//System.assert(invocations == 1);
	}

	@isTest static void claimPromotion() {
		init();
		Case c = Promotion_mp.buildPromoCase(dealer.Id,
																				 null,
																				 promoItem.Id,
																				 serialNumber.Id,
																				 reg.Id);
		insert c;
		Test.startTest();
		Case c2 = Promotion_mp.claimPromotion(c.Id, reg.Id, promoItem.Id);
		Test.stopTest();
		System.assert(c2.Serial_Number__c == reg.SerialNumber__c);
		System.assert(c2.Promotion_Item__c == promoItem.Id);
		System.assert(c2.Status == 'Pending review');
	}

	@isTest static void getDealerAccounts() {
		init();
		Test.startTest();
		Account[] accounts = Promotion_mp.getDealerAccounts();
		Test.stopTest();
		System.assert(accounts.size() > 0);
	}

	@isTest static void createNewPromotion() {
		init();
		List<Id> dealers = new List<Id>();
		dealers.add(dealer.Id);
		Test.startTest();
		Promotion_mp.createNewPromotion(promo, dealers);
		Test.stopTest();
		List<Promotion_Account__c> promoAccounts =
			[SELECT Id
				 FROM Promotion_Account__c
			  WHERE Account__c = :dealer.Id];
		System.assert(promoAccounts.size() > 0);
	}

	@isTest static void createNewPromotionWithoutAccountLimits() {
		init();
		Test.startTest();
		Promotion_mp.createNewPromotion(promo, null);
		Test.stopTest();
		List<Promotion__c> promos = [SELECT Id FROM Promotion__c];
		System.assert(promos.size() > 0);
	}

	@isTest static void getProducts() {
		Factory_Product.createSerializedProduct('Boat', 'Pontoon');
		Test.startTest();
		Product2[] products = Promotion_mp.getProducts();
		Test.stopTest();
		System.assert(products.size() > 0);
	}

	@isTest static void getDetailedProducts() {
		init();
		Product2 product =
			Factory_Product.createSerializedProduct('Boat', 'Pontoon');
		String[] prodList = new List<String>();
		prodList.add(product.Id);
		Test.startTest();
		Promotion_Item__c[] products = Promotion_mp.getDetailedProducts(
																			prodList,
																			promo
																	 );
		Test.stopTest();
		System.assert(products.size() > 0);
	}

	@isTest static void savePromoAndItems() {
		init();
		String[] prodList = new List<String>();
		prodList.add(product.Id);
		Test.startTest();
		Promotion_Item__c[] promoItems = Promotion_mp.getDetailedProducts(
																			  prodList,
																			  promo
																		 );
		Promotion__c mypromo = Promotion_mp.savePromoAndItems(
			promo,
			promoItems
		);
		Test.stopTest();
		System.assert(mypromo.Id == promo.Id);
	}

	@isTest static void getPromotions() {
		init();
		Test.startTest();
		String promosString = Promotion_mp.getPromotions();
		Test.stopTest();
		Promotion__c[] mypromos = (List<Promotion__c>)JSON.deserialize(promosString, List<Promotion__c>.class);
		System.assert(mypromos.size() > 0);
	}

	@isTest static void claimPromoWithoutSerno() {
		init();
		Case promoClaim = Promotion_mp.claimPromoWithoutSerno(
												promoItem.Id
											);
		System.assert(promoClaim.Id != null);

		Case promoClaim2 = Promotion_mp.claimPromoWithoutSerno(
												promoItem.Id,
												customerAccount.Id
											);
		System.assert(promoClaim2.Id != null);

		Account customer = new Account(
			Name = 'Testy'
		);
		insert customer;

		Case promoClaim3 = Promotion_mp.claimPromoWithoutSerno(
												promoItem.Id,
												customer.Id
											);
		System.assert(promoClaim3.Id != null);
	}

	@isTest static void getPromoItems() {
		init();
		Test.startTest();
		String promoItems = Promotion_mp.getPromoItems(promo.Id);
		Test.stopTest();
		System.assert(promoItems.length() > 0);
	}

	@isTest static void clonePromo() {
		init();
		Test.startTest();
		String cloneString = Promotion_mp.clonePromo(promo.Id);
		Test.stopTest();
		Promotion__c clone = (Promotion__c)JSON.deserialize(cloneString, Promotion__c.class);
		System.assert(clone.Name == (promo.Name + ' (copy)' ));
	}

	@isTest static void getClaimDetails() {
		init();
		Case c = Promotion_mp.buildPromoCase(dealer.Id,
																				 null,
																				 promoItem.Id,
																				 serialNumber.Id,
																				 reg.Id);
		insert c;
		Test.startTest();
		Case claim = Promotion_mp.getClaimDetails(c.Id);
		Test.stopTest();
		System.assert(claim.CaseNumber != null);
	}

	@isTest static void getAvailablePromotionsByProduct() {
		init();
		Test.startTest();
		String promotionsJSON = Promotion_mp.getAvailablePromotionsByProduct(product.Id);
		Test.stopTest();
		Promotion_Item__c[] promotions = (List<Promotion_Item__c>)System.JSON.deserialize(
					promotionsJSON, List<Promotion_Item__c>.class);
		System.assert(promotions[0] != null);
	}

	@isTest static void getPromoDocumentationRequirementOptions() {
		List<String> reqs = Promotion_mp.getPromoDocumentationRequirementOptions();
		System.assert(reqs.size() > 0);
	}

	@isTest static void getPromotionViaItem() {
		init();
		Test.startTest();
		Promotion_Item__c promo = Promotion_mp.getPromotionViaItem(promoItem.Id);
		Test.stopTest();
		System.assert(promo.Id != null);
	}

	@isTest static void getCustomerAccountId_Test() {
		Lead ld = Factory_Lead.buildAcceptedLead('Jaime', 'Lannister');
		insert ld;
		Test.startTest();
		Promotion_mp.getCustomerAccountId(ld.Id);
		Test.stopTest();
		Account[] a = [SELECT Id FROM Account WHERE FirstName = 'Jaime' AND LastName = 'Lannister'];
		System.assert(a.size() > 0);
	}

}

