@isTest(SeeAllData=false)
public class EcwidEvents_T {
  static AcctSeed__GL_Account__c revenueAccount;
  static AcctSeed__GL_Account__c expenseAccount;
  static AcctSeed__GL_Account__c inventoryAccount;
  @testSetup
  static void dataSetup() {
    Pricebook2 customPb = new Pricebook2(
      Name = 'CustomPb',
      isActive = true,
      Sales_Year__c = String.valueOf(Date.today().year()),
      Version__c = 2
    );
    insert customPb;
    buildGlAccounts();
    Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
      .get('PersonAccount')
      .getRecordTypeId();

    Account acc = new Account();
    acc.RecordTypeId = personAccountRecordTypeId;
    acc.BillingStreet = 'test';
    acc.BillingCity = 'test';
    acc.BillingState = 'Ontario';
    acc.BillingStateCode = 'ON';
    acc.BillingCountry = 'Canada';
    acc.BillingCountryCode = 'CA';
    acc.BillingPostalCode = 'M3R2R2';
    acc.ShippingCountry = 'Canada';
    acc.BillingPostalCode = 'M3R2R2';
    acc.ShippingCountry = 'Canada';
    acc.ShippingCountryCode = 'CA';
    acc.PersonEmail = 'test@malinattor.com';
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
    );
    insert accVariable;

    AcctSeed__Accounting_Variable__c accVariableWholesale = new AcctSeed__Accounting_Variable__c(
      AcctSeed__Type__c = 'GL Account Variable 3',
      Name = 'Wholesale',
      Tax_is_Harmonized__c = true,
      Tax_Rate_Provincial__c = 8.0,
      Tax_Rate_Retail__c = 8.0,
      AcctSeed__Active__c = true
    );
    insert accVariableWholesale;

    AcctSeed__GL_Account__c glAccount = new AcctSeed__GL_Account__c();
    glAccount.name = 'test Gl Account';
    glAccount.AcctSeed__Type__c = 'Balance Sheet';
    glAccount.AcctSeed__Sub_Type_1__c = 'Assets';
    glAccount.AcctSeed__Sub_Type_2__c = 'Cash';
    glAccount.AcctSeed__Bank__c = true;
    insert glAccount;

    AcctSeed__Billing_Format__c format = new AcctSeed__Billing_Format__c();

    format.name = 'Test';
    format.AcctSeed__Visualforce_PDF_Page__c = 'BillingActivityStatementPDF';
    format.AcctSeed__Default_Email_Template__c = 'Activity_Statement_Email_Template';
    insert format;
    AcctSeed__Ledger__c ledger = new AcctSeed__Ledger__c();
    ledger.Name = 'test';
    ledger.AcctSeed__Type__c = 'Transactional';
    ledger.AcctSeed__Billing_Activity_Statement_Format__c = format.id;
    ledger.AcctSeed__Billing_Outstanding_Statement_Format__c = format.id;
    ledger.AcctSeed__Default_Bank_Account__c = glAccount.id;
    ledger.AcctSeed__Default_Billing_Format__c = format.id;
    ledger.AcctSeed__Default_Purchase_Order_Format__c = format.id;
    ledger.AcctSeed__Default_Packing_Slip_Format__c = format.id;
    insert ledger;

    Id rtId = recordIdFromType('Part');
    Product2 p = new Product2(
      name = 'Legend Blue Towel',
      recordTypeId = rtId,
      AcctSeed__Inventory_Type__c = 'Purchased',
      AcctSeed__Accounting_Type__c = 'Taxable_Product',
      AcctSeed__Expense_GL_Account__c = expenseAccount.Id,
      AcctSeed__Inventory_GL_Account__c = inventoryAccount.Id,
      AcctSeed__Revenue_GL_Account__c = revenueAccount.Id,
      AcctSeed__Unit_Cost__c = 100.00,
      Unique_Product_Code__c = 'TOWELBLUE',
      isActive = true
    );
    insert p;
    Factory_PricebookEntry.createStandardEntries(new Set<Id>{ p.Id }, 0);
    insert Factory_PricebookEntry.buildEntry(p.Id, customPb.id, 0);
  }

  private static void buildGlAccounts() {
    List<AcctSeed__GL_Account__c> glAccts = new List<AcctSeed__GL_Account__c>();
    if (revenueAccount == null) {
      revenueAccount = new AcctSeed__GL_Account__c(
        Name = 'Test Revenue Account',
        AcctSeed__Active__c = true,
        AcctSeed__Type__c = 'Revenue'
      );
      glAccts.add(revenueAccount);
    }
    if (expenseAccount == null) {
      expenseAccount = new AcctSeed__GL_Account__c(
        Name = 'Test Expense Account',
        AcctSeed__Active__c = true,
        AcctSeed__Type__c = 'Expense'
      );
      glAccts.add(expenseAccount);
    }
    if (inventoryAccount == null) {
      inventoryAccount = new AcctSeed__GL_Account__c(
        Name = 'Test Inventory Account',
        AcctSeed__Active__c = true,
        AcctSeed__Sub_Type_1__c = 'Assets',
        AcctSeed__Type__c = 'Balance Sheet'
      );
      glAccts.add(inventoryAccount);
    }
    if (glAccts.size() > 0)
      insert glAccts;
  }

  private static Id recordIdFromType(String record_type) {
    Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.Product2;
    Map<String, Schema.RecordTypeInfo> Product2RecordTypeInfo = cfrSchema.getRecordTypeInfosByName();
    return Product2RecordTypeInfo.get(record_type).getRecordTypeId();
  }

  @isTest
  static void restAPICall_LeadCreation_Test() {
    EcwidRestUtils.storeId = '63103347';
    AcctSeedERP__Warehouse__c warehouse = [SELECT id, name FROM AcctSeedERP__Warehouse__c LIMIT 1];
    System.debug('@@@ warehouse= ' + warehouse);
    List<AcctSeed__Accounting_Variable__c> accVariable = [SELECT Id FROM AcctSeed__Accounting_Variable__c];
    System.debug('@@@ accVariable= ' + accVariable);
    AcctSeed__Ledger__c ledger = [SELECT id, AcctSeed__Type__c FROM AcctSeed__Ledger__c LIMIT 1];
    System.debug('@@ledger= ' + ledger);
    EcwidRestUtils.init();
    EcwidRestUtils.wareHouseId = warehouse.id;
    Account acc = [
      SELECT id, BillingStreet, BillingCity, BillingState, BillingStateCode, BillingCountry, PersonEmail
      FROM account
      WHERE PersonEmail = 'test@malinattor.com'
    ];

    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();

    req.requestURI = '/services/apexrest/Ecwid/events';
    req.httpMethod = 'POST';
    req.addHeader('X-Ecwid-Webhook-Signature', 'FXOMKlyXEr3K5FnljerQSF69WSF8F7pCNh31knzvc5Y=');
    req.addHeader('Content-Type', 'application/json; charset=UTF-8');
    String body = '{"eventId":"6b30fd3f-1b03-422c-9b19-aeae4d7ce697","eventCreated":1652876816,"storeId":63103347,"entityId":342611005,"eventType":"order.created","data":{"newPaymentStatus":"AWAITING_PAYMENT","newFulfillmentStatus":"AWAITING_PROCESSING","orderId":"LYCLM"}}';
    req.requestBody = Blob.valueOf(body);
    RestContext.request = req;
    RestContext.response = res;
    Test.setMock(HttpCalloutMock.class, new EcwidOrderCalloutMock_T());
    EcwidEvents.process();
  }
}
