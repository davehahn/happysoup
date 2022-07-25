/**
 * Created by dave on 2021-06-08.
 */

@IsTest
private class ProductRequired_Automation_T {
  private static WorkOrder wo;
  private static List<ProductRequired> records;
  private static List<Product2> parts;

  private static final Integer PARTS_COUNT = 3;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Account acct = Factory_Account.insertFullPersonAccount('Testy', 'McTesterson');
    Id pbId = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
    TriggerBase.bypass('WorkOrder');
    TriggerBase.bypass('WorkOrderLineItem');
    gcProject.disableTrigger = true;
    gcProjectTask.disableTrigger = true;
    WorkOrder wo = Factory_WorkOrder.createNew(acct.Id, pbId);
    AcctSeed__Project__c erp = new AcctSeed__Project__c(
      Name = (wo.Account.Name + ' - ' + String.valueOf(wo.WorkOrderNumber)).LEFT(80),
      AcctSeed__Account__c = wo.AccountId,
      Work_Order__c = wo.Id
    );
    insert erp;
    wo.ERP_Order__c = erp.Id;
    update wo;
    AcctSeed__Project_Task__c orderTask = Factory_ERPOrderTask.buildProjectTask(erp.Id, 'WOLI Unit Test');
    WorkOrderLineItem woli = Factory_WorkOrder.createLineItems(wo.Id, 1)[0];
    orderTask.Work_Order_Line_Item__c = woli.Id;
    insert orderTask;
    woli.ERP_Order_Task__c = orderTask.Id;
    update woli;
  }

  private static void fetchWorkOrder() {
    wo = [SELECT Id, ERP_Order__c, (SELECT Id FROM WorkOrderLineItems) FROM WorkOrder LIMIT 1];
  }

  private static void buildRecords() {
    createParts();
    records = Factory_ProductRequired.buildRecords(wo.WorkOrderLineItems[0].Id, parts, 1);
  }

  private static void createRecordsWithMaterials() {
    createParts();
    AcctSeed__Project__c erp = [
      SELECT Id, (SELECT Id FROM AcctSeed__Project_Tasks__r)
      FROM AcctSeed__Project__c
      LIMIT 1
    ];
    List<AcctSeedERP__Material__c> mats = Factory_Material.insertMaterials(
      erp.Id,
      erp.AcctSeed__Project_Tasks__r[0].Id,
      parts
    );
    records = Factory_ProductRequired.buildRecordFromMaterials(wo.Id, mats);
    TriggerBase.bypass('ProductRequired');
    insert records;
    TriggerBase.clearBypass('ProductRequired');
  }

  private static void createParts() {
    parts = Factory_Product.createNonSerializedProducts('Part', 'Electronics', PARTS_COUNT);
  }

  private static void refreshRecords() {
    Map<Id, ProductRequired> prMap = new Map<Id, ProductRequired>(records);
    records = [SELECT Id, Material__c FROM ProductRequired WHERE Id IN :prMap.keySet()];
  }

  private static List<AcctSeedERP__Material__c> fetchMaterials() {
    return [SELECT Id FROM AcctSeedERP__Material__c WHERE AcctSeedERP__Project__c = :wo.ERP_Order__c];
  }

  @IsTest
  static void afterInsert_Test() {
    fetchWorkOrder();
    buildRecords();

    Test.startTest();
    insert records;
    Test.stopTest();

    refreshRecords();

    for (ProductRequired record : records) {
      System.assert(record.Material__c != null);
    }
  }

  @IsTest
  static void beforeUpdate_Test() {
    fetchWorkOrder();
    buildRecords();
    TriggerBase.bypass('ProductRequired');
    insert records;
    TriggerBase.clearBypass('ProductRequired');

    refreshRecords();
    for (ProductRequired record : records) {
      System.assert(record.Material__c == null);
    }

    Test.startTest();
    update records;
    Test.stopTest();

    refreshRecords();
    for (ProductRequired record : records) {
      System.assert(record.Material__c != null);
    }
  }

  @IsTest
  static void beforeDelete_Test() {
    fetchWorkOrder();
    createRecordsWithMaterials();

    List<AcctSeedERP__Material__c> matsBefore = fetchMaterials();
    System.assertEquals(PARTS_COUNT, matsBefore.size());

    Test.startTest();
    TA_ProductRequired_DeleteMaterials.beforeDelete(records);
    Test.stopTest();

    List<AcctSeedERP__Material__c> matsAfter = fetchMaterials();
    System.assertEquals(0, matsAfter.size());
  }
}
