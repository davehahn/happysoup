@isTest
private class LGND_API_Partners_Test {
  private class partnersWrapper {
    public String id;
    public String name;
    public String street;
    public String city;
    public String province;
    public String country;
    public String postalCode;
    public Decimal longitude;
    public Decimal latitude;
    public String phone;
    public String fax;
    public String email;
  }

  static Integer acctCount = 20;

  @testSetup
  static void dataSetup() {
    Factory_Account.insertDealerAccounts(acctCount);
  }

  @isTest
  static void partners_test() {
    // set up the request object
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();

    req.requestURI = '/v2/partners';
    req.httpMethod = 'GET';
    RestContext.request = req;
    RestContext.response = res;

    Test.startTest();
    LGND_API_Partners.fetchPartners();
    String jsonData = res.responseBody.toString();
    List<partnersWrapper> result = (List<partnersWrapper>) JSON.deserialize(jsonData, List<partnersWrapper>.class);
    Test.stopTest();

    System.assertEquals(acctCount, result.size());
  }
}
