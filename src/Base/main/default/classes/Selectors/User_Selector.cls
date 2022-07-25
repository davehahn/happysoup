/**
 * Created by dave on 2020-11-06.
 */

public virtual class User_Selector extends Application_Selector {
  private final List<String> defaultFields = new List<String>{
    'Id',
    'AccountId',
    'ContactId',
    'Warehouse__c',
    'FirstName',
    'LastName',
    'Email',
    'ManagerId'
  };

  public User_Selector() {
    this.sObjectName = 'User';
    this.fields = defaultFields;
  }

  public static User getCurrentUser() {
    return getById(UserInfo.getUserId());
  }

  public static User getById(Id recordId) {
    User[] result = getAllByIds(new Set<Id>{ recordId });
    if (result.size() == 0)
      throw new Application_Selector.SelectorException('No user found with supplied Id');
    return result[0];
  }

  public static List<User> getAllByIds(Set<Id> recordIds) {
    User_Selector selector = new User_Selector();
    selector.addWhereIdIn(recordIds);
    return selector.query();
  }
}
