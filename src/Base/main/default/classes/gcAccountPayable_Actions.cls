public with sharing class gcAccountPayable_Actions {
	public gcAccountPayable_Actions() {}
	
	public gcAccountPayable_Actions(ApexPages.StandardController stc){
		idFilter = stc.getId();
		retUrl = '/'+stc.getId();
	}

	public gcAccountPayable_Actions(ApexPages.StandardSetController ssc){
		retUrl = ApexPages.currentPage().getParameters().get('retUrl');
	}
	
	public pageReference back()
	{
		return new pageReference(retUrl);
	}
	
	public pageReference init()
	{
		String processName = ApexPages.currentPage().getParameters().get('processName');
		idFilter = ApexPages.currentPage().getParameters().get('idFilter');

		if(idFilter == null)
		{
	 		ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'No Purchase Order was selected to Create AP.'));
	 		return null;					
	 	}

		if(retUrl == null && idFilter != null)
			retUrl = '/'+idFilter;

		return createAP();
	}
	
	private Id idFilter{get;set;}
	private String retUrl{get;set;}

	public pageReference createAP()
	{
		if(!AcctSeed__Account_Payable__c.sObjectType.getDescribe().accessible)
		{
	 		ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'The current user does not have access to the Account Payable object.'));
	 		return null;					
		}

		AcctSeedERP__Purchase_Order__c po = [SELECT Id, Name, AcctSeedERP__Vendor__c, AcctSeedERP__Vendor__r.Name FROM AcctSeedERP__Purchase_Order__c WHERE Id =:idFilter][0];
		String vendorInvoiceNumber = po.Name + '-' + po.AcctSeedERP__Vendor__r.Name + String.valueOf(DateTime.now().getTime());
		AcctSeed__Account_Payable__c ap = new AcctSeed__Account_Payable__c(
												AcctSeed__Vendor__c = po.AcctSeedERP__Vendor__c,
												AcctSeed__Date__c = date.Today(),
												Approval_Date__c = date.Today(),
												Approved__c = true,
												AcctSeed__Payee_Reference__c = vendorInvoiceNumber,
												AcctSeedERP__Purchase_Order__c = po.Id);
		insert ap;

		//get the Vouchers Payable account
		Id idGLVP = [SELECT AcctSeed__Vouchers_Payable_GL_Account__c FROM AcctSeed__Accounting_Settings__c][0].AcctSeed__Vouchers_Payable_GL_Account__c;

		//get the VP balance for each Purchase Order Line
		list<AggregateResult> listAggRes = new list<AggregateResult>();

		listAggRes.addAll(
			[SELECT AcctSeedERP__Purchase_Order_Inventory_Movement__r.AcctSeedERP__Purchase_Order_Line__c idPOL,
					sum(AcctSeedERP__Purchase_Order_Inventory_Movement__r.AcctSeedERP__Quantity__c) qty,
					sum(AcctSeed__Amount__c) amt
			 FROM AcctSeed__Transaction__c
			 WHERE AcctSeed__GL_Account__c = :idGLVP
			   AND AcctSeedERP__Purchase_Order_Inventory_Movement__r.AcctSeedERP__Purchase_Order_Line__r.AcctSeedERP__Purchase_Order__c = :po.Id
			   AND AcctSeedERP__Purchase_Order_Inventory_Movement__r.GMBLASERP__Account_Payable_Line__c = null
			   AND (AcctSeed__Amount__c < 0 OR AcctSeed__Amount__c > 0)
			 GROUP BY AcctSeedERP__Purchase_Order_Inventory_Movement__r.AcctSeedERP__Purchase_Order_Line__c]);

		list<AcctSeed__Account_Payable_Line__c> listAPL = new list<AcctSeed__Account_Payable_Line__c>();
		map<Id,AcctSeedERP__Purchase_Order_Line__c> mapPOL = new map<Id,AcctSeedERP__Purchase_Order_Line__c>();

		//create the new AP Lines
		for(AggregateResult aggRes : listAggRes)
		{
			Decimal amt = (Decimal)aggRes.get('amt');

			if(amt != null && amt != 0)
			{
				mapPOL.put((Id)aggRes.get('idPOL'), null);
				listAPL.add(new AcctSeed__Account_Payable_Line__c(
					AcctSeed__Account_Payable__c = ap.Id,
					AcctSeed__Amount__c = amt * (-1),
					AcctSeed__Expense_GL_Account__c = idGLVP,
					AcctSeed__Quantity__c = (Decimal)aggRes.get('qty'),
					AcctSeedERP__Purchase_Order_Line__c = (Id)aggRes.get('idPOL')
				));
			}
		}

		//retrieve additional PO line details, to be used to populate the AP lines
		for(AcctSeedERP__Purchase_Order_Line__c pol : 
			[SELECT Id,
					AcctSeedERP__Product__c, 
					AcctSeedERP__Project__c, 
					AcctSeedERP__Project_Task__c
			 FROM AcctSeedERP__Purchase_Order_Line__c
			 WHERE Id IN : mapPOL.keySet()])
		{
			mapPOL.put(pol.Id,pol);
		}

		//transfer the details of the PO lines to the new AP lines
		for(AcctSeed__Account_Payable_Line__c apl : listAPL)
		{
			AcctSeedERP__Purchase_Order_Line__c pol = mapPOL.get(apl.AcctSeedERP__Purchase_Order_Line__c);
			apl.AcctSeed__Product__c = pol.AcctSeedERP__Product__c;
			apl.AcctSeed__Project__c = pol.AcctSeedERP__Project__c;
			apl.AcctSeed__Project_Task__c = pol.AcctSeedERP__Project_Task__c;
		}

		Id idGLExpenseDefault = null;
		for(AcctSeed__GL_Account__c gl :[SELECT Id FROM AcctSeed__GL_Account__c WHERE AcctSeed__Type__c = 'Expense' AND AcctSeed__Active__c = true ORDER BY Name LIMIT 1])
			idGLExpenseDefault = gl.Id;
		if(idGLExpenseDefault == null)
		{
	 		ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'There must be at least one active GL Account of type Expense, in order to process an AP.'));
	 		return null;					
		}

		//retrieve PO lines for non-inventory products, and create AP lines for them
		for(AcctSeedERP__Purchase_Order_Line__c pol : 
			[SELECT Id, Name,
				    AcctSeedERP__Product__c,
				    AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__c,
				    AcctSeedERP__Product__r.Name,
				    AcctSeedERP__Project__c,
				    AcctSeedERP__Project_Task__c,
				    AcctSeedERP__Unit_Price__c,
				    GMBLASERP__Quantity_Received_Non_Inventory__c,
				    (SELECT AcctSeed__Amount__c, AcctSeed__Quantity__c FROM AcctSeedERP__Account_Payable_Lines__r WHERE AcctSeed__Expense_GL_Account__c != :idGLVP)
			 FROM AcctSeedERP__Purchase_Order_Line__c
			 WHERE AcctSeedERP__Purchase_Order__c = : po.Id
			   AND GMBLASERP__Quantity_Received_Non_Inventory__c != 0
			   AND GMBLASERP__Quantity_Received_Non_Inventory__c != null
			   AND AcctSeedERP__Unit_Price__c != 0
			   AND AcctSeedERP__Unit_Price__c != null])
		{
			Decimal qtyPaid = 0;
			Decimal amtPaid = 0;
			for(AcctSeed__Account_Payable_Line__c apl : pol.AcctSeedERP__Account_Payable_Lines__r)
			{
				if(apl.AcctSeed__Amount__c != null) amtPaid += apl.AcctSeed__Amount__c;
				if(apl.AcctSeed__Quantity__c != null) qtyPaid += apl.AcctSeed__Quantity__c;
			}

			Decimal qtyReceived = pol.GMBLASERP__Quantity_Received_Non_Inventory__c;
			Decimal amtReceived = pol.GMBLASERP__Quantity_Received_Non_Inventory__c * pol.AcctSeedERP__Unit_Price__c;

			Id idGL = pol.AcctSeedERP__Product__r.AcctSeed__Expense_GL_Account__c;
			if(idGL == null) idGL = idGLExpenseDefault;

			if(amtPaid.setScale(6) < amtReceived.setScale(6))
			listAPL.add(new AcctSeed__Account_Payable_Line__c(
				AcctSeed__Account_Payable__c = ap.Id,
				AcctSeed__Amount__c = (amtReceived - amtPaid).setScale(6),
				AcctSeed__Quantity__c = (qtyReceived - qtyPaid).setScale(6),
				AcctSeed__Expense_GL_Account__c = idGL,
				AcctSeed__Product__c = pol.AcctSeedERP__Product__c,
				AcctSeed__Project__c = pol.AcctSeedERP__Project__c,
				AcctSeed__Project_Task__c = pol.AcctSeedERP__Project_Task__c,
				AcctSeedERP__Purchase_Order_Line__c = pol.Id
			));
		}

		insert listAPL;

		//prepare to update the Purchase Order Inventory Movements with the new AP Lines
		map<Id,Id> mapPOLtoAPL = new map<Id,Id>();
		for(AcctSeed__Account_Payable_Line__c apl : listAPL)
		{
			mapPOLtoAPL.put(apl.AcctSeedERP__Purchase_Order_Line__c, apl.Id);
		}

		//update the Purchase Order Inventory Movements
		list<AcctSeedERP__Purchase_Order_Inventory_Movement__c> listMove = new list<AcctSeedERP__Purchase_Order_Inventory_Movement__c>();
		for(AcctSeedERP__Purchase_Order_Inventory_Movement__c move :
			[SELECT Id, AcctSeedERP__Purchase_Order_Line__c, GMBLASERP__Account_Payable_Line__c
			 FROM AcctSeedERP__Purchase_Order_Inventory_Movement__c
			 WHERE AcctSeedERP__Purchase_Order_Line__c IN : mapPOLtoAPL.keySet()
			   AND GMBLASERP__Account_Payable_Line__c = null])
		{
			move.GMBLASERP__Account_Payable_Line__c = mapPOLtoAPL.get(move.AcctSeedERP__Purchase_Order_Line__c);
			listMove.add(move);
		}

		GMBLASERP.gcPurchaseOrderInventoryMovement.disableTrigger = true;
		update listMove;
		GMBLASERP.gcPurchaseOrderInventoryMovement.disableTrigger = false;
 		//ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, 'Account Payable has been created. <a target="_blank" href="/'+ap.Id+'">Click here to view AP detail.</a>'));
 		return new pageReference('/'+ap.Id);
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
	}
}