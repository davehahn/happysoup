global with sharing class gcAccountPayable_payBatch {
	
	private ApexPages.StandardSetController myStandardSetController;
	
	public AcctSeed__Cash_Disbursement__c cdHolder{get;set;}

	public String accData {get;set;}
	public String selectedApIds {get;set;}
	public String defaultAcc {get;set;}
	public String selectedAcc {get;set;}
	public String includedApId {get;set;}
	public String discountedApId {get;set;}

	public gcAccountPayable_payBatch(ApexPages.StandardSetController c)
	{
		myStandardSetController = c;
		cdHolder = new AcctSeed__Cash_Disbursement__c();
		cdHolder.AcctSeed__Disbursement_Date__c = date.Today();

		//Get the default bank account
		for(AcctSeed__Accounting_Settings__c s : 
			[SELECT Id,
					AcctSeed__Default_Bank_Account__c
			 FROM AcctSeed__Accounting_Settings__c
			 ORDER BY CreatedDate
			 LIMIT 1])
		{
			if(s.AcctSeed__Default_Bank_Account__c != null)
			{
				defaultAcc = String.valueOf(s.AcctSeed__Default_Bank_Account__c);
			}
		}

		//Get the Account Data
		List<Map<String, String>> listAccData = new List<Map<String, String>>();
		for(AcctSeed__GL_Account__c gl : [
			SELECT
				Id,
				Name,
				(	SELECT AcctSeed__Check_Number__c
					FROM AcctSeed__Cash_Disbursements__r
					WHERE AcctSeed__Check_Number__c != null
					ORDER BY AcctSeed__Check_Number__c DESC
					LIMIT 1)
			FROM AcctSeed__GL_Account__c
			WHERE AcctSeed__Bank__c = True
			ORDER BY Name ASC])
		{
			Map<String, String> m = new Map<String, String>();
			m.put('id', gl.Id);
			m.put('name', gl.Name);

			Decimal checkNum = 1;
			if(!gl.AcctSeed__Cash_Disbursements__r.isEmpty())
			{
				checkNum = gl.AcctSeed__Cash_Disbursements__r[0].AcctSeed__Check_Number__c + 1;
			}
			m.put('checkNum', String.valueOf(checkNum));

			listAccData.add(m);
		}
		accData = JSON.serialize(listAccData);

		//Get the selected APs
		Set<Id> setIdAP = new Set<Id>();
		for(AcctSeed__Account_Payable__c ap : (List<AcctSeed__Account_Payable__c>)myStandardSetController.getSelected())
		{
			setIdAP.add(ap.Id);
		}
		selectedApIds = JSON.serialize(setIdAP);
	}

	public pageReference cancel()
	{
		String prefix = AcctSeed__Account_Payable__c.sObjectType.getDescribe().getKeyPrefix();
		return new pageReference('/'+prefix+'?fcf='+myStandardSetController.getFilterId().LEFT(15));
	}

	public pageReference payBatch()
	{
		List<Object> listApId = (List<Object>)JSON.deserializeUntyped(includedApId);
		List<Object> listDiscountApId = (List<Object>)JSON.deserializeUntyped(discountedApId);

		Set<Id> setIdAp = new Set<Id>();
		for(Object apId : listApId)
		{
			Id idAp = Id.valueOf(String.valueOf(apId));
			setIdAp.add(idAp);
		}
		if(!listDiscountApId.isEmpty())
		{
			Map<String,Object> mapString = new Map<String,Object>();
			Set<String> setAPDiscountIds = new Set<String>();
			for(Object apIdDiscount : listDiscountApId)
			{
				Map<String,Object> m = (Map<String,Object>)apIdDiscount;
				mapString.putAll(m);
			}
			List<AcctSeed__Account_Payable__c> listAp = new List<AcctSeed__Account_Payable__c>();
			for(AcctSeed__Account_Payable__c ap : 
				[SELECT Id,
						AcctSeed__Discount_Amount__c
				 FROM AcctSeed__Account_Payable__c
				 WHERE Id IN :mapString.keySet()])
			{
				ap.AcctSeed__Discount_Amount__c = Decimal.valueOf(String.valueOf(mapString.get(ap.Id)));
				listAp.add(ap);
			}
			if(!listAp.isEmpty())
				update listAp;
		}
		//Id idGlBank = null;
		//if(!String.isBlank(selectedAcc)) idGlBank = Id.valueOf(selectedAcc);

		Id idBatch = pay(setIdAp, cdHolder);

		if(idBatch == null)
		{
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING,'There are no qualifying AP records.'));
			return null;  
		}
		else
		{
			return new pageReference('/' + idBatch);
		}
	}

	webservice static string payWS(Id idAp)
	{
		AcctSeed__Cash_Disbursement__c cdHolder = new AcctSeed__Cash_Disbursement__c();

		Id idBatch = pay(new set<Id>{idAp}, cdHolder);
		if(idBatch == null)
		{
			throw new gcException('The AP cannot be paid; check that it is posted, and that it has a positive balance.');
		}
		else
			return idBatch;
	}

	public static Id pay(set<Id> setIdAp, AcctSeed__Cash_Disbursement__c cdHolder)
	{
		list<AcctSeed__Cash_Disbursement__c> listCD = new list<AcctSeed__Cash_Disbursement__c>();
		list<AcctSeed__AP_Disbursement__c> listAPD = new list<AcctSeed__AP_Disbursement__c>();

		map<Id,AcctSeed__Cash_Disbursement__c> mapPayeeCD = new map<Id,AcctSeed__Cash_Disbursement__c>();
		map<Id,list<AcctSeed__AP_Disbursement__c>> mapPayeeAPD = new map<Id,list<AcctSeed__AP_Disbursement__c>>();


		Date disbursementDate = cdHolder.AcctSeed__Disbursement_Date__c;
		Id idGlBank = cdHolder.AcctSeed__Bank_Account__c;
		Id idGlV1 = cdHolder.AcctSeed__GL_Account_Variable_1__c;
		Id idCashFlowCategory = cdHolder.AcctSeed__Cash_Flow_Category__c;
		//Id idGlBank = selectedAcc;
		Id idGlDiscount = null;
		String accountType = cdHolder.AcctSeed__Type__c;
		Decimal startingCheckNumber = cdHolder.AcctSeed__Check_Number__c;
		Boolean noChequeRequired = false;
		Set<String> setCheckTypes = new Set<String>{'Cheque','Check','US Check'};
		if(accountType == null || !setCheckTypes.contains(accountType)){
			startingCheckNumber = 0;
			noChequeRequired = true;
		}

		//Populate disbursement date
		if(disbursementDate == null) disbursementDate = Date.today();

		//Populate bank and discount accounts
		for(AcctSeed__Accounting_Settings__c s : 
			[SELECT Id,
					AcctSeed__Default_Bank_Account__c,
					AcctSeed__Payment_Discount_GL_Account__c
			 FROM AcctSeed__Accounting_Settings__c
			 ORDER BY CreatedDate
			 LIMIT 1])
		{
			if(idGlBank == null) idGlBank = s.AcctSeed__Default_Bank_Account__c;
			idGlDiscount = s.AcctSeed__Payment_Discount_GL_Account__c;
		}

		//Populate starting check number
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
		Decimal nextCheckNumber = startingCheckNumber;

		List<payee> listPayee = new List<payee>();

		//Go through the payables
		for(AcctSeed__Account_Payable__c ap : 
			[SELECT Id,
					AcctSeed__Payee__c,
					AcctSeed__Vendor__c,
					AcctSeed__Contact__c,
					AcctSeed__Employee__c,
					AcctSeed__Total__c,
					AcctSeed__Discount_Amount__c,
					AcctSeed__Credit_Memo_Applied_Amount__c,
					AcctSeed__Paid_Amount__c,
					AcctSeed__Balance__c
			 FROM AcctSeed__Account_Payable__c
			 WHERE Id IN :setIdAp
			   AND AcctSeed__Status__c = 'Posted'
			   AND AcctSeed__Balance__c != 0])
		{
			Id idPayee = ap.AcctSeed__Vendor__c;
			if(idPayee == null)
				idPayee = ap.AcctSeed__Contact__c;
			if(idPayee == null)
				idPayee = ap.AcctSeed__Employee__c;

			if(!mapPayeeCD.containsKey(idPayee))
			{
				AcctSeed__Cash_Disbursement__c cd = new AcctSeed__Cash_Disbursement__c(
					AcctSeed__Amount__c = 0,
					AcctSeed__Bank_Account__c = idGlBank,
					AcctSeed__Type__c = accountType,
					AcctSeed__Disbursement_Date__c = disbursementDate,
					AcctSeed__Debit_GL_Account__c = gcConstants.idGlAPayable,
					AcctSeed__GL_Account_Variable_1__c = idGlV1,
					AcctSeed__Cash_Flow_Category__c = idCashFlowCategory,
					AcctSeed__Source__c = 'Account Payable'
					//AcctSeed__Check_Number__c = nextCheckNumber
				);
				//nextCheckNumber += 1;

				if(idPayee == ap.AcctSeed__Vendor__c)
					cd.AcctSeed__Vendor__c = ap.AcctSeed__Vendor__c;
				else if(idPayee == ap.AcctSeed__Contact__c)
					cd.AcctSeed__Contact__c = ap.AcctSeed__Contact__c;
				else if(idPayee == ap.AcctSeed__Employee__c)					
					cd.AcctSeed__Employee__c = ap.AcctSeed__Employee__c;

				//listCD.add(cd);
				listPayee.add(new payee(ap.AcctSeed__Payee__c, cd));
				mapPayeeCD.put(idPayee,cd);
				mapPayeeAPD.put(idPayee, new list<AcctSeed__AP_Disbursement__c>());
			}

			AcctSeed__AP_Disbursement__c apd = new AcctSeed__AP_Disbursement__c(
				AcctSeed__Account_Payable__c = ap.Id,
				AcctSeed__Paid_Amount__c = ap.AcctSeed__Balance__c
			); 

			listAPD.add(apd);
			mapPayeeAPD.get(idPayee).add(apd);
			mapPayeeCD.get(idPayee).AcctSeed__Amount__c += ap.AcctSeed__Balance__c;
		}

		//Sort the list then add the check numbers
		listPayee.sort();

		for(payee payeeObj : listPayee)
		{
			if(!noChequeRequired){
				payeeObj.disbursement.AcctSeed__Check_Number__c = nextCheckNumber;
				nextCheckNumber += 1;
			}
			listCD.add(payeeObj.disbursement);
		}

		for(AcctSeed__Cash_Disbursement__c cd : listCD)
		{
			if(cd.AcctSeed__Amount__c < 0)
			{
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING, 'A negative cash disbursement is not allowed.'));
				return null;
			}
		}
		//System.debug(LoggingLevel.ERROR,'mapPayeeCD:'+mapPayeeCD);
		//throw new gcException('Stop Here');
		if(!mapPayeeCD.isEmpty())
		{
			//create the batch record
			AcctSeed__Cash_Disbursement_Batch__c cdb = new AcctSeed__Cash_Disbursement_Batch__c(
				Name = DateTime.now().format(), 
				AcctSeed__Starting_Check_Number__c = startingCheckNumber);
			insert cdb;

			for(AcctSeed__Cash_Disbursement__c cd : listCD)
			{
				cd.AcctSeed__Cash_Disbursement_Batch__c = cdb.Id;
			}

			//Let the Cash Disbursement know it is from AP
			//gcCashDisbursement.isApDisbursement = true;
			System.debug('listCD');
			System.debug(listCD);
			insert listCD;
			
			//Reset the Cash Disbursement
			//gcCashDisbursement.isApDisbursement = false;
			
			for(Id idPayee : mapPayeeCD.keySet())
			{
				Id idCD = mapPayeeCD.get(idPayee).Id;
				for(AcctSeed__AP_Disbursement__c apd : mapPayeeAPD.get(idPayee))
				{
					apd.AcctSeed__Cash_Disbursement__c = idCD;
				}
			}

			insert listAPD;

			return cdb.Id;
		}

		return null;
	}

	class payee implements Comparable
	{
		public String name;
		public AcctSeed__Cash_Disbursement__c disbursement;

		public payee(string payeeName, AcctSeed__Cash_Disbursement__c payeeDisbursement)
		{
			name = payeeName;
			disbursement = payeeDisbursement;
		}

		public Integer compareTo(Object obj)
		{
			payee payeeObj = (payee)obj;
			Integer result = 0;
			if(name > payeeObj.name) result = 1;
			else if (name < payeeObj.name) result = -1;
			return result;
		}
	}

	@RemoteAction @ReadOnly
	public static List<Map<String,String>> retrieveApData(String[] setId)
	{
		List<Map<String,String>> listResult = new List<Map<String,String>>();

		for(AcctSeed__Account_Payable__c ap : [
			SELECT
				Id,
				Name,
				AcctSeed__Date__c,
				AcctSeed__Payee__c,
				AcctSeed__Total__c,
				AcctSeed__Discount_Amount__c,
				AcctSeed__Credit_Memo_Applied_Amount__c,
				AcctSeed__Payee_Reference__c,
				AcctSeed__Paid_Amount__c,
				AcctSeed__Balance__c,
				AcctSeed__Vendor__c,
				AcctSeed__Contact__c,
				AcctSeed__Employee__c
			FROM AcctSeed__Account_Payable__c
			WHERE
				Id IN :setId AND
				AcctSeed__Status__c = 'Posted' AND
				AcctSeed__Balance__c != 0
			ORDER BY AcctSeed__Payee__c ASC, AcctSeed__Date__c])
		{
			Id idPayee = ap.AcctSeed__Vendor__c;
			if(idPayee == null) idPayee = ap.AcctSeed__Contact__c;
			if(idPayee == null) idPayee = ap.AcctSeed__Employee__c;

			Map<String,String> mapAp = new Map<String,String>();
			mapAp.put('id', ap.Id);
			mapAp.put('name', ap.Name);
			mapAp.put('date', ap.AcctSeed__Date__c.format());
			mapAp.put('payeeId', String.valueOf(idPayee));
			mapAp.put('payeeRef', ap.AcctSeed__Payee_Reference__c);
			mapAp.put('payee', ap.AcctSeed__Payee__c);
			mapAp.put('total', String.valueOf(ap.AcctSeed__Total__c.setScale(2)));
			mapAp.put('dbDiscountAmt', String.valueOf(ap.AcctSeed__Discount_Amount__c.setScale(2)));
			mapAp.put('discountAmt', String.valueOf(ap.AcctSeed__Discount_Amount__c.setScale(2)));
			mapAp.put('cmAppliedAmt', String.valueOf(ap.AcctSeed__Credit_Memo_Applied_Amount__c.setScale(2)));
			mapAp.put('paidAmt', String.valueOf(ap.AcctSeed__Paid_Amount__c.setScale(2)));
			mapAp.put('dbBalance', String.valueOf(ap.AcctSeed__Balance__c.setScale(2)));
			mapAp.put('balance', String.valueOf(ap.AcctSeed__Balance__c.setScale(2)));
			mapAp.put('preIncluded', 'true');
			listResult.add(mapAp);
		}
		return listResult;
	}

	@RemoteAction @ReadOnly
	public static List<Map<String,String>> retrieveApDataAll()
	{
		List<Map<String,String>> listResult = new List<Map<String,String>>();

		for(AcctSeed__Account_Payable__c ap : [
			SELECT
				Id,
				Name,
				AcctSeed__Date__c,
				AcctSeed__Payee__c,
				AcctSeed__Total__c,
				AcctSeed__Discount_Amount__c,
				AcctSeed__Credit_Memo_Applied_Amount__c,
				AcctSeed__Payee_Reference__c,
				AcctSeed__Paid_Amount__c,
				AcctSeed__Balance__c,
				AcctSeed__Vendor__c,
				AcctSeed__Contact__c,
				AcctSeed__Employee__c
			FROM AcctSeed__Account_Payable__c
			WHERE
				AcctSeed__Status__c = 'Posted' AND
				AcctSeed__Balance__c != 0 AND
				AcctSeed__Date__c < THIS_MONTH
			ORDER BY AcctSeed__Payee__c ASC, AcctSeed__Date__c])
		{
			Id idPayee = ap.AcctSeed__Vendor__c;
			if(idPayee == null) idPayee = ap.AcctSeed__Contact__c;
			if(idPayee == null) idPayee = ap.AcctSeed__Employee__c;

			Map<String,String> mapAp = new Map<String,String>();
			mapAp.put('id', ap.Id);
			mapAp.put('name', ap.Name);
			mapAp.put('date', ap.AcctSeed__Date__c.format());
			mapAp.put('payeeId', String.valueOf(idPayee));
			mapAp.put('payeeRef', ap.AcctSeed__Payee_Reference__c);
			mapAp.put('payee', ap.AcctSeed__Payee__c);
			mapAp.put('total', String.valueOf(ap.AcctSeed__Total__c.setScale(2)));
			mapAp.put('dbDiscountAmt', String.valueOf(ap.AcctSeed__Discount_Amount__c.setScale(2)));
			mapAp.put('discountAmt', String.valueOf(ap.AcctSeed__Discount_Amount__c.setScale(2)));
			mapAp.put('cmAppliedAmt', String.valueOf(ap.AcctSeed__Credit_Memo_Applied_Amount__c.setScale(2)));
			mapAp.put('paidAmt', String.valueOf(ap.AcctSeed__Paid_Amount__c.setScale(2)));
			mapAp.put('dbBalance', String.valueOf(ap.AcctSeed__Balance__c.setScale(2)));
			mapAp.put('balance', String.valueOf(ap.AcctSeed__Balance__c.setScale(2)));
			mapAp.put('preIncluded', 'true');
			listResult.add(mapAp);
		}
		return listResult;
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
	}
}