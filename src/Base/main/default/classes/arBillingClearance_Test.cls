@isTest(SeeAllData=TRUE)
private class arBillingClearance_Test{

	static testMethod void test1()
	{
        arBillingClearance.coverage();
    }
}
//@isTest(seeAllData=true)
//private class arBillingClearance_Test {
//	static Account supplierAccount;
//	static AcctSeed__Project__c warrantyErp;
//  	static Case cs;

//  	public static void init()
//  	{
//  		supplierAccount = AccountFactory.insertSupplierAccount('New Supplier');
//	    cs = Factory_Case.createWarrantyCase( supplierAccount );
//	    warrantyErp = Factory_ERPOrder.createWarrantyERP( supplierAccount, c.Serial_Number__c, 2 );
//	}	
//	@isTest(seeAllData=true)
//  	static void testWarrantyClearing() {

//  	}
//}