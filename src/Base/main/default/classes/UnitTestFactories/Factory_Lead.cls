@isTest
public class Factory_Lead {
  private static TA_Lead_TestHelper helper = TA_Lead_TestHelper.getInstance();

  public static Lead buildLead(String fName, String lName) {
    Lead l = constructBasicLead(fName, lName);
    l.Status = Lead_Service.NEW_STATUS;
    l.OwnerId = helper.getQueue().Id;
    return l;
  }

  public static List<Lead> buildLeads( String fName, String lName, Integer count ){
    List<Lead> result = new List<Lead>();
    for( Integer i=0; i<count; i++){
      result.add( buildLead(fName + String.valueOf(i), lName + String.valueOf(i)) );
    }
    return result;
  }

  public static Lead buildAcceptedLead(String fName, String lName) {
    Lead l = constructBasicLead(fName, lName);
    l.Status = Lead_Service.ACCEPTED_STATUS;
    l.OwnerId = UserInfo.getUserId();
    return l;
  }

  public static Lead buildLead(String fName, String lName, String leadSource) {
    Lead l = buildLead(fName, lName);
    l.LeadSource = leadSource;
    return l;
  }

  public static Lead buildLead(Boolean isPersonAccount) {
    String uniq = LGND_Utilities.generateRandomString(6);
    return new Lead(
      FirstName = '_unitTest_First_' + uniq,
      LastName = '_unitTest_Last_' + uniq,
      Email = 'unitTest_' + uniq + '@testing.net',
      isPersonAccount__c = isPersonAccount,
      Status = 'New',
      OwnerId = helper.getQueue().Id,
      Company = '_unitTest_Company_' + uniq
    );
  }

  public static Lead insertLead(String fName, String lName) {
    Lead l = buildLead(fName, lName);
    insert l;
    return l;
  }

  public static Lead insertLead(String fName, String lName, String leadSource) {
    Lead l = buildLead(fName, lName, leadSource);
    insert l;
    return l;
  }

  private static Lead constructBasicLead(String fName, String lName) {
    String[] langs = LGND_Utilities.getPicklistValues('Lead', 'Preferred_Language__c');
    return new Lead(
      Email = fname + '@' + lname + '.com',
      FirstName = fname,
      LastName = lname,
      Phone = '111-111-1111',
      MobilePhone = '222-222-2222',
      Preferred_Language__c = langs[0]
    );
  }
}
