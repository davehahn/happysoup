/**
 * Created by dave on 2022-01-17.
 */
@IsTest
public with sharing class TA_CommLI2_TestHelper {
  private static Legend_Settings__c settings = Legend_Settings__c.getOrgDefaults();
  public final static  Id retailPbId = settings.Default_Retail_Pricebook__c;
  public final static  Id factoryPbId = settings.Default_Factory_Pricebook__c;

  public static void testDataSetup(){
    new Factory_TestData();
    Factory_CustomSettings.setupInventorySettings();
    Account customer = Factory_Account.insertCustomerAccounts(1)[0];
    AcctSeed__Project__c project = Factory_ERPOrder.buildERP( customer, null, gcConstants.idRtProjectBoatSale );
    project.GMBLASERP__Pricebook__c = retailPbId;
    insert project;
  }


  public AcctSeed__Project__c project {
    get {
      if( project ==  null ){
        project = [SELECT Id, GL_Account_Variable_3__r.Name FROM AcctSeed__Project__c LIMIT 1];
      }
      return project;
    }
    set {}
  }
  public Decimal retailHourlyRate {
    get {
      if( retailHourlyRate == null ){
        retailHourlyRate = [
          SELECT DeveloperName, Hourly_Rate__c
          FROM Labour_Rate__mdt
          WHERE DeveloperName = 'Retail'
          LIMIT 1
        ].Hourly_Rate__c;
      }
      return retailHourlyRate;
    }
    set {}
  }
  public AcctSeed__Project_Task__c task;
  public AcctSeedERP__Material__c material;
  public CommissionLineItem2__c lineItem;
  public final Decimal RIGGING_TIME = 2;
  public final Decimal PART_SALE_PRICE = 20000;
  public final Decimal PART_COST = 10000;

  public void initForInsurance(){
    this.task = Factory_ERPOrderTask.buildBusinessOfficeTask( project.Id );
    insert this.task;
    CommissionRecord2__c record = insertCommissionRecord();
    InsurancePlan__c iPlan = new InsurancePlan__c(
      Name = 'Test Insurance Plan',
      Profit_Percent__c = 25
    );
    insert iPlan;
    Product2 insuranceProduct = Factory_Product.createInsuranceProduct( 'Insurance',
      'Test Insurance Product',
      iPlan.Id,
      false,
      retailPbId );
    material = new AcctSeedERP__Material__c(
      AcctSeedERP__Project_Task__c = this.task.Id,
      AcctSeedERP__Project__c = project.Id,
      AcctSeedERP__Product__c = insuranceProduct.Id,
      AcctSeedERP__Quantity_Per_Unit__c = 1,
      GMBLASERP__Unit_Price__c = 1000
    );
    insert material;
    lineItem = new CommissionLineItem2__c(
      CommissionRecord2__c = record.Id,
      Material__c = material.Id,
      Product__c = material.AcctSeedERP__Product__c,
      Quantity__c = material.AcctSeedERP__Quantity_Per_Unit__c,
      Sale_Price__c = material.GMBLASERP__Unit_Price__c
    );
  }

  public void initForFee(){
    this.task = Factory_ERPOrderTask.buildRetailSaleTask( project.Id );
    insert this.task;
    CommissionRecord2__c record = insertCommissionRecord();

    Product2 feeProduct = Factory_Product.createNonSerializedProduct( 'Fees', 'Factory Freight');
    Product_Fee_Amount__c pfa = new Product_Fee_Amount__c(
      Fee_Product__c = feeProduct.Id,
      Price_Book__c = factoryPbId,
      Province__c = project.GL_Account_Variable_3__r.Name,
      Amount__c = 500
    );
    insert pfa;
    this.material = new AcctSeedERP__Material__c(
      AcctSeedERP__Project_Task__c = task.Id,
      AcctSeedERP__Project__c = project.Id,
      AcctSeedERP__Product__c = feeProduct.Id,
      AcctSeedERP__Quantity_Per_Unit__c = 1,
      GMBLASERP__Unit_Price__c = 0
    );
    insert this.material;
    this.lineItem = new CommissionLineItem2__c(
      CommissionRecord2__c = record.Id,
      Material__c =this.material.Id,
      Product__c = this.material.AcctSeedERP__Product__c,
      Quantity__c = this.material.AcctSeedERP__Quantity_Per_Unit__c,
      Sale_Price__c = this.material.GMBLASERP__Unit_Price__c
    );
  }

  public void initForPart(){
    this.task = Factory_ERPOrderTask.buildRetailSaleTask( project.Id );
    insert this.task;
    CommissionRecord2__c record = insertCommissionRecord();
    Product2 part = Factory_Product.buildNonSerializedProduct('Part', 'Hardware');
    part.Rigging_Time__c = RIGGING_TIME;
    insert part;
    Factory_PricebookEntry.createAllDefaultEntriesEntries( part.Id, this.PART_COST );
    this.material = new AcctSeedERP__Material__c(
      AcctSeedERP__Product__c = part.Id,
      AcctSeedERP__Quantity_Per_Unit__c = 1,
      AcctSeedERP__Project__c = project.Id,
      AcctSeedERP__Project_Task__c = this.task.Id,
      GMBLASERP__Unit_Price__c = this.PART_SALE_PRICE
    );
    insert this.material;
    this.lineItem = new CommissionLineItem2__c(
      CommissionRecord2__c = record.Id,
      Material__c = this.material.Id,
      Product__c = this.material.AcctSeedERP__Product__c,
      Quantity__c = this.material.AcctSeedERP__Quantity_Per_Unit__c,
      Sale_Price__c = this.material.GMBLASERP__Unit_Price__c
    );
  }

  public void populateLineItemForPart(){
    this.lineItem.Id = TestUtility.getFakeId(CommissionLineItem2__c.SObjectType);
    this.lineItem.Cost__c = this.PART_COST;
    this.lineItem.Profit__c = this.PART_COST - (this.retailHourlyRate * this.RIGGING_TIME);
    this.lineItem.Sale_Price__c = this.PART_SALE_PRICE;
    this.lineItem.Commission_Rate__c = 0.10;
    this.lineItem.Labour_Cost__c = LGND_Constants.retailLabourRate * this.RIGGING_TIME;
    this.lineItem.Payment_Amount__c = 0.10 * ((this.PART_SALE_PRICE - this.PART_COST) - (this.retailHourlyRate * this.RIGGING_TIME));
  }

  public Id insertLineItem(){
    insert this.lineItem;
    return this.lineItem.Id;
  }

  private CommissionRecord2__c insertCommissionRecord(){
    CommissionRecord2__c record = new CommissionRecord2__c(
      Project_Task__c = this.task.Id,
      Project__c = this.project.Id,
      Calculation_Method__c = this.task.Commission_Calculation_Method__c,
      Department_GLV2__c = this.task.AcctSeed__GL_Account_Variable_2__c,
      Retail_Pricebook__c = Test_Constants.idRetailPricebook,
      Factory_Pricebook__c = Test_Constants.idFactoryPricebook
    );
    TriggerBase.bypass('CommissionRecord2__c');
    insert record;
    TriggerBase.clearBypass('CommissionRecord2__c');
    return record;
  }


}