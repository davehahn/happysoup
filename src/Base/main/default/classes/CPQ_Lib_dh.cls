/*
  A simple class to hold wrapper classes used in CPQ
*/

public with sharing class CPQ_Lib_dh {
  public static Map<String, Id> defaultPricebooks {
    get {
      if (defaultPricebooks == null) {
        Legend_Settings__c lSettings = Legend_Settings__c.getOrgDefaults();
        defaultPricebooks = new Map<String, Id>{
          'partner' => lSettings.Default_Partner_Pricebook__c,
          'retail' => lSettings.Default_Retail_Pricebook__c,
          'factory' => lSettings.Default_Factory_Pricebook__c
        };
      }
      return defaultPricebooks;
    }
    set;
  }

  public static void addRetailOverridePricebook(Id pbId) {
    defaultPricebooks.put('active', pbId);
  }

  public class TaxZone {
    public String id { get; set; }
    public String name { get; set; }
    public Decimal provincialRate { get; set; }
    public Decimal retailRate { get; set; }
    public Decimal federalRate { get; set; }
    public Boolean isHarmonized { get; set; }
    public String taxName { get; set; }
    public String taxNameFrench { get; set; }

    public TaxZone(AcctSeed__Accounting_Variable__c aVar) {
      this.id = aVar.Id;
      this.name = aVar.name;
      this.provincialRate = aVar.Tax_Rate_Provincial_Statutory__c;
      this.retailRate = aVar.Tax_Rate_Retail__c;
      this.federalRate = 5.0;
      this.isHarmonized = aVar.Tax_is_Harmonized__c;
      determineTaxName(aVar);
    }

    private void determineTaxName(AcctSeed__Accounting_Variable__c aVar) {
      if (aVar.Tax_is_Harmonized__c == true) {
        this.taxName = 'HST';
        this.taxNameFrench = 'TVH';
      } else if (aVar.Name == 'Quebec') {
        this.taxName = 'QST';
        this.taxNameFrench = 'TVQ';
      } else {
        this.taxName = 'PST';
        this.taxNameFrench = 'PST';
      }
    }
  }

  public virtual class CPQ_Product {
    public String id;
    public String name { get; set; }
    public String make { get; set; }
    public String recordTypeName;
    public String family;
    public Decimal retailPrice { get; set; }
    public Decimal activePrice { get; set; }
    public Decimal partnerPrice;
    public Decimal factoryPrice;
    public Boolean taxable { get; set; }
    public Boolean retailPricebookEntryIsActive;
    public Boolean partnerPricebookEntryIsActive;
    public Boolean factoryPricebookEntryIsActive;
    public Boolean activePricebookEntryIsActive;
    public String retailPricebookEntryId;
    public String partnerPricebookEntryId;
    public String factoryPricebookEntryId;
    public String activePricebookEntryId;
    public String image;
    public SObject originalLineItem;
    private Product2 prod;
    private String locale = 'en_US';

    public CPQ_Product(String prodId) {
      System.debug('Product Constructor');
      this.id = prodId;
      this.prod = findProduct();
      construct();
    }

    public CPQ_Product(Product2 prod) {
      this.prod = prod;
      construct();
    }

    public CPQ_Product(String prodId, String locale) {
      if (locale != null) {
        this.locale = locale;
      }
      this.id = prodId;
      this.prod = findProduct();
      construct();
    }

    public CPQ_Product(Product2 prod, String locale) {
      if (locale != null) {
        this.locale = locale;
      }
      this.prod = prod;
      construct();
    }

    public CPQ_Product(SObject lineItem) {
      this.originalLineItem = lineItem;
      try {
        this.id = String.valueOf(lineItem.getSObject('PricebookEntry').get('Product2Id'));
        this.prod = findProduct();
        construct();
      } catch (Exception e) {
        throw new CPQ.CPQ_Exception('This does not appear to be an OpportunityLineItem or a QuoteLineItem');
      }
    }

    public CPQ_Product(SObject lineItem, String locale) {
      if (locale != null) {
        this.locale = locale;
      }
      this.originalLineItem = lineItem;
      try {
        this.id = String.valueOf(lineItem.getSObject('PricebookEntry').get('Product2Id'));
        this.prod = findProduct();
        construct();
      } catch (Exception e) {
        throw new CPQ.CPQ_Exception('This does not appear to be an OpportunityLineItem or a QuoteLineItem');
      }
    }

    private void construct() {
      setAttrs();
      setPrices();
    }

    private void setAttrs() {
      this.id = this.prod.Id;
      this.name = this.locale == 'fr'
        ? (this.prod.Name_FR__c == null || this.prod.Name_FR__c.length() == 0 ? this.prod.Name : this.prod.Name_FR__c)
        : this.prod.Name;
      this.make = this.prod.Make__c;
      this.recordTypeName = this.prod.RecordType.Name;
      this.family = this.prod.Family;
      this.image = this.prod.Default_Image_Thumb__c;
      this.taxable = this.prod.Taxable__c;
    }

    private Product2 findProduct() {
      return [
        SELECT
          Id,
          Name,
          Name_FR__c,
          RecordType.Name,
          Family,
          Make__c,
          Standard_Motor__c,
          Standard_Trailer__c,
          Standard_Trolling_Motor__c,
          Default_Image_Thumb__c,
          Taxable__c,
          (
            SELECT Id, UnitPrice, Pricebook2Id, IsActive
            FROM PricebookEntries
            WHERE Pricebook2Id IN :CPQ_Lib_dh.defaultPricebooks.values()
          )
        FROM Product2
        WHERE Id = :this.id
      ];
    }

    private void setPrices() {
      if (this.prod.pricebookEntries.size() == 0)
        throw new CPQ.CPQ_Exception(
          this.prod.Name + ' does not have an entry in the current Retail, Partner or Factory Pricebooks'
        );
      for (PricebookEntry pbe : this.prod.pricebookEntries) {
        if (CPQ_Lib_dh.defaultPricebooks.get('retail') == pbe.Pricebook2Id) {
          this.retailPrice = pbe.UnitPrice;
          this.retailPricebookEntryId = pbe.Id;
          this.retailPricebookEntryIsActive = pbe.IsActive;
        }
        if (CPQ_Lib_dh.defaultPricebooks.get('partner') == pbe.Pricebook2Id) {
          this.partnerPrice = pbe.UnitPrice;
          this.partnerPricebookEntryId = pbe.Id;
          this.partnerPricebookEntryIsActive = pbe.IsActive;
        }
        if (CPQ_Lib_dh.defaultPricebooks.get('factory') == pbe.Pricebook2Id) {
          this.factoryPrice = pbe.UnitPrice;
          this.factoryPricebookEntryId = pbe.Id;
          this.factoryPricebookEntryIsActive = pbe.IsActive;
        }
        if (CPQ_Lib_dh.defaultPricebooks.get('active') == pbe.Pricebook2Id) {
          this.activePrice = pbe.UnitPrice;
          this.activePricebookEntryId = pbe.Id;
          this.activePricebookEntryIsActive = pbe.IsActive;
        }
      }
    }
  }

  public virtual class Boat extends CPQ_Product {
    public String standardTrailerId;
    public String standardMotorId;
    public String standardTrollingMotorId;
    public List<Fee> fees;
    private String prov;

    public Boat(String prodId, String prov) {
      super(prodId);
      this.prov = prov;
      finishConstruction();
    }

    public Boat(String prodId, String prov, String locale) {
      super(prodId, locale);
      this.prov = prov;
      finishConstruction();
    }

    public Boat(SObject lineItem, String prov) {
      super(lineItem);
      this.prov = prov;
      finishConstruction();
    }

    public Boat(SObject lineItem, String prov, String locale) {
      super(lineItem, locale);
      this.prov = prov;
      finishConstruction();
    }

    private void finishConstruction() {
      this.standardMotorId = this.prod.Standard_Motor__c;
      this.standardTrailerId = this.prod.Standard_Trailer__c;
      this.standardTrollingMotorId = this.prod.Standard_Trolling_Motor__c;
      this.fees = CPQ.findAllFees(this.id, this.prov, this.locale);
    }

    public SObject[] createLineItems(String objectType) {
      List<SObject> result = new List<SObject>();
      SObject obj = Schema.getGlobalDescribe().get(objectType).newSObject();
      obj.put('Quantity', 1);
      obj.put('Description', 'Boat Package');
      obj.put('BoatBuilderItem__c', true);
      if (this.activePrice == null) {
        obj.put('UnitPrice', this.retailPrice);
        obj.put('PricebookEntryId', this.retailPricebookEntryId);
      } else {
        obj.put('UnitPrice', this.activePrice);
        obj.put('PricebookEntryId', this.activePricebookEntryId);
      }
      result.add(obj);
      for (CPQ_Lib_dh.Fee fee : this.fees) {
        result.add(fee.createLineItem(objectType));
      }
      return result;
    }
  }

  public virtual class UpgradeProduct extends CPQ_Product {
    public Decimal retailUpgradeCost { get; set; }
    public Decimal activeUpgradeCost { get; set; }
    public Decimal partnerUpgradeCost;
    public List<OptionProduct> options;
    public List<CPQ_Lib_dh.Fee> fees;

    public UpgradeProduct(String fromId, String toId, String activePricebookId, String prov) {
      super(toId);
      this.fees = CPQ.findAllFees(this.id, prov, this.locale);
      if (!setUpgradeCosts(fromId, toId))
        setUpgradeCostFromPUCs(findProductUpgradeCosts(fromId, toId));
      this.options = CPQ.fetchAllOptions(toId, activePricebookId);
    }

    public UpgradeProduct(String fromId, Product2 toProd, Product_Upgrade_Cost__c[] pucs, String prov) {
      super(toProd);
      this.fees = CPQ.findAllFees(this.id, prov, this.locale);
      if (!setUpgradeCosts(fromId, toProd.Id)) {
        setUpgradeCostFromPUCs(pucs);
      }
    }

    public UpgradeProduct(String fromId, String toId, String activePricebookId, String prov, String locale) {
      super(toId, locale);
      this.fees = CPQ.findAllFees(this.id, prov, this.locale);
      if (!setUpgradeCosts(fromId, toId))
        setUpgradeCostFromPUCs(findProductUpgradeCosts(fromId, toId));
      this.options = CPQ.fetchAllOptions(toId, activePricebookId);
    }

    public UpgradeProduct(String fromId, Product2 toProd, Product_Upgrade_Cost__c[] pucs, String prov, String locale) {
      super(toProd, locale);
      this.fees = CPQ.findAllFees(this.id, prov, this.locale);
      if (!setUpgradeCosts(fromId, toProd.Id)) {
        setUpgradeCostFromPUCs(pucs);
      }
    }

    public SObject[] createLineItems(String objectType, String description) {
      List<SObject> result = new List<SObject>();
      SObject obj = Schema.getGlobalDescribe().get(objectType).newSObject();
      obj.put('Quantity', 1);
      obj.put('Description', description);
      obj.put('BoatBuilderItem__c', true);
      if (this.activePrice == null) {
        obj.put('UnitPrice', this.retailUpgradeCost);
        obj.put('PricebookEntryId', this.retailPricebookEntryId);
      } else {
        obj.put('UnitPrice', this.activeUpgradeCost);
        obj.put('PricebookEntryId', this.activePricebookEntryId);
      }
      result.add(obj);
      if (this.fees.size() > 0) {
        for (CPQ_Lib_dh.Fee fee : this.fees) {
          result.add(fee.createLineItem(objectType));
        }
      }
      return result;
    }

    private Boolean setUpgradeCosts(String fromId, String toId) {
      this.retailUpgradeCost = null;
      this.partnerUpgradeCost = null;
      this.activeUpgradeCost = null;
      if (fromId == toId) {
        this.retailUpgradeCost = 0;
        this.partnerUpgradeCost = 0;
        this.activeUpgradeCost = 0;
        return true;
      }
      if (fromId == null) {
        this.retailUpgradeCost = this.retailPrice;
        this.partnerUpgradeCost = this.partnerPrice;
        this.activeUpgradeCost = this.activePrice;
        return true;
      }
      return false;
    }

    private Product_Upgrade_Cost__c[] findProductUpgradeCosts(String fromId, String toId) {
      return [
        SELECT Id, Cost__c, Price_book__c
        FROM Product_Upgrade_Cost__c
        WHERE
          Price_Book__c IN :CPQ_Lib_dh.defaultPricebooks.values()
          AND Product_Upgrade__r.From_Product__c = :fromId
          AND Product_Upgrade__r.To_Product__c = :toId
      ];
    }

    private void setUpgradeCostFromPUCs(Product_Upgrade_Cost__c[] pucs) {
      if (pucs == null) {
        throw new CPQ.CPQ_Exception('No pricing information can be found in pricebook or upgrade');
      }
      this.retailUpgradeCost = 0;
      this.partnerUpgradeCost = 0;
      this.activeUpgradeCost = 0;
      for (Product_Upgrade_Cost__c puc : pucs) {
        if (puc.Price_Book__c == CPQ_Lib_dh.defaultPricebooks.get('retail') && puc.Cost__c != null) {
          this.retailUpgradeCost = puc.Cost__c;
        }
        if (CPQ_Lib_dh.defaultPricebooks.containsKey('active')) {
          if (puc.Price_Book__c == CPQ_Lib_dh.defaultPricebooks.get('active') && puc.Cost__c != null)
            this.activeUpgradeCost = puc.Cost__c;
        }
        if (puc.Price_Book__c == CPQ_Lib_dh.defaultPricebooks.get('partner') && puc.Cost__c != null) {
          this.partnerUpgradeCost = puc.Cost__c;
        }
      }
    }
  }

  public virtual class OptionProduct extends CPQ_Product {
    public String uniqueId;
    public Boolean isSubOption;
    public String parentProductId;
    public Decimal standard;
    public Decimal maximum;
    public Boolean isCheckbox;
    public Boolean isSelected;
    public Decimal quantitySelected { get; set; }
    public List<CPQ_Lib_dh.OptionProduct> subOptions;
    public List<CPQ_Lib_dh.OptionProduct> selectedSubOptions;
    public List<String> premiumPackage;

    public OptionProduct(Product2 prod, String parentProductId, Decimal std, Decimal max) {
      super(prod);
      System.debug('Option Constructor');
      this.parentProductId = parentProductId;
      this.standard = std;
      this.maximum = max;
      setRemainingAttrs();
    }

    public OptionProduct(Product2 prod, String parentProductId, Decimal std, Decimal max, String locale) {
      super(prod, locale);
      this.parentProductId = parentProductId;
      this.standard = std;
      this.maximum = max;
      setRemainingAttrs();
    }

    public OptionProduct(SObject lineItem) {
      super((Sobject)lineItem);
      this.parentProductId = (String)lineItem.get('ParentProductId__c');
    }

    public void buildPremiumPackageDetails() {
      for (Product_Feature_Map__c pfm : [
        SELECT Id, Feature_Id__r.Description__c, Feature_Id__r.description_fr__c
        FROM Product_Feature_Map__c
        WHERE Product_Id__c = :this.id
      ]) {
        String feature = this.locale == 'fr' &&
          pfm.Feature_Id__r.description_fr__c != null
          ? pfm.Feature_Id__r.description_fr__c
          : pfm.Feature_Id__r.Description__c;
        this.premiumPackage.add(feature);
      }
    }

    private void setRemainingAttrs() {
      this.isSubOption = false;
      this.uniqueId = this.id + this.parentProductId;
      this.isCheckbox = this.maximum == 1;
      this.isSelected = this.standard > 0;
      this.quantitySelected = this.standard;
      this.subOptions = new List<CPQ_Lib_dh.SubOptionProduct>();
      this.selectedSubOptions = new List<CPQ_Lib_dh.SubOptionProduct>();
      this.premiumPackage = new List<String>();
      if (this.family == 'Premium Package') {
        buildPremiumPackageDetails();
      }
    }
  }

  public virtual class WarrantyOptionProduct extends OptionProduct{
    public String cpqListName;
    public WarrantyOptionProduct(Product2 prod, Product2 parentProduct, Decimal std, Decimal max){
      super(prod, parentProduct.Id,std, max);
      this.cpqListName ='warrantyOptions';
    }

    public WarrantyOptionProduct(QuoteLineItem lineItem)
    {
      super((SObject) lineItem);
      this.cpqListName = 'warrantyOptions';
      this.quantitySelected = lineItem.Quantity;
    }

    public SObject createLineItem(String objectType) {
      SObject obj = Schema.getGlobalDescribe().get(objectType).newSObject();
      obj.put('Quantity', this.quantitySelected);
      obj.put('UnitPrice', this.retailPrice);
      obj.put('PricebookEntryId', this.retailPricebookEntryId);
      obj.put('BoatBuilderItem__c', true);
      obj.put('ParentProductId__c', this.parentProductId);
      return obj;
    }

  }

  public virtual class MaintenanceServicePlanOptionProduct extends OptionProduct{
    public Boolean isPrepayable;
    public Boolean isPrepaid;
    public String cpqListName;
    public MaintenanceServicePlanOptionProduct(Product2 prod, Product2 parentProduct, Decimal std, Decimal max){
      super(prod, parentProduct.Id, std, max);
      init();
    }

    public MaintenanceServicePlanOptionProduct(QuoteLineItem lineItem)
    {
      super((SObject) lineItem);
      this.cpqListName = 'maintenanceServicePlanOptions';
      this.isPrepayable = lineItem.PricebookEntry.Product2.isPrepayable__c;
      this.isPrepaid = lineItem.IsPrepaid__c;
      this.quantitySelected = lineItem.Quantity;

    }

    private void init(){
      this.isPrepayable = this.prod.isPrepayable__c;
      this.isPrepaid = false;
      this.cpqListName = 'maintenanceServicePlanOptions';
    }

    public SObject createLineItem(String objectType) {
      SObject obj = Schema.getGlobalDescribe().get(objectType).newSObject();
      obj.put('Quantity', this.quantitySelected);
      obj.put('UnitPrice', this.retailPrice);
      obj.put('PricebookEntryId', this.retailPricebookEntryId);
      obj.put('BoatBuilderItem__c', true);
      obj.put('IsPrepaid__c', this.isPrepaid);
      obj.put('ParentProductId__c', this.parentProductId);
      return obj;
    }
  }

//  public virtual class ServiceAndWarrantyProduct extends OptionProduct {
//    public Boolean isPrepayable;
//    public Boolean isPrepaid;
//
//    public ServiceAndWarrantyProduct(Product2 prod, String parentProductId, Decimal std, Decimal max){
//      super(prod, parentProductId,std, max);
//      this.isPrepayable = prod.isPrepayable__c;
//    }
//
//    public ServiceAndWarrantyProduct(Product2 prod, String parentProductId, Decimal std, Decimal max, String locale){
//      super(prod, parentProductId,std, max, locale);
//      this.isPrepayable = prod.isPrepayable__c;
//    }
//
//  }



  public virtual class InsuranceProduct extends CPQ_Product {
    public String coverage { get; set; }
    public String type { get; set; }
    public Decimal insuranceRate { get; set; }
    public Boolean isResidual { get; set; }
    public Decimal unitPrice { get; set; }

    public InsuranceProduct(OpportunityLineItem lineItem){
      super((SObject)lineItem);
      this.coverage = lineItem.InsuranceCoverage__c;
      this.insuranceRate = lineItem.Insurance_Rate__c;
      this.unitPrice = lineItem.UnitPrice;
      this.isResidual = lineItem.PricebookEntry.Product2.Is_Residual_Insurance__c;
      this.type = lineItem.PricebookEntry.Product2.Family;
    }

    public InsuranceProduct(QuoteLineItem lineItem){
      super((SObject)lineItem);
      this.coverage = lineItem.InsuranceCoverage__c;
      this.insuranceRate = lineItem.Insurance_Rate__c;
      this.unitPrice = lineItem.UnitPrice;
      this.isResidual = lineItem.PricebookEntry.Product2.Is_Residual_Insurance__c;
      this.type = lineItem.PricebookEntry.Product2.Family;
    }
    public InsuranceProduct(AcctSeedERP__Material__c lineItem){
      super((SObject)lineItem);
      this.coverage = lineItem.Insurance_Coverage__c;
      this.insuranceRate = lineItem.Insurance_Rate__c;
      this.unitPrice = lineItem.GMBLASERP__Unit_Price__c;
      this.isResidual = lineItem.AcctSeedERP__Product__r.Is_Residual_Insurance__c;
      this.type = lineItem.AcctSeedERP__Product__r.Family;
    }

    public SObject createLineItem(String objectType) {
      SObject obj = Schema.getGlobalDescribe().get(objectType).newSObject();
      obj.put('Quantity', 1);
      obj.put('UnitPrice', this.unitPrice);
      obj.put('PricebookEntryId', this.activePricebookEntryId);
      obj.put('BoatBuilderItem__c', true);
      obj.put('isInsurance__c', true);
      obj.put('InsuranceCoverage__c', this.coverage);
      obj.put('Insurance_Rate__c', this.insuranceRate);
      return obj;
    }

  }

  public virtual class SubOptionProduct extends OptionProduct {
    public SubOptionProduct(Product2 prod, String parentProductId, Decimal std, Decimal max) {
      super(prod, parentProductId, std, max);
      this.isSubOption = true;
    }

    //public override OpportunityLineItem[] createOppyLineItems( String oppId )
    //{
    //  return super.createOppyLineItems( oppId );
    //}
  }

  public virtual class Fee {
    public Decimal retailAmount { get; set; }
    public Decimal activeAmount { get; set; }
    //public String retailPricebookEntryId;
    public Decimal partnerAmount;
    //public String partnerPricebookEntryId;
    public String feeName { get; set; }
    public String feeProductId;
    public Boolean taxable;

    public Fee() {
      this.retailAmount = 0;
      this.partnerAmount = 0;
    }

    public SObject createLineItem(String objectType) {
      try {
        Id pbId = CPQ_Lib_dh.defaultPricebooks.containsKey('active')
          ? CPQ_Lib_dh.defaultPricebooks.get('active')
          : CPQ_Lib_dh.defaultPricebooks.get('retail');
        PricebookEntry pbe = [
          SELECT Id
          FROM PricebookEntry
          WHERE Product2Id = :this.feeProductId AND Pricebook2Id = :pbId
        ];
        Decimal price = this.activeAmount == null ? this.retailAmount : this.activeAmount;
        SObject obj = Schema.getGlobalDescribe().get(objectType).newSObject();
        obj.put('Quantity', 1);
        obj.put('UnitPrice', price);
        obj.put('PricebookEntryId', pbe.Id);
        obj.put('BoatBuilderItem__c', true);
        return obj;
      } catch (Exception e) {
        throw new CPQ.CPQ_Exception(e.getMessage());
      }
    }
  }

  public virtual class AdditionalAccessory {
    public Id id;
    public Decimal quantity {get; set;}
    public Decimal salePrice {get; set;}
    public Decimal retailPrice;
    public Id productId;
    public Id pricebookEntryId;
    public String productName { get; set;}
    public Boolean isTaxable { get; set; }

    public AdditionalAccessory(){}

    public AdditionalAccessory( QuoteLineItem qli ){
      this.quantity = qli.Quantity;
      this.id = qli.Id;
      this.salePrice = qli.UnitPrice;
      this.retailPrice = qli.PricebookEntry.UnitPrice;
      this.productId = qli.PricebookEntry.Product2Id;
      this.productName = qli.PricebookEntry.Product2.Name;
      this.pricebookEntryId = qli.PricebookEntryId;
      this.isTaxable = qli.PricebookEntry.Product2.Taxable__c;

    }

    public SObject createLineItem(String objectType) {
      SObject obj = Schema.getGlobalDescribe().get(objectType).newSObject();
      obj.put('Quantity', this.quantity);
      obj.put('UnitPrice', this.salePrice);
      obj.put('PricebookEntryId', this.pricebookEntryId);
      obj.put('BoatBuilderItem__c', true);
      return obj;
    }


  }

  public virtual class CustomProduct {
    public String id;
    public Id productId;
    public String description { get; set; }
    public Decimal amount { get; set; }
    public Decimal cost { get; set; }
    public Decimal quantity { get; set; }

    public CustomProduct() {
      this.id = LGND_Utilities.generateRandomString(18);
      this.productId = LGND_Constants.partnerCustomProductId;
    }

    public CustomProduct(OpportunityLineItem oli) {
      this.id = oli.Id;
      this.productId = oli.PricebookEntry.Product2Id;
      this.description = oli.Description;
      this.quantity = oli.Quantity;
      this.amount = oli.UnitPrice;
    }

    public CustomProduct(QuoteLineItem qli) {
      this.id = qli.Id;
      this.productId = qli.PricebookEntry.Product2Id;
      this.description = qli.Description;
      this.quantity = qli.Quantity;
      this.amount = qli.UnitPrice;
    }

    public SObject createLineItem(String objectType) {
      try {
        PricebookEntry pb = [
          SELECT Id
          FROM PricebookEntry
          WHERE Product2Id = :this.productId AND Pricebook2Id = :CPQ_Lib_dh.defaultPricebooks.get('retail')
        ];
        SObject obj = Schema.getGlobalDescribe().get(objectType).newSObject();
        obj.put('Quantity', this.quantity);
        obj.put('UnitPrice', this.amount);
        obj.put('Description', this.description);
        obj.put('PricebookEntryId', pb.Id);
        return obj;
      } catch (Exception e) {
        throw new CPQ.CPQ_Exception(e.getMessage());
      }
    }
  }

  public virtual class SavingsLine {
    public String id;
    public Id productId;
    public String description { get; set; }
    public Decimal amount { get; set; }

    public SavingsLine() {
      this.id = LGND_Utilities.generateRandomString(18);
      this.productId = LGND_Constants.savingsProductId;
    }

    public SavingsLine(OpportunityLineItem oli) {
      this.id = oli.Id;
      this.description = oli.Description;
      this.productId = oli.PricebookEntry.Product2Id;
      this.amount = oli.UnitPrice;
    }

    public SavingsLine(QuoteLineItem qli) {
      this.id = qli.Id;
      this.description = qli.Description;
      this.productId = qli.PricebookEntry.Product2Id;
      this.amount = qli.UnitPrice;
    }

    public SObject createLineItem(String objectType) {
      try {
        PricebookEntry pb = [
          SELECT Id, Product2.Name
          FROM PricebookEntry
          WHERE Product2Id = :this.productId AND Pricebook2Id = :CPQ_Lib_dh.defaultPricebooks.get('retail')
        ];
        SObject obj = Schema.getGlobalDescribe().get(objectType).newSObject();
        obj.put('Quantity', 1);
        obj.put('UnitPrice', this.amount);
        obj.put('Description', this.description);
        obj.put('PricebookEntryId', pb.Id);
        obj.put('BoatBuilderItem__c', true);
        return obj;
      } catch (Exception e) {
        throw new CPQ.CPQ_Exception(e.getMessage());
      }
    }
  }

  public class OptionsWrapper implements Comparable {
    public String family;
    public Integer count;
    public List<CPQ_Lib_dh.OptionProduct> items;
    public OptionsWrapper() {
    }

    public Integer compareTo(Object compareTo) {
      OptionsWrapper compareOW = (OptionsWrapper) compareTo;
      if (family == compareOW.family)
        return 0;
      if (family > compareOW.family)
        return 1;
      return -1;
    }
  }

  public virtual class TradeIn {
    public Decimal value { get; set; }
    public Decimal lien { get; set; }
    public String id;
    public List<TradeInItem> items { get; set; }

    public TradeIn() {
      this.value = 0;
      this.lien = 0;
      this.items = new List<TradeInItem>();
    }

    public TradeIn(Trade_In_Record__c tr) {
      this.lien = tr.Lien_Amount__c;
      this.value = tr.Total_Value__c;
      this.items = new List<TradeInItem>();
      this.id = tr.Id;
      for (Trade_In_Item__c tii : tr.Trade_In_Items__r) {
        this.items.add(new TradeInItem(tii));
      }
    }

    public void save(String recordId) {
      if (this.items.size() == 0)
        return;
      String sObjectType = LGND_Utilities.sObjectNameFromId(recordId);
      switch on sObjectType {
        when 'Quote' {
          saveToQuote(recordId);
        }
        when 'Opportunity' {
          saveToOpp(recordId);
        }
        when else {
          throw new CPQ.CPQ_Exception(
            'Can only create a Trade In Record for either a Quote or an Opportunity.  An Id of sObject type ' +
            sObjectType +
            ' was supplied'
          );
        }
      }
    }

    private void saveToOpp(Id recordId) {
      Trade_In_Record__c tr = new Trade_In_Record__c(
        Lien_Amount__c = this.lien,
        Total_Value__c = this.value,
        Opportunity__c = recordId
      );
      insert tr;
      this.saveLineItems(tr.Id);
    }

    private void saveToQuote(Id recordId) {
      Quote q = [SELECT Id, OpportunityId, IsSyncing FROM Quote WHERE Id = :recordId];
      Trade_In_Record__c tr = new Trade_In_Record__c(
        Id = this.id,
        Lien_Amount__c = this.lien,
        Total_Value__c = this.value,
        Quote__c = recordId,
        Opportunity__c = q.OpportunityId,
        IsSyncing__c = q.IsSyncing
      );
      upsert tr;
      saveLineItems(tr.Id);
    }

    private void saveLineItems(Id tradeId) {
      List<Trade_In_Item__c> ti_items = new List<Trade_In_Item__c>();
      for (TradeInItem item : this.items) {
        ti_items.add(
          new Trade_In_Item__c(
            Id = item.Id,
            Trade_In_Record__c = tradeId,
            Make__c = item.manufacturer,
            Model__c = item.model,
            Model_Year__c = String.valueOf(item.modelYear),
            Serial_Number__c = item.serialNumber
          )
        );
      }
      upsert ti_items;
    }
  }

  public virtual class TradeInItem {
    public String id;
    public Integer modelYear { get; set; }
    public String manufacturer { get; set; }
    public String model { get; set; }
    public String serialNumber { get; set; }

    public TradeInItem() {
    }

    public TradeInItem(Trade_In_Item__c tii) {
      this.id = tii.Id;
      this.modelYear = Integer.valueOf(tii.Model_Year__c);
      this.model = tii.Model__c;
      this.manufacturer = tii.Make__c;
      this.serialNumber = tii.Serial_Number__c;
    }
  }

  public virtual class SaleLineItem {
    public Decimal quantity { get; set; }
    public Decimal salePrice { get; set; }
    public Decimal partnerPrice { get; set; }
    public String lineItemId;
    public String productName { get; set; }
    public String productId;
    public String pricebookEntryId;
    public String parentProductId;
    public Decimal lineTotal { get; set; }
    public Boolean taxable;
    public List<SaleLineItem> subSaleItems { get; set; }
    public List<String> premiumPackage { get; set; }
    public String locale = 'en_US';

    public SaleLineItem() {
    }

    public SaleLineItem(OptionProduct op) {
      this.quantity = op.quantitySelected;
      this.salePrice = op.standard == op.quantitySelected ? 0 : op.retailPrice;
      this.partnerPrice = op.partnerPrice;
      this.lineItemId = null;
      this.productId = op.prod.Id;
      this.productName = op.prod.Name;
      this.taxable = op.taxable;
      this.pricebookEntryId = op.retailPricebookEntryId;
      this.parentProductId = op.parentProductId;
      this.subSaleItems = new List<SaleLineItem>();
      this.premiumPackage = new List<String>();
      if (op.prod.Family == 'Premium Package') {
        buildPremiumPackageDetails();
        this.salePrice = op.retailPrice;
      }
      this.lineTotal = this.quantity * this.salePrice;
    }

//    public SaleLineItem( AdditionalAccessory acc ){
//      this.quantity = acc.quantity;
//      this.salePrice = acc.salePrice;
//      this.partnerPrice = acc.partnerPrice;
//      this.lineItemId = null;
//      this.productId = acc.id;
//      this.productName = acc.name;
//      this.taxable = acc.taxable;
//      this.pricebookEntryId = acc.retailPricebookEntryId;
//      this.subSaleItems = new List<SaleLineItem>();
//      this.premiumPackage = new List<String>();
//      this.lineTotal = this.quantity * this.salePrice;
//    }

    public SaleLineItem(OpportunityLineItem oli) {
      setAttrs(oli);
    }

    public SaleLineItem(OpportunityLineItem oli, String locale) {
      if (locale != null) {
        this.locale = locale;
      }
      setAttrs(oli);
    }

    public SaleLineItem(QuoteLineItem qli) {
      setAttrs(qli);
    }

    public SaleLineItem(QuoteLineItem qli, String locale) {
      if (locale != null) {
        this.locale = locale;
      }
      setAttrs(qli);
    }

    public void buildPremiumPackageDetails() {
      for (Product_Feature_Map__c pfm : [
        SELECT Id, Feature_Id__r.Description__c, Feature_Id__r.description_fr__c
        FROM Product_Feature_Map__c
        WHERE Product_Id__c = :this.productId
      ]) {
        String feature = this.locale == 'fr' &&
          pfm.Feature_Id__r.description_fr__c != null
          ? pfm.Feature_Id__r.description_fr__c
          : pfm.Feature_Id__r.Description__c;
        this.premiumPackage.add(feature);
      }
    }

    public SObject createLineItem(String objectType) {
      SObject obj = Schema.getGlobalDescribe().get(objectType).newSObject();
      obj.put('ParentProductId__c', this.parentProductId);
      obj.put('Quantity', this.quantity);
      obj.put('UnitPrice', this.salePrice);
      obj.put('Description', this.salePrice == 0 ? 'Included' : '');
      obj.put('PricebookEntryId', this.pricebookEntryId);
      obj.put('BoatBuilderItem__c', true);
      return obj;
    }

    private void setAttrs(QuoteLineItem qli) {
      this.quantity = qli.Quantity;
      this.salePrice = qli.UnitPrice;
      this.lineItemId = qli.Id;
      this.taxable = qli.Taxable_Provincial__c;
      this.productId = qli.PricebookEntry.Product2Id;
      this.productName = this.locale == 'fr' &&
        qli.PricebookEntry.Product2.Name_FR__c != null
        ? qli.PricebookEntry.Product2.Name_FR__c
        : qli.PricebookEntry.Product2.Name;
      this.pricebookEntryId = qli.PricebookEntryId;
      this.parentProductId = qli.ParentProductId__c;
      this.subSaleItems = new List<SaleLineItem>();
      this.lineTotal = this.quantity * this.salePrice;
      this.premiumPackage = new List<String>();
      if (qli.PricebookEntry.Product2.Family == 'Premium Package') {
        buildPremiumPackageDetails();
      }
    }

    private void setAttrs(OpportunityLineItem oli) {
      this.quantity = oli.Quantity;
      this.salePrice = oli.UnitPrice;
      this.lineItemId = oli.Id;
      this.productId = oli.PricebookEntry.Product2Id;
      this.productName = this.locale == 'fr' &&
        oli.PricebookEntry.Product2.Name_FR__c != null
        ? oli.PricebookEntry.Product2.Name_FR__c
        : oli.PricebookEntry.Product2.Name;
      this.pricebookEntryId = oli.PricebookEntryId;
      this.parentProductId = oli.ParentProductId__c;
      this.taxable = oli.Taxable_Provincial__c;
      this.subSaleItems = new List<SaleLineItem>();
      this.lineTotal = this.quantity * this.salePrice;
      this.premiumPackage = new List<String>();
      if (oli.PricebookEntry.Product2.Family == 'Premium Package') {
        buildPremiumPackageDetails();
      }
    }
  }

  /*************************************************************************/
  /*****   OPTION WRAPPER CLASS *****/
  /*************************************************************************/

  public class OptionWrapper {
    public String productId { get; set; }
    public String pricebookEntryId { get; set; }
    public String productName { get; set; }
    public String parentProductId { get; set; }
    public String lineId { get; set; }
    public Decimal unitCost { get; set; }
    public Boolean isSelected { get; set; }
    public Boolean isCheckbox { get; set; }
    public Boolean isPrepayable { get; set; }
    public Boolean isPrepaid { get; set; }
    public Decimal standard { get; set; }
    public Decimal maximum { get; set; }
    public Decimal quantitySelected { get; set; }
    public List<CPQ_Lib_dh.OptionWrapper> subOptions { get; set; }

    public OptionWrapper(PricebookEntry pbe, Decimal standard, Decimal maximum) {
      this.productId = pbe.Product2Id;
      this.productName = pbe.Product2.Name;
      this.unitCost = pbe.UnitPrice;
      this.pricebookEntryId = pbe.Id;
      this.standard = standard;
      this.maximum = maximum;
      this.quantitySelected = standard;
      this.isSelected = this.quantitySelected > 0;
      this.isCheckbox = (maximum == 1);
      this.isPrepayable = pbe.Product2.isPrepayable__c;
      this.subOptions = new List<CPQ_Lib_dh.OptionWrapper>();
    }

    public OptionWrapper(PricebookEntry pbe, Decimal standard, Decimal maximum, Boolean isPrepaid) {
      this.productId = pbe.Product2Id;
      this.productName = pbe.Product2.Name;
      this.unitCost = pbe.UnitPrice;
      this.pricebookEntryId = pbe.Id;
      this.standard = standard;
      this.maximum = maximum;
      this.quantitySelected = standard;
      this.isSelected = this.quantitySelected > 0;
      this.isCheckbox = (maximum == 1);
      this.isPrepayable = pbe.Product2.isPrepayable__c;
      this.isPrepaid = isPrepaid;
      this.subOptions = new List<CPQ_Lib_dh.OptionWrapper>();
    }
  }
}
