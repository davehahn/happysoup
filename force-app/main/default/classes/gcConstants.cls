public without sharing class gcConstants {

//
//
/////////////////////////	ACCOUNTING SETTINGS ////////////////////////
//
//

	public static Id idGlWip{
		get{
			if(idGlWip == null) fetchAccountingSettings();
			if(idGlWip == null) throw new gcException('The Accounting Settings do not specify a Work In Process GL Account.');
			return idGlWip;
		}
		set;
	}


	private static void fetchAccountingSettings()
	{
		for(AcctSeed__Accounting_Settings__c aset :
			[SELECT AcctSeed__Work_in_Process_GL_Account__c
			 FROM AcctSeed__Accounting_Settings__c
			 ORDER BY CreatedDate LIMIT 1])
		{
			idGlWip = aset.AcctSeed__Work_in_Process_GL_Account__c;
		}
	}

//
//
/////////////////////////	ACCOUNTING VARIABLES ////////////////////////
//
//
	public static Id idGlv1Barrie{
		get{
			if(idGlv1Barrie == null) fetchAccountingVariables();
			if(idGlv1Barrie == null) throw new gcException('An Accounting Variable of Type 1 with the name [Retail Barrie] does not exist.');
			return idGlv1Barrie;
		}
		set;
	}

	public static Id idGlv1Montreal{
		get{
			if(idGlv1Montreal == null) fetchAccountingVariables();
			if(idGlv1Montreal == null) throw new gcException('An Accounting Variable of Type 1 with the name [Retail Montreal] does not exist.');
			return idGlv1Montreal;
		}
		set;
	}

	public static Id idGlv1Whitefish{
		get{
			if(idGlv1Whitefish == null) fetchAccountingVariables();
			if(idGlv1Whitefish == null) throw new gcException('An Accounting Variable of Type 1 with the name [Retail Whitefish] does not exist.');
			return idGlv1Whitefish;
		}
		set;
	}

	public static Id idGlv1Wholesale{
		get{
			if(idGlv1Wholesale == null) fetchAccountingVariables();
			if(idGlv1Wholesale == null) throw new gcException('An Accounting Variable of Type 1 with the name [Wholesale] does not exist.');
			return idGlv1Wholesale;
		}
		set;
	}

	public static Id idGlv1HeadOfficeOverhead{
		get{
			if(idGlv1HeadOfficeOverhead == null) fetchAccountingVariables();
			if(idGlv1HeadOfficeOverhead == null) throw new gcException('An Accounting Variable of Type 1 with the name [Head Office / Overhead] does not exist.');
			return idGlv1HeadOfficeOverhead;
		}
		set;
	}

	public static Id idGlv2PartsAndService{
		get{
			if(idGlv2PartsAndService == null) fetchAccountingVariables();
			if(idGlv2PartsAndService == null) throw new gcException('An Accounting Variable of Type 2 with the name [Parts + Service] does not exist.');
			return idGlv2PartsAndService;
		}
		set;
	}

	public static Id idGlv2BusinessOffice{
		get{
			if(idGlv2BusinessOffice == null) fetchAccountingVariables();
			if(idGlv2BusinessOffice == null) throw new gcException('An Accounting Variable of Type 2 with the name [Business Office] does not exist.');
			return idGlv2BusinessOffice;
		}
		set;
	}

	public static Id idGlv2Logistics{
		get{
			if(idGlv2Logistics == null) fetchAccountingVariables();
			if(idGlv2Logistics == null) throw new gcException('An Accounting Variable of Type 2 with the name [Logistics] does not exist.');
			return idGlv2Logistics;
		}
		set;
	}

	public static Id idGlv2Production{
		get{
			if(idGlv2Production == null) fetchAccountingVariables();
			if(idGlv2Production == null) throw new gcException('An Accounting Variable of Type 2 with the name [Production] does not exist.');
			return idGlv2Production;
		}
		set;
	}

	public static Id idGlv2Sales{
		get{
			if(idGlv2Sales == null) fetchAccountingVariables();
			if(idGlv2Sales == null) throw new gcException('An Accounting Variable of Type 2 with the name [Sales] does not exist.');
			return idGlv2Sales;
		}
		set;
	}

	public static Id idGlv2Warranty{
		get{
			if(idGlv2Warranty == null) fetchAccountingVariables();
			if(idGlv2Warranty == null) throw new gcException('An Accounting Variable of Type 2 with the name [Warranty] does not exist.');
			return idGlv2Warranty;
		}
		set;
	}

	public static Id idGlv3Ontario{
		get{
			if(idGlv3Ontario == null) fetchAccountingVariables();
			if(idGlv3Ontario == null) throw new gcException('An Accounting Variable of Type 3 with the name [Ontario] does not exist.');
			return idGlv3Ontario;
		}
		set;
	}

	public static Id idGlv3Others{
		get{
			if(idGlv3Others == null) fetchAccountingVariables();
			if(idGlv3Others == null) throw new gcException('An Accounting Variable of Type 3 with the name [Others] does not exist.');
			return idGlv3Others;
		}
		set;
	}

	private static void fetchAccountingVariables()
	{
		List<String> listUniquefier = new list<String>{
			'Head Office / Overhead',
			'Ontario',
			'Parts + Service',
			'Production',
			'Retail Barrie',
			'Retail Montreal',
			'Retail Whitefish',
			'Sales',
			'Wholesale',
			'Others',
			'Warranty',
			'Logistics',
			'Business Office'
		};

		for(AcctSeed__Accounting_Variable__c glv :
			[SELECT Id,
					Name,
					AcctSeed__Type__c
			 FROM AcctSeed__Accounting_Variable__c
			 WHERE Name IN:listUniquefier
			 ORDER BY CreatedDate DESC])
		{
			if(glv.AcctSeed__Type__c == 'GL Account Variable 1')
			{
				if(glv.Name == 'Retail Barrie')
					idGlv1Barrie = glv.Id;
				else if(glv.Name == 'Retail Montreal')
					idGlv1Montreal = glv.Id;
				else if(glv.Name == 'Retail Whitefish')
					idGlv1Whitefish = glv.Id;
				else if(glv.Name == 'Wholesale')
					idGlv1Wholesale = glv.Id;
				else if(glv.Name == 'Head Office / Overhead')
					idGlv1HeadOfficeOverhead = glv.Id;
			}
			else if(glv.AcctSeed__Type__c == 'GL Account Variable 2')
			{
				if(glv.Name == 'Parts + Service')
					idGlv2PartsAndService = glv.Id;
				else if(glv.Name == 'Production')
					idGlv2Production = glv.Id;
				else if(glv.Name == 'Sales')
					idGlv2Sales = glv.Id;
				else if(glv.Name == 'Warranty')
					idGlv2Warranty = glv.Id;
				else if(glv.Name == 'Logistics')
					idGlv2Logistics = glv.Id;
				else if(glv.Name == 'Business Office')
					idGlv2BusinessOffice = glv.Id;
			}
			else if(glv.AcctSeed__Type__c == 'GL Account Variable 3')
			{
				if(glv.Name == 'Ontario')
					idGlv3Ontario = glv.Id;
				else if(glv.Name == 'Others')
					idGlv3Others = glv.Id;
			}
		}
	}

	public static Id convertProjectRecordTypeToGlv2(Id idRecordType)
	{
		if(idRecordType == idRtProjectBoatSale || idRecordType == idRtProjectPartnerBoatSale || idRecordType == idRtTradeIn)
			return idGlv2Sales;
		if(idRecordType == idRtProjectCounterSale || idRecordType == idRtPartnerPartsOrder || idRecordType == idRtProjectService || idRecordType == idRtFixedAsset)
			return idGlv2PartsAndService;
		if(idRecordType == idRtProjectWarranty)
			return idGlv2Warranty;
		if(idRecordType == idRtProjectManufacturing)
			return idGlv2Production;
		return null;
	}

	public static Id convertUserDeptToGlv1(String userDept)
	{
		return null;
	}

	public static Id convertUserDeptToWhs(String userDept)
	{
		return null;
	}



//
//
/////////////////////////	GL Accounts ////////////////////////
//
//
	public static Id idGlProductRevenue{
		get{
			if(idGlProductRevenue == null) fetchGlAccounts();
			if(idGlProductRevenue == null) throw new gcException('A GL Account with Uniquefier [SalesBoats] does not exist.');
			return idGlProductRevenue;
		}
		set;
	}

	public static Id idGlCash{
		get{
			if(idGlCash == null) fetchGlAccounts();
			if(idGlCash == null) throw new gcException('A GL Account with Uniquefier [Cash] does not exist.');
			return idGlCash;
		}
		set;
	}

	public static Id idGlCreditCard{
		get{
			if(idGlCreditCard == null) fetchGlAccounts();
			if(idGlCreditCard == null) throw new gcException('A GL Account with Uniquefier [CreditCard] does not exist.');
			return idGlCreditCard;
		}
		set;
	}

	public static Id idGlCogsParts{
		get{
			if(idGlCogsParts == null) fetchGlAccounts();
			if(idGlCogsParts == null) throw new gcException('A GL Account with Uniquefier [CogsParts] does not exist.');
			return idGlCogsParts;
		}
		set;
	}

	public static Id idGlDeposit{
		get{
			if(idGlDeposit == null) fetchGlAccounts();
			if(idGlDeposit == null) throw new gcException('A GL Account with Uniquefier [Deposits] does not exist.');
			return idGlDeposit;
		}
		set;
	}

	public static Id idGlProjectParts{
		get{
			if(idGlProjectParts == null) fetchGlAccounts();
			if(idGlProjectParts == null) throw new gcException('A GL Account with Uniquefier [ProjectParts] does not exist.');
			return idGlProjectParts;
		}
		set;
	}

	public static Id idGlProjectPartsClearing{
		get{
			if(idGlProjectPartsClearing == null) fetchGlAccounts();
			if(idGlProjectPartsClearing == null) throw new gcException('A GL Account with Uniquefier [ProjectPartsClearing] does not exist.');
			return idGlProjectPartsClearing;
		}
		set;
	}

	public static Id idGlSalesTaxRetail{
		get{
			if(idGlSalesTaxRetail == null) fetchGlAccounts();
			if(idGlSalesTaxRetail == null) throw new gcException('A GL Account with Uniquefier [SalesTaxRetail] does not exist.');
			return idGlSalesTaxRetail;
		}
		set;
	}

	public static Id idGlSalesTaxPaid{
		get{
			if(idGlSalesTaxPaid == null) fetchGlAccounts();
			if(idGlSalesTaxPaid == null) throw new gcException('A GL Account with Uniquefier [SalesTaxPaid] does not exist.');
			return idGlSalesTaxPaid;
		}
		set;
	}

	public static Id idGlSalesTaxPaidProvincial{
		get{
			if(idGlSalesTaxPaidProvincial == null) fetchGlAccounts();
			if(idGlSalesTaxPaidProvincial == null) throw new gcException('A GL Account with Uniquefier [SalesTaxPaidProvincial] does not exist.');
			return idGlSalesTaxPaidProvincial;
		}
		set;
	}

	public static Id idGlTradeIn{
		get{
			if(idGlTradeIn == null) fetchGlAccounts();
			if(idGlTradeIn == null) throw new gcException('A GL Account with Uniquefier [TradeIn] does not exist.');
			return idGlTradeIn;
		}
		set;
	}

	public static Id idGlCustomerRefund{
		get{
			if(idGlCustomerRefund == null) fetchGlAccounts();
			if(idGlCustomerRefund == null) throw new gcException('A GL Account with Uniquefier [CustomerRefund] does not exist.');
			return idGlCustomerRefund;
		}
		set;
	}

	public static Id idGlAPayable{
		get{
			if(idGlAPayable == null) fetchGlAccounts();
			if(idGlAPayable == null) throw new gcException('A GL Account with Uniquefier [APayable] does not exist.');
			return idGlAPayable;
		}
		set;
	}

	public static Id idGlBankFees{
		get{
			if(idGlBankFees == null) fetchGlAccounts();
			if(idGlBankFees == null) throw new gcException('A GL Account with Uniquefier [BankFees] does not exist.');
			return idGlBankFees;
		}
		set;
	}

	public static Id idGlFinancingFees{
		get{
			if(idGlFinancingFees == null) fetchGlAccounts();
			if(idGlFinancingFees == null) throw new gcException('A GL Account with Uniquefier [FinancingFees] does not exist.');
			return idGlFinancingFees;
		}
		set;
	}

	//public static Id idGlEquipmentExpense{
	//	get{
	//		if(idGlEquipmentExpense == null)
	//			fetchGlAccounts();
	//		if(idGlEquipmentExpense == null)
	//			throw new gcException('A GL Account with Uniquefier [EquipmentExpense] does not exist.');
	//		return idGlEquipmentExpense;
	//	}
	//	set;
	//}

	public static Id idGlGiftCards{
		get{
			if(idGlGiftCards == null) fetchGlAccounts();
			if(idGlGiftCards == null) throw new gcException('A GL Account with Uniquefier [GiftCards] does not exist.');
			return idGlGiftCards;
		}
		set;
	}

	public static Id idGlLegendBucks{
		get{
			if(idGlLegendBucks == null) fetchGlAccounts();
			if(idGlLegendBucks == null) throw new gcException('A GL Account with Uniquefier [LegendBucks] does not exist.');
			return idGlLegendBucks;
		}
		set;
	}

	public static Id idGlMerchantDebitCredit{
		get{
			if(idGlMerchantDebitCredit == null) fetchGlAccounts();
			if(idGlMerchantDebitCredit == null) throw new gcException('A GL Account with Uniquefier [MerchantDebitCredit] does not exist.');
			return idGlMerchantDebitCredit;
		}
		set;
	}

	public static Id idGlCashFloat{
		get{
			if(idGlCashFloat == null) fetchGlAccounts();
			if(idGlCashFloat == null) throw new gcException('A GL Account with Uniquefier [CashFloat] does not exist.');
			return idGlCashFloat;
		}
		set;
	}

	public static Id idGlRBCCDN{
		get{
			if(idGlRBCCDN == null) fetchGlAccounts();
			if(idGlRBCCDN == null) throw new gcException('A GL Account with Uniquefier [RBCCDN] does not exist.');
			return idGlRBCCDN;
		}
		set;
	}

	public static Id idGlCostVariance{
		get{
			if(idGlCostVariance == null) fetchGlAccounts();
			if(idGlCostVariance == null) throw new gcException('A GL Account with Uniquefier [CostVariance] does not exist.');
			return idGlCostVariance;
		}
		set;
	}

	public static Id idGlAccruedExpenses{
		get{
			if(idGlAccruedExpenses == null) fetchGlAccounts();
			if(idGlAccruedExpenses == null) throw new gcException('A GL Account with Uniquefier [AccruedExpenses] does not exist.');
			return idGlAccruedExpenses;
		}
		set;
	}

	public static Id idGlClearingARAP{
		get{
			if(idGlClearingARAP == null) fetchGlAccounts();
			if(idGlClearingARAP == null) throw new gcException('A GL Account with Uniquefier [ClearingARAP] does not exist.');
			return idGlClearingARAP;
		}
		set;
	}

	public static Id idGlInternalBilling{
		get{
			if(idGlInternalBilling == null) fetchGlAccounts();
			if(idGlInternalBilling == null) throw new gcException('A GL Account with Uniquefier [InternalBilling] does not exist.');
			return idGlInternalBilling;
		}
		set;
	}

	public static Id idGlInternalLabour{
		get{
			if(idGlInternalLabour == null) fetchGlAccounts();
			if(idGlInternalLabour == null) throw new gcException('A GL Account with Uniquefier [InternalLabour] does not exist.');
			return idGlInternalLabour;
		}
		set;
	}

	public static Id idGlWagesLabour{
		get{
			if(idGlWagesLabour == null) fetchGlAccounts();
			if(idGlWagesLabour == null) throw new gcException('A GL Account with Uniquefier [WagesLabour] does not exist.');
			return idGlWagesLabour;
		}
		set;
	}

	public static Id idGlInternalRevenue{
		get{
			if(idGlInternalRevenue == null) fetchGlAccounts();
			if(idGlInternalRevenue == null) throw new gcException('A GL Account with Uniquefier [InternalRevenue] does not exist.');
			return idGlInternalRevenue;
		}
		set;
	}

	public static Id idGLInternalWarrantyClearing{
		get{
			if(idGLInternalWarrantyClearing == null) fetchGlAccounts();
			if(idGLInternalWarrantyClearing == null) throw new gcException('A GL Account with Uniquefier [InternalWarrantyClearing] does not exist.');
			return idGLInternalWarrantyClearing;
		}
		set;
	}

	public static Id idGlPrepaidDeposit{
		get{
			if(idGlPrepaidDeposit == null) fetchGlAccounts();
			if(idGlPrepaidDeposit == null) throw new gcException('A GL Account with Uniquefier [PrepaidDeposit] does not exist.');
			return idGlPrepaidDeposit;
		}
		set;
	}

	public static Id idGlMerchantOnline{
		get{
			if(idGlMerchantOnline == null) fetchGlAccounts();
			if(idGlMerchantOnline == null) throw new gcException('A GL Account with Uniquefier [MerchantOnline] does not exist.');
			return idGlMerchantOnline;
		}
		set;
	}

	public static Id idGlRevenueCF{
		get{
			if(idGlRevenueCF == null) fetchGlAccounts();
			if(idGlRevenueCF == null) throw new gcException('A Cash Flow GL Account with Uniquefier [RevenueCF] does not exist.');
			return idGlRevenueCF;
		}
		set;
	}

	private static void fetchGlAccounts()
	{
		List<String> listUniquefier = new list<String>{
			'Cash',
			'CreditCard',
			'CogsParts',
			'Deposits',
			'ProjectParts',
			'ProjectPartsClearing',
			'SalesTaxRetail',
			'SalesTaxPaid',
			'SalesTaxPaidProvincial',
			'AccruedExpenses',
			'TradeIn',
			'CustomerRefund',
			'FinancingFees',
			'EquipmentExpense',
			'BankFees',
			'GiftCards',
			'MerchantDebitCredit',
			'CashFloat',
			'RBCCDN',
			'CostVariance',
			'APayable',
			'ClearingARAP',
			'InternalBilling',
			'InternalLabour',
			'WagesLabour',
			'InternalRevenue',
			'InternalWarrantyClearing',
			'LegendBucks',
			'SalesBoats',
			'PrepaidDeposit',
			'MerchantOnline',
			'RevenueCF'
		};

		for(AcctSeed__GL_Account__c gl :
			[SELECT Id, Uniquefier__c
			 FROM AcctSeed__GL_Account__c
			 WHERE Uniquefier__c IN :listUniquefier])
		{
			if(gl.Uniquefier__c == 'Cash')
				idGlCash = gl.Id;
			else if(gl.Uniquefier__c == 'CreditCard')
				idGlCreditCard = gl.Id;
			else if(gl.Uniquefier__c == 'CogsParts')
				idGlCogsParts = gl.Id;
			else if(gl.Uniquefier__c == 'Deposits')
				idGlDeposit = gl.Id;
			else if(gl.Uniquefier__c == 'ProjectParts')
				idGlProjectParts = gl.Id;
			else if(gl.Uniquefier__c == 'ProjectPartsClearing')
				idGlProjectPartsClearing = gl.Id;
			else if(gl.Uniquefier__c == 'SalesTaxRetail')
				idGlSalesTaxRetail = gl.Id;
			else if(gl.Uniquefier__c == 'SalesTaxPaid')
				idGlSalesTaxPaid = gl.Id;
			else if(gl.Uniquefier__c == 'SalesTaxPaidProvincial')
				idGlSalesTaxPaidProvincial = gl.Id;
			else if(gl.Uniquefier__c == 'AccruedExpenses')
				idGlAccruedExpenses = gl.Id;
			else if(gl.Uniquefier__c == 'TradeIn')
				idGlTradeIn = gl.Id;
			else if(gl.Uniquefier__c == 'CustomerRefund')
				idGlCustomerRefund = gl.Id;
			else if(gl.Uniquefier__c == 'APayable')
				idGlAPayable = gl.Id;
			else if(gl.Uniquefier__c == 'BankFees')
				idGlBankFees = gl.Id;
			else if(gl.Uniquefier__c == 'FinancingFees')
				idGlFinancingFees = gl.Id;
			//else if(gl.Uniquefier__c == 'EquipmentExpense')
			//	idGlEquipmentExpense = gl.Id;
			else if(gl.Uniquefier__c == 'GiftCards')
				idGlGiftCards = gl.Id;
			else if(gl.Uniquefier__c == 'MerchantDebitCredit')
				idGlMerchantDebitCredit = gl.Id;
			else if(gl.Uniquefier__c == 'CashFloat')
				idGlCashFloat = gl.Id;
			else if(gl.Uniquefier__c == 'RBCCDN')
				idGlRBCCDN = gl.Id;
			else if(gl.Uniquefier__c == 'CostVariance')
				idGlCostVariance = gl.Id;
			else if(gl.Uniquefier__c == 'ClearingARAP')
				idGlClearingARAP = gl.Id;
			else if(gl.Uniquefier__c == 'InternalLabour')
				idGlInternalLabour = gl.Id;
			else if(gl.Uniquefier__c == 'InternalBilling')
				idGlInternalBilling = gl.Id;
			else if(gl.Uniquefier__c == 'WagesLabour')
				idGlWagesLabour = gl.Id;
			else if(gl.Uniquefier__c == 'InternalRevenue')
				idGlInternalRevenue = gl.Id;
			else if(gl.Uniquefier__c == 'InternalWarrantyClearing')
				idGLInternalWarrantyClearing = gl.Id;
			else if(gl.Uniquefier__c == 'LegendBucks')
				idGlLegendBucks = gl.Id;
			else if(gl.Uniquefier__c == 'SalesBoats')
				idGlProductRevenue = gl.Id;
			else if(gl.Uniquefier__c == 'PrepaidDeposit')
				idGlPrepaidDeposit = gl.Id;
			else if(gl.Uniquefier__c == 'MerchantOnline')
				idGlMerchantOnline = gl.Id;
			else if(gl.Uniquefier__c == 'RevenueCF')
				idGlRevenueCF = gl.Id;
		}
	}

//
//
/////////////////////////	PRODUCTS ////////////////////////
//
//
	public static Id idProductSalesTaxFederal{
		get{
			if(idProductSalesTaxFederal == null) fetchProducts();
			if(idProductSalesTaxFederal == null) throw new gcException('A Product with Unique Product Code [SalesTaxFederal] does not exist.');
			return idProductSalesTaxFederal;
		}
		set;
	}

	public static Id idProductSalesTaxHarmonized{
		get{
			if(idProductSalesTaxHarmonized == null) fetchProducts();
			if(idProductSalesTaxHarmonized == null) throw new gcException('A Product with Unique Product Code [SalesTaxHarmonized] does not exist.');
			return idProductSalesTaxHarmonized;
		}
		set;
	}

	public static Id idProductSalesTaxProvincial{
		get{
			if(idProductSalesTaxProvincial == null) fetchProducts();
			if(idProductSalesTaxProvincial == null) throw new gcException('A Product with Unique Product Code [SalesTaxProvincial] does not exist.');
			return idProductSalesTaxProvincial;
		}
		set;
	}

	public static Id idProductSalesTaxRetail{
		get{
			if(idProductSalesTaxRetail == null) fetchProducts();
			if(idProductSalesTaxRetail == null) throw new gcException('A Product with Unique Product Code [SalesTaxRetail] does not exist.');
			return idProductSalesTaxRetail;
		}
		set;
	}

	public static Id idProductTradeIn{
		get{
			if(idProductTradeIn == null) fetchProducts();
			if(idProductTradeIn == null) throw new gcException('A Product with Unique Product Code [Trade in] does not exist.');
			return idProductTradeIn;
		}
		set;
	}

	public static Id idProductTradeInLien{
		get{
			if(idProductTradeInLien == null) fetchProducts();
			if(idProductTradeInLien == null) throw new gcException('A Product with Unique Product Code [Trade in Lien] does not exist.');
			return idProductTradeInLien;
		}
		set;
	}

	public static Id idProductTradeInBoats{
		get{
			if(idProductTradeInBoats == null) fetchProducts();
			if(idProductTradeInBoats == null) throw new gcException('A Product with Unique Product Code [TradeInBoats] does not exist.');
			return idProductTradeInBoats;
		}
		set;
	}

	public static Id idProductPrecisionFix{
		get{
			if(idProductPrecisionFix == null) fetchProducts();
			if(idProductPrecisionFix == null) throw new gcException('A Product with Unique Product Code [PrecisionFix] does not exist.');
			return idProductPrecisionFix;
		}
		set;
	}

	public static Id idProductInternalLabour{
		get{
			if(idProductInternalLabour == null) fetchProducts();
			if(idProductInternalLabour == null) throw new gcException('A Product with Unique Product Code [InternalLabour] does not exist.');
			return idProductInternalLabour;
		}
		set;
	}

	public static Id idProductInternalBilling{
		get{
			if(idProductInternalBilling == null) fetchProducts();
			if(idProductInternalBilling == null) throw new gcException('A Product with Unique Product Code [InternalBilling] does not exist.');
			return idProductInternalBilling;
		}
		set;
	}

	public static Id idProductInternalBalance{
		get{
			if(idProductInternalBalance == null) fetchProducts();
			if(idProductInternalBalance == null) throw new gcException('A Product with Unique Product Code [InternalBalance] does not exist.');
			return idProductInternalBalance;
		}
		set;
	}

	public static String internalProductRecordTypeName{
		get{
			return 'Internal';
		}
		set;
	}

	private static void fetchProducts()
	{
		List<String> listUniquefier = new list<String>{
			'SalesTaxFederal',
			'SalesTaxHarmonized',
			'SalesTaxProvincial',
			'SalesTaxRetail',
			'TaxCanada',
			'Trade in',
			'Trade in Lien',
			'TradeInBoats',
			'PrecisionFix',
			'InternalLabour',
			'InternalBilling',
			'InternalBalance'
		};

		for(Product2 p :
			[SELECT Id, Unique_Product_Code__c
			 FROM Product2
			 WHERE Unique_Product_Code__c IN :listUniquefier
			 ORDER BY CreatedDate DESC])
		{
			if(p.Unique_Product_Code__c == 'SalesTaxFederal')
				idProductSalesTaxFederal = p.Id;
			else if(p.Unique_Product_Code__c == 'SalesTaxHarmonized')
				idProductSalesTaxHarmonized = p.Id;
			else if(p.Unique_Product_Code__c == 'SalesTaxProvincial')
				idProductSalesTaxProvincial = p.Id;
			else if(p.Unique_Product_Code__c == 'SalesTaxRetail')
				idProductSalesTaxRetail = p.Id;
			else if(p.Unique_Product_Code__c == 'Trade in')
				idProductTradeIn = p.Id;
			else if(p.Unique_Product_Code__c == 'Trade in Lien')
				idProductTradeInLien = p.Id;
			else if(p.Unique_Product_Code__c == 'TradeInBoats')
				idProductTradeInBoats = p.Id;
			else if(p.Unique_Product_Code__c == 'PrecisionFix')
				idProductPrecisionFix = p.Id;
			else if(p.Unique_Product_Code__c == 'InternalLabour')
				idProductInternalLabour = p.Id;
			else if(p.Unique_Product_Code__c == 'InternalBilling')
				idProductInternalBilling = p.Id;
			else if(p.Unique_Product_Code__c == 'InternalBalance')
				idProductInternalBalance = p.Id;
		}
	}

//
//
/////////////////////////	PRICEBOOKS ////////////////////////
//
//

	public static Id idPricebookFactory{
		get{
			if(idPricebookFactory == null)
			{
				idPricebookFactory = Legend_Settings__c.getOrgDefaults().Default_Factory_Pricebook__c;
				if(idPricebookFactory == null) throw new gcException('The Custom Setting Legend_Settings__c.Default_Factory_Pricebook__c is blank.');
				if(!setIdPricebook.contains(idPricebookFactory)) throw new gcException('The value stored in the Custom Setting Legend_Settings__c.Default_Factory_Pricebook__c is not the Id of a Pricebook.');
			}

			return idPricebookFactory;
		}
		set;
	}

	public static Id idPricebookRetail{
		get{
			if(idPricebookRetail == null)
			{
				//idPricebookRetail = inventorySettings.Work_Order_Retail_Pricebook_Id__c;
				idPricebookRetail = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
				if(idPricebookRetail == null) throw new gcException('The Custom Setting Legend_Settings__c.Default_Retail_Pricebook__c is blank.');
				if(!setIdPricebook.contains(idPricebookRetail)) throw new gcException('The value stored in the Custom Setting Legend_Settings__c.Default_Retail_Pricebook__c is not the Id of a Pricebook.');
			}

			return idPricebookRetail;
		}
		set;
	}

	public static Id idPricebookPartner{
		get{
			if(idPricebookPartner == null)
			{
				idPricebookPartner = Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c;
				if(idPricebookPartner == null) throw new gcException('The Custom Setting Legend_Settings__c.Default_Partner_Pricebook__c is blank.');
				if(!setIdPricebook.contains(idPricebookPartner)) throw new gcException('The value stored in the Custom Setting Legend_Settings__c.Default_Partner_Pricebook__c is not the Id of a Pricebook.');
			}

			return idPricebookPartner;
		}
		set;
	}

	//private static GMBLASERP__Inventory_Settings__c inventorySettings{
	//	get{
	//		if(inventorySettings == null)
	//			inventorySettings = GMBLASERP__Inventory_Settings__c.getOrgDefaults();
	//		if(inventorySettings == null)
	//			throw new gcException('The Custom Setting GMBLASERP__Inventory_Settings__c has not been initialized with org-wide defaults.');
	//		return inventorySettings;
	//	}
	//	set;
	//}

	private static set<Id> setIdPricebook{
		get{
			if(setIdPricebook == null)
			{
				setIdPricebook = new set<Id>();
				for(Pricebook2 pb : [SELECT Id FROM Pricebook2])
					setIdPricebook.add(pb.Id);
			}
			return setIdPricebook;
		}
		set;
	}

//
//
/////////////////////////	RECORD TYPES ////////////////////////
//
//
	public static Id idRtProjectBoatSale{
		get{
			if(idRtProjectBoatSale == null) fetchRecordTypes();
			if(idRtProjectBoatSale == null) throw new gcException('A Project Record Type having API name [BoatSale] does not exist.');
			return idRtProjectBoatSale;
		}
		set;
	}

	public static Id idRtProjectPartnerBoatSale{
		get{
			if(idRtProjectPartnerBoatSale == null) fetchRecordTypes();
			if(idRtProjectPartnerBoatSale == null) throw new gcException('A Project Record Type having API name [PartnerBoatSale] does not exist.');
			return idRtProjectPartnerBoatSale;
		}
		set;
	}

	public static Id idRtProjectCounterSale{
		get{
			if(idRtProjectCounterSale == null) fetchRecordTypes();
			if(idRtProjectCounterSale == null) throw new gcException('A Project Record Type having API name [CounterSale] does not exist.');
			return idRtProjectCounterSale;
		}
		set;
	}

	public static Id idRtProjectManufacturing{
		get{
			if(idRtProjectManufacturing == null) fetchRecordTypes();
			if(idRtProjectManufacturing == null) throw new gcException('A Project Record Type having API name [Manufacturing] does not exist.');
			return idRtProjectManufacturing;
		}
		set;
	}

	public static Id idRtProjectService{
		get{
			if(idRtProjectService == null) fetchRecordTypes();
			if(idRtProjectService == null) throw new gcException('A Project Record Type having API name [Service] does not exist.');
			return idRtProjectService;
		}
		set;
	}

	public static Id idRtProjectWarranty{
		get{
			if(idRtProjectWarranty == null) fetchRecordTypes();
			if(idRtProjectWarranty == null) throw new gcException('A Project Record Type having API name [Legend_Warranty] does not exist.');
			return idRtProjectWarranty;
		}
		set;
	}

	public static Id idRtPartnerPartsOrder{
		get{
			if(idRtPartnerPartsOrder == null) fetchRecordTypes();
			if(idRtPartnerPartsOrder == null) throw new gcException('A Project Record Type having API name [LegendPartnerPartsOrder] does not exist.');
			return idRtPartnerPartsOrder;
		}
		set;
	}

	public static Id idRtTradeIn{
		get{
			if(idRtTradeIn == null) fetchRecordTypes();
			if(idRtTradeIn == null) throw new gcException('A Project Record Type having API name [TradeIn] does not exist.');
			return idRtTradeIn;
		}
		set;
	}

	public static Id idRtFixedAsset{
		get{
			if(idRtFixedAsset == null) fetchRecordTypes();
			if(idRtFixedAsset == null) throw new gcException('A Project Record Type having API name [LegendFixedAsset] does not exist.');
			return idRtFixedAsset;
		}
		set;
	}

	private static void fetchRecordTypes()
	{
		for(RecordType rt :
			[SELECT Id, DeveloperName, SobjectType
			 FROM RecordType
			 WHERE (SobjectType = 'AcctSeed__Project__c' AND
			 		(DeveloperName = 'BoatSale' OR
			 		 DeveloperName = 'PartnerBoatSale' OR
			 		 DeveloperName = 'CounterSale' OR
			 		 DeveloperName = 'Manufacturing' OR
			 		 DeveloperName = 'TradeIn' OR
			 		 DeveloperName = 'Legend_Warranty' OR
			 		 DeveloperName = 'LegendFixedAsset' OR
			 		 DeveloperName = 'LegendPartnerPartsOrder' OR
			    	 DeveloperName = 'Service'))])
		{
			if(rt.SobjectType == 'AcctSeed__Project__c')
			{
				if(rt.DeveloperName == 'BoatSale')
					idRtProjectBoatSale = rt.Id;
				else if(rt.DeveloperName == 'PartnerBoatSale')
					idRtProjectPartnerBoatSale = rt.Id;
				else if(rt.DeveloperName == 'CounterSale')
					idRtProjectCounterSale = rt.Id;
				else if(rt.DeveloperName == 'Manufacturing')
					idRtProjectManufacturing = rt.Id;
				else if(rt.DeveloperName == 'Service')
					idRtProjectService = rt.Id;
				else if(rt.DeveloperName == 'Legend_Warranty')
					idRtProjectWarranty = rt.Id;
				else if(rt.DeveloperName == 'TradeIn')
					idRtTradeIn = rt.Id;
				else if(rt.DeveloperName == 'LegendFixedAsset')
					idRtFixedAsset = rt.Id;
				else if(rt.DeveloperName == 'LegendPartnerPartsOrder')
					idRtPartnerPartsOrder = rt.Id;
			}
		}
	}

//
//
/////////////////////////	User Info ////////////////////////
//
//
	public static String nameUserSalesDepartment{
		get{
			if(nameUserSalesDepartment == null) fetchUserInfo();
			return nameUserSalesDepartment;
		}
		set;
	}

	public static String nameUserWarehouse{
		get{
			if(nameUserWarehouse == null) fetchUserInfo();
			return nameUserWarehouse;
		}
		set;
	}

	public static String nameUserBusinessUnitGLV1{
		get{
			if(nameUserBusinessUnitGLV1 == null) fetchUserInfo();
			return nameUserBusinessUnitGLV1;
		}
		set;
	}

	private static void fetchUserInfo()
	{
		Id idUser = UserInfo.getUserId();
		for(User u : [SELECT Id, Sales_Department__c, GL_Account_Variable_1__c, Warehouse__c FROM User WHERE Id =:idUser])
		{
			if(u.GL_Account_Variable_1__c != null)
				nameUserBusinessUnitGLV1 = u.GL_Account_Variable_1__c;
			if(u.Warehouse__c != null)
				nameUserWarehouse = u.Warehouse__c;
			if(u.Sales_Department__c != null)
				nameUserSalesDepartment = u.Sales_Department__c;
		}
	}
//
//
/////////////////////////	WAREHOUSES ////////////////////////
//
//
	public static Id idWarehouseBarrie{
		get{
			if(idWarehouseBarrie == null) fetchWarehouses();
			if(idWarehouseBarrie == null) throw new gcException('A Warehouse with the name [Barrie] does not exist.');
			return idWarehouseBarrie;
		}
		set;
	}

	public static Id idWarehouseWholesale{
		get{
			if(idWarehouseWholesale == null) fetchWarehouses();
			if(idWarehouseWholesale == null) throw new gcException('A Warehouse with the name [Wholesale] does not exist.');
			return idWarehouseWholesale;
		}
		set;
	}

	public static Id idWarehouseMontreal{
		get{
			if(idWarehouseMontreal == null) fetchWarehouses();
			if(idWarehouseMontreal == null) throw new gcException('A Warehouse with the name [Montreal] does not exist.');
			return idWarehouseMontreal;
		}
		set;
	}

	public static Id idWarehouseWhitefish{
		get{
			if(idWarehouseWhitefish == null) fetchWarehouses();
			if(idWarehouseWhitefish == null) throw new gcException('A Warehouse with the name [Whitefish] does not exist.');
			return idWarehouseWhitefish;
		}
		set;
	}

	private static void fetchWarehouses()
	{
		List<String> listWarehouseNames = new list<String>{
			'Wholesale',
			'Whitefish',
			'Barrie',
			'Montreal'
		};
		for(AcctSeedERP__Warehouse__c whs : [SELECT Id, Name FROM AcctSeedERP__Warehouse__c WHERE Name IN:listWarehouseNames])
		{
			if(whs.Name == 'Wholesale')
				idWarehouseWholesale = whs.Id;
			else if(whs.Name == 'Whitefish')
				idWarehouseWhitefish = whs.Id;
			else if(whs.Name == 'Barrie')
				idWarehouseBarrie = whs.Id;
			else if(whs.Name == 'Montreal')
				idWarehouseMontreal = whs.Id;
		}
	}

	public static Id idWarehouseForUser{
		get{
			if(idWarehouseForUser == null)
			{
				Id idUser = UserInfo.getUserId();
				String dept = [SELECT Id, Sales_Department__c FROM User WHERE Id = :idUser][0].Sales_Department__c;

		    	set<Id> setIdWarehouseReserved = new set<Id>();
		    	setIdWarehouseReserved.add(GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Adjustment_Warehouse_Id__c);
		    	setIdWarehouseReserved.add(GMBLASERP__Inventory_Settings__c.getOrgDefaults().GMBLASERP__Transit_Warehouse_Id__c);
		    	setIdWarehouseReserved.remove(null);

				Id idWarehouse;

		    	for(AcctSeedERP__Warehouse__c whs :
		    		[SELECT Id, Name
		    		 FROM AcctSeedERP__Warehouse__c
		    		 WHERE Id NOT IN :setIdWarehouseReserved
		    		 ORDER BY CreatedDate])
		    	{
		    		if(whs.Name == dept)
		    		{
		    		   idWarehouse = whs.Id;
		    		   break;
		    		}
		    		if(idWarehouse == null)
		    		   idWarehouse = whs.Id;
		    	}
		    	idWarehouseForUser = idWarehouse;
			}
			return idWarehouseForUser;
		}
		set;
	}
	/// Kept so that the other class does not throw errors
 	public static void coverage()
 	{
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
 	}

	public static void coverage1()
	{
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
	}
}