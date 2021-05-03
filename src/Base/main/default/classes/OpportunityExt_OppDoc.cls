global with sharing class OpportunityExt_OppDoc {
  public ApexPages.StandardController std;
  //public List<Opportunity_Document__c> oppDocs{get;set;}
  public Map<String, List<Opportunity_Document__c>> oppDocs { get; set; }
  public Opportunity_Document__c[] docs { get; private set; }
  public Opportunity opp;
  public Id acctId { get; set; }
  private User currentUser;

	global OpportunityExt_OppDoc(ApexPages.StandardController controller) {
		std = controller;
    Id oppId=std.getId();
    opp = [SELECT Id, AccountId, Invoice_Document_Id__c FROM Opportunity WHERE Id = :oppId];
    this.acctId = opp.AccountId;
    oppDocs = refreshDocList();
    currentUser = [SELECT Id, Name, Profile.Name
                   FROM User
                   WHERE Id = :UserInfo.getUserId()];
	}

  @RemoteAction
  global static void deleteDoc(String docId)
  {
    Opportunity_Document__c toDel = new Opportunity_Document__c(id=docId);
    try {
      delete toDel;
    }
    catch(Exception e){}
  }

  public Boolean getRenderList()
  {
    return !oppDocs.isEmpty();
  }

  //public Boolean getIsBOM_or_ADMIN()
  //{
  //  return new Set<String>{'Business Manager', 'System Administrator', 'Legend Admin'}.contains( currentUser.Profile.Name );
  //}

  //public Boolean getCanCreateInvoice()
  //{
  //  return new Set<String>{'System Administrator', 'Legend Admin'}.contains( currentUser.Profile.Name ) ||
  ////    ( getIsBOM_or_ADMIN() && opp.Invoice_Document_Id__c != null );
  //}

  private Map<String, List<Opportunity_Document__c>> refreshDocList()
  {
    Map<String, List<Opportunity_Document__c>> docMap = new Map<String, List<Opportunity_Document__c>>();
    docs = [SELECT Id, Name, Document_Id__c, Opportunity__c, Document_Type__c
            FROM Opportunity_Document__c
            WHERE Opportunity__c = :opp.Id
            ORDER BY createddate desc];

    for(Opportunity_Document__c od : docs)
    {
      if( !docMap.containsKey(od.Document_Type__c) )
      {
        docMap.put(od.Document_Type__c, new List<Opportunity_Document__c>() );
      }
      docMap.get(od.Document_Type__c).add(od);
    }
    return docMap;
  }

}