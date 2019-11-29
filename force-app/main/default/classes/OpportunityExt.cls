public with sharing class OpportunityExt {

  private ApexPages.StandardController std;
  public Account account { get; set; }
  public Opportunity current_opportunity {get; set;}
  public Contact cont {get; private set;}
  public Contact buyer { get; set; }
  public Contact coBuyer { get; set; }
  public Boolean isNewRecord { get; private set;}
  public String httpStage {get; set; }
  public transient Map<String, Decimal> probabilityStageNameMap;
  public String testString;
  public User currentUser {get; set;}
  public List<String> previousOppContactIds {
    get {
        if( previousOppContactIds == null ){
            previousOppContactIds = new List<String>();
        }
        return previousOppContactIds;
    }
    private set;}
  public boolean renderOtherDepositMethod {
    get {
      if(renderOtherDepositMethod == null){
        renderOtherDepositMethod = false;
      }
      return renderOtherDepositMethod;
    }
    set;
  }

  public List<String> fields = new List<String>{ 'AccountId',
                                            'Name',
                                            'BoatId__c',
                                            'Line_Item_Count__c',
                                            'Invoice_Document_Id__c',
                                            'On_Water_Orientation__c',
                                            'Delivery_Date__c',
                                            'Payment_Method__c',
                                            'Probability',
                                            'Pickup_Location__c',
                                            'Deposit__c',
                                            'Deposit_Method__c',
                                            'Deposit_Method_Other__c',
                                            'StageName',
                                            'Customer_Notes__c',
                                            'Boat_Model_Year__c',
                                            'Trailer_Model_Year__c',
                                            'Account.Id',
                                            'Account.Name',
                                            'Account.FirstName',
                                            'Account.MiddleName',
                                            'Account.LastName',
                                            'Account.PersonEmail',
                                            'Account.Phone',
                                            'Account.Sex__c',
                                            'Account.PersonHomePhone',
                                            'Account.PersonMobilePhone',
                                            'Account.IsPersonAccount',
                                            'Account.PersonBirthDate',
                                            'Account.Drivers_License__c',
                                            'Account.BillingStreet',
                                            'Account.BillingState',
                                            'Account.BillingStateCode',
                                            'Account.BillingCity',
                                            'Account.BillingCountryCode',
                                            'Account.BillingPostalCode',
                                            'Account.ShippingStreet',
                                            'Account.ShippingStateCode',
                                            'Account.ShippingCity',
                                            'Account.ShippingCountryCode',
                                            'Account.ShippingPostalCode'};

  public Map<String, String> stageRollbackMap = new Map<String,String>{
    'Orientation Specialist Add-On Call' => 'Tagging Pending',
    'Pending Work Order' => 'Orientation Specialist Add-On Call',
    'Pending Rigging' => 'Pending Work Order',
    'Pending Inspection' => 'Pending Rigging',
    'Pending Pickup' => 'Pending Inspection',
    'Picked Up / Won' => 'Pending Pickup'
  };

  public OpportunityExt(ApexPages.StandardController stdCtrl) {
    std=stdCtrl;
    String oppId = std.getId();

    currentUser = [SELECT Id, Name, Profile.Name
                   FROM User
                   WHERE Id = :UserInfo.getUserId()];

    //if( test.isRunningTest() )
    //{
      if( oppId == null )
      {
        this.current_opportunity = (Opportunity)std.getRecord();
      }
      else
      {
        String query = 'SELECT ' + fieldsToString(fields) + ' FROM Opportunity WHERE Id = \'' + oppId + '\'';
        this.current_opportunity = Database.query(query);
      }
    //}
    //else
    //{
    //  std.addFields(fields);
    //  this.current_opportunity = (Opportunity)std.getRecord();
    //}

    isNewRecord = this.current_opportunity.Id == null;
    if( isNewRecord == true ){
      this.current_opportunity.StageName = 'Quoting';
      this.current_opportunity.Probability = findProbability('Quoting');
      Id actId = ApexPages.currentPage().getParameters().get('AccountId');
      User u = [SELECT Id, Sales_Department__c FROM User WHERE Id = :UserInfo.getUserId()];
      if(actId != null){
        account = [SELECT Id, Name, (SELECT Id FROM Opportunities) FROM Account WHERE Id = :actId];
        this.current_opportunity.Name = account.Name + ' - ' + (account.Opportunities.size() + 1);
        this.current_opportunity.AccountId = account.Id;
        if( u.Sales_Department__c != null){
          this.current_opportunity.Sales_Department__c = u.Sales_Department__c;
        }
      }
    }
    else
    {
      for(OpportunityContactRole ocr: fetchContectRoles( current_opportunity.Id ) ){
        previousOppContactIds.add( ocr.ContactId );
        if( ocr.Role == 'Buyer' )
        {
          buyer = ocr.Contact;
        }
        if( ocr.Role == 'Co-Buyer' )
        {
          coBuyer = ocr.Contact;
        }
      }
      System.debug( buyer );
      System.debug( coBuyer );
      Id contactId = ApexPages.currentPage().getParameters().get('contactId');
      if( contactId == null ){
        cont = new Contact();
      } else {
        String query = 'SELECT ' + contactFields() + ' FROM Contact WHERE Id = \'' + contactId + '\'';
        cont = Database.query(query);
      }
    }
  }

  private OpportunityContactRole[] fetchContectRoles( Id oppId)
  {
    String query = 'SELECT Id, ContactId, Role, Contact.Id, ';
    for(Schema.FieldSetMember f : Schema.SObjectType.Contact.FieldSets.getMap().get('BuyerFields').getFields() )
    {
      query += 'Contact.' + f.getFieldPath() + ', ';
    }
    query = query.removeEnd(', ');
    query += ' FROM OpportunityContactRole WHERE OpportunityId = \'' + oppId + '\'';
    return Database.query( query );
  }

  public String getBoatBuilderButtonText()
  {
    return current_opportunity.BoatId__c == null ? 'Build a Boat' : 'Edit Boat Sale';
  }

  public Boolean getHasLineItems()
  {
    return current_opportunity.Line_Item_Count__c > 0;
  }

  public Boolean getCanSubmitForApproval()
  {
    return new Set<String>{'Quoting', 'Negotiation/Review'}.contains(current_opportunity.StageName);
  }

  public Boolean getIsBOM_or_ADMIN()
  {
    return new Set<String>{'Business Manager', 'System Administrator'}.contains( currentUser.Profile.Name );
  }

  public Boolean getCanCreateInvoice()
  {
    return new Set<String>{'System Administrator'}.contains( currentUser.Profile.Name ) ||
      ( getIsBOM_or_ADMIN() && current_opportunity.Invoice_Document_Id__c != null );
  }

  public Boolean getHasCommission()
  {
    Set<String> allowedProfiles = new Set<String>{'System Administrator', 'Sales and Operations Manager'};
    return current_opportunity.BoatId__c != null && allowedProfiles.contains(currentUser.Profile.Name) && current_opportunity.Probability > 0;
  }

  public String getExcludedIds(){
    return JSON.serialize(previousOppContactIds);
  }

  //public String getTestString(){
  //  return testString == null ? 'This is Pre actionFunction' : testString;
  //}

  //public void testFunc(){
  //  System.debug('****************************** ' + ApexPages.currentPage().getParameters().get('testParam') );
  //  testString = ApexPages.currentPage().getParameters().get('testParam');
  //}

  public String getProbabilityJSON() {
    if( probabilityStageNameMap == null ){
      probabilityStageNameMap = new Map<String, Decimal>();
      for (OpportunityStage oppStage : [Select MasterLabel, DefaultProbability
                                        From OpportunityStage]) {
        probabilityStageNameMap.put(oppStage.MasterLabel, oppStage.DefaultProbability);
      }
    }
    return JSON.serialize(probabilityStageNameMap);
  }

  public String getPageSubTitle() {
    return isNewRecord == true ? 'Create an Opportunity' : 'Edit Opportunity';
  }

  public PageReference httpUpdateStage(){
    updateTheStage(current_opportunity, httpStage);
    return new PageReference('/'+current_opportunity.Id );
  }

  public PageReference saveAndBuildBoat() {
    Opportunity opp = (Opportunity)std.getRecord();
    insert opp;
    // PageReference pageRef = Page.BoatBuilder;
    PageReference pageRef = Page.BoatConfigurator;
    pageRef.setRedirect(true);
    pageRef.getParameters().put('opportunity_id', opp.id);
    return pageRef;
  }

  //public PageReference finalSave() {
  //  try {
  //    update current_opportunity;
  //    update current_opportunity.Account;
  //  }
  //  catch (Exception e){
  //    System.debug('+++++++++++++++++++++++ ' + e.getMessage() );
  //    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, e.getMessage() );
  //    ApexPages.addmessage(myMsg);
  //    return null;
  //  }

  //  return new PageReference('/' + current_opportunity.Id);
  //}

  public PageReference finalSave(){
    return dofinalSave(false);
  }

  public PageReference finalSaveAndSubmit(){
    return dofinalSave(true);
  }

  //public PageReference buildInvoiceAndSubmit()
  //{
  //  try
  //  {
  //    Document invoicePDF = OpportunityDocumentBuilder.buildInvoicePDF(current_opportunity);
  //    current_opportunity.Invoice_Document_Id__c = invoicePDF.Id;
  //    update current_opportunity;
  //    Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
  //    req1.setComments('Submitting request for approval.');
  //    req1.setObjectId(current_opportunity.id);
  //    req1.setSubmitterId( UserInfo.getUserId() );
  //    req1.setProcessDefinitionNameOrId('Retail_Sales_Approval');
  //    Approval.process(req1);
  //  }
  //  catch (Exception e)
  //  {
  //    System.debug('+++++++++++++++++++++++ ' + e.getMessage() );
  //    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, e.getMessage() );
  //    ApexPages.addmessage(myMsg);
  //    return null;
  //  }
  //  return new PageReference('/' + current_opportunity.Id);
  //}

  private PageReference dofinalSave(Boolean submitForApproval) {
    try {
      update current_opportunity;
      update current_opportunity.Account;
      if( !current_opportunity.Account.IsPersonAccount )
      {
        if( buyer != null )
        {
          update buyer;
        }
        if( coBuyer != null )
        {
          update coBuyer;
        }
      }

      //Create and submit for approval
      if(submitForApproval == true)
      {
        //createInvoice(current_opportunity);
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(current_opportunity.id);
        req1.setSubmitterId( UserInfo.getUserId() );
        req1.setProcessDefinitionNameOrId('Retail_Sales_Approval');
        Approval.process(req1);
      }
    }
    catch (Exception e){
      System.debug('+++++++++++++++++++++++ ' + e.getMessage() );
      ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, e.getMessage() );
      ApexPages.addmessage(myMsg);
      return null;
    }

    return new PageReference('/' + current_opportunity.Id);
  }

  public void selectContact() {
    String contactId = ApexPages.currentPage().getParameters().get('contactId');
    String query = 'SELECT ' + contactFields() + ' FROM Contact WHERE Id = \'' + contactId + '\'';
    cont = Database.query(query);
  }

  public PageReference saveCoBuyer() {
      try{
          upsert cont;
          OpportunityContactRole ocr = new OpportunityContactRole(
              OpportunityId = current_opportunity.Id,
              ContactId = cont.Id,
              Role = 'Co-Buyer',
              isPrimary = false
          );
          try{
              insert ocr;
              //return new PageReference('/' + current_opportunity.Id);
              FeedItem fItem = new FeedItem();
              fitem.parentId = current_opportunity.Id;
              fitem.body = 'Added ' + cont.FirstName + ' ' + cont.LastName + ' as a Co-Buyer';
              insert fitem;
              cont = new Contact();
              return null;
          }
          catch(Exception e){
              ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Something Is Wrong - ' + e.getMessage() );
              ApexPages.addmessage(myMsg);
              return null;
          }
      }
      catch( Exception e){
          ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Something Is Wrong - ' + e.getMessage() );
          ApexPages.addmessage(myMsg);
          return null;
      }

  }

  // public PageReference changeStageName() {
  //   this.current_opportunity.Probability = findProbability(this.current_opportunity.StageName);
  //   return null;
  // }

  public PageReference depositMethodChanged() {
    renderOtherDepositMethod = this.current_opportunity.Deposit_Method__c == 'Other'
      ? true
      : false;
    return null;
  }

  private void updateTheStage(Opportunity opp, String newStage){
    if( opp.StageName == newStage ){
      String previousStage = stageRollbackMap.get(newStage);
      opp.StageName = previousStage;
      opp.Probability = findProbability(previousStage);
      update opp;
    } else {
      Set<String> stages = new Set<String>();
      Schema.DescribeFieldResult opportunityStageName = Opportunity.StageName.getDescribe();
      for( Schema.PickListEntry ple : opportunityStageName.getPicklistValues() ){
        stages.add( ple.getLabel() );
      }
      if( stages.contains(newStage) ){
        opp.StageName = newStage;
        opp.Probability = findProbability(newStage);
        update opp;
      }
    }
  }

  private Decimal findProbability(String stage){
    if( probabilityStageNameMap == null ){
      probabilityStageNameMap = new Map<String, Decimal>();
      for (OpportunityStage oppStage : [Select MasterLabel, DefaultProbability
                                        From OpportunityStage]) {
        probabilityStageNameMap.put(oppStage.MasterLabel, oppStage.DefaultProbability);
      }
    }
    if (probabilityStageNameMap.containsKey(stage)) {
      return probabilityStageNameMap.get(stage);
    }
    return null;
  }

  private String contactFields() {
    String qString = '';
    Set<String> fieldNames = new Set<String>{'Name', 'Salutation', 'FirstName'};
    Map<String, Schema.FieldSet> FsMap = Schema.SObjectType.Contact.FieldSets.getMap();
    for(String fsn : FsMap.keySet() ){
      for(Schema.FieldSetMember f : FsMap.get(fsn).getFields()){
        fieldNames.add(f.getFieldPath());
      }
    }
    for( String f : fieldNames ){
      qString += f + ', ';
    }
    return qString.removeEnd(', ');
  }

  private String fieldsToString(String[] fields){
    String qString = '';
    for( String f : fields ){
      qString += f + ', ';
    }
    return qString.removeEnd(', ');
  }

  //private void createInvoice(Opportunity opp)
  //{
  //  String docName = opp.Name + '.pdf';
  //  Document inv = OpportunityDocumentBuilder.buildInvoicePDF(opp);
  //  opp.Invoice_Document_Id__c = inv.Id;
  //  update opp;
  //}






}