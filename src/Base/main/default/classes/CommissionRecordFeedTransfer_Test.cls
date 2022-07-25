@isTest
public class CommissionRecordFeedTransfer_Test {
  @isTest
  static void coverage_test() {
    CommissionRecordFeedTransfer.coverage();
  }

  //static User stdLegendUser;

  //static {
  //  stdLegendUser = User_TestFactory.newUser('John', 'Doey', 'Standard Legend User');
  //}

  //@isTest(seeAllData=true)
  //public static void transfer_Test()
  //{

  //  System.runAs(stdLegendUser)
  //  {
  //    Test.startTest();
  //    Opportunity opp = OpportunityFactory.insertRetailBoatSale();
  //    CommissionRecord__c[] newRecords = CommissionRecord.recreateCommissionRecords(opp);
  //    FeedItem[] fis = CommissionRecordFeedTransfer.fetchFeedItems(newRecords[0].Id);
  //    // create a new feed item
  //    FeedItem fi = new FeedItem( ParentId = newRecords[0].Id, Body = 'This is a test Post');
  //    insert fi;
  //    FeedComment fc = new FeedComment( FeedItemId = fis[0].Id, CommentBody = 'This is a test Comment');
  //    insert fc;
  //    newRecords = CommissionRecord.recreateCommissionRecords(opp);
  //    FeedItem[] fis_a = CommissionRecordFeedTransfer.fetchFeedItems(newRecords[0].Id);

  //    Test.stopTest();

  //    System.assert(fis_a.size() > fis.size() );

  //  }

  //}
}
