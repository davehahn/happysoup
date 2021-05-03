@isTest
private class gcConstants_Test {

	@testSetup static void dataSetup()
	{
		new Factory_TestData();
		Factory_CustomSettings.setupInventorySettings();
	}
	
	@isTest 
	static void test_method_one() {
		Id idGLWIP = gcConstants.idGLWIP;
		/// GL Variables
		Id idGlv1Barrie = gcConstants.idGlv1Barrie;
		Id idGlv1Montreal = gcConstants.idGlv1Montreal;
		Id idGlv1Whitefish = gcConstants.idGlv1Whitefish;
		Id idGlv1Wholesale = gcConstants.idGlv1Wholesale;
		Id idGlv1HeadOfficeOverhead = gcConstants.idGlv1HeadOfficeOverhead;
		Id idGlv2PartsAndService = gcConstants.idGlv2PartsAndService;
		Id idGlv2Logistics = gcConstants.idGlv2Logistics;
		Id idGlv2Production = gcConstants.idGlv2Production;
		Id idGlv2Sales = gcConstants.idGlv2Sales;
		Id idGlv2Warranty = gcConstants.idGlv2Warranty;
		Id idGlv3Ontario = gcConstants.idGlv3Ontario;
		Id idGlv3Others = gcConstants.idGlv3Others;
		/// GL Accounts
		Id idGlProductRevenue = gcConstants.idGlProductRevenue;
		Id idGlCash = gcConstants.idGlCash;
		Id idGlCreditCard = gcConstants.idGlCreditCard;
		Id idGlCogsParts = gcConstants.idGlCogsParts;
		Id idGlDeposit = gcConstants.idGlDeposit;
		Id idGlProjectParts = gcConstants.idGlProjectParts;
		Id idGlProjectPartsClearing = gcConstants.idGlProjectPartsClearing;
		Id idGlSalesTaxRetail = gcConstants.idGlSalesTaxRetail;
		Id idGlSalesTaxPaid = gcConstants.idGlSalesTaxPaid;
		Id idGlSalesTaxPaidProvincial = gcConstants.idGlSalesTaxPaidProvincial;
		Id idGlTradeIn = gcConstants.idGlTradeIn;
		Id idGlCustomerRefund = gcConstants.idGlCustomerRefund;
		Id idGlAPayable = gcConstants.idGlAPayable;
		Id idGlBankFees = gcConstants.idGlBankFees;
		Id idGlFinancingFees = gcConstants.idGlFinancingFees;
		//Id idGlEquipmentExpense = gcConstants.idGlEquipmentExpense;
		Id idGlGiftCards = gcConstants.idGlGiftCards;
		Id idGlMerchantDebitCredit = gcConstants.idGlMerchantDebitCredit;
		Id idGlCashFloat = gcConstants.idGlCashFloat;
		Id idGlRBCCDN = gcConstants.idGlRBCCDN;
		Id idGlRBCUS = gcConstants.idGlRBCUS;
		Id idGlCCPayable = gcConstants.idGlCCPayable;
		Id idGlCostVariance = gcConstants.idGlCostVariance;
		Id idGlAccruedExpenses = gcConstants.idGlAccruedExpenses;
		Id idGlClearingARAP = gcConstants.idGlClearingARAP;
		Id idGlInternalBilling = gcConstants.idGlInternalBilling;
		Id idGlInternalLabour = gcConstants.idGlInternalLabour;
		Id idGlWagesLabour = gcConstants.idGlWagesLabour;
		/// Products
		Id idProductSalesTaxFederal = gcConstants.idProductSalesTaxFederal;
		Id idProductSalesTaxHarmonized = gcConstants.idProductSalesTaxHarmonized;
		Id idProductSalesTaxProvincial = gcConstants.idProductSalesTaxProvincial;
		Id idProductSalesTaxRetail = gcConstants.idProductSalesTaxRetail;
		Id idProductTradeIn = gcConstants.idProductTradeIn;
		Id idProductTradeInLien = gcConstants.idProductTradeInLien;
		Id idProductTradeInBoats = gcConstants.idProductTradeInBoats;
		Id idProductPrecisionFix = gcConstants.idProductPrecisionFix;
		Id idProductInternalLabour = gcConstants.idProductInternalLabour;
		Id idProductInternalBilling = gcConstants.idProductInternalBilling;
		Id idProductInternalBalance = gcConstants.idProductInternalBalance;
		/// Pricebooks
		Id idPricebookFactory = gcConstants.idPricebookFactory;
		Id idPricebookRetail = gcConstants.idPricebookRetail;
		Id idPricebookPartner = gcConstants.idPricebookPartner;
		/// ProjectRecordTypes
		Id idRtProjectBoatSale = gcConstants.idRtProjectBoatSale;
		Id idRtProjectPartnerBoatSale = gcConstants.idRtProjectPartnerBoatSale;
		Id idRtProjectCounterSale = gcConstants.idRtProjectCounterSale;
		Id idRtProjectManufacturing = gcConstants.idRtProjectManufacturing;
		Id idRtProjectService = gcConstants.idRtProjectService;
		Id idRtProjectWarranty = gcConstants.idRtProjectWarranty;
		Id idRtPartnerPartsOrder = gcConstants.idRtPartnerPartsOrder;
		Id idRtTradeIn = gcConstants.idRtTradeIn;
		Id idRtFixedAsset = gcConstants.idRtFixedAsset;
		/// User Info
		String nameUserSalesDepartment = gcConstants.nameUserSalesDepartment;
		String nameUserWarehouse = gcConstants.nameUserWarehouse;
		String nameUserBusinessUnitGLV1 = gcConstants.nameUserBusinessUnitGLV1;
		/// All Warehouses
		Id idWarehouseBarrie = gcConstants.idWarehouseBarrie;
		Id idWarehouseWholesale = gcConstants.idWarehouseWholesale;
		Id idWarehouseMontreal = gcConstants.idWarehouseMontreal;
		Id idWarehouseWhitefish = gcConstants.idWarehouseWhitefish;
		/// User Warehouse
		Id idWarehouseForUser = gcConstants.idWarehouseForUser;
		/// Others
		gcConstants.convertProjectRecordTypeToGlv2(idRtTradeIn);
		gcConstants.convertProjectRecordTypeToGlv2(idRtFixedAsset);
		gcConstants.convertProjectRecordTypeToGlv2(idRtProjectWarranty);
		gcConstants.convertProjectRecordTypeToGlv2(idRtProjectManufacturing);
		gcConstants.convertProjectRecordTypeToGlv2(null);

		gcConstants.convertUserDeptToGlv1('');
		gcConstants.convertUserDeptToWhs('');

		gcConstants.coverage();
		gcConstants.coverage1();
	}	
}