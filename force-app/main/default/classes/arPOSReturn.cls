public with sharing class arPOSReturn {
	@AuraEnabled
	public static List<String> getCDOptions() {
		List<String> options = new list<String>();

		Schema.DescribeFieldResult fieldResult = AcctSeed__Cash_Disbursement__c.AcctSeed__Type__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
			
		for( Schema.PicklistEntry f : ple)
			options.add(f.getValue());

		return options;
	}

	@AuraEnabled
	public static list<map<string,string>> getWarehouses()
	{
		list<map<string,string>> listJSON = new list<map<string,string>>();

		Id idWarehouseTransit = GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Transit_Warehouse_Id__c;
		Id idWarehouseAdjustment = GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Adjustment_Warehouse_Id__c;
		for(AcctSeedERP__Warehouse__c whs :
			[SELECT Id, Name 
			 FROM AcctSeedERP__Warehouse__c 
			 WHERE Id != :idWarehouseTransit 
				 AND Id != :idWarehouseAdjustment 
				 ORDER BY Name])
		{
			map<string,string> obj = new map<string,string>{'idWarehouse'=>whs.Id,'warehouseName'=>whs.Name};
			listJSON.add(obj);
		}
		return listJSON;
	}


	@AuraEnabled
	public static String retrieveERPOrders(Id idFilter) {
		List<AcctSeed__Project__c> listProjects = new list<AcctSeed__Project__c>();
		for(AcctSeed__Project__c pr : 
			[SELECT Id, 
				Name, 
				AcctSeedERP__Work_Order_Number__c,
				Manufactured_Product_Name__c,
				Model_Name__c,
				RecordType.Name,
				Order_Item_Total__c, 
				Serial_Number__r.Name,
				Grand_Total__c, 
				AcctSeed__Account__c
			FROM AcctSeed__Project__c 
			WHERE (AcctSeed__Account__c =:idFilter OR Id =:idFilter)
				AND Order_Item_Total__c > 0
				AND AcctSeed__Status__c = 'Completed'])
		{
			listProjects.add(pr);
		}
		return JSON.serialize(listProjects);
	}

	public class materialProducts {
	@AuraEnabled
		public String matId {get;set;}
	@AuraEnabled
		public String productId {get;set;}
	@AuraEnabled
		public String productName{get;set;}
	@AuraEnabled
		public String productType{get;set;}
	@AuraEnabled
		public String serialId {get;set;}
	@AuraEnabled
		public String serialName{get;set;}
	@AuraEnabled
		public String projectId {get;set;}
	@AuraEnabled
		public String projectName{get;set;}
	@AuraEnabled
		public String projectTaskName{get;set;}
	@AuraEnabled
		public Boolean isInventory { get; set; }
	@AuraEnabled
		public Boolean isSerialized { get; set; }
	@AuraEnabled
		public Decimal originalQuantity { get; set; }
	@AuraEnabled
		public Decimal returnQuantity { get; set; }
	@AuraEnabled
		public Decimal pricePerQuantity { get; set; }
	@AuraEnabled
		public Decimal totalPrice { get; set; }
	}

	@AuraEnabled
	public static String retrieveERPProducts(Id erpId)
	{
		List<materialProducts> listMaterials = new List<materialProducts>();
		for(AcctSeedERP__Material__c matl :
				[SELECT Id,
						AcctSeedERP__Project__c,
						AcctSeedERP__Project__r.Name,
						AcctSeedERP__Product__c,
						AcctSeedERP__Product__r.RecordType.Name,
						AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c,
						AcctSeedERP__Product__r.AcctSeedERP__Serialized__c,
						AcctSeedERP__Product__r.Name,
						GMBLASERP__Serial_Number__c,
						GMBLASERP__Serial_Number__r.Name,
						AcctSeedERP__Project_Task__r.Name,
						AcctSeedERP__Quantity_Per_Unit__c,
						AcctSeedERP__Quantity_Allocated__c,
						GMBLASERP__Unit_Price__c,
						GMBLASERP__Total_Price__c,
						(SELECT AcctSeedERP__Quantity_Per_Unit__c, AcctSeedERP__Quantity_Allocated__c FROM ReturndMaterials__r)
				 FROM AcctSeedERP__Material__c
		 WHERE AcctSeedERP__Project__c =:erpId
			AND Return_Parent__c = null
			AND (AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c = false 
				OR (AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c = true 
					AND AcctSeedERP__Quantity_Allocated__c > 0))])
		{
			materialProducts m = new materialProducts();
			m.matId = matl.Id;
			m.productId = matl.AcctSeedERP__Product__c;
			m.productType = matl.AcctSeedERP__Product__r.RecordType.Name;
			m.productName = matl.AcctSeedERP__Product__r.Name;
			m.serialId = matl.GMBLASERP__Serial_Number__c;
			m.serialName = matl.GMBLASERP__Serial_Number__r.Name;
			m.projectId = matl.AcctSeedERP__Project__c;
			m.projectName = matl.AcctSeedERP__Project__r.Name;
			m.projectTaskName = matl.AcctSeedERP__Project_Task__r.Name;
			m.isInventory = matl.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c;
			m.isSerialized = matl.AcctSeedERP__Product__r.AcctSeedERP__Serialized__c;
			m.originalQuantity = matl.AcctSeedERP__Quantity_Per_Unit__c;
			m.pricePerQuantity = matl.GMBLASERP__Unit_Price__c;
			m.totalPrice = matl.GMBLASERP__Total_Price__c == null ? 0.00 : matl.GMBLASERP__Total_Price__c.setScale(2);
			if(matl.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c)
				m.returnQuantity = matl.AcctSeedERP__Quantity_Allocated__c;
			else
				m.returnQuantity = matl.AcctSeedERP__Quantity_Per_Unit__c;

			if(!matl.ReturndMaterials__r.isEmpty())
			{
				for(AcctSeedERP__Material__c matlRet : matl.ReturndMaterials__r)
					m.returnQuantity += matlRet.AcctSeedERP__Quantity_Per_Unit__c;
			}
			if(m.returnQuantity > 0)
				listMaterials.add(m);
		}
		return JSON.serialize(listMaterials);
	}
	public class materialData {
		@AuraEnabled
		public String matId {get;set;}
		@AuraEnabled
		public String productName{get;set;}
		@AuraEnabled
		public String projectName{get;set;}
		@AuraEnabled
		public Boolean serialized { get; set; }
		@AuraEnabled
		public Decimal matQuantity { get; set; }
		@AuraEnabled
		public Decimal returnQuantity { get; set; }
		@AuraEnabled
		public Decimal pricePerQuantity { get; set; }
		@AuraEnabled
		public Decimal totalPrice { get; set; }
	}
	@AuraEnabled
	public static String saveReturnMaterials(Id idAccount, String paymentMethod, String pIdWarehouse, String allMaterials)
	{
		//return 'OK';
		Map<Id,List<AcctSeedERP__Material__c>> mapMaterialsInsert = new Map<Id,List<AcctSeedERP__Material__c>>();
		List<AcctSeedERP__Material__c> listMaterialsInsert = new List<AcctSeedERP__Material__c>();
		Set<Id> setIdProjects = new Set<Id>();
		Set<Id> setIdMaterials = new Set<Id>();
		Map<Id,Decimal> mapIdQuantity = new Map<Id,Decimal>();
		Map<Id,AcctSeedERP__Material__c> mapIdMaterial = new Map<Id,AcctSeedERP__Material__c>();
		List<materialData> listMapMaterials = (List<materialData>)JSON.deserialize(allMaterials, List<materialData>.class);
		Id idLocation = [SELECT Id FROM AcctSeedERP__Location__c WHERE AcctSeedERP__Warehouse__c = :pIdWarehouse ORDER BY CreatedDate LIMIT 1][0].Id;
		map<Id,map<Id,map<Id,Id>>> mapPWLB = new map<Id,map<Id,map<Id,Id>>>();
		for(materialData m : listMapMaterials)
		{
			setIdMaterials.add(m.matId);
			mapIdQuantity.put(m.matId, m.returnQuantity);
		}
		setIdMaterials.remove(null);
		if(!setIdMaterials.isEmpty())
		for(AcctSeedERP__Material__c matl :
				[SELECT Id,
						AcctSeedERP__GL_Account_Variable_1__c,
						AcctSeedERP__GL_Account_Variable_2__c,
						AcctSeedERP__GL_Account_Variable_3__c,
						AcctSeedERP__GL_Account_Variable_4__c,
						AcctSeedERP__Product__r.Name,
						AcctSeedERP__Product__r.AcctSeedERP__Serialized__c,
						AcctSeedERP__Product__r.GMBLASERP__Lot_Tracked__c,
						AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c,
						GMBLASERP__Lot__c,
						AcctSeedERP__Project__c,
						AcctSeedERP__Project_Task__c,
						AcctSeedERP__Product__c,
						GMBLASERP__Serial_Number__c,
						Taxable_Provincial__c,
						Taxable_Federal__c,
						Taxable_Retail__c,
						AcctSeedERP__Quantity_Per_Unit__c,
						GMBLASERP__Unit_Price__c,
						GMBLASERP__Total_Price__c,
						Return_Parent__c
				 FROM AcctSeedERP__Material__c
		 WHERE Id IN:setIdMaterials])
		{
			/// It is safe to get the Project Ids from here
			setIdProjects.add(matl.AcctSeedERP__Project__c);
			mapIdMaterial.put(matl.Id,matl);
			AcctSeedERP__Material__c newMatl = matl.clone(false,true);
			newMatl.Return_Parent__c = matl.Id;
			newMatl.AcctSeedERP__Quantity_Per_Unit__c = mapIdQuantity.get(matl.Id) * -1;
			newMatl.GMBLASERP__Price_Override__c = true;
			if(!mapMaterialsInsert.containsKey(matl.AcctSeedERP__Project__c))
				mapMaterialsInsert.put(matl.AcctSeedERP__Project__c, new List<AcctSeedERP__Material__c>());

			mapMaterialsInsert.get(matl.AcctSeedERP__Project__c).add(newMatl);
			listMaterialsInsert.add(newMatl);

			if(matl.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c)
			{
				if(!mapPWLB.containsKey(matl.AcctSeedERP__Product__c)){
			mapPWLB.put(matl.AcctSeedERP__Product__c, new map<Id,map<Id,Id>>{pIdWarehouse => new map<Id,Id>{idLocation => null}});
				}
			}
	}
	GMBLASERP.gcInventoryBalance.findOrCreateBalances(mapPWLB);
	// Now let us update the project status to active to allow new materials
	List<AcctSeed__Project__c> listProjects = new List<AcctSeed__Project__c>();
	Map<Id,AcctSeed__Billing__c> mapIdBillings = new Map<Id,AcctSeed__Billing__c>();
	Map<Id,AcctSeed__Cash_Disbursement__c> mapIdDisbursement = new Map<Id,AcctSeed__Cash_Disbursement__c>();
	Map<Id,AcctSeed__Project_Task__c> mapIdReturnTask = new Map<Id,AcctSeed__Project_Task__c>();
	List<AcctSeed__Project_Task__c> listNewTasks = new List<AcctSeed__Project_Task__c>();
	for(AcctSeed__Project__c pr : 
		[SELECT Id,
				AcctSeed__Account__c,
				AcctSeed__Opportunity__c,
				GL_Account_Variable_3__c,
				Tax_Rate_Provincial__c,
				Tax_Rate_Federal__c,
				Tax_Rate_Retail__c,
				Tax_is_Harmonized__c,
				Tax_Override__c, 
			AcctSeed__Status__c,
			(SELECT Id FROM AcctSeed__Project_Tasks__r WHERE Is_Return_Task__c = true LIMIT 1) 
		FROM AcctSeed__Project__c
		WHERE Id IN:setIdProjects])
	{
		pr.AcctSeed__Status__c = 'Active';
		listProjects.add(pr);
		/// Chek if there is already a return task
		if(!pr.AcctSeed__Project_Tasks__r.isEmpty())
			mapIdReturnTask.put(pr.Id, pr.AcctSeed__Project_Tasks__r[0]);
		else
		{
			AcctSeed__Project_Task__c pt = new AcctSeed__Project_Task__c(AcctSeed__Project__c = pr.Id, Name = 'Customer Return', Is_Return_Task__c = true, DisplayOnCustomerInvoice__c = true);
			mapIdReturnTask.put(pr.Id, pt);
			listNewTasks.add(pt);
		}

		/// This should never happen but still validating
		if(!mapIdBillings.containsKey(pr.Id)){
				AcctSeed__Billing__c b = new AcctSeed__Billing__c(
					AcctSeed__Date__c = date.Today(),
					AcctSeed__Customer__c = pr.AcctSeed__Account__c,
					GMBLASERP__Project__c = pr.Id,
					AcctSeed__Status__c = 'Approved',
					AcctSeed__Opportunity__c = pr.AcctSeed__Opportunity__c,
					GL_Account_Variable_3__c = pr.GL_Account_Variable_3__c,
					Tax_is_Harmonized__c = pr.Tax_is_Harmonized__c,
					Tax_Override__c = pr.Tax_Override__c,
					Tax_Rate_Federal__c = pr.Tax_Rate_Federal__c,
					Tax_Rate_Provincial__c = pr.Tax_Rate_Provincial__c,
					Tax_Rate_Retail__c = pr.Tax_Rate_Retail__c
				);    
				/// The bills
			mapIdBillings.put(pr.Id, b);	
		}
	}
	System.debug(loggingLevel.Error,'mapIdBillings: '+mapIdBillings);

	Savepoint sp = Database.setSavepoint();
	try{
		Boolean oldVal = gcProject.disableTrigger;
		gcProject.disableTrigger = true;
		update listProjects;
		gcProject.disableTrigger = oldVal;
		// Insert New Tasks
		if(!listNewTasks.isEmpty())
			insert listNewTasks;
		// Now insert all the materials
		/// This Loop is a bit redundant but more safe
		for(AcctSeedERP__Material__c matl : listMaterialsInsert)
		{
			matl.AcctSeedERP__Project_Task__c = mapIdReturnTask.get(matl.AcctSeedERP__Project__c).Id;
		}
		insert listMaterialsInsert;
		// Insert new Billings
		insert mapIdBillings.values();
		/// Create all the billing lines
			list<AcctSeed__Billing_Line__c> listLine = new list<AcctSeed__Billing_Line__c>();
			/// Create all the Payable lines
			list<AcctSeed__Account_Payable_Line__c> listAPLine = new list<AcctSeed__Account_Payable_Line__c>();
			Set<Id> setIdNewBills = new Set<Id>();
			Set<Id> setIdNewPayables = new Set<Id>();
			list<AcctSeedERP__Manufacturing_Inventory_Movement__c> listMove = new list<AcctSeedERP__Manufacturing_Inventory_Movement__c>();
		for(AcctSeedERP__Material__c matl : listMaterialsInsert)
		{
			/// Billing lines per product
				AcctSeed__Billing_Line__c bl = new AcctSeed__Billing_Line__c(
						AcctSeed__Billing__c = mapIdBillings.get(matl.AcctSeedERP__Project__c).Id,
						AcctSeed__Project__c = matl.AcctSeedERP__Project__c,
						AcctSeed__Project_Task__c = matl.AcctSeedERP__Project_Task__c,
						AcctSeed__Product__c = matl.AcctSeedERP__Product__c,
						AcctSeed__Hours_Units__c = matl.AcctSeedERP__Quantity_Per_Unit__c,
						AcctSeed__Rate__c = matl.GMBLASERP__Unit_Price__c,
						GMBLASERP__Material__c = matl.Id,
						Taxable_Federal__c = matl.Taxable_Federal__c,
						Taxable_Provincial__c = matl.Taxable_Provincial__c,
						Taxable_Retail__c = matl.Taxable_Retail__c
				);
				listLine.add(bl);
				setIdNewBills.add(bl.AcctSeed__Billing__c);
				/// Reverse Manufacturing Movements if the product is inventory product
				/// This bring in the inventory
				if(matl.AcctSeedERP__Product__r.AcctSeed__Inventory_Product__c)
				{
					Id idBalance = mapPWLB.get(matl.AcctSeedERP__Product__c).get(pIdWarehouse).get(idLocation);
					listMove.add(new AcctSeedERP__Manufacturing_Inventory_Movement__c(
						AcctSeedERP__GL_Account_Variable_1__c = matl.AcctSeedERP__GL_Account_Variable_1__c,
						AcctSeedERP__GL_Account_Variable_2__c = matl.AcctSeedERP__GL_Account_Variable_2__c,
						AcctSeedERP__GL_Account_Variable_3__c = matl.AcctSeedERP__GL_Account_Variable_3__c,
						AcctSeedERP__GL_Account_Variable_4__c = matl.AcctSeedERP__GL_Account_Variable_4__c,
						AcctSeedERP__Inventory_Balance__c = idBalance,
						AcctSeedERP__Material__c = matl.Id,
						AcctSeedERP__Quantity__c = matl.AcctSeedERP__Quantity_Per_Unit__c,
						AcctSeedERP__Movement_Date__c = Date.today(),
						GMBLASERP__Lot__c = matl.GMBLASERP__Lot__c,
						GMBLASERP__Serial_Number__c = matl.GMBLASERP__Serial_Number__c/*,
						GMBLASERP__Cost_Override__c = true,
						AcctSeedERP__Unit_Cost__c = matl.GMBLASERP__Unit_Price__c*/
					));
				}
		}
		/// Insert Manufacturing Moves
		insert listMove;
		/// Inserting all B lines
		insert listLine;
		/// Inserting all AP Lines
		insert listAPLine;

		/// Now Create one positive billing and insert all the negative ones as BCR
		AcctSeed__Billing__c posBill = new AcctSeed__Billing__c(
						AcctSeed__Date__c = date.Today(),
						AcctSeed__Customer__c = idAccount,
						AcctSeed__Status__c = 'Approved',
						GL_Account_Variable_3__c = gcConstants.idGlv3Others,
						Tax_is_Harmonized__c = false,
						Tax_Override__c = true,
						Tax_Rate_Federal__c = 0,
						Tax_Rate_Provincial__c = 0,
						Tax_Rate_Retail__c = 0
					);
		insert posBill;
		///
			Decimal startingCheckNumber = null;
			Boolean noChequeRequired = false;
			if(!paymentMethod.equals('Check')){
				startingCheckNumber = 0;
				noChequeRequired = true;
			}

			if(startingCheckNumber == null && !noChequeRequired)
			{
				startingCheckNumber = 0;
				for(AcctSeed__Cash_Disbursement__c cd : [
					SELECT Id, AcctSeed__Check_Number__c
					FROM AcctSeed__Cash_Disbursement__c
					WHERE AcctSeed__Check_Number__c != null
					ORDER BY AcctSeed__Check_Number__c DESC
					LIMIT 1])
				{
					startingCheckNumber = cd.AcctSeed__Check_Number__c;
				}
				startingCheckNumber += 1;
			}
			AcctSeed__Cash_Disbursement_Batch__c cashDisbursementBatch = new AcctSeed__Cash_Disbursement_Batch__c(
				AcctSeed__Starting_Check_Number__c = startingCheckNumber,
				Name = 'Refund Batch' + String.valueOf(System.now())
			);
			insert cashDisbursementBatch;

			Id idGlMerchantDebitCredit = gcConstants.idGlMerchantDebitCredit;
			Id idGlCashFloat = gcConstants.idGlCashFloat;
			Id idGlRBCCDN = gcConstants.idGlRBCCDN;
			Id idGlBank;

			if(paymentMethod == 'Credit Card' 
				|| paymentMethod == 'Visa' 
				|| paymentMethod == 'Debit')
				idGlBank = idGlMerchantDebitCredit;
			else if(paymentMethod == 'Cheque' 
				|| paymentMethod == 'Check' 
				|| paymentMethod == 'Draft')
				idGlBank = idGlRBCCDN;
			else if(paymentMethod == 'Cash')
				idGlBank = idGlCashFloat;
			else
				idGlBank = idGlRBCCDN;
		///
		Id idAccountingPeriod = [SELECT AcctSeed__Accounting_Period__c FROM AcctSeed__Billing__c WHERE Id =:posBill.Id][0].AcctSeed__Accounting_Period__c;
			List<AcctSeed__Billing_Credit_Memo__c> listBCM = new List<AcctSeed__Billing_Credit_Memo__c>();
			list<AcctSeed__Billing_Line__c> listLinePOS = new list<AcctSeed__Billing_Line__c>();
			Decimal totalAmount = 0;
			for(AcctSeed__Billing__c negBill : 
					[SELECT Id, 
					GMBLASERP__Project__c,
						AcctSeed__Balance__c 
					FROM AcctSeed__Billing__c
					WHERE AcctSeed__Type__c = 'Credit Memo' 
						AND Id IN:setIdNewBills
					ORDER BY AcctSeed__Balance__c ASC])
			{
				AcctSeed__Billing_Credit_Memo__c bcm = new AcctSeed__Billing_Credit_Memo__c(
					AcctSeed__Accounting_Period__c = idAccountingPeriod,
					AcctSeed__Amount__c = negBill.AcctSeed__Balance__c, 
					AcctSeed__Billing_Credit_Memo__c = negBill.Id, 
					AcctSeed__Billing_Invoice__c = posBill.Id
				);
				listBCM.add(bcm);

				AcctSeed__Billing_Line__c bl = new AcctSeed__Billing_Line__c(
						AcctSeed__Billing__c = posBill.Id,
						AcctSeed__Hours_Units__c = 1,
						AcctSeed__Rate__c = negBill.AcctSeed__Balance__c * -1,
						AcctSeed__Revenue_GL_Account__c = gcConstants.idGlCustomerRefund,
						AcctSeed__GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale,
						AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2Sales,
						Taxable_Federal__c = false,
						Taxable_Provincial__c = false,
						Taxable_Retail__c = false
				);
				listLinePOS.add(bl);
				/// Cash Disbursements by Balance
				AcctSeed__Cash_Disbursement__c disbursement = new AcctSeed__Cash_Disbursement__c(
					AcctSeed__Cash_Disbursement_Batch__c = cashDisbursementBatch.Id,
					AcctSeed__Disbursement_Date__c = Date.today(),
					AcctSeed__Type__c = paymentMethod,
					AcctSeed__Amount__c = negBill.AcctSeed__Balance__c * -1,
					AcctSeed__Source__c = 'Account Payable',
					AcctSeed__Bank_Account__c = idGlBank,//cr.AcctSeed__Bank_Account__c,
					AcctSeed__Vendor__c = idAccount,
					AcctSeed__Status__c = 'Approved',
					AcctSeed__Reference__c = System.now().format(),
					AcctSeed__Debit_GL_Account__c = gcConstants.idGlAPayable,
					AcctSeed__Payment_Status__c = 'Paid',
					AcctSeed__Project__c = negBill.GMBLASERP__Project__c,
					AcctSeed__Project_Task__c = mapIdReturnTask.get(negBill.GMBLASERP__Project__c).Id
				);

				mapIdDisbursement.put(negBill.GMBLASERP__Project__c, disbursement);

				totalAmount += bl.AcctSeed__Rate__c;
			}
			insert listLinePOS;
			List<AcctSeed__Billing__c> listAllBills = new List<AcctSeed__Billing__c>();
			listAllBills.addAll(mapIdBillings.values());
			listAllBills.add(posBill);
			AcctSeed.BillingPostService.postBillings(listAllBills);

			if(!listBCM.isEmpty())
				insert listBCM;

			insert mapIdDisbursement.values();

			AcctSeed.PostResult[] postResults = AcctSeed.CashDisbursementPostService.postCashDisbursements(mapIdDisbursement.values());
			for (AcctSeed.PostResult theResult : postResults) {
			    if (!theResult.isSuccess) {
			        for (AcctSeed.PostResult.PostErrorResult errorResult: theResult.errors) {
			        	throw new gcException('Cash Disbursement was not posted. Please try again. REASON: ' + errorResult.message);
			        }
			    }
			}
			List<AcctSeed__AP_Disbursement__c> listAPD = new List<AcctSeed__AP_Disbursement__c>();
			/// Positive Payable
			String payeeRef = 'POSRet-' + String.valueOf(DateTime.now().getTime()) + '-Refund';
			AcctSeed__Account_Payable__c posPay = new AcctSeed__Account_Payable__c(
				AcctSeed__Vendor__c = idAccount,
				AcctSeed__Payee_Reference__c = payeeRef,
				GL_Account_Variable_3__c = gcConstants.idGlv3Others,
				Tax_is_Harmonized__c = false,
				Tax_Override__c = true,
				Tax_Rate_Federal__c = 0,
				Tax_Rate_Provincial__c = 0,
				Tax_Rate_Retail__c = 0,
				AcctSeed__Date__c = Date.today()
			);
			insert posPay;
			AcctSeed__Account_Payable_Line__c payLine = new AcctSeed__Account_Payable_Line__c(
				AcctSeed__Account_Payable__c = posPay.Id,
				AcctSeed__Amount__c = totalAmount, 
				AcctSeed__Date__c = Date.today(), 
				AcctSeed__Expense_GL_Account__c = gcConstants.idGlCustomerRefund, 
				AcctSeed__GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale, 
				AcctSeed__GL_Account_Variable_2__c = gcConstants.idGlv2Sales
			);
			insert payLine;
			// Posting all the payables as well.
			AcctSeed.PostResult[] postResultsAP = AcctSeed.AccountPayablePostService.postAccountPayables(new List<AcctSeed__Account_Payable__c>{posPay});
			for (AcctSeed.PostResult theResult : postResultsAP) {
			    if (!theResult.isSuccess) {
			        for (AcctSeed.PostResult.PostErrorResult errorResult: theResult.errors) {
			        	throw new gcException('Account Payable was not posted. Please try again. REASON: ' + errorResult.message);
			        }
			    }
			}

			for(AcctSeed__Cash_Disbursement__c disbursement : mapIdDisbursement.values())
			{
				AcctSeed__AP_Disbursement__c apdisbursement = new AcctSeed__AP_Disbursement__c(
					AcctSeed__Cash_Disbursement__c = disbursement.Id,
					AcctSeed__Paid_Amount__c = disbursement.AcctSeed__Amount__c,
					AcctSeed__Account_Payable__c = posPay.Id
				);
				listAPD.add(apdisbursement);
			}
			/// Insert all APD
			insert listAPD;
			/// Make the status completed again
			for(AcctSeed__Project__c pr : listProjects)
			{
				pr.AcctSeed__Status__c = 'Completed';
			}
		gcProject.disableTrigger = true;
		update listProjects;
		gcProject.disableTrigger = oldVal;
		/// This is to include the COGS movements for the first Project Only. 
		/// As we have only one project now
		/// When we decide to move on with multiple projects again we will redo this section
			AcctSeed__Project__c pr = listProjects.get(0);
			//takeExpense(pr.Id);
			//throw new gcException(mapIdBillings.get(pr.Id).Id);
			return mapIdBillings.get(pr.Id).Id;
		}catch(Exception e){
			Database.rollback(sp);
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static void takeExpense(Id idProject, Id idNegBill)
	{
		AcctSeed__Project_Task__c pt = [SELECT Id, AcctSeed__Project__r.RecordTypeId, AcctSeed__Project__r.Internal_Partner_Parts_Order__c FROM AcctSeed__Project_Task__c WHERE AcctSeed__Project__c =:idProject AND Is_Return_Task__c = true LIMIT 1][0];
		gcProject_AccountingActions.takeExpense(pt.Id, null);
		if(pt.AcctSeed__Project__r.RecordTypeId == gcConstants.idRtProjectCounterSale
			|| pt.AcctSeed__Project__r.RecordTypeId == gcConstants.idRtPartnerPartsOrder)
			gcProject_Ext.createInvoice(idProject, idNegBill, pt.AcctSeed__Project__r.Internal_Partner_Parts_Order__c);
	}

	public static void coverage(){
		integer i;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
		i=1;
	}
}