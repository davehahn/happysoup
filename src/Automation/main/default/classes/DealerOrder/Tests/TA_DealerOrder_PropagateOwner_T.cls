@IsTest(SeeAllData=false)
public class TA_DealerOrder_PropagateOwner_T {
  static Dealer_Order__c order;
  static String partnerAccountName = 'TestPartner';
  static Account partner;
  static List<AcctSeed__Project__c> erps;
  static Set<Id> erpIds;
  static User partnerUser;

  @testSetup
  static void dataSetup() {
    TA_DealerOrder_TestHelper.dataSetup();
  }
  @IsTest
  static void afterUpdate_OwnerPropagation_Test() {
    TA_DealerOrder_TestHelper.init();
    TA_DealerOrder_TestHelper.buildBoat('Pontoon', 50000, null);
    order = TA_DealerOrder_TestHelper.insertDealerOrder(true, 'Pending Review');

    Dealer_Order__c orderOld = new Dealer_Order__c();
    orderOld = TA_DealerOrder_TestHelper.getOldList()[0];
    orderOld.OwnerId = null;
    List<Dealer_Order__c> oldlist = new List<Dealer_Order__c>{ orderOld };
    TA_DealerOrder_TestHelper.createDealerOrderLines(orderOld, 1);
    Test.startTest();
    partnerUser = TA_DealerOrder_TestHelper.fetchPartnerUser();
    order.OwnerId = partnerUser.id;
    update order;
    new TA_DealerOrder_PropagateOwner().afterUpdate(new List<Dealer_Order__c>{ order }, oldlist);
    Test.stopTest();
    order = [SELECT Id, OwnerId FROM Dealer_Order__c WHERE Id = :order.Id];
    AcctSeed__Project__c erp = [
      SELECT Id, OwnerId
      FROM AcctSeed__Project__c
      WHERE Id = :TA_DealerOrder_TestHelper.erps[0].Id
    ];
    System.assertEquals(partnerUser.Id, order.OwnerId);
    System.assertEquals(partnerUser.Id, erp.OwnerId);
  }
}
