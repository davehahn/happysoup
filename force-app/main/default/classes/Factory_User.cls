@isTest
public class Factory_User {

  public class Factory_User_Exception extends Exception{}
  public static Map<String, Id> profileMap;

  public static User newUser( String fName,
                              String lName,
                              String profName,
                              AcctSeedERP__Warehouse__c wh )
  {
    User u = buildUser(fName, lName, findProfileId(profName) );
    u.Sales_Department__c = wh.Name;
    u.Warehouse__c = wh.Name;
    u.GL_Account_Variable_1__c = 'Retail ' + wh.Name;
    return u;
  }

  public static User createPartnerUser( Id acctId )
  {
    Contact c = new Contact( FirstName = 'First ' + LGND_Utilities.generateRandomString(6),
                             LastName = 'Last ' + LGND_Utilities.generateRandomString( 6 ),
                             AccountId = acctId);
    insert c;
    User u = buildUser('TestUser_First', 'testUser_Last', findProfileId('Legend Partner'));
    u.ContactId = c.Id;
    insert u;
    return u;
  }

  public static User createPartnerUser(Account acct )
  {
    return createPartnerUser( acct.Id );
  }

  public static User buildUser( String fName, String lName, String profName )
  {
    return buildUser( fName, lName, findProfileId(profName) );
  }

  public static User buildUser(String fName, String lName, Id profId)
  {
    Integer random = Integer.valueOf( Math.random() * 1000 );
    fName = fName.length() > 3 ? fName.subString(0,3) : fName;
    lName = lName.length() > 3 ? lName.subString(0,3) : lName;
    return new User(alias = fName+lName,
      email= fName.substring(0,1) + lName + '@testorg.com',
      emailencodingkey='UTF-8',
      lastname=lName,
      firstname = fName,
      languagelocalekey='en_US',
      localesidkey='en_CA',
      profileid = profId,
      timezonesidkey='America/New_York',
      username=fName.substring(0,1) + lName + '_' + random +'@testorg.com');
  }

  private static Id findProfileId(String profileName)
  {
    if( profileMap == null )
    {
      profileMap = new Map<String, Id>();
      for(Profile p : [SELECT Id, Name FROM Profile])
      {
        profileMap.put(p.Name, p.Id);
      }
    }
    if( profileMap.containsKey( profileName) )
      return profileMap.get( profileName );
    else
     throw new Factory_User_Exception(profileName + ' not found in profiles');
  }
}