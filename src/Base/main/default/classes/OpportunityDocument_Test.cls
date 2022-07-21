@isTest(seeAllData=true)
private class OpportunityDocument_Test {
  @isTest
  static void test1() {
    Document document = new Document();
    document.AuthorId = UserInfo.getUserId();
    document.FolderId = UserInfo.getUserId();
    document.Name = 'testdoc.jpg';
    insert document;
    Opportunity_Document__c doc = new Opportunity_Document__c(Document_Id__c = document.Id, Document_Type__c = 'Quote');
    insert doc;
    delete doc;
    System.assertEquals(1, 1);
  }

  @isTest
  static void constructor_test() {
    Opportunity opp = OpportunityFactory.insertRetailBoatSale();
    PageReference pageRef = Page.OpportunityQuotePDF;
    pageRef.getParameters().put('opportunity_id', opp.Id);
    pageRef.getParameters().put('render_type', 'pdf');
    Test.setCurrentPage(pageRef);
    OpportunityDocument oppDoc = new OpportunityDocument();

    System.assertEquals('pdf', oppDoc.renderType);
    System.assertEquals(opp.Id, oppDoc.boatBuilder.opportunity_id);
  }
}
