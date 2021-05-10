@isTest(seeAllData=true)
private class OpportunityDispatcher_Test {

  static User sysAdmin;
  static User legAdmin;
  static User sales;
  static Opportunity opp;

  public static void init()
  {

    sysAdmin = User_TestFactory.newSysAdmin('fre','ptr');
    legAdmin = User_TestFactory.newUser('hft', 'psd', 'Legend Admin User - New');
    sales = User_TestFactory.newUser('awd', 'bep', 'Legend Standard User - New');
    User[] users = new List<User>{sysAdmin, legAdmin, sales};
    insert users;

    //adminPage = Page.CommissionRecords_Office;
    //salesPage = Page.CommissionRecord_Sales;

  }

  @isTest static void withoutOpp_Test()
  {
    PageReference pr = new PageReference('/006');
    pr.getParameters().put('nooverride', '1');
    ApexPages.StandardController sc = new ApexPages.StandardController( new Opportunity() );
    OpportunityDispatcher od = new OpportunityDispatcher(sc);

    System.assertEquals( pr.getUrl(), od.viewRedir().getUrl() );
    System.assertEquals( pr.getUrl(), od.editRedirect().getUrl() );
  }

	@isTest static void boat_sale_view_test() {
     opp = OpportunityFactory.insertRetailBoatSale();
     PageReference pageRef = Page.Opportunity_Detail;
     pageRef.getParameters().put('id', opp.Id);
     pageRef.getParameters().put('nooverride', '1');
     ApexPages.StandardController sc = new ApexPages.StandardController(opp);
     OpportunityDispatcher od = new OpportunityDispatcher(sc);

     System.assertEquals( pageRef.getUrl(), od.viewRedir().getUrl() );

	}

	@isTest static void counter_sale_view_test() {
		opp = OpportunityFactory.insertRetailCounterSale();
    PageReference pageRef = Page.Opportunity_CounterSaleView;
    pageRef.getParameters().put('id', opp.Id);
    pageRef.getParameters().put('nooverride', '1');
    ApexPages.StandardController sc = new ApexPages.StandardController(opp);
    OpportunityDispatcher od = new OpportunityDispatcher(sc);

    System.assertEquals( pageRef.getUrl(), od.viewRedir().getUrl() );
	}

  @isTest static void boat_sale_edit_test() {
     opp = OpportunityFactory.insertRetailBoatSale();
     PageReference pageRef = new PageReference('/'+opp.Id+'/e');
     pageRef.getParameters().put('nooverride', '1');
     ApexPages.StandardController sc = new ApexPages.StandardController(opp);
     OpportunityDispatcher od = new OpportunityDispatcher(sc);

     System.assertEquals( pageRef.getUrl(), od.editRedirect().getUrl() );

  }

  @isTest static void counter_sale_edit_test() {
    opp = OpportunityFactory.insertRetailCounterSale();
    PageReference pageRef = Page.RetailCounterSalesTool;
    pageRef.getParameters().put('id', opp.Id);
    pageRef.getParameters().put('nooverride', '1');
    ApexPages.StandardController sc = new ApexPages.StandardController(opp);
    OpportunityDispatcher od = new OpportunityDispatcher(sc);

    System.assertEquals( pageRef.getUrl(), od.editRedirect().getUrl() );
  }

  @isTest static void configurator_test() {
    init();
    opp = OpportunityFactory.insertRetailCounterSale();
    Id oppOwner = [SELECT Id, OwnerId FROM Opportunity WHERE Id =:opp.Id].OwnerId;
    PageReference unlockedPage = Page.BoatConfigurator;
    unlockedPage.getParameters().put('opportunity_id', opp.Id);
    unlockedPage.getParameters().put('nooverride', '1');
    PageReference lockedPage = Page.BoatConfigurator_View;
    lockedPage.getParameters().put('opportunity_id', opp.Id);
    lockedPage.getParameters().put('nooverride', '1');
    ApexPages.StandardController sc = new ApexPages.StandardController(opp);
    OpportunityDispatcher od = new OpportunityDispatcher(sc);
    PageReference adminOpen;
    PageReference adminLocked;
    PageReference salesOpen;
    PageReference salesLocked;
    Test.startTest();
    System.runAs(sysAdmin)
    {
      adminOpen = od.configuratorRedir();
    }
    System.runAs( sales )
    {
      salesOpen = od.configuratorRedir();
    }

    Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
    req1.setComments('Submitting request for approval.');
    req1.setObjectId(opp.id);
    req1.setSubmitterId( opp.OwnerId );
    req1.setProcessDefinitionNameOrId('Retail_Sales_Approval');
    Approval.process(req1);

    System.runAs(sysAdmin)
    {
      adminLocked = od.configuratorRedir();
    }
    System.runAs( sales )
    {
      salesLocked = od.configuratorRedir();
    }
    Test.stopTest();

    //System.assertEquals( unlockedPage.getUrl(), adminOpen.getUrl() );
    System.assertEquals( unlockedPage.getUrl(), salesOpen.getUrl() );
    //System.assertEquals( unlockedPage.getUrl(), adminLocked.getUrl() );
    System.assertEquals( lockedPage.getUrl(), salesLocked.getUrl() );
  }

}