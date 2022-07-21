/**
 * Created by dave on 2021-11-03.
 */

@IsTest
private class Material_Selector_T {
  static AcctSeed__Project__c project;
  static AcctSeed__Project_Task__c task;
  static List<AcctSeedERP__Material__c> materials;
  static Set<Id> matIds;
  static final Integer INSURANCE_ITEMS_COUNT = 4;
  static final Integer INSURANCE_ITEMS_NORATE_COUNT = 2;
  static final Integer PARTS_COUNT = 5;

  @testSetup
  static void dataSetup() {
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    setupTestData();
  }

  private static void setupTestData() {
    Account customer = Factory_Account.insertCustomerAccounts(1)[0];
    AcctSeedERP__Warehouse__c wh = [
      SELECT Id, Name
      FROM AcctSeedERP__Warehouse__c
      WHERE Name LIKE '%Whitefish%'
      LIMIT 1
    ];
    Product2 boat = Factory_Product.createSerializedProduct('Boat', 'Pontoon');
    GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertSerialNumber(boat, 'TestSerial1234');
    Boolean gcProjectOrig = gcProject.disableTrigger;
    Boolean gcProjectTaskOrig = gcProjectTask.disableTrigger;
    gcProject.disableTrigger = true;
    gcProjectTask.disableTrigger = true;
    AcctSeed__Project__c project = Factory_ERPOrder.insertRetailBoatSale(
      customer,
      wh,
      DateTime.now().addMonths(2),
      serial
    );
    AcctSeed__Project_Task__c task = [
      SELECT Id
      FROM AcctSeed__Project_Task__c
      WHERE AcctSeed__Project__c = :project.Id
    ];
    List<AcctSeedERP__Material__c> materials = new List<AcctSeedERP__Material__c>();
    List<Product2> parts = Factory_Product.createNonSerializedProducts('Part', 'Hardware', PARTS_COUNT);
    materials.addAll(Factory_Material.buildMaterials(project.Id, task.Id, parts));
    List<Product2> insuranceProductsWithNotRates = Factory_Product.createNonSerializedProducts(
      'Insurance',
      'Critical Illness Coverage',
      INSURANCE_ITEMS_NORATE_COUNT
    );
    materials.addAll(Factory_Material.buildMaterials(project.Id, task.Id, insuranceProductsWithNotRates));
    InsurancePlan__c iPlan = new InsurancePlan__c(Name = 'Insurance Plan One', Profit_Percent__c = 50);
    insert iPlan;
    List<Product2> insuranceProducts = Factory_Product.createInsuranceProducts(
      'Critical Illness Coverage',
      'Insurance Product',
      iPlan.Id,
      false,
      INSURANCE_ITEMS_COUNT
    );
    List<AcctSeedERP__Material__c> insuranceMats = Factory_Material.buildMaterials(
      project.Id,
      task.Id,
      insuranceProducts
    );
    for (AcctSeedERP__Material__c iMat : insuranceMats) {
      iMat.Insurance_Rate__c = 0.05;
      iMat.Insurance_Coverage__c = 'Single';
    }
    materials.addAll(insuranceMats);
    insert materials;
    gcProject.disableTrigger = gcProjectOrig;
    gcProjectTask.disableTrigger = gcProjectTaskOrig;
  }

  private static void init() {
    project = [SELECT Id FROM AcctSeed__Project__c LIMIT 1];
    task = [SELECT Id FROM AcctSeed__Project_Task__c WHERE AcctSeed__Project__c = :project.Id];
    materials = [
      SELECT Id
      FROM AcctSeedERP__Material__c
      WHERE AcctSeedERP__Project__c = :project.Id AND AcctSeedERP__Project_Task__c = :task.Id
    ];
    matIds = new Map<Id, AcctSeedERP__Material__c>(materials).keySet();
  }

  @IsTest
  static void selectAllByTaskId_Test() {
    init();
    List<AcctSeedERP__Material__c> result = Material_Selector.selectAllByTaskId(new Set<Id>{ task.Id });
    System.assertEquals(materials.size(), result.size());
  }

  @IsTest
  static void allByProjectId_Test() {
    init();
    List<AcctSeedERP__Material__c> result = Material_Selector.allByProjectId(project.Id);
    System.assertEquals(materials.size(), result.size());
  }

  @IsTest
  static void allInsuranceMaterialsByProjectIds_Test() {
    init();
    List<AcctSeedERP__Material__c> result = Material_Selector.allInsuranceMaterialsByProjectIds(
      new Set<Id>{ project.Id }
    );
    System.assertEquals(INSURANCE_ITEMS_COUNT, result.size());
  }

  @IsTest
  static void selectAllByIds_Test() {
    init();
    List<AcctSeedERP__Material__c> result = Material_Selector.selectAllByIds(matIds);
    System.assertEquals(materials.size(), result.size());
  }

  @IsTest
  static void mapAllByIds_Test() {
    init();
    Map<Id, AcctSeedERP__Material__c> result = Material_Selector.mapAllByIds(matIds);
    System.assertEquals(materials.size(), result.size());
  }
}
