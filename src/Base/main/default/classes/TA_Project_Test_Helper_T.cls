@isTest
public class TA_Project_Test_Helper_T {
  public static AcctSeed__Project__c[] project;
  public static AcctSeed__Project__c warrantyERP;
  public static Map<String, User> users;
  public static Account customer;
  public final static String RECORDTYPE = 'Insurance';
  public final static String FAMILY = 'Insurance';
  public static Map<Id, AcctSeed__Project_Task__c> erp_task_map;
  public static final Integer recordCount = 3;
  public static final Date deliveryDate = Date.today().addDays(10);
  public static Product2 boat;
  public static List<AcctSeed__Project__c> retailERPs;
  public static List<AcctSeed__Project__c> partnerERPs;
  public static Map<Id, AcctSeedERP__Purchase_Order_Line__c> pol_by_linkedPartnerERPid;

  public static void testDataSetup() {
    // Product2 internalLabour = Factory_Product.buildNonSerializedProduct('Internal', 'Labour');
    //insert internalLabour;
    //  Legend_Settings__c.getOrgDefaults().Product_Internal_Labour__c = String.valueOf(internalLabour.id);
    // Legend_Settings__c lSettings = [Select id,Product_Internal_Labour__c from Legend_Settings__c where SetupOwnerId = :Userinfo.getOrganizationId()];
    //lSettings.SetupOwnerId = Userinfo.getOrganizationId();
    // lSettings.Product_Internal_Labour__c = String.valueOf(internalLabour.id);
    // upsert lSettings;
    // System.debug('@@ lSettings= '+lSettings);
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();

    customer = Factory_Account.insertCustomerAccounts(1)[0];
    customer.GL_Account_Variable_1__c = gcConstants.idGlv1Whitefish;
    customer.Is_Internal__c = true;

    update customer;
    System.debug('@@ customer= ' + customer);
    GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertFullSerial('Boat', 'Pontoon', 'test12345');
    AcctSeedERP__Warehouse__c warehouse = [
      SELECT Id, Name, GL_Account_Variable_3__c
      FROM AcctSeedERP__Warehouse__c
      WHERE Name = 'Whitefish'
    ];
    users = new Map<String, User>{
      'sales' => Factory_User.newUser('Sales', 'Person', 'System Administrator', null),
      'businessOffice' => Factory_User.newUser('Business', 'Office', 'System Administrator', null)
    };
    insert users.values();
    AcctSeed__Accounting_Variable__c othersTaxZone = AcctSeed_Settings_Factory.createTaxZone('Others', false, 0);
    project = Factory_ERPOrder.insertServiceOrders(
      customer,
      warehouse,
      DateTime.now().addMonths(1),
      new List<GMBLASERP__Serial_Number__c>{ serial }
    );
    project[0].GMBLASERP__Pricebook__c = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
    project[0].Salesperson__c = users.get('sales').Id;
    project[0].Business_Manager__c = users.get('businessOffice').Id;
    project[0].Stage__c = 'Quoting';
    project[0].GL_Account_Variable_1__c = gcConstants.idGlv1Whitefish;
    project[0].Service_Follow_Up_Tasked__c = true;
    update project[0];
    System.debug('@@project= ' + project);
    // Factory_ERPOrderTask.insertDefaultRetailBoatSaleTasks(project[0].Id);
    warrantyERP = Factory_ERPOrder.createWarrantyERP(customer, serial.id, 2);
  }
  public static void generateCashReceipt(List<AcctSeed__Project__c> erps) {
    List<Product2> serializedProducts = Factory_Product.createSerializedProducts(RECORDTYPE, FAMILY, 1);
    AcctSeed__Ledger__c ledger = [SELECT Id FROM AcctSeed__Ledger__c LIMIT 1];
    List<AcctSeed__Cash_Receipt__c> lstCashReceipt = new List<AcctSeed__Cash_Receipt__c>();
    Account acc = [SELECT id FROM Account LIMIT 1];
    Map<Id, AcctSeed__Project_Task__c> erp_task_map = new Map<Id, AcctSeed__Project_Task__c>();
    for (AcctSeed__Project__c erp : erps) {
      erp_task_map.put(erp.Id, Factory_ERPOrder.buildProjectTask(erp.Id, 'Dealer Order'));
    }
    insert erp_task_map.values();
    for (AcctSeed__Project__c erp : erps) {
      lstCashReceipt.add(
        new AcctSeed__Cash_Receipt__c(
          AcctSeed__Account__c = acc.Id,
          AcctSeed__Amount__c = 5.0,
          AcctSeed__Receipt_Date__c = Date.today(),
          AcctSeed__Payment_Reference__c = 'Cash',
          AcctSeed__Ledger__c = ledger.Id,
          AcctSeed__Project__c = erp.Id,
          AcctSeed__Project_Task__c = erp_task_map.get(erp.Id).Id,
          AcctSeed__Product__c = serializedProducts[0].Id,
          Payment_Method__c = 'Visa'
        )
      );
    }

    insert lstCashReceipt;
  }
  public static List<AcctSeed__Project__c> getOldList() {
    System.debug('@@project in old= ' + project);
    List<AcctSeed__Project__c> oldList = new List<AcctSeed__Project__c>();
    for (AcctSeed__Project__c rec : project) {
      oldList.add(rec.clone(true, true, true, true));
    }

    return oldList;
  }

  public static void generateOpportunity(List<AcctSeed__Project__c> erps) {
    Account customer = [SELECT id FROM Account WHERE Id = :erps[0].AcctSeed__Account__c];

    Factory_Opportunity.insertOpportunityForBoatSale(LGND_Constants.retailPricebookId, customer);
    Opportunity opp = [SELECT Id, Pricebook2Id FROM Opportunity LIMIT 1];
    opp.Finance_Term__c = 7;
    opp.Deposit__c = 1000;
    opp.Finance_Annual_Interest__c = 10;
    opp.Finance_Ammortization__c = 100;
    opp.Insurance_Term__c = 9;
    opp.amount = 100;
    opp.Deposit__c = 50;
    opp.Tax_Rate_Federal__c = 10;
    opp.Tax_Rate_Retail__c = 10;
    opp.GL_Account_Variable_3__c = gcConstants.idGlv3Ontario;
    Trade_In_Record__c trade = new Trade_In_Record__c(
      Lien_Amount__c = 1000,
      Opportunity__c = opp.id,
      Total_Value__c = 10000
    );
    insert trade;

    update opp;
    opp = [
      SELECT
        id,
        Pre_Insurance_Total__c,
        Name,
        AccountId,
        Pricebook2Id,
        StageName,
        CloseDate,
        Finance_Term__c,
        Finance_Annual_Interest__c,
        Finance_Ammortization__c,
        Insurance_Term__c,
        Amount,
        Tax_Rate_Federal__c,
        Tax_Rate_Retail__c,
        TotalTaxes__c,
        Tax_Amount_Federal__c,
        Tax_Amount_Provincial__c,
        Tax_Amount_Retail__c,
        Insurance_Total__c,
        Trade_In_Value__c,
        Trade_In_Lien__c,
        Deposit__c,
        GL_Account_Variable_3__c,
        Calculate_Insurance_Amount__c
      FROM Opportunity
      WHERE id = :opp.id
    ];
    for (AcctSeed__Project__c erp : erps) {
      erp.AcctSeed__Opportunity__c = opp.id;
    }
    update erps;
  }
  public static id manufacturedProductERP() {
    GMBLASERP__Serial_Number__c ser = Factory_SerialNumber.insertFullSerial('Boat', 'Pontoon', '0987654321');
    Account acc = [SELECT id, firstName, lastName FROM Account LIMIT 1];
    AcctSeed__Project__c manufacturedERP = Factory_ERPOrder.buildERP(acc, ser.id, gcConstants.idRtProjectManufacturing);
    ser = [
      SELECT Id, Name, GMBLASERP__Product__c, GMBLASERP__Lot__c
      FROM GMBLASERP__Serial_Number__c
      WHERE Name = '0987654321'
      LIMIT 1
    ];
    manufacturedERP.AcctSeedERP__Manufactured_Product__c = ser.GMBLASERP__Product__c;
    manufacturedERP.Serial_Number__c = ser.id;
    insert manufacturedERP;
    return manufacturedERP.id;
  }
  public static void generateERPTask(List<AcctSeed__Project__c> erps) {
    erp_task_map = new Map<Id, AcctSeed__Project_Task__c>();
    for (AcctSeed__Project__c erp : erps) {
      erp_task_map.put(erp.Id, Factory_ERPOrder.buildProjectTask(erp.Id, 'Dealer Order'));
    }
    insert erp_task_map.values();
  }
  public static void insuranceProductERP(
    List<AcctSeed__Project__c> erps,
    double lowerTerm,
    double upperTerm,
    String coverageType,
    Id taxZone
  ) {
    List<AcctSeedERP__Material__c> materials = new List<AcctSeedERP__Material__c>();
    InsurancePlan__c iPlan = new InsurancePlan__c(Name = 'Test Insurance Plan', Profit_Percent__c = 25);
    insert iPlan;
    product2 insuranceProduct = Factory_Product.buildInsuranceProduct(
      'Accidental Coverage',
      'Insurance ' + String.valueOf(1),
      iPlan.Id,
      false
    );
    insert insuranceProduct;
    Insurance_Rate__c insuranceRate = new Insurance_Rate__c(
      Dump_Id__c = '111111',
      Joint__c = 1,
      Joint_Factor__c = 10,
      Product__c = insuranceProduct.id,
      Lower_Term__c = lowerTerm,
      Lower_Finance_Term__c = 5,
      Single__c = 3,
      Upper_Finance_Term__c = 10,
      Upper_Term__c = upperTerm,
      Tax_Zone__c = taxZone // gcConstants.idGlv3Others
    );
    insert insuranceRate;
    SYstem.debug('@@ insuranceProduct= ' + insuranceProduct);
    List<AcctSeedERP__Material__c> insuranceMats = Factory_Material.buildMaterials(
      erps[0].Id,
      erp_task_map.get(erps[0].Id).id,
      new List<product2>{ insuranceProduct }
    );
    for (AcctSeedERP__Material__c iMat : insuranceMats) {
      iMat.Insurance_Rate__c = 0.05;
      iMat.Insurance_Coverage__c = coverageType;
    }
    materials.addAll(insuranceMats);
    System.debug('@@ materials= ' + materials);
    insert materials;
    // erps[0].Boat_Product__c = insuranceProduct.id;
  }
  public static id retailBoatSaleERP() {
    GMBLASERP__Serial_Number__c ser = Factory_SerialNumber.insertFullSerial('Boat', 'Pontoon', '0987654111');
    ser = [
      SELECT Id, Name, GMBLASERP__Product__c, GMBLASERP__Lot__c
      FROM GMBLASERP__Serial_Number__c
      WHERE Name = '0987654321'
      LIMIT 1
    ];
    Account acc = [SELECT id, firstName, lastName FROM Account LIMIT 1];
    AcctSeedERP__Warehouse__c warehouse = [
      SELECT Id, Name, GL_Account_Variable_3__c
      FROM AcctSeedERP__Warehouse__c
      WHERE Name = 'Whitefish'
    ];

    AcctSeed__Project__c retailERP = Factory_ERPOrder.insertRetailBoatSale(
      acc,
      warehouse,
      DateTime.now().addMonths(1),
      ser
    );
    retailERP.Serial_Number__c = ser.id;
    retailERP.Service_ERP__c = null;
    update retailERP;
    return retailERP.id;
  }

  public static id counterSaleERP() {
    GMBLASERP__Serial_Number__c ser = Factory_SerialNumber.insertFullSerial('Boat', 'Pontoon', '0987654222');
    Account acc = [SELECT id, firstName, lastName FROM Account LIMIT 1];
    acc.GL_Account_Variable_1__c = gcConstants.idGlv1Montreal;
    update acc;
    AcctSeed__Project__c counterSaleERP = Factory_ERPOrder.buildERP(acc, ser.id, gcConstants.idRtProjectCounterSale);
    counterSaleERP.Serial_Number__c = ser.id;
    insert counterSaleERP;
    return counterSaleERP.id;
  }
  public static id changeGLV1(AcctSeed__Project__c erp) {
    Account acc = [SELECT id, firstName, lastName FROM Account LIMIT 1];
    erp.GL_Account_Variable_1__c = gcConstants.idGlv1Montreal;
    if (erp.AcctSeed__Opportunity__r.account.id != null)
      erp.AcctSeed__Account__c = erp.AcctSeed__Opportunity__r.account.id; //acc.id;
    else
      erp.AcctSeed__Account__c = acc.id;
    //  erp.RecordTypeId = gcConstants.idRtProjectCounterSale;
    update erp;
    return erp.id;
  }
  public static id changeSerialNo(AcctSeed__Project__c erp) {
    Account acc = [SELECT id, firstName, lastName FROM Account LIMIT 1];
    GMBLASERP__Serial_Number__c ser = Factory_SerialNumber.insertFullSerial('Boat', 'Pontoon', '0987111222');
    //erp.GL_Account_Variable_1__c = gcConstants.idGlv1Montreal;
    erp.AcctSeed__Account__c = erp.AcctSeed__Opportunity__r.account.id; //acc.id;
    erp.Serial_Number__c = ser.id;
    //  erp.RecordTypeId = gcConstants.idRtProjectCounterSale;
    update erp;
    return erp.id;
  }
  public static id changeStatus(AcctSeed__Project__c erp) {
    //erp.GL_Account_Variable_1__c = gcConstants.idGlv1Montreal;
    Account acc = [SELECT id, firstName, lastName FROM Account LIMIT 1];
    if (erp.AcctSeed__Opportunity__r.account.id != null)
      erp.AcctSeed__Account__c = erp.AcctSeed__Opportunity__r.account.id; //acc.id;
    else
      erp.AcctSeed__Account__c = acc.id;
    erp.AcctSeed__Status__c = 'Completed';
    //  erp.RecordTypeId = gcConstants.idRtProjectCounterSale;
    update erp;
    return erp.id;
  }
  public static id partnerBoatSaleERP_old() {
    Account acc = [SELECT id, firstName, lastName FROM Account LIMIT 1];
    GMBLASERP__Serial_Number__c ser = Factory_SerialNumber.insertFullSerial('Boat', 'Pontoon', '1187654222');

    AcctSeed__Project__c partnerSaleERP = Factory_ERPOrder.buildERP(
      acc,
      ser.id,
      gcConstants.idRtProjectPartnerBoatSale
    );
    partnerSaleERP.Serial_Number__c = ser.id;
    insert partnerSaleERP;
    return partnerSaleERP.id;
  }
  public static id partnerBoatSaleERP() {
    GMBLASERP__Serial_Number__c ser = Factory_SerialNumber.insertFullSerial('Boat', 'Pontoon', '1987654222');
    Account acc = [SELECT id, firstName, lastName FROM Account LIMIT 1];
    AcctSeed__Project__c counterSaleERP = Factory_ERPOrder.buildERP(acc, ser.id, gcConstants.idRtProjectBoatSale);
    counterSaleERP.Serial_Number__c = ser.id;
    counterSaleERP.Service_ERP__c = null;
    insert counterSaleERP;
    System.debug('counterSaleERP.id= ' + counterSaleERP.id);
    return counterSaleERP.id;
  }

  public static id addPickupLocation(AcctSeed__Project__c erp) {
    erp.Pickup_Location__c = 'Whitefish - Pick-up';
    erp.GL_Account_Variable_1__c = null;
    update erp;
    return erp.id;
  }
  public static Id inventoryMovement() {
    Account dealer = AccountFactory.buildDealerAccount('Test Dealer UnitTester');
    insert dealer;
    AcctSeed__Accounting_Settings__c accSetting = [
      SELECT AcctSeed__Default_Ledger__c
      FROM AcctSeed__Accounting_Settings__c
      ORDER BY CreatedDate
    ][0];

    AcctSeed__GL_Account__c glA = [SELECT Id FROM AcctSeed__GL_Account__c LIMIT 1];
    System.debug('@@ glA= ' + glA);
    AcctSeedERP__Warehouse__c warehouse = [
      SELECT Id, Name, GL_Account_Variable_3__c
      FROM AcctSeedERP__Warehouse__c
      WHERE Name = 'Whitefish'
    ];
    List<Product2> serializedProducts = Factory_Product.createSerializedProducts(RECORDTYPE, FAMILY, 1);
    AcctSeedERP__Location__c loc = new AcctSeedERP__Location__c(
      Name = 'Test Loc',
      AcctSeedERP__Warehouse__c = warehouse.Id
    );
    insert loc;
    AcctSeedERP__Inventory_Balance__c balance = new AcctSeedERP__Inventory_Balance__c(
      AcctSeedERP__Location__c = loc.Id,
      AcctSeedERP__Warehouse__c = warehouse.Id,
      AcctSeedERP__Product__c = serializedProducts[0].Id //part.Id
    );
    insert balance;
    GMBLASERP__Serial_Number__c serial = Factory_SerialNumber.insertFullSerial('Boat', 'Pontoon', 'test45543');
    AcctSeed__Project__c erp = Factory_ERPOrder.buildERP(dealer, serial.Id, gcConstants.idRtPartnerPartsOrder);
    insert erp;
    AcctSeed__Project_Task__c erp_task = Factory_ERPOrder.buildProjectTask(erp.Id, 'Dealer Order');
    insert erp_task;

    GMBLASERP__Lot__c lot = [SELECT Id FROM GMBLASERP__Lot__c WHERE GMBLASERP__Product__c = :serializedProducts[0].Id];
    GMBLASERP__Inventory_Adjustment__c adj = new GMBLASERP__Inventory_Adjustment__c();
    adj.GL_Account_Variable_1__c = gcConstants.idGlv1Wholesale;
    adj.Department_GLV_2__c = gcConstants.idGlv2Sales;
    adj.GMBLASERP__GL_Account__c = gcConstants.idGlCostVariance;
    adj.GMBLASERP__Product__c = serializedProducts[0].Id;
    adj.GMBLASERP__Adjustment_Type__c = 'Value';
    insert adj;
    AcctSeedERP__Inbound_Inventory_Movement__c movement = new AcctSeedERP__Inbound_Inventory_Movement__c(
      AcctSeedERP__Unit_Cost__c = 10,
      AcctSeedERP__Type__c = 'Other',
      AcctSeedERP__Quantity__c = 1,
      AcctSeedERP__Credit_GL_Account__c = glA.Id,
      AcctSeedERP__Inventory_Balance__c = balance.Id,
      AcctSeedERP__Ledger__c = accSetting.AcctSeed__Default_Ledger__c,
      GMBLASERP__Warehouse__c = warehouse.Id,
      GMBLASERP__Serial_Number__c = serial.Id,
      GMBLASERP__Lot__c = lot.Id,
      GMBLASERP__Inventory_Adjustment__c = adj.Id,
      AcctSeedERP__Project_Task__c = erp_task.Id,
      AcctSeedERP__Project__c = erp.Id
      // AcctSeedERP__Credit_GL_Account__c = gcConstants.idGLCostVariance
    );
    System.debug('movement= ' + movement);
    GMBLASERP.gcInboundInventoryMovement.disableTrigger = true;
    //gtInboundInventoryMovement.disableTrigger = true;
    Test.StartTest();
    insert movement;
    Test.StopTest();
    //  erp.AcctSeed__Status__c = 'Completed';
    //update erp;
    return erp.id;
  }
}
