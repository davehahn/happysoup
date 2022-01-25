@isTest
private class Prepaid_Services_TEST {

	static Id pricebookId = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
	static Account account;
	static Product2 pack;
	static Product2 pack2;
	static Prepaid_Package_Item__c packageItem;
	static Product2 bundle;
	static Prepaid_Package_Item__c bundleItem;
	static PricebookEntry pbe;
	static PricebookEntry pbe2;
	static AcctSeed__Project__c project;
	static AcctSeed__Project__c project2;
	static AcctSeedERP__Warehouse__c warehouse;
	static Prepaid_Services_mp.PrepaidServiceItem[] services;
	static AcctSeed__Project_Task__c[] tasks;
	static Prepaid_Service__c ps;
	static Prepaid_Service__c ps2;
	static Product2 creditProduct;

	@testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

	private static void init() {
		Product2 product = Factory_Product.buildSerializedProduct( 'Boat','Pontoon' );
		pack = Factory_Product.buildNonSerializedProduct( 'Protection and Services',
																											 'Maintenance Package' );
		pack.isPrepayable__c = true;
		pack2 = Factory_Product.buildNonSerializedProduct( 'Protection and Services',
																											  'Maintenance Package' );
		pack2.isPrepayable__c = true;
		bundle = Factory_Product.buildNonSerializedProduct( 'Package Bundle',
																																'Maintenance Package' );

		bundle.isPrepayable__c = true;
		Product2[] products = new List<Product2>{
			product,
			pack,
			pack2,
			bundle
		};
		insert products;
		Factory_PricebookEntry.createStandardEntries(products, 0);

		PricebookEntry[] pbes = new List<PricebookEntry>{
			Factory_PricebookEntry.buildEntry( product.Id, pricebookId, 500.0),
			Factory_PricebookEntry.buildEntry( pack.Id, pricebookId, 1500.0),
			Factory_PricebookEntry.buildEntry( pack2.Id, pricebookId, 2000.0)
		};
    insert pbes;

		bundleItem = new Prepaid_Package_Item__c(
			Package__c = bundle.Id,
			Item__c = pack.Id,
			Quantity__c = 1
		);
		insert bundleItem;

		packageItem = new Prepaid_Package_Item__c(
			Package__c = bundle.Id,
			Item__c = product.Id,
			Quantity__c = 4
		);
		insert packageItem;

		account = Factory_Account.insertCustomerAccounts(1)[0];

		creditProduct = new Product2(
			Name = 'Prepaid Maintenance Package Credit'
		);

		insert creditProduct;

		warehouse = [SELECT Id, Name FROM AcctSeedERP__Warehouse__c WHERE Name like '%Whitefish%' LIMIT 1];
		DateTime deliveryDate = System.now();
		GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertFullSerial('Boat', 'Pontoon', 'qwertyuiop');
		gcProject.disableTrigger = true;
		project = Factory_ERPOrder.insertRetailBoatSale(account, warehouse, deliveryDate, serial);
		gcProject.disableTrigger = false;
	}

	private static void initProjects() {

		AcctSeed__Project_Task__c t = new AcctSeed__Project_Task__c();
		t.AcctSeed__Project__c = project.Id;
		t.Name = 'test task';
		t.Complaint_dh__c = 'Everything is not awesome.';
		t.Estimated_Duration__c = 3;
		Boolean orig = gcProjectTask.ignoreCommissions;
		gcProjectTask.ignoreCommissions = true;
		insert t;
		gcProjectTask.ignoreCommissions = orig;
		List<AcctSeedERP__Material__c> mats = new List<AcctSeedERP__Material__c>();

		mats.add( new AcctSeedERP__Material__c(
			AcctSeedERP__Project__c = project.Id,
			AcctSeedERP__Product__c = pack.Id,
			AcctSeedERP__Quantity_per_Unit__c = 1,
			AcctSeedERP__Project_Task__c = t.Id,
			isPrepaid__c = true
		));

		mats.add( new AcctSeedERP__Material__c(
			AcctSeedERP__Project__c = project.Id,
			AcctSeedERP__Product__c = bundle.Id,
			AcctSeedERP__Quantity_per_Unit__c = 1,
			AcctSeedERP__Project_Task__c = t.Id,
			isPrepaid__c = true
		));

		insert mats;
	}

	private static void initPrepaids() {
		List<Prepaid_Service__c> ppss = new List<Prepaid_Service__c>();
		ppss.add( new Prepaid_Service__c(
			Account__c = account.Id,
			ERP_Order__c = project.Id,
			Product__c = pack.Id,
			Quantity__c = 5
		));

		//ps = [SELECT Id, Account__c, ERP_Order__c, Product__c, Name, Quantity__c FROM Prepaid_Service__c WHERE Id = :ps.Id];

		ppss.add( new Prepaid_Service__c(
			Account__c = account.Id,
			ERP_Order__c = project.Id,
			Product__c = bundle.Id,
			Quantity__c = 5
		));
		insert ppss;
		ps = ppss[0];
		ps2 = ppss[1];

		//ps2 = [SELECT Id, Account__c, ERP_Order__c, Product__c, Name, Quantity__c FROM Prepaid_Service__c WHERE Id = :ps2.Id];
	}

	@isTest static void PrepaidServiceClass_test() {
		Prepaid_Services_mp.PrepaidService p = new Prepaid_Services_mp.PrepaidService();
		p.prepaid = new Prepaid_Service__c();
		p.prepaid.Quantity__c = 3;

		System.assert(p.prepaid.Quantity__c == 3);
		System.assert(p.products.size() == 0);
	}

	@isTest static void PrepaidServiceItemClass_test() {
		Prepaid_Services_mp.PrepaidServiceItem pi = new Prepaid_Services_mp.PrepaidServiceItem();
		pi.name = 'test';
		pi.prepaidServiceName = 'test';
		pi.product = 'test';
		pi.quantity = 3;
		pi.redeemed = 2;

		System.assert(pi.name == 'test');
		System.assert(pi.children.size() == 0);
	}

	@isTest static void BundleClass_test() {
		Prepaid_Services_mp.Bundle b = new Prepaid_Services_mp.Bundle();
		b.Id = null;
		b.Name = 'test';

		System.assert(b.Name == 'test');
		System.assert(b.items.size() == 0);
	}

	//@isTest static void getPackagesForBundles_test() {
	//	init();
	//	String packageString = Prepaid_Services_mp.getPackagesForBundles(bundle.Id);
	//	Product2[] packages = (List<Product2>)JSON.deserialize(packageString, List<Product2>.class);
	//	System.assert(packages.size() > 0);
	//}

	//@isTest static void getBundles_test() {
	//	init();
	//	String bundlesString = Prepaid_Services_mp.getBundles();
	//	Prepaid_Services_mp.Bundle[] bundles = (List<Prepaid_Services_mp.Bundle>)JSON.deserialize(bundlesString, List<Prepaid_Services_mp.Bundle>.class);
	//	System.assert(bundles.size() > 0);
	//}

	//@isTest static void getBundle_test() {
	//	init();
	//	String bundleString = Prepaid_Services_mp.getBundle(bundle.Id);
	//	Prepaid_Services_mp.Bundle thisbundle = (Prepaid_Services_mp.Bundle)JSON.deserialize(bundleString, Prepaid_Services_mp.Bundle.class);
	//	System.assert(thisbundle.items.size() > 0);
	//}

	//@isTest static void createBundle_test() {
	//	init();
	//	Prepaid_Package_Item__c[] selectedItems = new List<Prepaid_Package_Item__c>();
	//	packageItem.Id = null;
	//	selectedItems.add(packageItem);
	//	String bundleString = Prepaid_Services_mp.createBundle('My Bundle', '12345', false, JSON.serialize(selectedItems) );
	//	Product2 thisbundle = (Product2)JSON.deserialize(bundleString, Product2.class);
	//	System.assert(thisbundle.Name == 'My Bundle');
	//}

	//@isTest static void saveBundle_test() {
	//	init();
	//	Prepaid_Package_Item__c[] selectedItems = new List<Prepaid_Package_Item__c>();
	//	selectedItems.add(packageItem);
	//	String bundleString = Prepaid_Services_mp.saveBundle(bundle.Id, 'My Revised Bundle', '54321', false, JSON.serialize(selectedItems) );
	//	Product2 thisbundle = (Product2)JSON.deserialize(bundleString, Product2.class);
	//	System.assert(thisbundle.Name == 'My Revised Bundle');
	//}

	@isTest static void handleProjectPrepaids_test() {
		init();
		initProjects();
		initPrepaids();
		Test.StartTest();
		Set<Id> projectsToCredit = new Set<Id>();
		Set<Id> projectsToClean = new Set<Id>();
		projectsToCredit.add(project.Id);
		Prepaid_Services_mp.handleProjectPrepaids(projectsToCredit, projectsToClean);
		Prepaid_Service__c[] preps = [SELECT Id FROM Prepaid_Service__c WHERE Account__c = :account.Id];
		Test.StopTest();

		System.assert(preps.size() > 0);
	}

	@isTest static void getPrepaidsOnAccount_test() {
		init();
		initProjects();
		initPrepaids();
		Test.startTest();
		String prepaidString = Prepaid_Services_mp.getPrepaidsOnAccount(account.Id);
		Prepaid_Services_mp.PrepaidService[] prepaids = (List<Prepaid_Services_mp.PrepaidService>)JSON.deserialize(prepaidString, List<Prepaid_Services_mp.PrepaidService>.class);
		Test.stopTest();
		System.assert(prepaids.size() > 0);
	}

	@isTest static void redeemPrepaids_test() {
		init();
		//initProjects();
		initPrepaids();

		Prepaid_Services_mp.PrepaidServiceItem[] prepaids = new List<Prepaid_Services_mp.PrepaidServiceItem>();

		Prepaid_Services_mp.PrepaidServiceItem p = new Prepaid_Services_mp.PrepaidServiceItem();
		p.product = ps.Name;
		p.quantity = 1;
		p.redeemed = 0;
		p.toredeem = 1;
		p.prepaidId = ps.Id;
		p.productId = ps.Product__c;

		prepaids.add( p );

		AcctSeed__Project_Task__c[] tasks = new List<AcctSeed__Project_Task__c>();

		AcctSeed__Project_Task__c t;
		for(AcctSeed__Project_Task__c pt : [SELECT Id, Name, AcctSeed__Project__c, Complaint_dh__c, Estimated_Duration__c FROM AcctSeed__Project_Task__c WHERE AcctSeed__Project__c =:project.Id]){
			t = pt;
		}
		gcProjectTask.disableTrigger = true;
		if(t == null)
			insert t;
		gcProjectTask.disableTrigger = false;
		t.Name = p.product;
		t.Complaint_dh__c = 'No complaints, really.';
		t.Estimated_Duration__c = 1;
		tasks.add( t );
		Prepaid_Services_mp.redeemPrepaids(JSON.serialize(prepaids), account.Id, project.Id, tasks);

		Prepaid_Service__c[] preps = [SELECT Id, Quantity__c, Balance__c, Redeemed__c FROM Prepaid_Service__c WHERE Account__c = :account.Id];

		System.assert(preps[0].Quantity__c > 0);
		System.assert(preps[0].Redeemed__c > 0);
	}

}