@isTest
public class Factory_Lead {

  public static Lead buildLead( String fName, String lName )
  {
    String[] langs = LGND_Utilities.getPicklistValues('Lead', 'Preferred_Language__c');
    Lead l = new Lead(
      Email = fname + '@' + lname + '.com',
      FirstName = fname,
      LastName = lname,
      Phone = '111-111-1111',
      MobilePhone = '222-222-2222',
      Preferred_Language__c = langs[0]
    );
    return l;
  }

  public static Lead buildLead(
    String fName,
    String lName,
    String leadSource )
  {
    Lead l = buildLead( fName, lName );
    l.LeadSource = leadSource;
    return l;
  }

  public static Lead buildLead(Boolean isPersonAccount)
  {
    String uniq = LGND_Utilities.generateRandomString(6);
    return new Lead( FirstName = '_unitTest_First_' + uniq,
      LastName = '_unitTest_Last_' +  uniq,
      Email = 'unitTest_' + uniq +'@testing.net',
      isPersonAccount__c = isPersonAccount,
      Company = '_unitTest_Company_' + uniq );
  }

  public static Lead insertLead( String fName, String lName )
  {
    Lead l = buildLead( fName, lName );
    insert l;
    return l;
  }

  public static Lead insertLead(
    String fName,
    String lName,
    String leadSource)
  {
    Lead l = buildLead( fName, lName, leadSource );
    insert l;
    return l;
  }

}