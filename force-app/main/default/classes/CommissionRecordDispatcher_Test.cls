@isTest
private class CommissionRecordDispatcher_Test {

  //static User accounting;
  static User allUser;
  static User ownerOnlyUser;
  //static User sales;
  static PageReference adminPage;
  static PageReference salesPage;

  public static void init()
  {
    allUser = User_TestFactory.newCommissionAllUser('fre','ptr');
    ownerOnlyUser = User_TestFactory.newCommissionOwnerOnlyUser('hft', 'psd');
    //sales = User_TestFactory.newUser('awd', 'bep', 'Standard Legend User');
    //accounting = User_TestFactory.newUser('brp', 'axp', 'Standard Legend User', 'Accounting');
    User[] users = new List<User>{allUser, ownerOnlyUser};
    insert users;
    adminPage = Page.CommissionRecords_Office;
    salesPage = Page.CommissionRecord_Sales;
  }



	@isTest static void completeTest() {
		init();
    System.runAs(allUser)
    {
      CommissionRecordDispatcher crd = new CommissionRecordDispatcher();
      System.assertEquals(adminPage.getUrl(), crd.indexRedirect().getUrl() );
    }
    System.runAs(ownerOnlyUser)
    {
      CommissionRecordDispatcher crd = new CommissionRecordDispatcher();
      System.assertEquals(salesPage.getUrl(), crd.indexRedirect().getUrl() );
    }
	}

}