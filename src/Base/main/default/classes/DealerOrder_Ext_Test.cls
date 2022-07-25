@isTest
private class DealerOrder_Ext_Test {
  //  static Account dealer;
  //  static Opportunity opp;
  //  static Dealer_Order__c order;
  //  static Dealer_Order_Line__c dol;
  //  static Id stdPB2Id = Test.getStandardPricebookId();
  static String partnerAccountName = 'TestPartner';

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Partner_Program_Settings__c pps = new Partner_Program_Settings__c(
      Available_Model_Years__c = '2020,2021',
      Available_Program_Years__c = '2021'
    );
    insert pps;
    Account partner = Factory_Account.buildDealerAccounts(1)[0];
    partner.Name = partnerAccountName;
    partner.BillingState = 'Ontario';
    insert partner;
    Factory_User.createPartnerUser(partner);
  }

  private static Account findPartner() {
    Id rtId = LGND_Utilities.recordTypeIdFromName('Account', 'Dealer');
    return [SELECT Id, BillingState FROM Account WHERE Name = :partnerAccountName AND RecordTypeId = :rtId];
  }

  private static List<Financing_Company__c> buildFinancingCompanies(Id acctId) {
    List<Financing_Company__c> companies = new List<Financing_Company__c>();
    for (Account supplier : Factory_Account.insertSupplierAccounts(2)) {
      companies.add(new Financing_Company__c(Account__c = acctId, Financing_Company__c = supplier.Id));
    }
    insert companies;
    return companies;
  }

  @IsTest
  static void builderInit_Test() {
    String jsonResult = DealerOrder_Ext.builderInit();
    Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(jsonResult);
    Integer currentYear = System.Today().year();
    if (System.Today().month() >= 8)
      currentYear++;
    List<Object> modelYears = (List<Object>) result.get('modelYearOptions');
    System.assertEquals(result.get('userType'), UserInfo.getUserType());
    System.assertEquals(result.get('modelYear'), currentYear);
    System.assertEquals(2, modelYears.size());
  }

  @IsTest
  static void getUserType() {
    System.assertEquals(UserInfo.getUserType(), DealerOrder_Ext.getUserType());
  }

  @IsTest
  static void getInitNewOrder_Test() {
    Account acct = findPartner();
    User partnerUser = [SELECT Id FROM User WHERE AccountId = :acct.Id];
    System.runAs(partnerUser) {
      String jsonResult = DealerOrder_Ext.getInitNewOrder();
      Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(jsonResult);

      System.assertEquals(result.get('accountId'), acct.Id);
      System.assertEquals(result.get('isFactoryStore'), false);
      System.assertEquals(result.get('province'), acct.BillingState);
      //System.assertEquals( (List<String>)result.get('programYearOptions').size(), 1 );
      System.assertEquals(result.get('allowBookingOrder'), true);
      //System.assertEquals( result.get('paymentMethodOptions').size(), LGND_Utilities.getPicklistValues('Dealer_Order__c', 'Payment_Method__c').size() );
      System.assertEquals(result.get('bookingOrder'), null);
    }
  }

  @IsTest
  static void findBookingOrder_Null_Test() {
    Account acct = findPartner();
    User partnerUser = [SELECT Id FROM User WHERE AccountId = :acct.Id];
    System.runAs(partnerUser) {
      Test.startTest();
      String result = DealerOrder_Ext.findBookingOrder('1990', acct.Id);
      Test.stopTest();

      System.assertEquals(null, result);
    }
  }

  @IsTest
  static void findBookingOrder_NotNull_Test() {
    Account acct = findPartner();
    User partnerUser = [SELECT Id FROM User WHERE AccountId = :acct.Id];
    String programYear = '2021';
    System.runAs(partnerUser) {
      Dealer_Order__c order = new Dealer_Order__c(
        Is_Booking_Order__c = true,
        Program_Year__c = programYear,
        Payment_Method__c = 'Cash',
        Account__c = acct.Id,
        Pricebook__c = gcConstants.idPricebookPartner
      );
      TriggerBase.bypass('Dealer_Order__c');
      insert order;
      TriggerBase.clearBypass('Dealer_Order__c');
      Partner_Booking_Order__c pbo = new Partner_Booking_Order__c(
        Account__c = acct.Id,
        Dealer_Order__c = order.Id,
        Name = programYear
      );
      insert pbo;

      Test.startTest();
      String result = DealerOrder_Ext.findBookingOrder(programYear, acct.Id);
      Test.stopTest();

      Partner_Booking_Order__c resultPbo = (Partner_Booking_Order__c) JSON.deserialize(
        result,
        Partner_Booking_Order__c.class
      );

      System.assertNotEquals(null, result);
      System.assertEquals(pbo.Id, resultPbo.Id);
    }
  }

  @IsTest
  static void fetchFinanceCompanys_Test() {
    Account acct = findPartner();
    List<Financing_Company__c> companies = buildFinancingCompanies(acct.Id);

    Test.startTest();
    String jsonResult = DealerOrder_Ext.fetchFinanceCompanys(acct.Id);
    List<Map<String, String>> result = (List<Map<String, String>>) JSON.deserialize(
      jsonResult,
      List<Map<String, String>>.class
    );
    Test.stopTest();

    System.assertEquals(2, result.size());
  }

  @IsTest
  static void saveDealerOrder_Test() {
    Account acct = findPartner();
    Dealer_Order__c order = new Dealer_Order__c(
      Is_Booking_Order__c = true,
      Program_Year__c = '2021',
      Payment_Method__c = 'Cash',
      Account__c = acct.Id,
      Pricebook__c = gcConstants.idPricebookPartner
    );

    Test.startTest();
    Dealer_Order__c result = DealerOrder_Ext.saveDealerOrder(JSON.serialize(order));
    Test.stopTest();

    System.assertEquals(result.Account__c, acct.Id);
  }

  @isTest
  static void tempTest2() {
    Account dealer = AccountFactory.buildDealerAccount('Test Dealer');
    insert dealer;
    Dealer_Order__c dealerOrder = new Dealer_Order__c(Account__c = dealer.Id, Payment_method__c = 'Cash');
    DealerOrder_Ext.coverage();
    DealerOrder_Ext.coverage2();
  }
}
