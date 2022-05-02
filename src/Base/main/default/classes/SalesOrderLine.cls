public without sharing class SalesOrderLine {


	public static Boolean disableTrigger{
		get{
			if(disableTrigger == null) return false;
			else return disableTrigger;
		}
		set{
			if(value == null) disableTrigger = false;
			else disableTrigger = value;
		}
	}

	public static Boolean disableAutosetTaxable{
		get{
			if(disableAutosetTaxable == null) return false;
			else return disableAutosetTaxable;
		}
		set{
			if(value == null) disableAutosetTaxable = false;
			else disableAutosetTaxable = value;
		}
	}

	public static void triggerHandler
		(map<Id,AcctSeedERP__Sales_Order_Line__c> oldMap,
		 map<Id,AcctSeedERP__Sales_Order_Line__c> newMap,
		 list<AcctSeedERP__Sales_Order_Line__c> listNew,
		 Boolean boolIsBefore,
		 Boolean boolIsInsert,
		 Boolean boolIsUpdate,
		 Boolean boolIsDelete)
	{
		if(oldMap == NULL) oldMap = new map<Id,AcctSeedERP__Sales_Order_Line__c>();
		if(newMap == NULL) newMap = new map<Id,AcctSeedERP__Sales_Order_Line__c>();
		if(listNew == NULL) listNew = new list<AcctSeedERP__Sales_Order_Line__c>();

		//updateAndValidate(oldMap,newMap,listNew,boolIsBefore,boolIsInsert,boolIsUpdate,boolIsDelete);

		if(boolIsBefore)
		{
			/*if(boolIsInsert)
			{
				setFinancialAttributes(listNew);
			}
			if(boolIsUpdate)
			{
				setFinancialAttributes(listNew);
			}
			if(boolIsDelete)
			{

			}*/
		}
		else //i.e. trigger.isAfter
		{
			set<Id> setIdBill = new set<Id>();
			if(boolIsInsert)
			{
				for(AcctSeedERP__Sales_Order_Line__c b : listNew)
					setIdBill.add(b.AcctSeedERP__Sales_Order__c);
                System.debug('setIdBill insert= '+setIdBill);
			}
			if(boolIsUpdate)
			{
				for(AcctSeedERP__Sales_Order_Line__c b : listNew)
					setIdBill.add(b.AcctSeedERP__Sales_Order__c);
				for(AcctSeedERP__Sales_Order_Line__c b : oldMap.values())
					setIdBill.add(b.AcctSeedERP__Sales_Order__c);
                System.debug('setIdBill update= '+setIdBill);
			}
			if(boolIsDelete)
			{
				for(AcctSeedERP__Sales_Order_Line__c b : oldMap.values())
					setIdBill.add(b.AcctSeedERP__Sales_Order__c);
			}
			updateSalesTax(setIdBill);
		}
	}

    	public static void updateSalesTax(set<Id> setIdBilling)
		{ 
		Id idProductSalesTaxFederal	   = gcConstants.idProductSalesTaxFederal;
		Id idProductSalesTaxProvincial = gcConstants.idProductSalesTaxProvincial;
		Id idProductSalesTaxRetail = gcConstants.idProductSalesTaxRetail;
		Id idProductSalesTaxHarmonized = gcConstants.idProductSalesTaxHarmonized;
		Id idProductPrecisionFix = gcConstants.idProductPrecisionFix;
		Id idProductInternalLabour = gcConstants.idProductInternalLabour;
		Id idProductInternalBilling = gcConstants.idProductInternalBilling;
		Id idProductInternalBalance = gcConstants.idProductInternalBalance;
		String internalProductRecordTypeName = gcConstants.internalProductRecordTypeName;

		Id idGlv1HeadOfficeOverhead = gcConstants.idGlv1HeadOfficeOverhead;
		Id idGlInternalLabour = gcConstants.idGlInternalLabour;
		Id idGLInternalWarrantyClearing = gcConstants.idGLInternalWarrantyClearing;
		Id idGlv2Sales = gcConstants.idGlv2Sales;
		Id idGlv3Others = gcConstants.idGlv3Others;

		List<AcctSeedERP__Sales_Order_Line__c> listBLupsert = new List<AcctSeedERP__Sales_Order_Line__c>();
		List<AcctSeedERP__Sales_Order_Line__c> listBLdelete = new List<AcctSeedERP__Sales_Order_Line__c>();
		List<GMBLASERP__Serial_Number__c> listSerialsUsed = new List<GMBLASERP__Serial_Number__c>();
		Map<Id,AcctSeed__Project_Task__c> mapTask = new Map<Id,AcctSeed__Project_Task__c>();
		for(AcctSeedERP__Sales_Order__c bill :
				[SELECT Id,
						GL_Account_Variable_3__c,
						Tax_is_Harmonized__c,
						Tax_Rate_Federal__c,
						Tax_Rate_Provincial__c,
						Tax_Rate_Retail__c,
						Revenue__c,
						Expense__c,
						Profit__c,
					(SELECT Id,
                     
						AcctSeedERP__GL_Account_Variable_1__c,
                    	AcctSeedERP__GL_Account_Variable_2__c,
                     	AcctSeedERP__GL_Account_Variable_3__c,
						AcctSeedERP__Product__c,
						AcctSeedERP__Product__r.RecordType.Name,
						AcctSeedERP__Total__c,
                     	AcctSeedERP__Unit_Price__c,
                     	Taxable_Federal__c,
           				Taxable_Provincial__c,
           				Taxable_Retail__c,
           				GMBLASERP__Serial_Number__c,
           				GMBLASERP__Revenue__c,
                     	Review_Price__c,
                     	AcctSeedERP__Quantity_Ordered__c
           	
					FROM AcctSeedERP__Sales_Order_Line__r
					ORDER BY CreatedDate)
			 	FROM AcctSeedERP__Sales_Order__c
			 	WHERE Id IN :setIdBilling
			 		AND AcctSeedERP__Status__c != 'Posted'])
		{
			AcctSeedERP__Sales_Order_Line__c taxLineFederal;
			AcctSeedERP__Sales_Order_Line__c taxLineProvincial;
			AcctSeedERP__Sales_Order_Line__c taxLineRetail;
			AcctSeedERP__Sales_Order_Line__c taxLineHarmonized;
			AcctSeedERP__Sales_Order_Line__c lineProductPrecisionFix;
			AcctSeedERP__Sales_Order_Line__c lineInternalBillingRevenue;
			AcctSeedERP__Sales_Order_Line__c lineInternalBillingBalance;
			AcctSeedERP__Sales_Order_Line__c lineInternalWarrantyBalance;
			Map<Id,AcctSeed__Billing_Line__c> mapTaskLabour = new Map<Id,AcctSeed__Billing_Line__c>();
			//AcctSeed__Billing_Line__c lineInternalLabour;

			Decimal taxRateFederal = (bill.Tax_Rate_Federal__c == null ? 0 : bill.Tax_Rate_Federal__c)/100;
			Decimal taxRateProvincial = (bill.Tax_Rate_Provincial__c == null ? 0 : bill.Tax_Rate_Provincial__c)/100;
			Decimal taxRateRetail = (bill.Tax_Rate_Retail__c == null ? 0 : bill.Tax_Rate_Retail__c)/100;
			Decimal taxRateHarmonized = (bill.Tax_is_Harmonized__c == true ? (taxRateFederal + taxRateProvincial) : 0);
			System.debug('taxRateFederal= '+taxRateFederal);
			System.debug('taxRateProvincial= '+taxRateProvincial);
			System.debug('taxRateHarmonized= '+taxRateHarmonized);
			System.debug('bill.Tax_is_Harmonized__c= '+bill.Tax_is_Harmonized__c);
			if(bill.Tax_is_Harmonized__c)
			{
				taxRateFederal = 0;
				taxRateProvincial = 0;
			}

			Decimal taxableAmountFederal = 0;
            Decimal taxableAmountProvincial = 0;
            Decimal taxableAmountRetail = 0;
            Decimal taxableAmountHarmonized = 0;
            Decimal totalLineAmount = 0;
            Decimal totalSerialRevenue = 0;
            Map<Id,Decimal> mapTotalLabour = new Map<Id,Decimal>();
            //Decimal totalLabour = 0;
			for(AcctSeedERP__Sales_Order_Line__c bl : bill.AcctSeedERP__Sales_Order_Line__r)
			{
				
                System.debug('bl.AcctSeedERP__Product__c= '+bl.AcctSeedERP__Product__c);
                System.debug('idProductSalesTaxHarmonized= '+idProductSalesTaxHarmonized);
                
				if(bl.AcctSeedERP__Product__c == idProductSalesTaxHarmonized)
				{
					if(taxRateHarmonized == 0 || taxLineHarmonized != null)
						listBLdelete.add(bl);
					else
						taxLineHarmonized = bl;
					continue;
				}
				
				
				totalLineAmount += (bl.AcctSeedERP__Total__c == null ? 0 : bl.AcctSeedERP__Total__c);
				System.debug('totalLineAmount='+totalLineAmount);
				
				if(bl.Taxable_Federal__c)
					taxableAmountFederal += (bl.AcctSeedERP__Total__c == null ? 0 : bl.AcctSeedERP__Total__c);
				if(bl.Taxable_Provincial__c)
					taxableAmountProvincial += (bl.AcctSeedERP__Total__c == null ? 0 : bl.AcctSeedERP__Total__c);
				if(bl.Taxable_Provincial__c || bl.Taxable_Federal__c)
					taxableAmountHarmonized += (bl.AcctSeedERP__Total__c == null ? 0 : bl.AcctSeedERP__Total__c);
				if(bl.Taxable_Retail__c)
					taxableAmountRetail += (bl.AcctSeedERP__Total__c == null ? 0 : bl.AcctSeedERP__Total__c);

				System.debug('taxableAmountFederal= '+taxableAmountFederal);
				System.debug('taxableAmountProvincial= '+taxableAmountProvincial);
				System.debug('taxableAmountHarmonized= '+taxableAmountHarmonized);
				System.debug('taxableAmountRetail= '+taxableAmountRetail);
				if(bl.AcctSeedERP__GL_Account_Variable_3__c != bill.GL_Account_Variable_3__c)
				{
					bl.AcctSeedERP__GL_Account_Variable_3__c = bill.GL_Account_Variable_3__c;
					listBLupsert.add(bl);
				}

				
			}

			if(taxableAmountFederal == 0)
			{
				if(taxLineFederal != null)
					listBLdelete.add(taxLineFederal);
            }
            else
            {
                if(taxRateFederal != 0)
				{
					if(taxLineFederal != null)
					{
						if(taxLineFederal.AcctSeedERP__Quantity_Ordered__c != taxRateFederal.setScale(5) ||
						   taxLineFederal.AcctSeedERP__Unit_Price__c  != taxableAmountFederal.setScale(2) ||
						   taxLineFederal.AcctSeedERP__GL_Account_Variable_3__c != bill.GL_Account_Variable_3__c ||
						   taxLineFederal.AcctSeedERP__GL_Account_Variable_3__c == null ||
						   taxLineFederal.Taxable_Federal__c == true)
						{
							taxLineFederal.AcctSeedERP__Quantity_Ordered__c = taxRateFederal.setScale(5);
							taxLineFederal.AcctSeedERP__Unit_Price__c  = taxableAmountFederal.setScale(2);
							if(taxLineFederal.AcctSeedERP__GL_Account_Variable_3__c == null)
								taxLineFederal.AcctSeedERP__GL_Account_Variable_3__c = bill.GL_Account_Variable_3__c;
							taxLineFederal.Taxable_Federal__c = false;
							listBLupsert.add(taxLineFederal);
						}
					}
					else
					{
						taxLineFederal = new AcctSeedERP__Sales_Order_Line__c(
							AcctSeedERP__Sales_Order__c = bill.Id,
							AcctSeedERP__GL_Account_Variable_3__c = bill.GL_Account_Variable_3__c,
							AcctSeedERP__Product__c = idProductSalesTaxFederal,
							//AcctSeed__Hours_Units__c = taxRateFederal.setScale(5),
							//AcctSeed__Rate__c = taxableAmountFederal.setScale(2),
							Taxable_Federal__c = false
						);
						listBLupsert.add(taxLineFederal);
					}
					totalLineAmount += (taxRateFederal.setScale(5) * taxableAmountFederal.setScale(2)).setScale(2);
				}
            }

            if(taxableAmountProvincial == 0)
            {
				if(taxLineProvincial != null)
					listBLdelete.add(taxLineProvincial);
			}
			else
			{
				if(taxRateProvincial != 0)
				{
					if(taxLineProvincial != null)
					{
                        
						if(taxLineProvincial.AcctSeedERP__Quantity_Ordered__c != taxRateProvincial.setScale(5) ||
						   taxLineProvincial.AcctSeedERP__Unit_Price__c  != taxableAmountProvincial.setScale(2) ||
						   taxLineProvincial.AcctSeedERP__GL_Account_Variable_3__c != bill.GL_Account_Variable_3__c ||
						   taxLineProvincial.AcctSeedERP__GL_Account_Variable_3__c == null ||
						   taxLineProvincial.Taxable_Provincial__c == true)
						{
							taxLineProvincial.AcctSeedERP__Quantity_Ordered__c = taxRateProvincial.setScale(5);
							taxLineProvincial.AcctSeedERP__Unit_Price__c  = taxableAmountProvincial.setScale(2);
							if(taxLineProvincial.AcctSeedERP__GL_Account_Variable_3__c == null)
								taxLineProvincial.AcctSeedERP__GL_Account_Variable_3__c = bill.GL_Account_Variable_3__c;
							taxLineProvincial.Taxable_Provincial__c = false;
							listBLupsert.add(taxLineProvincial);
						}
					}
					else
					{
						taxLineProvincial = new AcctSeedERP__Sales_Order_Line__c(
							AcctSeedERP__Sales_Order__c = bill.Id,
							AcctSeedERP__GL_Account_Variable_3__c = bill.GL_Account_Variable_3__c,
							AcctSeedERP__Product__c = idProductSalesTaxProvincial,
						    AcctSeedERP__Quantity_Ordered__c = taxRateProvincial.setScale(5),
							AcctSeedERP__Unit_Price__c  = taxableAmountProvincial.setScale(2),
							Taxable_Provincial__c = false
						);
						listBLupsert.add(taxLineProvincial);
					}
					totalLineAmount += (taxRateProvincial.setScale(5) * taxableAmountProvincial.setScale(2)).setScale(2);
				}
			}

            if(taxableAmountRetail == 0)
            {
				if(taxLineRetail != null)
					listBLdelete.add(taxLineRetail);
			}
			else
			{
				if(taxRateRetail != 0)
				{
					if(taxLineRetail != null)
					{
						if(taxLineRetail.AcctSeedERP__Quantity_Ordered__c != taxRateRetail.setScale(5) ||
						   taxLineRetail.AcctSeedERP__Unit_Price__c  != taxableAmountRetail.setScale(2) ||
						   taxLineRetail.AcctSeedERP__GL_Account_Variable_3__c != bill.GL_Account_Variable_3__c ||
						   taxLineRetail.AcctSeedERP__GL_Account_Variable_3__c == null ||
						   taxLineRetail.Taxable_Retail__c == true)
						{
							taxLineRetail.AcctSeedERP__Quantity_Ordered__c = taxRateRetail.setScale(5);
							taxLineRetail.AcctSeedERP__Unit_Price__c  = taxableAmountRetail.setScale(2);
							if(taxLineRetail.AcctSeedERP__GL_Account_Variable_3__c == null)
								taxLineRetail.AcctSeedERP__GL_Account_Variable_3__c = bill.GL_Account_Variable_3__c;
							taxLineRetail.Taxable_Retail__c = false;
							listBLupsert.add(taxLineRetail);
						}
					}
					else
					{
						taxLineRetail = new AcctSeedERP__Sales_Order_Line__c(
							AcctSeedERP__Sales_Order__c = bill.Id,
							AcctSeedERP__Product__c = idProductSalesTaxRetail,
							AcctSeedERP__Quantity_Ordered__c = taxRateRetail.setScale(5),
							AcctSeedERP__Unit_Price__c = taxableAmountRetail.setScale(2),
							AcctSeedERP__GL_Account_Variable_3__c = bill.GL_Account_Variable_3__c,
							Taxable_Retail__c = false
						);
						listBLupsert.add(taxLineRetail);
					}
					totalLineAmount += (taxRateRetail.setScale(5) * taxableAmountRetail.setScale(2)).setScale(2);
				}
			}
			System.debug('taxableAmountHarmonized= '+taxableAmountHarmonized);
			if(taxableAmountHarmonized == 0)
            {
				if(taxLineHarmonized != null)
					listBLdelete.add(taxLineHarmonized);
			}
			else
			{
				if(taxRateHarmonized != 0)
				{
					if(taxLineHarmonized != null)
					{ 
						if(taxLineHarmonized.AcctSeedERP__Quantity_Ordered__c != taxRateHarmonized.setScale(5) ||
						   taxLineHarmonized.AcctSeedERP__Unit_Price__c  != taxableAmountHarmonized.setScale(2) ||
						   taxLineHarmonized.AcctSeedERP__GL_Account_Variable_3__c != bill.GL_Account_Variable_3__c ||
						   taxLineHarmonized.AcctSeedERP__GL_Account_Variable_3__c == null ||
						   taxLineHarmonized.Taxable_Provincial__c == true)
						{
							taxLineHarmonized.AcctSeedERP__Quantity_Ordered__c = taxRateHarmonized.setScale(5);
							taxLineHarmonized.AcctSeedERP__Unit_Price__c  = taxableAmountHarmonized.setScale(2);
							if(taxLineHarmonized.AcctSeedERP__GL_Account_Variable_3__c == null)
								taxLineHarmonized.AcctSeedERP__GL_Account_Variable_3__c = bill.GL_Account_Variable_3__c;
							taxLineHarmonized.Taxable_Provincial__c = false;
							listBLupsert.add(taxLineHarmonized);
						}
					}
					else
					{
                        System.debug('@@ in else');
						taxLineHarmonized = new AcctSeedERP__Sales_Order_Line__c(
							AcctSeedERP__Sales_Order__c = bill.Id,
							AcctSeedERP__Product__c = idProductSalesTaxHarmonized,
							AcctSeedERP__Quantity_Ordered__c = taxRateHarmonized.setScale(5),
							AcctSeedERP__Unit_Price__c  = taxableAmountHarmonized.setScale(2),
							AcctSeedERP__GL_Account_Variable_3__c = bill.GL_Account_Variable_3__c,
							Taxable_Provincial__c = false
						);
						listBLupsert.add(taxLineHarmonized);
					}
					totalLineAmount += (taxRateHarmonized.setScale(5) * taxableAmountHarmonized.setScale(2)).setScale(2);
				}
			}

			Decimal actualValue = totalLineAmount.setScale(6);
			Decimal acctSeedValue = totalLineAmount.setScale(2,System.RoundingMode.HALF_UP);
			Decimal currentPrecision = (acctSeedValue - actualValue).setScale(6);
			if(currentPrecision != 0)
			{
				//if(currentPrecision < 0.005) currentPrecision = currentPrecision * -1;
				if(lineProductPrecisionFix != null)
				{
					lineProductPrecisionFix.AcctSeedERP__Quantity_Ordered__c = 1;
					lineProductPrecisionFix.AcctSeedERP__Unit_Price__c  = currentPrecision;
					lineProductPrecisionFix.Taxable_Federal__c = false;
					lineProductPrecisionFix.Taxable_Provincial__c = false;
					lineProductPrecisionFix.Taxable_Retail__c = false;
					listBLupsert.add(lineProductPrecisionFix);
				}
				else
				{
					lineProductPrecisionFix = new AcctSeedERP__Sales_Order_Line__c(
						AcctSeedERP__Sales_Order__c = bill.Id,
						AcctSeedERP__GL_Account_Variable_3__c = idGlv3Others,
						AcctSeedERP__Product__c = idProductPrecisionFix,
						AcctSeedERP__Quantity_Ordered__c = 1,
						AcctSeedERP__Unit_Price__c  = currentPrecision,
						Taxable_Federal__c = false,
						Taxable_Provincial__c = false,
						Taxable_Retail__c = false
					);
					listBLupsert.add(lineProductPrecisionFix);
				}
			}
			else
			{
				if(lineProductPrecisionFix != null)
					listBLdelete.add(lineProductPrecisionFix);
			}

			
		}
		System.debug('listBLdelete= '+listBLdelete);
		System.debug('listBLupsert= '+listBLupsert);
		if(!listBLdelete.isEmpty() || !listBLupsert.isEmpty())
		{
			Boolean boolOld = gcBillingLine.disableTrigger;
			gcBillingLine.disableTrigger = true;
			if (!listBLdelete.isEmpty())
				delete listBLdelete;
			if (!listBLupsert.isEmpty())
				upsert listBLupsert;
			gcBillingLine.disableTrigger = boolOld;

			
		}
	}

}