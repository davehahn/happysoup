/**
 * Created by dhavalmacbook on 18/05/22.
 */
@isTest
public class EcwidOrderService_T {

    @testSetup static void methodName() {
        
        Id personAccountRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
		
		Account acc = new Account();
        acc.RecordTypeId  = personAccountRecordTypeId;
        acc.BillingStreet = 'test';
        acc.BillingCity='test';
        acc.BillingState = 'Ontario';
        acc.BillingStateCode='ON';
        acc.BillingCountry = 'Canada';
        acc.BillingCountryCode='CA';
        acc.BillingPostalCode = 'M3R2R2';
        acc.ShippingCountry='Canada';
        acc.BillingPostalCode = 'M3R2R2';
        acc.ShippingCountry='Canada';
        acc.ShippingCountryCode = 'CA';
        acc.PersonEmail = 'testmail@mallinator.com';
        acc.lastName = 'TestName';
        insert acc;
        AcctSeedERP__Warehouse__c warehouse = new AcctSeedERP__Warehouse__c(name = 'Wholesale');
        insert warehouse;
        AcctSeed__Accounting_Variable__c accVariable = new AcctSeed__Accounting_Variable__c(
                                                              AcctSeed__Type__c = 'GL Account Variable 3',
                                                              Name = 'Ontario',
                                                              Tax_is_Harmonized__c = true,
                                                              Tax_Rate_Provincial__c = 8.0,
                                                              Tax_Rate_Retail__c = 8.0,
                                                              AcctSeed__Active__c = true
                                                            ) ; 
        insert accVariable;
        
        AcctSeed__GL_Account__c glAccount = new AcctSeed__GL_Account__c();
        glAccount.name = 'test Gl Account';
        glAccount.AcctSeed__Type__c = 'Balance Sheet';
        glAccount.AcctSeed__Sub_Type_1__c = 'Assets';
        glAccount.AcctSeed__Sub_Type_2__c = 'Cash';
        glAccount.AcctSeed__Bank__c = true;
        insert glAccount;
        
        AcctSeed__Billing_Format__c format = new AcctSeed__Billing_Format__c();
        
        format.name = 'Test';
        format.AcctSeed__Visualforce_PDF_Page__c ='BillingActivityStatementPDF';
        format.AcctSeed__Default_Email_Template__c ='Activity_Statement_Email_Template';
        insert format;
        AcctSeed__Ledger__c ledger = new AcctSeed__Ledger__c();
        ledger.Name ='test';
        ledger.AcctSeed__Type__c = 'Transactional';
        ledger.AcctSeed__Billing_Activity_Statement_Format__c = format.id;
        ledger.AcctSeed__Billing_Outstanding_Statement_Format__c = format.id;
        ledger.AcctSeed__Default_Bank_Account__c =glAccount.id;
        ledger.AcctSeed__Default_Billing_Format__c=format.id;
        ledger.AcctSeed__Default_Purchase_Order_Format__c=format.id;
        ledger.AcctSeed__Default_Packing_Slip_Format__c = format.id;
        insert ledger;
        
 	}
    @isTest
    static void createSalesOrder_test(){
        EcwidRestUtils.storeId = '63103347';
        AcctSeedERP__Warehouse__c warehouse = [select id,name from AcctSeedERP__Warehouse__c limit 1];
        System.debug('@@@ warehouse= '+warehouse);
        AcctSeed__Accounting_Variable__c accVariable = [SELECT Id FROM AcctSeed__Accounting_Variable__c limit 1 ];
        System.debug('@@@ accVariable= '+accVariable);
        AcctSeed__Ledger__c ledger = [Select id,AcctSeed__Type__c from AcctSeed__Ledger__c limit 1 ];
        System.debug('@@ledger= '+ledger);
        EcwidRestUtils.init();
        EcwidRestUtils.wareHouseId = warehouse.id;
        Account acc = [Select id,BillingStreet,BillingCity,BillingState,BillingStateCode,BillingCountry,PersonEmail from account limit 1];
 		
        EcwidOrderMessageProcessing processing = new EcwidOrderMessageProcessing();
        processing.createSalesOrder(acc, new AcctSeedERP__Sales_Order__c());   	
    }
    	
}