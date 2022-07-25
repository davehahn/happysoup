@IsTest(SeeAllData=false)
public with sharing class DealerOrder_Service_T {
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
  static void afterInsert_Test() {
    TA_DealerOrder_TestHelper.init();
    Dealer_Order__c order = TA_DealerOrder_TestHelper.insertDealerOrder(true, 'Draft');
    Test.startTest();
    new TA_DealerOrder_CreatePartnerOrder().afterInsert(new List<Dealer_Order__c>{ order });
    System.assert(TA_DealerOrder_TestHelper.getPartnerBookingOrder().size() > 0);
    Test.stopTest();
  }

  @IsTest
  static void BeforeDelete_Test() {
    TA_DealerOrder_TestHelper.init();
    Dealer_Order__c order = TA_DealerOrder_TestHelper.insertDealerOrder(true, 'Pending Review');
    Test.startTest();
    try {
      //delete order;
      new TA_DealerOrder_DeleteERPs().beforeDelete(new List<Dealer_Order__c>{ order });
    } catch (Exception e) {
      System.assert(e.getMessage().contains('You can not delete a Dealer Order with stage "Pending Review"'));
    }
    Test.stopTest();
  }

  @IsTest
  static void BeforeDeleteDraftStage_Test() {
    TA_DealerOrder_TestHelper.init();
    TA_DealerOrder_TestHelper.buildBoat('Pontoon', 50000, null);

    Dealer_Order__c order = TA_DealerOrder_TestHelper.insertDealerOrder(true, 'Draft');
    TA_DealerOrder_TestHelper.createDealerOrderLines(order, 3);
    Test.startTest();
    new TA_DealerOrder_DeleteERPs().beforeDelete(new List<Dealer_Order__c>{ order });
    delete order;
    Test.stopTest();
    List<AcctSeed__Project__c> erps = [
      SELECT Id, OwnerId
      FROM AcctSeed__Project__c
      WHERE Id = :TA_DealerOrder_TestHelper.erps[0].Id
    ];
    System.assert(erps.isEmpty());
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

  @IsTest
  static void afterUpdate_PendingFinancing_Test() {
    TA_DealerOrder_TestHelper.init();
    TA_DealerOrder_TestHelper.buildBoat('Pontoon', 50000, null);

    Dealer_Order__c order = TA_DealerOrder_TestHelper.insertDealerOrder(true, 'Draft');
    TA_DealerOrder_TestHelper.createDealerOrderLines(order, 1);
    Dealer_Order__c orderOld = new Dealer_Order__c();
    orderOld = TA_DealerOrder_TestHelper.getOldList()[0];
    List<Dealer_Order__c> oldlist = new List<Dealer_Order__c>{ orderOld };
    Test.startTest();
    order.Stage__c = 'Pending Financing';
    update order;
    new TA_DealerOrder_SetERPStage().afterUpdate(new List<Dealer_Order__c>{ order }, oldlist);
    Test.stopTest();
    AcctSeed__Project__c erp = [
      SELECT Id, Stage__c
      FROM AcctSeed__Project__c
      WHERE Id = :TA_DealerOrder_TestHelper.erps[0].Id
    ];
    System.assertEquals('Pending Financing', erp.Stage__c);
  }

  @IsTest
  static void afterUpdate_Approved_Test() {
    TA_DealerOrder_TestHelper.init();
    TA_DealerOrder_TestHelper.buildBoat('Pontoon', 50000, null);

    Dealer_Order__c order = TA_DealerOrder_TestHelper.insertDealerOrder(true, 'Draft');
    TA_DealerOrder_TestHelper.createDealerOrderLines(order, 1);
    Dealer_Order__c orderOld = new Dealer_Order__c();
    orderOld = TA_DealerOrder_TestHelper.getOldList()[0];
    List<Dealer_Order__c> oldlist = new List<Dealer_Order__c>{ orderOld };
    Test.startTest();
    order.Stage__c = 'Approved';
    update order;
    new TA_DealerOrder_SetERPStage().afterUpdate(new List<Dealer_Order__c>{ order }, oldlist);
    Test.stopTest();
    AcctSeed__Project__c erp = [
      SELECT Id, Stage__c
      FROM AcctSeed__Project__c
      WHERE Id = :TA_DealerOrder_TestHelper.erps[0].Id
    ];
    System.assertEquals('Tagging Pending', erp.Stage__c);
  }

  @IsTest
  static void afterUpdate_PendingReview_Test() {
    TA_DealerOrder_TestHelper.init();
    TA_DealerOrder_TestHelper.buildBoat('Pontoon', 50000, null);

    Dealer_Order__c order = TA_DealerOrder_TestHelper.insertDealerOrder(true, 'Draft');
    TA_DealerOrder_TestHelper.createDealerOrderLines(order, 1);
    Dealer_Order__c orderOld = new Dealer_Order__c();
    orderOld = TA_DealerOrder_TestHelper.getOldList()[0];
    List<Dealer_Order__c> oldlist = new List<Dealer_Order__c>{ orderOld };
    Test.startTest();
    order.Stage__c = 'Pending Review';
    update order;
    new TA_DealerOrder_SetERPStage().afterUpdate(new List<Dealer_Order__c>{ order }, oldlist);
    Test.stopTest();
    AcctSeed__Project__c erp = [
      SELECT Id, Stage__c
      FROM AcctSeed__Project__c
      WHERE Id = :TA_DealerOrder_TestHelper.erps[0].Id
    ];
    System.assertEquals('Pending Review', erp.Stage__c);
  }

  @IsTest
  static void beforeUpdate_Test() {
    TA_DealerOrder_TestHelper.init();
    Dealer_Order__c order = TA_DealerOrder_TestHelper.insertDealerOrder(true, 'Draft');

    System.assert(TA_DealerOrder_TestHelper.getDealerOrder()[0].Date_Submitted__c == null);
    Test.startTest();
    List<Dealer_Order__c> oldList = TA_DealerOrder_TestHelper.getOldList();
    oldList[0].Stage__c = 'Pending Review';
    new TA_DealerOrder_SetStageWiseSubmittedDate().beforeUpdate(TA_DealerOrder_TestHelper.getNewList(), oldList);
    System.debug('@@= ' + TA_DealerOrder_TestHelper.getDealerOrder()[0].Date_Submitted__c);
    System.assert(TA_DealerOrder_TestHelper.getDealerOrder()[0].Date_Submitted__c == null);
    Test.stopTest();
  }

  @IsTest
  static void beforeInsert_Test() {
    TA_DealerOrder_TestHelper.init();
    Dealer_Order__c order = TA_DealerOrder_TestHelper.buildDealerOrder(true, 'Pending Review');
    DateTime tNow = DateTime.now();
    Test.startTest();
    new TA_DealerOrder_SetSubmittedDate().beforeInsert(new List<Dealer_Order__c>{ order });
    insert order;
    Test.stopTest();

    order = [SELECT Id, Date_Submitted__c FROM Dealer_Order__c WHERE Id = :order.Id];
    System.assertEquals(tNow.year(), order.Date_Submitted__c.year());
    System.assertEquals(tNow.month(), order.Date_Submitted__c.month());
    System.assertEquals(tNow.day(), order.Date_Submitted__c.day());
  }

  @IsTest
  static void afterUpdate_MotorRequest_SendEmail_Test() {
    TA_DealerOrder_TestHelper.init();
    TA_DealerOrder_TestHelper.buildMotor(2000);
    Dealer_Order__c order = TA_DealerOrder_TestHelper.insertDealerOrder(true, 'Draft');
    Dealer_Order__c orderOld = new Dealer_Order__c();
    orderOld = TA_DealerOrder_TestHelper.getOldList()[0];
    List<Dealer_Order__c> oldlist = new List<Dealer_Order__c>{ orderOld };
    Dealer_Motor_Request__c dmr = new Dealer_Motor_Request__c(
      Motor__c = TA_DealerOrder_TestHelper.motor.Id,
      Notes__c = 'Test DMR',
      Quantity__c = 1
    );
    insert dmr;
    Factory_DealerOrder.createDealerOrderLines(
      new List<Dealer_Motor_Request__c>{ dmr },
      order,
      TA_DealerOrder_TestHelper.motor
    );
    Test.startTest();
    order.Stage__c = 'Pending Financing';
    update order;
    new TA_DealerOrder_SetERPStage().afterUpdate(new List<Dealer_Order__c>{ order }, oldlist);

    Test.stopTest();

    order = [SELECT Id, Merc_Order_Sent__c FROM Dealer_Order__c WHERE Id = :order.Id];
    System.assert(order.Merc_Order_Sent__c);
  }

  @IsTest
  static void beforeUpdate_Test_DatewiseChange() {
    TA_DealerOrder_TestHelper.init();

    Dealer_Order__c order = TA_DealerOrder_TestHelper.insertDealerOrder(true, 'Draft');
    Dealer_Order__c orderOld = new Dealer_Order__c();
    orderOld = TA_DealerOrder_TestHelper.getOldList()[0];
    List<Dealer_Order__c> oldlist = new List<Dealer_Order__c>{ orderOld };

    //order = [SELECT Id, Date_Submitted__c FROM Dealer_Order__c WHERE Id = :order.Id];
    // System.assert(order.Date_Submitted__c == null);
    Test.startTest();
    order.Stage__c = 'Pending Review';
    new TA_DealerOrder_SetStageWiseSubmittedDate().beforeUpdate(new List<Dealer_Order__c>{ order }, oldlist);
    update order;
    order = [SELECT Id, Date_Submitted__c FROM Dealer_Order__c WHERE Id = :order.Id];
    System.assert(order.Date_Submitted__c != null);
    order.Stage__c = 'Draft';
    new TA_DealerOrder_SetStageWiseSubmittedDate().beforeUpdate(new List<Dealer_Order__c>{ order }, oldlist);
    update order;
    order = [SELECT Id, Date_Submitted__c FROM Dealer_Order__c WHERE Id = :order.Id];
    System.assert(order.Date_Submitted__c == null);
    Test.stopTest();
  }
}
