/**
 * Created by dave on 2020-05-12.
 */
@IsTest
public with sharing class Factory_Boat {
  public static final Decimal BOAT_PRICE = 30000;
  public static final Decimal UPGRADE_PRICE = 1000;
  public static final Decimal UPGRADE_COST = 100;
  public static final Decimal OPTION_PRICE = 100;
  public static final Decimal FEE_AMOUNT = 500;
  public static final Decimal PREMIUM_PACKAGE_PRICE = 5000;
  public static final List<Schema.PickListEntry> FEATURE_CATEGORIES = Feature__c.Category__c.getDescribe()
    .getPicklistValues();
  public static final Integer FEATURE_COUNT = 3;
  public static final List<String> PART_FAMILIES = new List<String>{ 'Hardware', 'Saftey', 'Canvas' };
  public Product2 boat;
  public Product2 standardTrailer;
  public Product2 standardMotor;
  public Product2 standardTrollingMotor;
  public Product2 premiumPackage;

  private PricebookEntry[] stdPbEntries = new List<PricebookEntry>();
  private PricebookEntry[] pbEntries = new List<PricebookEntry>();
  private Product2[] motors;
  private Product2[] trailers;
  private Product2[] trollingMotors;
  private Product_Option__c[] options = new List<Product_Option__c>();
  private Marketing_Content__c[] marketingContents = new List<Marketing_Content__c>();
  private AcctSeed__Product_Part__c[] productParts = new List<AcctSeed__Product_Part__c>();
  private Product2[] feeProducts;
  private Id pricebookId;

  public Factory_Boat(String family, Id pricebookId) {
    this.pricebookId = pricebookId;
    this.boat = Factory_Product.createSerializedProducts_AvailableOnline('Boat', family, 1)[0];
    addPricebookEntries(boat.Id, BOAT_PRICE);
  }

  public Factory_Boat(String family, Id pricebookId, String series) {
    this.pricebookId = pricebookId;
    this.boat = Factory_Product.createSerializedProducts_AvailableOnline('Boat', family, 1, series)[0];
    addPricebookEntries(boat.Id, BOAT_PRICE);
  }

  public Id getPricebookEntry(Id productId) {
    for (PricebookEntry pb : this.pbEntries) {
      if (pb.Product2Id == productId) {
        return pb.Id;
      }
    }
    return null;
  }

  public Factory_Boat addStandardProducts(List<Map<String, String>> rt_family_map) {
    for (Map<String, String> rt_family : rt_family_map) {
      addStandardProduct(rt_family.get('recordTypeName'), rt_family.get('family'));
    }
    update this.boat;
    return this;
  }

  public Factory_Boat addMotorUpgrades(Integer count) {
    this.motors = addUpgrades('Motor', 'Remote', count);
    return this;
  }

  public Factory_Boat addTrailerUpgrades(Integer count) {
    this.trailers = addUpgrades('Trailer', 'Boat Trailer', count);
    return this;
  }

  public Factory_Boat addTrollingMotorUpgrades(Integer count) {
    this.trollingMotors = addUpgrades('Trolling Motor', 'Hardware', count);
    return this;
  }

  public Factory_Boat addPremiumPackage() {
    this.premiumPackage = Factory_Product.createNonSerializedProduct('Part', 'Premium Package');
    addPricebookEntries(this.premiumPackage.Id, PREMIUM_PACKAGE_PRICE);
    Factory_ProductFeature.createAllFeatures(this.premiumPackage.Id, FEATURE_COUNT);
    options.add(Factory_ProductOption.buildProductOption(this.boat.Id, this.premiumPackage.Id, 1, 1, true));
    return this;
  }

  public Factory_Boat addOptions() {
    List<Product2> parts = new List<Product2>();
    for (String family : PART_FAMILIES) {
      for (Integer i = 0; i < 15; i++) {
        parts.add(Factory_Product.buildNonSerializedProduct('Part', family));
      }
    }
    insert parts;
    addPricebookEntries(parts, OPTION_PRICE);

    Map<String, Set<Id>> boatFilter = new Map<String, Set<Id>>();
    Map<String, Set<Id>> motorFilter = new Map<String, Set<Id>>();
    Map<String, Set<Id>> trailerFilter = new Map<String, Set<Id>>();

    for (Product2 part : parts) {
      Id parentId = this.boat.Id;
      Boolean availableOnline = false;
      if (!boatFilter.containsKey(part.Family))
        boatFilter.put(part.Family, new Set<Id>());
      if (!motorFilter.containsKey(part.Family))
        motorFilter.put(part.Family, new Set<Id>());
      if (!trailerFilter.containsKey(part.Family))
        trailerFilter.put(part.Family, new Set<Id>());

      if (boatFilter.get(part.Family).size() == 0) {
        boatFilter.get(part.Family).add(part.Id);
        parentId = this.boat.Id;
        availableOnline = true;
        for (Product2 pp : Factory_Product.createNonSerializedProducts('Part', 'Hardware', 3)) {
          addPricebookEntries(pp.Id, 0);
          productParts.add(
            new AcctSeed__Product_Part__c(
              AcctSeed__Product__c = part.Id,
              AcctSeed__Product_Part__c = pp.Id,
              AcctSeed__Quantity__c = 1
            )
          );
        }
      } else if (motorFilter.get(part.Family).size() == 0) {
        motorFilter.get(part.Family).add(part.Id);
        parentId = this.standardMotor.Id;
        availableOnline = true;
      } else if (motorFilter.get(part.Family).size() == 1) {
        motorFilter.get(part.Family).add(part.Id);
        parentId = this.motors[0].Id;
        availableOnline = true;
      } else if (trailerFilter.get(part.Family).size() == 0) {
        trailerFilter.get(part.Family).add(part.Id);
        parentId = this.standardTrailer.Id;
        availableOnline = true;
      }
      options.add(Factory_ProductOption.buildProductOption(parentId, part.Id, 0, 2, availableOnline));
    }
    return this;
  }

  public Factory_Boat addAdditionalFees(Id parentProductId) {
    List<Product_Fee_Map__c> feeMaps = new List<Product_Fee_Map__c>();
    List<Product_Fee_Amount__c> feeAmounts = new List<Product_Fee_Amount__c>();
    if (this.feeProducts == null)
      insertFeeProducts();
    for (Product2 fee : this.feeProducts) {
      feeMaps.add(new Product_Fee_Map__c(Parent_Product__c = parentProductId, Fee_Product__c = fee.Id));
    }
    insert feeMaps;
    for (Product2 fee : this.feeProducts) {
      for (Schema.PickListEntry prov : Product_Fee_Amount__c.Province__c.getDescribe().getPicklistValues()) {
        feeAmounts.add(
          new Product_Fee_Amount__c(
            Fee_Product__c = fee.Id,
            Amount__c = FEE_AMOUNT,
            Price_Book__c = this.pricebookId,
            Province__c = prov.getLabel()
          )
        );
      }
    }
    insert feeAmounts;
    return this;
  }

  public Factory_Boat addMarketingContent(Id parentProductId, Integer count) {
    for (Integer i = 0; i < count; i++) {
      this.marketingContents.add(
        new Marketing_Content__c(
          Product__c = parentProductId,
          Label__c = 'Label ' + String.valueOf(i),
          Content__c = 'This is the Contents - ' + String.valueOf(i)
        )
      );
    }
    return this;
  }

  public Factory_Boat addMarketingContentImage(Id parentProductId) {
    this.marketingContents.add(
      new Marketing_Content__c(
        Product__c = parentProductId,
        Label__c = 'images',
        Content__c = 'backLeft:backleft-image-url|backRight:backright-image-url'
      )
    );
    return this;
  }

  public Factory_Boat finish() {
    insert this.stdPbEntries;
    insert this.pbEntries;
    insert this.options;
    insert this.productParts;
    insert marketingContents;
    return this;
  }

  private void addPricebookEntries(Id prodId, Decimal cost) {
    this.stdPbEntries.add(Factory_PricebookEntry.buildEntry(prodId, Test.getStandardPricebookId(), cost));
    this.pbEntries.add(Factory_PricebookEntry.buildEntry(prodId, this.pricebookId, cost));
  }

  private void addPricebookEntries(Product2[] prods, Decimal cost) {
    stdPbEntries.addAll(Factory_PricebookEntry.buildEntries(prods, Test.getStandardPricebookId(), cost));
    pbEntries.addAll(Factory_PricebookEntry.buildEntries(prods, this.pricebookId, cost));
  }

  private List<Product2> addUpgrades(String recordTypeName, String family, Integer count) {
    Id stdId = standardIdByRecordTypeName(recordTypeName);
    List<Product2> upgrades = Factory_Product.createSerializedProducts(recordTypeName, family, count);
    addPricebookEntries(upgrades, UPGRADE_PRICE);
    for (Integer i = 0; i < upgrades.size(); i++) {
      options.add(Factory_ProductOption.buildProductOption(this.boat.Id, upgrades[i].Id, 0, 1, i < 2));
    }

    Factory_ProductUpgrade.createUpgradesWithCostInPricebook(stdId, upgrades, this.pricebookId, UPGRADE_COST);

    return upgrades;
  }

  private Id standardIdByRecordTypeName(String recordTypeName) {
    switch on recordTypeName {
      when 'Motor' {
        return this.standardMotor != null ? this.standardMotor.Id : null;
      }
      when 'Trailer' {
        return this.standardTrailer != null ? this.standardTrailer.Id : null;
      }
      when 'Trolling Motor' {
        return this.standardTrollingMotor != null ? this.standardTrollingMotor.Id : null;
      }
      when else {
        return null;
      }
    }
  }

  private void addStandardProduct(String recordTypeName, String family) {
    Product2 stdProd = Factory_Product.createSerializedProduct(recordTypeName, family);
    addPricebookEntries(stdProd.Id, UPGRADE_COST);
    switch on recordTypeName {
      when 'Motor' {
        this.standardMotor = stdProd;
        this.boat.Standard_Motor__c = stdProd.Id;
      }
      when 'Trailer' {
        this.standardTrailer = stdProd;
        this.boat.Standard_Trailer__c = stdProd.Id;
      }
      when 'Trolling Motor' {
        this.standardTrollingMotor = stdProd;
        this.boat.Standard_Trolling_Motor__c = stdProd.Id;
      }
    }
  }

  private void insertFeeProducts() {
    this.feeProducts = new List<Product2>();
    this.feeProducts.add(Factory_Product.buildNonSerializedProduct('Fees', 'Freight'));
    this.feeProducts.add(Factory_Product.buildNonSerializedProduct('Fees', 'Documentation Fee'));
    this.feeProducts.add(Factory_Product.buildNonSerializedProduct('Fees', 'Rigging and Preparation'));
    insert this.feeProducts;
    addPricebookEntries(this.feeProducts, 0);
  }
}
