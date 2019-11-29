@isTest
public with sharing class User_TestFactory {
  public static AcctSeedERP__Warehouse__c warehouse;
  static {
    warehouse = AcctSeed_Settings_Factory.getWarehouse('Whitefish');
    if( warehouse.GL_Account_Variable_3__c == null )
      warehouse.GL_Account_Variable_3__c = AcctSeed_Settings_Factory.getTaxZone('Ontario').Id;
  }

  public static User newUser( String fName, String lName, String profName )
  {
    return buildUser(fName, lName, findProfileId(profName) );
  }
  public static User newUser( String fName, String lName, String profName, AcctSeedERP__Warehouse__c wh )
  {
    User u = buildUser(fName, lName, findProfileId(profName) );
    u.Sales_Department__c = wh.Name;
    u.Warehouse__c = wh.Name;
    u.GL_Account_Variable_1__c = 'Retail ' + wh.Name;
    insert u;
    return u;
  }

  public static User createWhitefishUser( String fName, String lName, String profName )
  {
    User u = buildUser(fName, lName, findProfileId(profName));
    u.Sales_Department__c = 'Whitefish';
    u.Warehouse__c = warehouse.Name;
    insert u;
    return u;
  }

  public static User createPartnerUser(Account acct )
  {
    Contact c = new Contact( FirstName = 'TestContact_First',
                             LastName = 'TestContact_Last',
                             AccountId = acct.Id);
    insert c;
    User u = buildUser('TestUser_First', 'testUser_Last', findProfileId('Legend Partner'));
    u.ContactId = c.Id;
    insert u;
    return u;
  }

  public static User newCommissionAllUser( String fName, String lName ){
    Integer random = Integer.valueOf( Math.random() * 1000 );
    fName = fName.length() > 3 ? fName.subString(0,3) : fName;
    lName = lName.length() > 3 ? lName.subString(0,3) : lName;
    return new User(alias = fName+lName,
      email= fName.substring(0,1) + lName + '@testorg.com',
      emailencodingkey='UTF-8',
      profileid = findProfileId('System Administrator'),
      lastname=lName,
      firstname = fName,
      languagelocalekey='en_US',
      localesidkey='en_CA',
      Commission_Access__c = 'All Records',
      Receives_Commission__c = true,
      Commission_Percentage__c = 100,
      timezonesidkey='America/New_York',
      username=fName.substring(0,1) + lName + '_' + random +'@testorg.com');
  }

  public static User newCommissionOwnerOnlyUser( String fName, String lName ){
    Integer random = Integer.valueOf( Math.random() * 1000 );
    fName = fName.length() > 3 ? fName.subString(0,3) : fName;
    lName = lName.length() > 3 ? lName.subString(0,3) : lName;
    return new User(alias = fName+lName,
      email= fName.substring(0,1) + lName + '@testorg.com',
      emailencodingkey='UTF-8',
      profileid = findProfileId('System Administrator'),
      lastname=lName,
      firstname = fName,
      languagelocalekey='en_US',
      localesidkey='en_CA',
      Commission_Access__c = 'Own Records',
      timezonesidkey='America/New_York',
      username=fName.substring(0,1) + lName + '_' + random +'@testorg.com');
  }

  public static User newPartnerUser( String fName, String lName, Id accountId )
  {
    Id profId = findProfileId('Legend Partner');
    Contact cont = new Contact(
      FirstName = fName,
      LastName = lName,
      AccountId = accountId
    );
    insert cont;
    User user = buildUser( fName, lName, profId );
    user.ContactId = cont.Id;
    return user;
  }

  public static User newUser( String fName, String lName, String profName, String roleName )
  {
    User u = buildUser(fName, lName, findProfileId(profName) );
    u.UserRoleId = findUserRoleId(roleName);
    return u;
  }

  public static User newSysAdmin(String fName, String lName)
  {
    return buildUser(fName, lName, findProfileId('System Administrator') );
  }

  public static User newSysAdmin(String fName, String lName, String salesDept)
  {
    User u = newSysAdmin(fName, lName);
    u.Sales_Department__c = salesDept;
    return u;
  }

  private static Id findProfileId(String profileName)
  {
    return [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1].Id;
  }

  private static Id findUserRoleId(String roleName)
  {
    return [SELECT Id FROM UserRole WHERE Name = :roleName LIMIT 1].Id;
  }

  private static User buildUser(String fName, String lName, Id profId)
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

}