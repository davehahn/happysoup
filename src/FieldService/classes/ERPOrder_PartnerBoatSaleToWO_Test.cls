/**
 * Created by dave on 2019-08-29.
 */

@IsTest
private class ERPOrder_PartnerBoatSaleToWO_Test {
  static Id pbId;
  static Account acct;
  static AcctSeed__Project__c erp;
  static List<AcctSeed__Project__c> erps;
  static GMBLASERP__Serial_Number__c[] serials;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
  }

  private static void init() {
    pbId = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
    acct = Factory_Account.insertDealerAccounts(1)[0];
    serials = Factory_SerialNumber.insertFullSerials(4, 'Boat', 'Pontoon');
    erps = Factory_ERPOrder.createPartnerBoatSales(acct, serials);
    erp = erps[0];
  }

  private static void addFeeAndLabourMaterials() {
    Product2 fee = Factory_Product.createNonSerializedProduct('Fees', 'Freight');
    Product2 labour = Factory_Product.createNonSerializedProduct('Part', 'Labour');
    Map<Id, AcctSeed__Project__c> erpMap = new Map<Id, AcctSeed__Project__c>(erps);
    Map<Id, List<AcctSeed__Project_Task__c>> tasksByErpId = new Map<Id, List<AcctSeed__Project_Task__c>>();
    List<AcctSeedERP__Material__c> mats = new List<AcctSeedERP__Material__c>();
    List<AcctSeed__Project_Task__c> tasks = [
      SELECT Id, AcctSeed__Project__c
      FROM AcctSeed__Project_Task__c
      WHERE AcctSeed__Project__c IN :erpMap.keySet()
    ];
    for (AcctSeed__Project_Task__c task : tasks) {
      if (!tasksByErpId.containsKey(task.AcctSeed__Project__c)) {
        tasksByErpId.put(task.AcctSeed__Project__c, new List<AcctSeed__Project_Task__c>());
      }
      tasksByErpId.get(task.AcctSeed__Project__c).add(task);
    }
    for (Id erpId : erpMap.keySet()) {
      Id taskId = tasksByErpId.get(erpId)[0].Id;
      mats.add(Factory_Material.buildMaterial(erpId, taskId, fee.Id));
      mats.add(Factory_Material.buildMaterial(erpId, taskId, labour.Id));
    }
    insert mats;
  }

  @IsTest
  static void createWorkOrders_Promise_Test() {
    init();
    Test.startTest();
    Set<Id> erpIds = new Set<Id>{ erp.Id };
    new ERPOrder_PartnerBoatSaleToWO_Promise.createWorkOrders_Promise().resolve((Object) erpIds);
    Test.stopTest();
    List<WorkOrder> workOrders = [SELECT Id, Location.Warehouse__c FROM WorkOrder WHERE ERP_Order__c IN :erpIds];
    erp = [SELECT Id, Work_Order__c, GMBLASERP__Warehouse__c FROM AcctSeed__Project__c WHERE Id = :erp.Id];
    System.assertEquals(1, workOrders.size());
    System.assertEquals(workOrders[0].Location.Warehouse__c, erp.GMBLASERP__Warehouse__c);
    System.assertEquals(erp.Work_Order__c, workOrders[0].Id);
  }

  @IsTest
  static void createWorkOrders_Promise_Multiple_Test() {
    init();
    Test.startTest();
    Set<Id> erpIds = LGND_Utilities.getIdSetFromList((List<sObject>) erps);
    new ERPOrder_PartnerBoatSaleToWO_Promise.createWorkOrders_Promise().resolve((Object) erpIds);
    Test.stopTest();
    List<WorkOrder> workOrders = [SELECT Id, Location.Warehouse__c FROM WorkOrder WHERE ERP_Order__c IN :erpIds];
    erp = [SELECT Id, Work_Order__c, GMBLASERP__Warehouse__c FROM AcctSeed__Project__c WHERE Id = :erp.Id];
    System.assertEquals(erps.size(), workOrders.size());
  }

  @IsTest
  static void createWorkOrderLineItems_Promise_Test() {
    init();
    Set<Id> erpIds = new Set<Id>{ erp.Id };
    List<WorkOrder> workOrders = ERPOrder_PartnerBoatSaleToWO_Promise.doStepOne(erpIds);
    Test.startTest();
    new ERPOrder_PartnerBoatSaleToWO_Promise.createWorkOrderLineItems_Promise().resolve(workOrders);
    Test.stopTest();
    List<AcctSeed__Project_Task__c> tasks = [
      SELECT Id, DisplayOnCustomerInvoice__c, Work_Order_Line_Item__c
      FROM AcctSeed__Project_Task__c
      WHERE AcctSeed__Project__c = :erp.Id
    ];
    List<WorkOrderLineItem> wolis = [
      SELECT Id, ERP_Order_Task__c, Visible_to_Customer__c
      FROM WorkOrderLineItem
      WHERE WorkOrderId = :workOrders[0].Id
    ];
    System.assertEquals(tasks.size(), wolis.size());
    System.assertEquals(tasks[0].Work_Order_Line_Item__c, wolis[0].Id);
    System.assertEquals(tasks[0].Id, wolis[0].ERP_Order_Task__c);
    System.assertEquals(tasks[0].DisplayOnCustomerInvoice__c, wolis[0].Visible_to_Customer__c);
  }

  @IsTest
  static void createWorkOrderLineItems_Promise_Multiple_Test() {
    init();
    Set<Id> erpIds = LGND_Utilities.getIdSetFromList((List<sObject>) erps);
    List<WorkOrder> workOrders = ERPOrder_PartnerBoatSaleToWO_Promise.doStepOne(erpIds);
    Set<Id> woIds = LGND_Utilities.getIdSetFromList((List<SObject>) workOrders);
    Test.startTest();
    new ERPOrder_PartnerBoatSaleToWO_Promise.createWorkOrderLineItems_Promise().resolve(workOrders);
    Test.stopTest();
    List<AcctSeed__Project_Task__c> tasks = [
      SELECT Id, DisplayOnCustomerInvoice__c, Work_Order_Line_Item__c
      FROM AcctSeed__Project_Task__c
      WHERE AcctSeed__Project__c IN :erpIds
    ];
    List<WorkOrderLineItem> wolis = [
      SELECT Id, ERP_Order_Task__c, Visible_to_Customer__c
      FROM WorkOrderLineItem
      WHERE WorkOrderId = :woIds
    ];
    System.assertEquals(tasks.size(), wolis.size());
    System.assertEquals(erps.size(), wolis.size());
    System.assertEquals(erps.size(), tasks.size());
  }

  @IsTest
  static void createProductRequireds_Promise_Test() {
    init();
    Set<Id> erpIds = new Set<Id>{ erp.Id };
    List<WorkOrder> workOrders = ERPOrder_PartnerBoatSaleToWO_Promise.doStepOne(erpIds);
    List<WorkOrderLineItem> workOrderLineItems = ERPOrder_PartnerBoatSaleToWO_Promise.doStepTwo(workOrders);
    Test.startTest();
    new ERPOrder_PartnerBoatSaleToWO_Promise.createProductRequireds_Promise().resolve(workOrderLineItems);
    Test.stopTest();
    List<AcctSeedERP__Material__c> materials = [
      SELECT Id, AcctSeedERP__Product__c
      FROM AcctSeedERP__Material__c
      WHERE AcctSeedERP__Project_Task__c = :workOrderLineItems[0].ERP_Order_Task__c
    ];
    List<ProductRequired> productRequireds = [
      SELECT Id, Product2Id, Material__c
      FROM ProductRequired
      WHERE ParentRecordId = :workOrderLineItems[0].Id
    ];
    System.assertEquals(materials.size(), productRequireds.size());
    System.assertEquals(materials[0].Id, productRequireds[0].Material__c);
    System.assertEquals(materials[0].AcctSeedERP__Product__c, productRequireds[0].Product2Id);
  }

  @IsTest
  static void createProductRequireds_Promise_Multiple_Test() {
    init();
    Set<Id> erpIds = LGND_Utilities.getIdSetFromList((List<sObject>) erps);
    List<WorkOrder> workOrders = ERPOrder_PartnerBoatSaleToWO_Promise.doStepOne(erpIds);
    List<WorkOrderLineItem> workOrderLineItems = ERPOrder_PartnerBoatSaleToWO_Promise.doStepTwo(workOrders);
    Set<Id> woliIds = LGND_Utilities.getIdSetFromList((List<sObject>) workOrderLineItems);
    Test.startTest();
    new ERPOrder_PartnerBoatSaleToWO_Promise.createProductRequireds_Promise().resolve(workOrderLineItems);
    Test.stopTest();
    List<AcctSeedERP__Material__c> materials = [
      SELECT Id, AcctSeedERP__Product__c
      FROM AcctSeedERP__Material__c
      WHERE AcctSeedERP__Project__c IN :erpIds
    ];
    List<ProductRequired> productRequireds = [
      SELECT Id, Product2Id, Material__c
      FROM ProductRequired
      WHERE ParentRecordId = :woliIds
    ];
    System.assertEquals(materials.size(), productRequireds.size());
  }

  @IsTest
  static void createProductRequireds_Promise_Multiple_WithOneFee_AndOneLabourProduct_Test() {
    init();
    addFeeAndLabourMaterials();
    Set<Id> erpIds = LGND_Utilities.getIdSetFromList((List<sObject>) erps);
    List<WorkOrder> workOrders = ERPOrder_PartnerBoatSaleToWO_Promise.doStepOne(erpIds);
    List<WorkOrderLineItem> workOrderLineItems = ERPOrder_PartnerBoatSaleToWO_Promise.doStepTwo(workOrders);
    Set<Id> woliIds = LGND_Utilities.getIdSetFromList((List<sObject>) workOrderLineItems);
    Test.startTest();
    new ERPOrder_PartnerBoatSaleToWO_Promise.createProductRequireds_Promise().resolve(workOrderLineItems);
    Test.stopTest();
    List<AcctSeedERP__Material__c> materials = [
      SELECT Id, AcctSeedERP__Product__c
      FROM AcctSeedERP__Material__c
      WHERE AcctSeedERP__Project__c IN :erpIds
    ];
    List<ProductRequired> productRequireds = [
      SELECT Id, Product2Id, Material__c
      FROM ProductRequired
      WHERE ParentRecordId = :woliIds
    ];

    /* we do not create Product Requireds for Products of record Type Fee
       OR Products of family = Labour and we added 1 of each to the ERPs
       in method addFeeAndLabourMaterials()
       SO the expect number of ProductRequireds would be
       materials - ( erp.size() * 2 )
     */

    Integer expected = materials.size() - (2 * erps.size());

    System.assertEquals(expected, productRequireds.size());
  }

  @IsTest
  static void DoneHandler_Test() {
    ERPOrder_PartnerBoatSaleToWO_Promise.DoneHandler doneHandler = new ERPOrder_PartnerBoatSaleToWO_Promise.DoneHandler();
    doneHandler.done(null);
  }

  @IsTest
  static void DoneHandler_WithError_Test() {
    try {
      Integer i = 1 / 0;
    } catch (Exception e) {
      Object errorHandler = new ERPOrder_PartnerBoatSaleToWO_Promise.ErrorHandler().error(e);

      ERPOrder_PartnerBoatSaleToWO_Promise.DoneHandler doneHandler = new ERPOrder_PartnerBoatSaleToWO_Promise.DoneHandler();
      doneHandler.done(errorHandler);

      List<Queueable_Exception_Log__c> queueableException = [SELECT Id FROM Queueable_Exception_Log__c];

      System.assertEquals(1, queueableException.size());
    }
  }
}
