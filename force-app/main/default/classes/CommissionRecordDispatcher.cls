public with sharing class CommissionRecordDispatcher {

  private final User currentUser;
  private final Set<String> salesProfiles = new Set<String>{'Business Manager', 'Standard Legend User'};

	public CommissionRecordDispatcher()
  {
    this.currentUser = [SELECT Id, Commission_Access__c
                   FROM User
                   WHERE Id = :UserInfo.getUserId()];
	}

  public PageReference indexRedirect()
  {
    if( currentUser.Commission_Access__c == 'All Records' )
    {
      return Page.CommissionRecords_Office;
    }
    if( currentUser.Commission_Access__c == 'Own Records' )
    {
      return Page.CommissionRecord_Sales;
    }
    return null;
  }

}