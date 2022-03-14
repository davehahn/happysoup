/**
 * Created by dave on 2021-06-03.
 */

public inherited sharing class Application_Constants
{

  private static Application_Constants instance = null;

  public User currentUser {
    get {
      if( currentUser == null )
      {
        currentUser = [
          SELECT
            Id,
            Sales_Department__c,
            Warehouse__c
          FROM User
          WHERE Id = :UserInfo.getUserId()
        ];
      }
      return currentUser;
    }
    private set;
  }

  private Application_Constants(){}

  public static Application_Constants getInstance()
  {
    if( instance == null ) instance = new Application_Constants();
    return instance;
  }

}