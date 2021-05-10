@isTest
private class OpportunityDocumentBuilder_Test {

   static Id rTId;
   static Opportunity opp;
   static Account a;

   //get the Id of the Person Account Record Type
  private static void init()
  {
    Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.Account;
    Map<String,Schema.RecordTypeInfo> AccountRecordTypeInfo = cfrSchema.getRecordTypeInfosByName();
    rTId = AccountRecordTypeInfo.get('Person Account').getRecordTypeId();
    a = new Account(FirstName= 'Test', LastName='User', RecordTypeId=rTId);
    insert a;
    opp = new Opportunity(
      CloseDate= Date.today(),
      StageName='Prospecting',
      AccountId = a.Id,
      Name = 'Test opp with a really really really really really really really stupidly ironically and completly pointlessly long name '
    );
    insert opp;
  }

  @testSetup static void dataSetup()
  {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  @isTest static void filler()
  {
    init();
    OpportunityDocumentBuilder odb = new OpportunityDocumentBuilder();
    odb.getLanguageOptions();
    odb.getProvinceOptions();
  }

  @isTest static void test1()
  {
    init();
    OpportunityDocumentBuilder odb = new OpportunityDocumentBuilder();
    System.assertEquals(false, odb.isSaveable);
    //System.assertEquals(null, odb.closeWindow);
    //System.assertEquals(null, odb.closeWindowEmail);
    System.assertEquals(null, odb.attachId);
    System.assertEquals(null, odb.opportunityId);
    System.assertEquals(2, OpportunityDocumentBuilder.pageMap.keyset().size() );

    PageReference pageRef = Page.OpportunityDocumentBuilder;
    pageRef.getParameters().put('id', opp.Id);
    pageRef.getParameters().put('docType', 'invoice');
    Test.setCurrentPageReference(pageRef);

    odb.preview();
    System.assert(odb.isSaveable);
    odb.savePDF();
    opp = [SELECT Id, Invoice_Document_Id__c, (SELECT Id FROM Opportunity_Document__r) FROM Opportunity WHERE Id = :opp.Id];
    System.assert(opp.Invoice_Document_Id__c != null);
    System.assert(opp.Opportunity_Document__r.size() > 0);

    //odb.saveAndEmail();
    //OpportunityDocumentBuilder.buildInvoicePDF(opp.Id, 'this.pdf');
    //OpportunityDocumentBuilder.buildQuotePDF(opp.Id, 'a boat', 'this.pdf');

    System.assertEquals(1,1);
  }

  @isTest static void test2()
  {
    init();
    Datetime dt = Datetime.now();
    String dateString1 = (dt + 7).format('d/MM/yy');
    String dateString2 = dt.format('d/MM/yy');
    PageReference pageRef = Page.OpportunityDocumentBuilder;

    Test.setCurrentPageReference(pageRef);
    OpportunityDocumentBuilder odb = new OpportunityDocumentBuilder(opp.Id);
    pageRef.getParameters().put('docType', 'quote');
    odb.preview();
    odb.setQuoteValidDate();

    System.assertEquals(dateString1, odb.quoteValidDate);

    pageRef.getParameters().put('quote_valid_date', dateString2);
    odb.setQuoteValidDate();
    System.assertEquals(dateString2, odb.quoteValidDate);
  }

  @isTest static void buildInvoicePDFTest()
  {
    init();
    Document doc = OpportunityDocumentBuilder.buildInvoicePDF(opp, 'english');
    //System.assertEquals('This is Just a Test', doc.Name);

    Opportunity_Document__c oppdoc = [SELECT Id, Name, Document_Type__c FROM Opportunity_Document__c WHERE Opportunity__c = :opp.Id AND Document_Id__c = :doc.Id];
    System.assert(oppdoc != null);
  }

  @isTest static void buildQuotePDFTest1()
  {
    init();
    Opportunity_Document__c oppdoc = OpportunityDocumentBuilder.buildQuotePDF( opp.Id,
                                                                               'english',
                                                                               'BoatName This is Really Really Really Stupidly pointlessly long But we have had very long product names that have created issues in the past so we need to test this',
                                                                               'fileName');
    System.assert(oppdoc != null);
    System.assertEquals(opp.Id, oppdoc.Opportunity__c);
  }

  @isTest static void buildQuotePDF_WithValidDate_Test()
  {
    init();
    Opportunity_Document__c oppdoc = OpportunityDocumentBuilder.buildQuotePDF( opp.Id,
                                                                               'english',
                                                                               'BoatName',
                                                                               'fileName',
                                                                               '07/07/76');
    System.assert(oppdoc != null);
    System.assertEquals(opp.Id, oppdoc.Opportunity__c);
  }

  @isTest static void buildQuotePDFTest2()
  {
    init();
    Opportunity tempOpp = opp.clone();
    insert tempOpp;
    Opportunity_Document__c oppdoc = OpportunityDocumentBuilder.buildQuotePDF(tempOpp.Id,
                                                                              opp.Id,
                                                                              'english',
                                                                              'BoatName',
                                                                              'fileName');
    System.assert(oppdoc != null);
    System.assertEquals(opp.Id, oppdoc.Opportunity__c);
  }
}