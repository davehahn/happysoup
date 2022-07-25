@isTest
private class OpportunityExt_OppDoc_Test {
  static Id rTId;
  static AcctSeedERP__Warehouse__c warehouse;

  //get the Id of the Person Account Record Type
  static {
    Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.Account;
    Map<String, Schema.RecordTypeInfo> AccountRecordTypeInfo = cfrSchema.getRecordTypeInfosByName();
    rTId = AccountRecordTypeInfo.get('Person Account').getRecordTypeId();
    warehouse = AcctSeed_Settings_Factory.getWarehouse(null);
  }

  @isTest
  static void test1() {
    Account a = new Account(FirstName = 'Test', LastName = 'User', RecordTypeId = rTId);
    insert a;
    Opportunity opp = new Opportunity(
      CloseDate = Date.today(),
      StageName = 'Prospecting',
      AccountId = a.Id,
      Warehouse__c = warehouse.Id,
      Name = 'Test opp'
    );
    insert opp;
    ApexPages.StandardController sc = new ApexPages.StandardController(opp);
    OpportunityExt_OppDoc oe_od = new OpportunityExt_OppDoc(sc);

    System.assertEquals(0, oe_od.oppDocs.size());

    Document document = new Document();
    document.AuthorId = UserInfo.getUserId();
    document.FolderId = UserInfo.getUserId();
    document.Name = 'testdoc.jpg';
    insert document;
    Opportunity_Document__c doc = new Opportunity_Document__c(
      Document_Id__c = document.Id,
      Document_Type__c = 'Quote',
      Opportunity__c = opp.Id
    );
    insert doc;
    oe_od = new OpportunityExt_OppDoc(sc);
    System.assertEquals(1, oe_od.oppDocs.size());
    System.assert(oe_od.getRenderList());

    OpportunityExt_OppDoc.deleteDoc(doc.Id);
    oe_od = new OpportunityExt_OppDoc(sc);
    System.assertEquals(0, oe_od.oppDocs.size());
  }
}
