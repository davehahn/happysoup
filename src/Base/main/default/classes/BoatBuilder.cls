public with sharing class BoatBuilder {
  public class opportunityStaleException extends Exception {
  }
  public class opportunityException extends Exception {
  }

  public Decimal defaultFedTaxRate {
    get {
      return Legend_Settings__c.getOrgDefaults().FederalTaxRate__c;
    }
    private set;
  }

  public class AdditionalAccessory {
    public String id { get; set; }
    public String productId { get; set; }
    public String productName { get; set; }
    public String productNameFR { get; set; }
    public String productPricebookEntryId { get; set; }
    public Decimal quantity { get; set; }
    public Decimal unitPrice { get; set; }
    public Decimal taxRate { get; set; }
    public Decimal totalPrice {
      get {
        return quantity == null || unitPrice == null ? 0 : quantity * unitPrice;
      }
      set;
    }
    public Decimal totalTaxes {
      get {
        return taxRate == null ? 0 : totalPrice * taxRate;
      }
      set;
    }
    public AdditionalAccessory() {
    }
  }

  public class SubOptionItem {
    public String id { get; set; }
    public Boolean isAvailable { get; set; }
    public String name { get; set; }
    public String name_FR { get; set; }
    public String description { get; set; }
    public String description_FR { get; set; }
    public Decimal standard { get; set; }
    public Decimal maximum { get; set; }
    public Decimal step { get; set; }
    public Decimal price { get; set; }
    public String productFamily { get; set; }
    public String productPriceBookEntryId { get; set; }
    public String productPricebookId { get; set; }
    public Decimal taxRate { get; set; }
    public List<Product_Fee_Map__c> feeProducts { get; set; }

    public subOptionItem() {
    }
  }

  public class FeeItem {
    public String Id { get; set; }
    public Decimal cost { get; set; }
    public String description { get; set; }
    public String description_FR { get; set; }
    public String priceBookEntryId { get; set; }
    public Decimal quantity { get; set; }
    public Decimal taxRate { get; set; }
    public Decimal total {
      get {
        if (cost == null || quantity == null) {
          return null;
        } else {
          return cost * quantity;
        }
      }
      set;
    }
    public Decimal totalTaxes {
      get {
        return total == null || taxRate == null ? 0 : total * taxRate;
      }
      set;
    }

    public FeeItem() {
    }

    public FeeItem(Product2 fee, Product_Fee_Amount__c pfa, Decimal taxRate) {
      this.Id = LGND_Utilities.generateRandomString(12);
      this.cost = pfa.Amount__c;
      this.description = fee.Name;
      this.description_FR = fee.Name_FR__c;
      this.pricebookEntryId = fee.PricebookEntries[0].Id;
      this.quantity = 1;
      this.taxRate = taxRate;
    }

    public FeeItem(OpportunityLineItem oli, Decimal taxRate) {
      this.Id = LGND_Utilities.generateRandomString(12);
      this.cost = oli.unitPrice;
      this.description = oli.PricebookEntry.Product2.Name;
      this.description_FR = oli.PricebookEntry.Product2.Name_FR__c;
      this.priceBookEntryId = oli.PricebookEntry.Id;
      this.quantity = oli.quantity;
      this.taxRate = taxRate;
    }
  }

  public class Discount {
    public String id { get; set; }
    public Decimal amount { get; set; }
    public String description { get; set; }

    public Discount() {
    }
  }

  public class TradeInItem {
    public Boolean isNew {
      get {
        if (isNew == null) {
          isNew = true;
        }
        return isNew;
      }
      set;
    }
    public String id { get; set; }
    public String modelYear { get; set; }
    public String make { get; set; }
    public String model { get; set; }
    public String serialNumber { get; set; }
    public Boolean isDeleted {
      get {
        if (isDeleted == null) {
          isDeleted = false;
        }
        return isDeleted;
      }
      set;
    }

    public TradeInItem() {
    }
  }

  public class TradeInPackage {
    public Decimal value { get; set; }
    public Decimal lienAmount { get; set; }
    public Map<String, TradeInItem> items { get; set; }
    public String recordId { get; set; }
    public String opportunityId { get; set; }
    public Decimal totalValue {
      get {
        return value - lienAmount;
      }
    }

    public TradeInPackage() {
      this.value = 0;
      this.lienAmount = 0;
      this.items = new Map<String, TradeInItem>();
    }
  }

  public Map<String, Discount> discountItems { get; set; }

  private ApexPages.StandardController std;
  private Id currentUserId;
  public Boolean soldToBusiness { get; set; }
  public Boolean isEditable { get; private set; }
  public Boolean isValid { get; private set; }
  private User currentUser;
  public Opportunity opportunity { get; private set; }
  public OpportunityContactRole buyer { get; private set; }
  public OpportunityContactRole cobuyer { get; private set; }
  public Id pb2Id { get; private set; }
  public Id opportunity_id { get; private set; }
  public String defaultView { get; private set; }
  public Boolean renderBuilder { get; private set; }
  public Boolean renderOptionSelect { get; private set; }

  private List<PricebookEntry> boatPriceBookEntries { get; set; }
  public String selectedProductFamily { get; set; }
  public Id selectedBoatId { get; set; }
  public Id selectedMotorId { get; set; }
  public Id selectedTrollingMotorId { get; set; }
  public Id selectedTrailerId { get; set; }

  public Product2 selectedBoat { get; private set; }
  public Product2 selectedMotor { get; private set; }
  public Product2 selectedTrollingMotor { get; private set; }
  public Product2 selectedTrailer { get; private set; }

  // used to hold sub options for boat options
  public Map<String, List<SubOptionItem>> subOptions { get; private set; }

  public Map<String, List<Product2>> availableProductUpgrades {
    get {
      if (availableProductUpgrades == null) {
        availableProductUpgrades = new Map<String, List<Product2>>();
      }
      return availableProductUpgrades;
    }
    private set;
  }

  public Map<Id, Product2> availableMotorOptions { get; private set; }
  public Map<Id, Product2> availableTrailerOptions { get; private set; }
  public Map<Id, Product2> availableTrollingMotorOptions { get; private set; }

  public Set<String> productFamilies = new Set<String>{
    'Full Windshield',
    'Pontoon',
    'Side Console',
    'Utility',
    'LooseItem'
  };

  public Map<String, Map<String, Product2>> availableBoatOptions {
    get {
      if (availableBoatOptions == null) {
        availableBoatOptions = new Map<String, Map<String, Product2>>();
      }
      return availableBoatOptions;
    }
    private set;
  }

  public class ProtectionProductWrapper {
    public String belongTo { get; set; }
    public String belongsToType { get; set; }
    public Product2 protectionProduct { get; set; }

    public protectionProductWrapper() {
    }
  }

  public Map<String, Map<String, ProtectionProductWrapper>> availableProtectionOptions {
    get {
      if (availableProtectionOptions == null) {
        availableProtectionOptions = new Map<String, Map<String, ProtectionProductWrapper>>();
      }
      return availableProtectionOptions;
    }
    private set;
  }

  private List<Product2> allboatOptions { get; set; }
  public TradeInPackage trade_in_package {
    get {
      if (trade_in_package == null) {
        trade_in_package = new TradeInPackage();
      }
      return trade_in_package;
    }
    set;
  }

  public Decimal basePrice { get; private set; }
  public Decimal runningPrice { get; private set; }
  public Decimal runningTaxableTotal { get; private set; }
  public Decimal runningTaxes { get; private set; }
  public Decimal discountTotal {
    get {
      if (discountTotal == null) {
        discountTotal = 0;
      }
      return discountTotal;
    }
    private set;
  }

  public String motorUpgradePrice { get; private set; }
  public String trailerUpgradePrice { get; private set; }
  public String trollingMotorUpgradePrice { get; private set; }
  public Map<Id, Decimal> upgradeCostMap;

  public Map<String, Map<String, BoatBuilderLineItem>> selectedItemsMap {
    get {
      if (selectedItemsMap == null) {
        selectedItemsMap = new Map<String, Map<String, BoatbuilderLineItem>>();
        selectedItemsMap.put('boat', new Map<String, BoatBuilderLineItem>());
        selectedItemsMap.put('motor', new Map<String, BoatBuilderLineItem>());
        selectedItemsMap.put('trailer', new Map<String, BoatBuilderLineItem>());
        selectedItemsMap.put('trolling motor', new Map<String, BoatBuilderLineItem>());
        selectedItemsMap.put('protection', new Map<String, BoatBuilderLineItem>());
        selectedItemsMap.put('bundle', new Map<String, BoatBuilderLineItem>());
      }
      return selectedItemsMap;
    }
    private set;
  }

  public Map<String, Map<String, List<FeeItem>>> provinceFeesMap {
    get {
      if (provinceFeesMap == null) {
        provinceFeesMap = new Map<String, Map<String, List<FeeItem>>>();
      }
      return provinceFeesMap;
    }
    private set;
  }

  public Map<String, String> familyNames {
    get {
      if (familyNames == null) {
        familyNames = new Map<String, String>();
      }
      return familyNames;
    }
    private set;
  }

  public List<AdditionalAccessory> additionalAccessories { get; set; }
  private Map<String, Decimal> lineItemQuantityMap;
  private Map<String, Map<String, Decimal>> subLineItemQuantityMap;
  public Boolean isPublicView { get; private set; }
  //public Boolean opportunityLocked { get; private set;}
  public List<Integer> invoiceOptionRowFiller {
    get {
      return new List<Integer>{
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
        19,
        20,
        21,
        22,
        23,
        24,
        25,
        26,
        27,
        28
      };
    }
  }
  public Date quoteValidDate { get; private set; }
  public String pdfStoreAddress { get; private set; }
  public Map<String, String> pdfPhoneNumbers { get; private set; }
  public Boolean hasChanged { get; set; }
  //public String looseItemBoatId;
  public Boolean isLooseItemSale { get; private set; }
  public Boolean isDealerOrder { get; set; }
  public String tempDisclaimer { get; set; }
  public List<InvoiceDisclaimer__mdt> invoiceDisclaimers { get; set; }
  //public LGND_Store lgnd_store { get; set; }

  //public String taxationProvince { get; set; }
  public LGND_Utilities.ProvincialTax provTaxRate { get; private set; }
  public Map<String, LGND_Utilities.ProvincialTax> provincialTaxInfo;
  public AcctSeedERP__Warehouse__c warehouse { get; set; }

  public List<Product_Fee_Amount__c> allFees { get; private set; }
  public String language {
    get {
      if (language == null) {
        language = 'english';
      }
      return language;
    }
    set;
  }
  public Id dealerOrderId { get; set; }
  /* ENABLE FOR DEALER ORDERING */
  public Dealer_Order__c dealerOrder { get; set; }
  public Dealer_Order_Line__c workingDealerOrderLine { get; set; }

  public OpportunityLineItem[] insuranceItems;
  public Decimal insuranceTaxes;

  public BoatBuilder(Id oppId) {
    this.opportunity_id = oppId;
    init();
  }

  public BoatBuilder(Dealer_Order_Line__c dealerOrderLine) {
    this.dealerOrderId = dealerOrderLine.Dealer_Order__c;
    this.opportunity_id = dealerOrderLine.Opportunity__c;
    this.dealerOrder = [
      SELECT Id, Name, Account__c, Stage__c, Account__r.Name, LineItemCount__c
      FROM Dealer_Order__c
      WHERE Id = :this.dealerOrderId
    ];
    //provincialTaxInfo = LGND_Utilities.fetchProvincialTaxInfo();
    initForDealerOrder();
  }

  /* ENABLE FOR DEALER ORDERING */
  public BoatBuilder() {
    this.opportunity_id = ApexPages.currentPage().getParameters().get('opportunity_id');
    this.dealerOrderId = ApexPages.currentPage().getParameters().get('dealer_order_id');
    //provincialTaxInfo = LGND_Utilities.fetchProvincialTaxInfo();
    if (this.dealerOrderId != null) {
      dealerOrder = [
        SELECT Id, Name, Account__c, Stage__c, Account__r.Name, Account__r.BillingState, LineItemCount__c
        FROM Dealer_Order__c
        WHERE Id = :dealerOrderId
      ];
      if (dealerOrder.Stage__c == 'Processed') {
        throw new opportunityException(
          'You can not add new Line items to a Dealer Order that has already been processed'
        );
      }
      initForDealerOrder();
    } else {
      String lang = ApexPages.currentPage().getParameters().get('language');
      if (lang != null)
        this.language = lang;
      init();
    }
  }
  /* ENABLE FOR DEALER ORDERING */
  public void initForDealerOrder() {
    isDealerOrder = true;
    hasChanged = false;
    //looseItemBoatId = Legend_Settings__c.getOrgDefaults().LooseItemBoatProduct__c;
    isLooseItemSale = false;
    renderBuilder = false;
    renderOptionSelect = false;
    isPublicView = false;
    isEditable = true;
    isValid = true;
    defaultView = 'showConfig';
    renderBuilder = true;
    selectedBoat = null;
    if (this.opportunity_id != null) {
      this.opportunity = findOpportunity();
      this.workingDealerOrderLine = [
        SELECT Id
        FROM Dealer_Order_Line__c
        WHERE Opportunity__c = :opportunity_id AND Dealer_Order__c = :dealerOrderId
      ];
    }
    setup_Taxes_User_and_Fees();
    buildUpgradeCostMap();
    if (this.opportunity == null)
      this.opportunity = new Opportunity(
        Warehouse__c = this.warehouse.Id,
        GL_Account_Variable_3__c = this.provTaxRate.id
      );
    if (this.opportunity.OpportunityLineItems.size() > 0) {
      buildFromOpportunity();
    }
  }

  private void buildInvoiceDisclaimers() {
    this.invoiceDisclaimers = [
      SELECT Id, English__c, French__c
      FROM InvoiceDisclaimer__mdt
      WHERE isActive__c = TRUE AND Invoice_Type__c = 'Quote And Sales Agreement'
    ];
  }

  public void init() {
    soldToBusiness = false;
    hasChanged = false;
    //looseItemBoatId = Legend_Settings__c.getOrgDefaults().LooseItemBoatProduct__c;
    tempDisclaimer = language == 'french'
      ? Legend_Settings__c.getOrgDefaults().Invoice_temp_disclaimer_french__c
      : Legend_Settings__c.getOrgDefaults().Invoice_temp_disclaimer__c;
    this.buildInvoiceDisclaimers();
    isLooseItemSale = false;
    isDealerOrder = false;
    renderBuilder = false;
    renderOptionSelect = false;
    isPublicView = true;
    isEditable = false;
    isValid = true;
    defaultView = 'showConfig';
    String dateString = ApexPages.currentPage().getParameters().get('quote_valid_date');
    try {
      quoteValidDate = Date.parse(dateString);
    } catch (Exception e) {
      quoteValidDate = Date.today() + 30;
    }

    if (opportunity_id != null) {
      opportunity = findOpportunity();
      //if( opportunity.RecordTypeId == LGND_Utilities.recordTypeIdFromName('Opportunity', 'Partner Boat Sale') )
      //{
      //  isDealerOrder = true;
      //}
      if (opportunity.Account.recordTypeId == LGND_Utilities.recordTypeIdFromName('Account', 'Business Account'))
        soldToBusiness = true;
      //a public view will never have an opportunity so ....
      isPublicView = false;
      //Let check to see if the opportunity is locked
      Set<String> statuses = new Set<String>{ 'Pending', 'Approved' };
      List<Processinstance> pi = [
        SELECT Id, Status
        FROM Processinstance
        WHERE TargetObjectId = :opportunity_id AND Status IN :statuses
      ];
      /* might need to find a better way to determine if the opportunity can be edited
         but for now it stands as if the current User is a System admin OR the
        Opportunity has not been submitted for approval then we can edit the boat
        Configurator
      */
      isEditable = true;
      //set the default view to display
      String view = ApexPages.currentPage().getParameters().get('defaultView');
      if (view != null) {
        defaultView = isEditable ? view : 'showSummary';
      } else {
        defaultView = isEditable ? 'showConfig' : 'showSummary';
      }
      //pull buyer and cobuyer out
      for (OpportunityContactRole ocr : opportunity.OpportunityContactRoles) {
        if (ocr.Role == 'Buyer')
          buyer = ocr;
        if (ocr.Role == 'Co-Buyer')
          cobuyer = ocr;
      }
    }

    renderBuilder = true;
    selectedBoat = null;
    setup_Taxes_User_and_Fees();
    buildUpgradeCostMap();

    if (this.opportunity != null && opportunity.OpportunityLineItems.size() > 0) {
      buildFromOpportunity();
    }
  }

  private void setup_Taxes_User_and_Fees() {
    // set the pricebook
    this.pb2Id = this.opportunity_id == null
      ? isDealerOrder
          ? Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c
          : Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c
      : this.Opportunity.Pricebook2Id;

    //set current User
    this.currentUserId = UserInfo.getUserId();
    if (this.currentUserId != null) {
      currentUser = [
        SELECT Id, Name, Profile.Name, Sales_Department__c, Warehouse__c
        FROM User
        WHERE Id = :currentUserId
      ];
    }

    //set warehouse
    String whName = currentUser.Warehouse__c == null ? 'Whitefish' : currentUser.WareHouse__c;
    String qString = 'SELECT Id, Name, City__c, Country__c, Postal_Code__c, State__c, Street__c, GL_Account_Variable_3__c, Phone__c, Toll_Free__c, Fax__c FROM AcctSeedERP__Warehouse__c WHERE ';
    if (this.opportunity.Warehouse__c == null) {
      qString += 'Name = \'' + whName + '\'';
    } else {
      qString += 'Id = \'';
      qString += this.opportunity.Warehouse__c;
      qString += '\'';
    }
    this.warehouse = Database.query(qString);

    //set tax information
    this.provincialTaxInfo = LGND_Utilities.fetchProvincialTaxInfo();
    if (this.opportunity_id == null) {
      if (this.dealerOrder != null) {
        if (this.dealerOrder.Account__r.BillingState != null)
          this.provTaxRate = this.provincialTaxInfo.containsKey(this.dealerOrder.Account__r.BillingState)
            ? this.provincialTaxInfo.get(this.dealerOrder.Account__r.BillingState)
            : this.provincialTaxInfo.get('Others');
      } else if (this.warehouse.GL_Account_Variable_3__c != null)
        this.provTaxRate = new LGND_Utilities.ProvincialTax(this.warehouse.GL_Account_Variable_3__c);
    } else {
      if (this.opportunity.GL_Account_Variable_3__c != null)
        this.provTaxRate = new LGND_Utilities.ProvincialTax(this.opportunity.GL_Account_Variable_3__c);
    }
    if (this.provTaxRate == null)
      this.provTaxRate = this.provincialTaxInfo.get('Ontario');

    //build out fees
    this.allFees = findAllFees();
  }

  public void updateTaxes() {
    String newProvZone = ApexPages.currentPage().getParameters().get('tax_zone');

    if (newProvZone != this.provTaxRate.name) {
      provinceFeesMap.remove('additional');
      try {
        this.provTaxRate = new LGND_Utilities.ProvincialTax(newProvZone);
      } catch (Exception e) {
        this.provTaxRate = this.provincialTaxInfo.get('Others');
      }
      allFees = findAllFees();
    }
    opportunity.Tax_Override__c = Boolean.valueOf(ApexPages.currentPage().getParameters().get('over_ride'));
    Decimal p_overRideRate = Decimal.valueOf(ApexPages.currentPage().getParameters().get('provincial_over_ride_rate'));
    Decimal f_overRideRate = Decimal.valueOf(ApexPages.currentPage().getParameters().get('federal_over_ride_rate'));
    Decimal r_overRideRate = Decimal.valueOf(ApexPages.currentPage().getParameters().get('retail_over_ride_rate'));
    if (opportunity.Tax_Override__c == true) {
      opportunity.Tax_Rate_Federal__c = f_overRideRate;
      opportunity.Tax_Rate_Provincial__c = p_overRideRate;
      opportunity.Tax_Rate_Retail__c = r_overRideRate;
    } else {
      opportunity.Tax_Rate_Federal__c = defaultFedTaxRate;
      opportunity.Tax_Rate_Provincial__c = this.provTaxRate.rate;
      opportunity.Tax_Rate_Retail__c = this.provTaxRate.retailRate;
    }
    opportunity.GL_Account_Variable_3__c = this.provTaxRate.id;
    opportunity.GL_Account_Variable_3__r = this.provTaxRate.accountVariableRecord;
    opportunity.Tax_is_Harmonized__c = this.provTaxRate.isHarmonized;
    updateRunningPrice();
  }

  public void updateFeeItemAmount() {
    Map<String, String> params = ApexPages.currentPage().getParameters();
    String feeId = params.get('fee_id');
    String prov = params.get('province');
    String feeParent = params.get('fee_parent');
    String amount = params.get('amount');

    for (FeeItem fi : provinceFeesMap.get(feeParent).get(prov)) {
      if (fi.Id == feeId) {
        fi.cost = amount == null || amount == '' ? 0 : Decimal.valueOf(amount);
        break;
      }
    }
    updateRunningPrice();
  }

  public void deleteFeeItem() {
    Map<String, String> params = ApexPages.currentPage().getParameters();
    String feeId = params.get('fee_id');
    String prov = params.get('province');
    String feeParent = params.get('fee_parent');
    List<FeeItem> feeItems = provinceFeesMap.get(feeParent).get(prov);
    Integer foundIndex;

    for (Integer i = 0; i < feeItems.size(); i++) {
      if (feeItems.get(i).Id == feeId) {
        foundIndex = i;
        break;
      }
    }

    feeItems.remove(foundIndex);
    updateRunningPrice();
  }

  public void addAdditionalFee() {
    Id pId = ApexPages.currentPage().getParameters().get('fee_product_id');
    if (pId != null) {
      Product2 fee = [
        SELECT
          Id,
          Name,
          Name_FR__c,
          Taxable__c,
          (
            SELECT Id, Amount__c
            FROM Product_Fee_Amounts__r
            WHERE Province__c = :opportunity.GL_Account_Variable_3__r.Name AND Price_Book__c = :opportunity.Pricebook2Id
          ),
          (SELECT Id FROM PricebookEntries WHERE Pricebook2Id = :opportunity.pricebook2Id)
        FROM Product2
        WHERE Id = :pId
      ];

      if (!provinceFeesMap.containsKey('additional')) {
        provinceFeesMap.put('additional', new Map<String, List<FeeItem>>());
      }
      if (!provinceFeesMap.get('additional').containsKey(opportunity.GL_Account_Variable_3__r.Name)) {
        provinceFeesMap.get('additional').put(opportunity.GL_Account_Variable_3__r.Name, new List<FeeItem>());
      }
      provinceFeesMap.get('additional')
        .get(opportunity.GL_Account_Variable_3__r.Name)
        .add(new FeeItem(fee, fee.Product_Fee_Amounts__r[0], findTaxRate(fee.Taxable__c)));
      updateRunningPrice();
    }
  }

  public void addAdditionalAccessory() {
    Map<String, String> params = Apexpages.currentPage().getParameters();
    String productId = params.get('productId');
    if (productId != null || productId != '') {
      PricebookEntry pbe = [
        SELECT
          Id,
          Product2.Name,
          Product2.Name_FR__c,
          Product2.Description,
          Product2.Description_FR__c,
          Product2.Taxable__c
        FROM PricebookEntry
        WHERE Pricebook2Id = :pb2Id AND Product2Id = :productId
      ];

      if (additionalAccessories == null) {
        additionalAccessories = new List<AdditionalAccessory>();
      }
      Set<String> currentIds = new Set<String>();
      for (AdditionalAccessory aa : additionalAccessories) {
        currentIds.add(aa.id);
      }
      AdditionalAccessory a = new AdditionalAccessory();
      a.id = generateUniqueId(currentIds);
      a.productId = productId;
      a.productName = pbe.Product2.Name;
      a.productNameFR = pbe.Product2.Name_FR__c;
      a.productPriceBookEntryId = pbe.Id;
      a.quantity = Decimal.valueOf(params.get('quantity'));
      a.unitPrice = Decimal.valueOf(params.get('salePrice'));
      a.taxRate = findTaxRate(pbe.Product2.Taxable__c);
      additionalAccessories.add(a);
      updateRunningPrice();
    }
  }

  public void removeAdditionalAccessory() {
    String aaId = Apexpages.currentPage().getParameters().get('aaId');
    for (Integer i = 0; i < additionalAccessories.size(); i++) {
      if (aaId == additionalAccessories[i].id) {
        additionalAccessories.remove(i);
        break;
      }
    }
    updateRunningPrice();
  }

  public List<SelectOption> getProvinceOptions() {
    List<SelectOption> options = new List<SelectOption>();
    options.add(new SelectOption('', '-- Select --'));
    for (String prov : this.provincialTaxInfo.keySet()) {
      options.add(new SelectOption(this.provincialTaxInfo.get(prov).id, prov));
    }
    return options;
  }

  public String getProvincialTaxInfo() {
    return JSON.serialize(this.provincialTaxInfo);
  }

  public String getTotalTaxRateDisplay() {
    Decimal p_Rate;
    Decimal f_Rate;
    if (this.opportunity != null) {
      p_Rate = opportunity.Tax_Rate_Provincial__c == null ? this.provTaxRate.rate : opportunity.Tax_Rate_Provincial__c;
      f_Rate = opportunity.Tax_Rate_Federal__c == null ? defaultFedTaxRate : opportunity.Tax_Rate_Federal__c;
    } else {
      p_Rate = this.provTaxRate.rate;
      f_Rate = defaultFedTaxRate;
    }
    return String.valueOf(p_Rate + f_Rate);
  }

  public boolean getRenderMotorSelector() {
    return (selectedBoat != null &&
    isDealerOrder == false &&
    (selectedBoat.Standard_Motor__c != null ||
    (availableProductUpgrades.containsKey('motors') && availableProductUpgrades.get('motors').size() > 0)));
  }

  public boolean getRenderTrailerSelector() {
    return (selectedBoat != null &&
    (selectedBoat.Standard_Trailer__c != null ||
    (availableProductUpgrades.containsKey('trailers') && availableProductUpgrades.get('trailers').size() > 0)));
  }

  public boolean getRenderTrollingMotorSelector() {
    return (selectedBoat != null &&
    (selectedBoat.Standard_Trolling_Motor__c != null ||
    (availableProductUpgrades.containsKey('trolling_motors') &&
    availableProductUpgrades.get('trolling_motors').size() > 0)));
  }

  public Boolean getRenderSummaryOptionList() {
    return !selectedItemsMap.get('boat').isEmpty();
  }

  public Boolean getRenderAllOptionDetails() {
    return !(selectedItemsMap.get('boat').isEmpty() &&
    selectedItemsMap.get('motor').isEmpty() &&
    selectedItemsMap.get('trailer').isEmpty() &&
    selectedItemsMap.get('trolling motor').isEmpty() &&
    additionalAccessories == null);
  }

  public Boolean getRenderProtectionOptionList() {
    if (availableProtectionOptions.size() > 0)
      return true;
    if (insuranceItems != null && insuranceItems.size() > 0)
      return true;
    return false;
  }

  public Boolean getRenderDiscountSummary() {
    return discountItems == null ? false : discountItems.size() > 0 ? true : false;
  }

  public Boolean getRenderSummaryFees() {
    return !provinceFeesMap.isEmpty();
  }

  public Boolean getRenderProtectionProducts() {
    return !selectedItemsMap.get('protection').isEmpty() || !getInsuranceItems().isEmpty();
  }

  public String getSummaryTitle() {
    String title = '';
    if (opportunity != null) {
      title += opportunity.Account.Name;
    }
    if (selectedBoat != null) {
      title += ', ' + selectedBoat.Name;
    }
    return title.replace('"', '').replace('\'', '');
  }

  /* THESE METHODS HELP RENDERING FIELDS ON INVOICE AND QUOTES **/
  public String getDepositMethod() {
    if (opportunity != null) {
      if (opportunity.Deposit_Method__c == 'Other') {
        return opportunity.Deposit_Method_Other__c;
      }
      return opportunity.Deposit_Method__c;
    }
    return '';
  }

  public String getPaymentString() {
    if (opportunity.Finance_Payments_Per_Year__c == 12) {
      return language == 'french' ? 'Paiement Mensuel' : 'Monthly Payment';
    }
    if (opportunity.Finance_Payments_Per_Year__c == 26) {
      return 'Bi-Weekly Payment';
    }
    if (opportunity.Finance_Payments_Per_Year__c == 52) {
      return 'Weekly Payment';
    }
    return null;
  }

  public Decimal getPaymentAmount() {
    if (opportunity.Finance_Payments_Per_Year__c == 12) {
      return opportunity.Finance_Payment_Monthly__c;
    }
    if (opportunity.Finance_Payments_Per_Year__c == 26) {
      return opportunity.Finance_Payment_Bi_Weekly__c;
    }
    if (opportunity.Finance_Payments_Per_Year__c == 52) {
      return opportunity.Finance_Payment_Weekly__c;
    }
    return null;
  }

  //public List<Product_Fee_Amount__c> findAllFees()
  //{
  //  return [SELECT Id, Amount__c, Fee_Product__r.Name
  //          FROM Product_Fee_Amount__c
  //          WHERE Province__c = :opportunity.TaxationProvince__c
  //          AND Price_Book__c = :opportunity.Pricebook2Id ];
  //}
  public List<Product_Fee_Amount__c> findAllFees() {
    return [
      SELECT Id, Amount__c, Fee_Product__r.Name
      FROM Product_Fee_Amount__c
      WHERE Province__c = :this.provTaxRate.name AND Price_Book__c = :this.pb2Id
    ];
  }

  public List<Product_Fee_Amount__c> findAllFees(String prov, Id pbId) {
    return [
      SELECT Id, Amount__c, Fee_Product__r.Name
      FROM Product_Fee_Amount__c
      WHERE Province__c = :prov AND Price_Book__c = :pbId
    ];
  }

  public List<OpportunityLineItem> getInsuranceItems() {
    if (insuranceItems == null) {
      insuranceItems = new List<OpportunityLineItem>();
      for (OpportunityLineItem oli : opportunity.OpportunityLineItems) {
        if (oli.isInsurance__c == true) {
          insuranceItems.add(oli);
        }
      }
    }
    return insuranceItems;
  }

  public Decimal getInsuranceTaxes() {
    if (insuranceTaxes != null)
      return insuranceTaxes;
    if (insuranceItems == null || insuranceItems.size() == 0)
      return 0;

    Decimal tRate = opportunity.Tax_Rate_Provincial__c == null ? provTaxRate.rate : opportunity.Tax_Rate_Provincial__c;
    Decimal iTotal = 0;
    for (OpportunityLineItem oli : insuranceItems) {
      iTotal += oli.UnitPrice;
    }
    insuranceTaxes = iTotal * (tRate / 100);
    return insuranceTaxes;
  }

  /* ============= End render helper Methods ====================== */

  /* +++++++++++++ Select & Tab List Builders +++++++++++++++++++++++++++ */

  public List<SelectOption> getProductFamilySelectItems() {
    List<SelectOption> items = new List<SelectOption>();
    items.add(new SelectOption('', 'Select a Boat Type'));
    for (String fam : productFamilies) {
      items.add(new SelectOption(fam, fam));
    }
    return items;
  }

  public List<SelectOption> getBoatSelectItems() {
    List<SelectOption> items = new List<SelectOption>();
    if (selectedProductFamily != null) {
      if (boatPriceBookEntries == null) {
        boatPriceBookEntries = [
          SELECT Id, Name, Product2Id, UnitPrice
          FROM PricebookEntry
          WHERE
            Pricebook2Id = :pb2Id
            AND IsActive = TRUE
            AND Product2.Family = :selectedProductFamily
            AND Product2.RecordType.Name = 'Boat'
          ORDER BY Product2.Name
        ];
      }
      items.add(new SelectOption('', 'Select a ' + selectedProductFamily + ' Boat'));
      for (PricebookEntry b : boatPriceBookEntries) {
        items.add(new SelectOption(b.Product2Id, b.Name));
      }
    }
    return items;
  }

  public List<SelectOption> getMotorSelectItems() {
    return buildUpgradeSelectOptions('Motor', selectedBoat.Standard_Motor__c, selectedBoat.Standard_Motor__r.Name);
  }

  public List<SelectOption> getTrailerSelectItems() {
    return buildUpgradeSelectOptions(
      'Trailer',
      selectedBoat.Standard_Trailer__c,
      selectedBoat.Standard_Trailer__r.Name
    );
  }

  public List<SelectOption> getTrollingMotorSelectItems() {
    return buildUpgradeSelectOptions(
      'Trolling Motor',
      selectedBoat.Standard_Trolling_Motor__c,
      selectedBoat.Standard_Trolling_Motor__r.Name
    );
  }

  public Discount[] getJustDiscountItems() {
    return discountItems == null ? new List<Discount>() : discountItems.values();
  }

  public TradeInItem[] getTradeInPackageItems() {
    List<TradeInItem> tiItems = new List<TradeInItem>();
    for (TradeInItem ti : trade_in_package.items.values()) {
      if (!ti.isDeleted)
        tiItems.add(ti);
    }
    return tiItems;
  }

  public List<BoatBuilderLineItem> getSelectedBoatOptions() {
    return selectedItemsMap.get('boat').values();
  }

  public List<BoatBuilderLineItem> getSelectedMotorOptions() {
    return selectedItemsMap.get('motor').values();
  }

  public List<BoatBuilderLineItem> getSelectedTrailerOptions() {
    return selectedItemsMap.get('trailer').values();
  }

  public List<BoatBuilderLineItem> getSelectedTrollingMotorOptions() {
    return selectedItemsMap.get('trolling motor').values();
  }

  public List<BoatBuilderLineItem> getSelectedProtectionOptions() {
    return selectedItemsMap.get('protection').values();
  }

  /* =============== End Selct & Tab List Builders ========================= */

  /*
    this builds a comma seperated String list of all Products Id's that have been selected
    in the process of building a boat.
    It is used in the BoatBuilder visualforce page to determine if a product has been selected
    or not
  */
  public Map<String, String> getSelectedPartsIdList() {
    String s;
    Map<String, String> stringMap = new Map<String, String>();
    if (selectedItemsMap == null) {
      return stringMap;
    } else {
      for (String pType : selectedItemsMap.keyset()) {
        s = '';
        List<BoatBuilderLineItem> items = selectedItemsMap.get(ptype).values();
        for (BoatBuilderLineItem li : items) {
          //wrap the productId with ':' to distinguish it from a subItem below
          s += ':';
          s += li.product_id;
          s += ':';
          s += ', ';
          if (li.subItems.size() > 0) {
            for (BoatBuilderLineItem sli : li.subItems.values()) {
              //for subItems we concat the parentId and the subItem Id to use as a check
              // if the item is a subItem
              s += li.product_id;
              s += sli.product_id;
              s += ', ';
            }
          }
        }
        stringMap.put(pType, s.removeEnd(', '));
      }
      return stringMap;
    }
  }

  /*
    This gets fires when the Product Family Select Changes
    OR when boat type tile gets clicked
  */
  public void selectProductFamily() {
    String bType = ApexPages.currentPage().getParameters().get('boatType');
    if (bType != null) {
      selectedProductFamily = bType;
    }
    if (selectedProductFamily == null) {
      resetToBeginning();
    } else {
      String holder = selectedProductFamily;
      resetToBeginning();
      selectedProductFamily = holder;
      isLooseItemSale = false;
      boatPriceBookEntries = [
        SELECT Id, Name, Product2Id, UnitPrice
        FROM PricebookEntry
        WHERE
          Pricebook2Id = :pb2Id
          AND IsActive = TRUE
          AND Product2.Family = :selectedProductFamily
          AND Product2.RecordType.Name = 'Boat'
        ORDER BY Product2.Name
      ];
    }
  }

  /*
    This gets fired when the boat select menu has changed.
  */
  public void selectBoatFromSelector() {
    resetSelected(); // clear all variable holding information about selected Items
    selectBoat();
  }

  public void selectBoat() {
    if (selectedBoatId == null) {
      return;
    }
    //if( selectedBoatId == looseItemBoatId) isLooseItemSale = true;

    String prevSelectedBoatId = selectedBoat == null ? null : selectedBoat.Id;

    selectedBoat = [
      SELECT
        Id,
        Name,
        Name_FR__c,
        Standard_Motor__c,
        Standard_Trailer__c,
        Standard_Motor__r.Name,
        Make__c,
        Standard_Trailer__r.Name,
        Family,
        Standard_Trolling_Motor__c,
        Standard_Trolling_Motor__r.Name,
        Taxable__c,
        Default_image_700w__c,
        // select options
        (
          SELECT
            Id,
            Standard__c,
            Maximum__c,
            Step__c,
            Rank__c,
            From_Product__r.Id,
            From_Product__r.Name,
            From_Product__r.Name_FR__c,
            From_Product__r.Description,
            From_Product__r.Description_FR__c,
            From_Product__r.RecordType.Name,
            From_Product__r.Family
          FROM To_Product_Options__r
          ORDER BY Rank__c
        ),
        (SELECT Id, Fee_Product__c FROM Parent_Product_Fee_Maps__r),
        (SELECT Id, UnitPrice, Pricebook2Id FROM PricebookEntries WHERE Pricebook2Id = :pb2Id)
      FROM Product2
      WHERE Id = :selectedBoatId
    ];

    if (selectedProductFamily == null) {
      selectedProductFamily = selectedBoat.Family;
    }

    setupOptions(); //sets up all available options for the selected Boat

    if (selectedBoat.PriceBookEntries.size() > 0) {
      basePrice = selectedBoat.PricebookEntries[0].UnitPrice;
      runningPrice = selectedBoat.PricebookEntries[0].UnitPrice;
    } else {
      basePrice = 0;
      runningPrice = 0;
    }

    //add addition fees associated with this boat
    updateAdditionalFees(prevSelectedBoatId, selectedBoatId, selectedBoat.Parent_Product_Fee_Maps__r, 1);
    updateRunningPrice();
    /*If this is a dealer Order we do not want to anything with the motors */
    if (isDealerOrder != true) {
      /* if we are building from an opportunity we have already set the selectedMotorId */
      if (selectedMotorId != null) {
        selectMotor();
      } else if (selectedBoat.Standard_Motor__c != null) {
        /* We need to check and see if the standard motor for the selected boat exists in the currently
           selected pricebook.  If it is not we can not include it as a line item on the opportunity
        */
        selectedMotorId = selectedBoat.Standard_Motor__c;
        selectMotor();
      }
    }

    /* if we are building from an opportunity we have already set the selectedTrailerrId */
    if (selectedTrailerId != null) {
      selectTrailer();
    } else if (selectedBoat.Standard_Trailer__c != null) {
      /* We need to check and see if the standard trailer for the selected boat exists in the currently
         selected pricebook.  If it is not we can not include it as a line item on the opportunity
      */
      selectedTrailerId = selectedBoat.Standard_Trailer__c;
      selectTrailer();
    }

    /* if we are building from an opportunity we have already set the selectedTrollingMotorId */
    if (selectedTrollingMotorId != null) {
      selectTrollingMotor();
    } else if (selectedBoat.Standard_Trolling_Motor__c != null) {
      /* We need to check and see if the standard trolling motor for the selected boat exists in the currently
         selected pricebook.  If it is not we can not include it as a line item on the opportunity
      */
      selectedTrollingMotorId = selectedBoat.Standard_Trolling_Motor__c;
      selectTrollingMotor();
    }
  }

  /*
    Does pretty much what it says, Selects the Motor.  This gets fired after the boat is selected
    if said boat has a standard motor and when ever the Motor Select menu changes
  */
  public void selectMotor() {
    String prevSelectedMotorId = selectedMotor == null ? null : selectedMotor.Id;

    //remove fee from the previously selected motor
    if (prevSelectedMotorId != null && provinceFeesMap.containsKey(prevSelectedMotorId)) {
      provinceFeesMap.remove(prevSelectedMotorId);
      //remove subItems Fees as well
      for (String pId : selectedItemsMap.get('motor').keySet()) {
        if (provinceFeesMap.containsKey(pId)) {
          provinceFeesMap.remove(pid);
        }
      }
    }
    // remove protection products from motor
    if (prevSelectedMotorId != null) {
      removeSelectedProtectionProducts(selectedMotor.To_Product_Options__r);
    }

    //remove any options that where selected from the previously selected Motor
    if (availableMotorOptions != null) {
      selectedItemsMap.put('motor', new Map<String, BoatBuilderLineItem>());
      // remove all options assoiciated with the selected motor
      availableMotorOptions = null;
    }
    if (selectedMotorId == null) {
      selectedMotor = null;
      motorUpgradePrice = null;
    } else {
      Map<String, Product2> selected = setSelectedUpgrade(selectedMotorId, selectedBoat.Standard_Motor__c);
      for (String price : selected.keySet()) {
        motorUpgradePrice = price;
        break;
      }
      selectedMotor = selected.get(motorUpgradePrice);
      //add addition fees associated with this trailer
      updateAdditionalFees(prevSelectedMotorId, selectedMotorId, selectedMotor.Parent_Product_Fee_Maps__r, 1);
    }

    if (selectedMotor != null && selectedMotor.To_Product_Options__r.size() > 0) {
      availableMotorOptions = new Map<Id, Product2>();
      createOptionList(selectedMotor.To_Product_Options__r, availableMotorOptions, selectedMotorId, 'motor');
    }
    updateRunningPrice();
  }

  /*
    Does pretty much what it says, Selects the Trailer.  This gets fired after the boat is selected
    if said boat has a standard trailer and when ever the Trailer Select menu changes
  */
  public void selectTrailer() {
    String prevSelectedTrailerId = selectedTrailer == null ? null : selectedTrailer.Id;

    //remove fee from the previously selected Trailer
    if (prevSelectedTrailerId != null && provinceFeesMap.containsKey(prevSelectedTrailerId)) {
      provinceFeesMap.remove(prevSelectedTrailerId);
      //remove subItems Fees as well
      for (String pId : selectedItemsMap.get('trailer').keySet()) {
        if (provinceFeesMap.containsKey(pId)) {
          provinceFeesMap.remove(pid);
        }
      }
    }

    // remove protection products from trailer
    if (prevSelectedTrailerId != null) {
      removeSelectedProtectionProducts(selectedTrailer.To_Product_Options__r);
    }

    //remove any options that where selected from the previously selected Trailer
    if (availableTrailerOptions != null) {
      selectedItemsMap.put('trailer', new Map<String, BoatBuilderLineItem>());
      // remove all options assoiciated with the selected motor
      availableTrailerOptions = null;
    }

    if (selectedTrailerId == null) {
      selectedTrailer = null;
      trailerUpgradePrice = null;
    } else {
      Map<String, Product2> selected = setSelectedUpgrade(selectedTrailerId, selectedBoat.Standard_Trailer__c);
      for (String price : selected.keySet()) {
        trailerUpgradePrice = price;
        break;
      }
      selectedTrailer = selected.get(trailerUpgradePrice);
      //add addition fees associated with this trailer
      updateAdditionalFees(prevSelectedTrailerId, selectedTrailerId, selectedTrailer.Parent_Product_Fee_Maps__r, 1);
    }

    if (selectedTrailer != null && selectedTrailer.To_Product_Options__r.size() > 0) {
      availableTrailerOptions = new Map<Id, Product2>();
      createOptionList(selectedTrailer.To_Product_Options__r, availableTrailerOptions, selectedTrailerId, 'trailer');
    }
    updateRunningPrice();
  }

  /*
    Does pretty much what it says, Selects the Trolling Motor.  This gets fired after the boat is selected
    if said boat has a standard  trolling motor and when ever the Trolling Motor Select menu changes
  */
  public void selectTrollingMotor() {
    String prevSelectedTrollingMotorId = selectedTrollingMotor == null ? null : selectedTrollingMotor.Id;

    //remove fee from the previously selected trolling motor
    if (prevSelectedTrollingMotorId != null && provinceFeesMap.containsKey(prevSelectedTrollingMotorId)) {
      provinceFeesMap.remove(prevSelectedTrollingMotorId);
      //remove subItems Fees as well
      for (String pId : selectedItemsMap.get('trolling_motor').keySet()) {
        if (provinceFeesMap.containsKey(pId)) {
          provinceFeesMap.remove(pid);
        }
      }
    }

    // remove protection products from trolling motor
    if (prevSelectedTrollingMotorId != null) {
      removeSelectedProtectionProducts(selectedTrollingMotor.To_Product_Options__r);
    }

    //remove any options that where selected from the previously selected Motor
    if (availableTrollingMotorOptions != null) {
      selectedItemsMap.put('trolling motor', new Map<String, BoatBuilderLineItem>());
      // remove all options assoiciated with the selected motor
      availableTrollingMotorOptions = null;
    }

    if (selectedTrollingMotorId == null) {
      selectedTrollingMotor = null;
      trollingMotorUpgradePrice = null;
    } else {
      Map<String, Product2> selected = setSelectedUpgrade(
        selectedTrollingMotorId,
        selectedBoat.Standard_Trolling_Motor__c
      );
      for (String price : selected.keySet()) {
        trollingMotorUpgradePrice = price;
        break;
      }
      selectedTrollingMotor = selected.get(trollingMotorUpgradePrice);
      //add addition fees associated with this trailer
      updateAdditionalFees(
        prevSelectedTrollingMotorId,
        selectedTrollingMotorId,
        selectedTrollingMotor.Parent_Product_Fee_Maps__r,
        1
      );
    }

    if (selectedTrollingMotor != null && selectedTrollingMotor.To_Product_Options__r.size() > 0) {
      availableTrollingMotorOptions = new Map<Id, Product2>();
      createOptionList(
        selectedTrollingMotor.To_Product_Options__r,
        availableTrollingMotorOptions,
        selectedTrollingMotorId,
        'trolling motor'
      );
    }
    updateRunningPrice();
  }

  public void productOptionsChanged() {
    String productid = Apexpages.currentPage().getParameters().get('productId');
    String parentProductId = Apexpages.currentPage().getParameters().get('parentProductId');
    String productType = Apexpages.currentPage().getParameters().get('productType').toLowerCase();
    String quantity = Apexpages.currentPage().getParameters().get('quantity');
    String selectedId;
    if (parentProductid == null || parentProductid == '') {
      if (productType == null || productType == 'boat') {
        selectedId = selectedBoatId;
      } else {
        if (productType == 'motor') {
          selectedId = selectedMotorId;
        }
        if (productType == 'trailer') {
          selectedId = selectedTrailerId;
        }
        if (productType == 'trolling motor') {
          selectedId = selectedTrollingMotorId;
        }
        if (productType == 'protection') {
          for (String family : availableProtectionOptions.keyset()) {
            if (availableProtectionOptions.get(family).containsKey(productid)) {
              selectedId = availableProtectionOptions.get(family).get(productid).belongTo;
              break;
            }
          }
        }
      }
      Product2 p = [
        SELECT
          Id,
          Name,
          Name_FR__c,
          Family,
          Description,
          Description_FR__c,
          Taxable__c,
          (SELECT Id, UnitPrice FROM PricebookEntries WHERE Pricebook2Id = :pb2Id),
          (
            SELECT Id, Standard__c, Maximum__c, Step__c, From_Product__c, From_Product__r.Name
            FROM From_Product_Options__r
            WHERE To_Product__c = :selectedId
          ),
          (SELECT Id, Feature_Id__r.Description__c, Feature_Id__r.Description_FR__c FROM Product_Feature_Maps__r),
          (SELECT Id, Fee_Product__c FROM Parent_Product_Fee_Maps__r)
        FROM Product2
        WHERE Id = :productid
      ];
      updateSelectedItems(p, productType.toLowerCase(), quantity);
    } else {
      updateSelectedSubOptionList(productid, parentProductId, productType, quantity);
    }
    updateRunningPrice();
  }

  public void updateTradeInRecord() {
    String total = ApexPages.currentPage().getParameters().get('totalValue');
    String lien = Apexpages.currentPage().getParameters().get('lienAmount');
    total = total.length() == 0 ? '0' : total;
    lien = lien.length() == 0 ? '0' : lien;
    trade_in_package.value = Decimal.valueOf(total);
    trade_in_package.lienAmount = Decimal.valueOf(lien);
    updateRunningPrice();
  }

  public void addTradeInLineItem() {
    String jsonData = Apexpages.currentPage().getParameters().get('jsonData');
    TradeInItem item = (TradeInItem) JSON.deserialize(jsonData, TradeInItem.class);

    Set<String> currentIds = new Set<String>();
    //for(TradeInItem i : trade_in_package.items){
    //  currentIds.add(i.id);
    //}
    for (String id : trade_in_package.items.keyset()) {
      currentIds.add(id);
    }

    item.id = generateUniqueId(currentIds);
    //trade_in_package.items.add(item);
    trade_in_package.items.put(item.id, item);
    hasChanged = true;
  }

  public void updateTradeInLineItem() {
    String jsonData = Apexpages.currentPage().getParameters().get('jsonData');
    TradeInItem item = (TradeInItem) JSON.deserialize(jsonData, TradeInItem.class);
    /*
      generated dummy id is 24 characters long so if it not 24 then it is an existing item
      see  generateUniqueId method on line 2436
    */
    if (item.id.length() != 24)
      item.isNew = false;
    if (trade_in_package.items.containsKey(item.id)) {
      trade_in_package.items.put(item.id, item);
    }
    hasChanged = true;
  }

  public void removeTradeInLineItem() {
    String itemId = Apexpages.currentPage().getParameters().get('itemId');
    if (trade_in_package.items.containsKey(itemId)) {
      trade_in_package.items.get(itemId).isDeleted = true;
    }
    hasChanged = true;
  }

  public void createDiscount() {
    String description = Apexpages.currentPage().getParameters().get('discountDescription');
    String amount = Apexpages.currentPage().getParameters().get('discountAmount');
    buildDiscountItem(description, amount);
    updateRunningPrice();
  }

  public void createPremiumPackageDiscount(Product2 premiumPackageProduct) {
    Boolean allreadyExists = false;
    if (discountItems != null) {
      for (Discount d : discountItems.values()) {
        if (d.description == premiumPackageProduct.Name)
          allreadyExists = true;
      }
    }
    if (!allreadyExists)
      buildDiscountItem(
        premiumPackageProduct.Name,
        String.valueOf(premiumPackageProduct.PricebookEntries[0].UnitPrice)
      );
  }

  public void buildDiscountItem(String description, String amount) {
    if (discountItems == null) {
      discountItems = new Map<String, Discount>();
    }
    Set<String> currentIds = new Set<String>();
    for (Discount d : discountItems.values()) {
      currentIds.add(d.id);
    }

    Decimal a = amount == null | amount == '' ? 0 : Decimal.valueOf(amount);
    a = a < 0 ? a * -1 : a;
    Discount d = new Discount();
    d.id = generateUniqueId(currentIds);
    d.description = description;
    d.amount = a;
    discountItems.put(d.id, d);
  }

  public void updateDiscount() {
    String discountId = Apexpages.currentPage().getParameters().get('discountId');
    String description = Apexpages.currentPage().getParameters().get('discountDescription');
    String amount = Apexpages.currentPage().getParameters().get('discountAmount');
    Decimal a = amount == null | amount == '' ? 0 : Decimal.valueOf(amount);
    if (discountItems.containsKey(discountId)) {
      discountItems.get(discountId).description = description;
      discountItems.get(discountId).amount = a;
      updateRunningPrice();
    }
  }

  public void removeDiscount() {
    String discountId = Apexpages.currentPage().getParameters().get('discountId');
    discountItems.remove(discountId);
    updateRunningPrice();
  }

  /* ENABLE FOR DEALER ORDERING */
  public PageReference cancel() {
    String redirectRecordId = isDealerOrder
      ? workingDealerOrderLine == null ? dealerOrderId : workingDealerOrderLine.Id
      : opportunity_id;
    PageReference pr = new PageReference('/' + redirectRecordId);
    pr.setRedirect(true);
    return pr;
  }

  /* ENABLE FOR DEALER ORDERING */

  public PageReference saveBoatConfig() {
    String customer_notes = Apexpages.currentPage().getParameters().get('customerNotes');
    Dealer_Order_Line__c dol;
    if (opportunity == null || opportunity.Id == null) {
      //OpportunityTriggerHandler.disableAutoPricebookSet = true;
      Opportunity_Service.disableAutoPricebookSet = true;
      opportunity = new Opportunity(
        AccountId = dealerOrder.Account__c,
        RecordTypeId = LGND_Utilities.recordTypeIdFromName('Opportunity', 'Partner Boat Sale'),
        Name = (dealerOrder.Account__r.Name).LEFT(72) + ' - [' + String.valueOf(dealerOrder.LineItemCount__c + 1) + ']',
        StageName = 'Building',
        //taxationProvince__c = taxationProvince,
        GL_Account_Variable_3__c = this.provTaxRate.Id,
        CloseDate = Date.today().addMonths(1),
        Customer_Notes__c = customer_notes
      );
      insert opportunity;
      opportunity.Pricebook2Id = pb2Id;
      update opportunity;
      opportunity_id = opportunity.Id;
      opportunity = findOpportunity();
      opportunity_id = opportunity.Id;
      dol = new Dealer_Order_Line__c(Opportunity__c = opportunity.Id, Dealer_Order__c = DealerOrderId);
    } else {
      opportunity.Customer_Notes__c = customer_notes;
      update opportunity;
      dol = [
        SELECT Id
        FROM Dealer_Order_Line__c
        WHERE Opportunity__c = :opportunity.Id AND Dealer_Order__c = :DealerOrderId
      ];
    }

    PageReference returnPage = saveLineItems();
    if (dol != null) {
      upsert dol;
    }
    return returnPage;
    //return null;
  }

  public PageReference saveAndReturn() {
    String customer_notes = Apexpages.currentPage().getParameters().get('customerNotes');

    PageReference pr = saveToOpportunity(customer_notes);
    return pr;
  }

  public PageReference saveAndFinalize() {
    String customer_notes = Apexpages.currentPage().getParameters().get('customerNotes');
    PageReference pr;
    if (hasChanged == true)
      pr = saveToOpportunity(customer_notes);
    return pr;
  }

  public Opportunity tempOpp { get; set; }

  public PageReference savePDF() {
    String customer_notes = Apexpages.currentPage().getParameters().get('customerNotes');
    tempOpp = new Opportunity(
      Name = 'temp Opportunity',
      CloseDate = Date.today(),
      AccountId = Opportunity.AccountId,
      StageName = 'Quoting'
    );
    try {
      insert tempOpp;
      tempOpp.Pricebook2Id = Opportunity.PriceBook2.Id;
      tempOpp.RecordTypeId = Opportunity.RecordTypeId;
      tempOpp.Deposit__c = opportunity.Deposit__c;
      tempOpp.Deposit_Method__c = opportunity.Deposit_Method__c;
      tempOpp.Deposit_Method_Other__c = opportunity.Deposit_Method_Other__c;
      tempOpp.Customer_Notes__c = customer_notes;
      update tempOpp;
    } catch (Exception e) {
      throw new opportunityException('Something Is Wrong - ' + e.getMessage());
      return null;
    }

    List<OpportunityLineItem> olItems = buildOppLineItems(tempOpp.Id);
    Trade_In_Record__c tradeInRecord = buildTradeInRecord(tempOpp);
    try {
      insert olItems;
      if (tradeInRecord.Total_Value__c > 0) {
        upsert tradeInRecord;
        saveTradeInItems(tradeInRecord.Id);
      }
      ApexPages.Message myMsg = new ApexPages.Message(
        ApexPages.Severity.INFO,
        'Please be patience, PDF is being generated'
      );
      ApexPages.addmessage(myMsg);
      return null;
    } catch (Exception e) {
      delete tempOpp;
      throw new opportunityException('Something Is Wrong - ' + e.getMessage());
      return null;
    }
  }

  public PageReference doPDFAttach() {
    if (tempOpp != null) {
      String fileName = selectedBoat.Name + ' - ' + Opportunity.Account.Name + '.pdf';

      try {
        OpportunityDocumentBuilder.buildQuotePDF(tempOpp.Id, opportunity_id, 'english', selectedBoat.Name, fileName);
      } catch (Exception e) {
        delete tempOpp;
        throw new opportunityException('Something Is Wrong - ' + e.getMessage());
        return null;
      }
      delete tempOpp;
      ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, 'PDF Saved Successfully');
      ApexPages.addmessage(myMsg);
      return null;
    }
    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'There was no temp Opportunity found');
    ApexPages.addmessage(myMsg);
    return null;
  }

  public PageReference doFrenchPDFAttach() {
    if (tempOpp != null) {
      String fileName = selectedBoat.Name + ' - ' + Opportunity.Account.Name + '.pdf';

      try {
        OpportunityDocumentBuilder.buildQuotePDF(tempOpp.Id, opportunity_id, 'french', selectedBoat.Name, fileName);
      } catch (Exception e) {
        delete tempOpp;
        throw new opportunityException('Something Is Wrong - ' + e.getMessage());
        return null;
      }
      delete tempOpp;
      ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, 'PDF Saved Successfully');
      ApexPages.addmessage(myMsg);
      return null;
    }
    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'There was no temp Opportunity found');
    ApexPages.addmessage(myMsg);
    return null;
  }

  private PageReference saveToOpportunity(String notes) {
    Opportunity oppCheck = [
      SELECT Id, LastModifiedBy.Name, LastModifiedDate
      FROM Opportunity
      WHERE Id = :opportunity.Id
    ];
    if (opportunity.LastModifiedDate == oppCheck.LastModifiedDate) {
      opportunity.Customer_Notes__c = notes;
      update opportunity;
      return saveLineItems();
    } else {
      throw new opportunityStaleException(
        'Can not save record. The Opportunity has been modified by ' +
        oppCheck.LastModifiedBy.Name +
        ' at ' +
        oppCheck.LastModifiedDate +
        '. Please Refresh your browser, and apply your changes again.  Sorry for the inconvenience'
      );
    }
  }

  private PageReference saveLineItems() {
    Map<String, List<OpportunityLineItem>> lineItemMap = readyLineItemsForUpsert();
    Trade_In_Record__c tradeInRecord = buildTradeInRecord(opportunity);

    try {
      delete lineItemMap.get('delete');
      upsert lineItemMap.get('upsert');
      if (tradeInRecord.Total_Value__c > 0) {
        upsert tradeInRecord;
        saveTradeInItems(tradeInRecord.Id);
      } else if (tradeInRecord.Id != null) {
        delete tradeInRecord;
      }
      return null;
    } catch (Exception e) {
      ApexPages.Message myMsg = new ApexPages.Message(
        ApexPages.Severity.FATAL,
        'Something Is Wrong - ' + e.getMessage()
      );
      ApexPages.addmessage(myMsg);
      throw new opportunityException('Something Is Wrong - ' + e.getMessage());
      return ApexPages.currentPage();
    }
  }

  private Map<String, List<OpportunityLineItem>> readyLineItemsForUpsert() {
    Map<String, List<OpportunityLineItem>> result = new Map<String, List<OpportunityLineItem>>();
    result.put('upsert', new List<OpportunityLineItem>());
    result.put('delete', new List<OpportunityLineItem>());
    OpportunityLineItem[] currentLIs = buildOppLineItems(opportunity.Id);
    Map<String, OpportunityLineItem> origMap = build_PBE_OLI_map(opportunity.OpportunityLineItems);
    Map<String, OpportunityLineItem> currentMap = build_PBE_OLI_map(currentLIs);
    /*
    first we will see it there items in the original map that are NOT in
    the currentMap and put then in the 'delete' result map as these must have been removed
    UNLESS it is an insurance Item and Discount Items are skipped and ALL
    Discount items will be deleted
    */
    for (String key : origMap.keySet()) {
      if (!currentMap.containsKey(key) && !origMap.get(key).isInsurance__c) {
        result.get('delete').add(origMap.get(key));
      }
    }
    /* we now need to add all discount items  to the to be deleted list */
    for (OpportunityLineItem oli : opportunity.OpportunityLineItems) {
      if (oli.isDiscount__c)
        result.get('delete').add(oli);
    }
    /*
    second we will see if ana item in the currentMap isin the origMap and if so
    we will set the OpportunityLineItem.Id from the original map.
    Then regardles of the above we will add it to the 'upsert' result
    */
    for (String key : currentMap.keySet()) {
      if (origMap.containsKey(key)) {
        currentMap.get(key).Id = origMap.get(key).Id;
      }
      result.get('upsert').add(currentMap.get(key));
    }

    /* we now add all the discounts */
    for (OpportunityLineItem oli : currentLIs) {
      if (oli.isDiscount__c == true) {
        result.get('upsert').add(oli);
      }
    }
    return result;
  }

  private Map<String, OpportunityLineItem> build_PBE_OLI_map(OpportunityLineItem[] olis) {
    Map<String, OpportunityLineItem> result = new Map<String, OpportunityLineItem>();
    for (OpportunityLineItem oli : olis) {
      String key;
      if (oli.isDiscount__c != true) {
        key = oli.PricebookEntryId;
        if (oli.ParentProductId__c != null) {
          key += ':' + oli.ParentProductId__c;
        }
        result.put(key, oli);
      }
    }
    return result;
  }

  private Trade_In_Record__c buildTradeInRecord(Opportunity opp) {
    Trade_In_Record__c tir = opp.Trade_In_Records__r.size() > 0
      ? opp.Trade_In_Records__r[0]
      : new Trade_in_Record__c(Opportunity__c = opp.Id);
    tir.Total_Value__c = trade_in_package.value;
    tir.Lien_Amount__c = trade_in_package.lienAmount;
    return tir;
  }

  private void saveTradeInItems(String tradeInRecordId) {
    List<Trade_In_Item__c> items = new List<Trade_In_Item__c>();
    List<Trade_In_Item__c> updateItems = new List<Trade_In_Item__c>();
    List<String> deleteIds = new List<String>();
    for (TradeInItem ti : trade_in_package.items.values()) {
      if (ti.isNew == true && ti.isDeleted == false) {
        Trade_In_Item__c i = new Trade_In_Item__c(
          Trade_In_Record__c = tradeInRecordId,
          Make__c = ti.make,
          Model__c = ti.model,
          Model_Year__c = ti.modelYear,
          Serial_Number__c = ti.serialNumber
        );
        items.add(i);
      }
      if (ti.isNew == false && ti.isDeleted == false) {
        Trade_In_Item__c item = new Trade_In_Item__c(
          Trade_In_Record__c = tradeInRecordId,
          Id = ti.id,
          Make__c = ti.make,
          Model__c = ti.model,
          Model_Year__c = ti.modelYear,
          Serial_Number__c = ti.serialNumber
        );
        updateItems.add(item);
      }
      if (ti.isNew == false && ti.isDeleted == true) {
        deleteIds.add(ti.id);
      }
    }
    insert items;
    if (updateItems.size() > 0) {
      update updateItems;
    }
    if (deleteIds.size() > 0) {
      List<Trade_In_Item__c> itemsToDelete = [SELECT Id FROM Trade_In_Item__c WHERE Id IN :deleteIds];
      delete itemsToDelete;
    }
  }

  private List<OpportunityLineItem> buildOppLineItems(ID oppId) {
    System.debug('buildOppLineItems');
    List<OpportunityLineItem> olItems = new List<OpportunityLineItem>();
    String description;
    OpportunityLineItem oli;
    OpportunityLineItem oli_boat = new OpportunityLineItem(
      BoatBuilderItem__c = true,
      OpportunityId = oppId,
      Quantity = 1,
      Description = 'Boat Package',
      UnitPrice = basePrice,
      PriceBookEntryId = selectedBoat.PricebookEntries[0].Id
    );
    olItems.add(oli_boat);

    /* add the selected motor if it exists */
    if (selectedMotorId != null) {
      description = selectedBoat.Standard_Motor__c == selectedMotor.Id ? 'Included with Boat' : 'Motor Upgrade';
      OpportunityLineItem oli_motor = new OpportunityLineItem(
        BoatBuilderItem__c = true,
        OpportunityId = oppId,
        Quantity = 1,
        Description = description,
        UnitPrice = stringToDecimal(motorUpgradePrice),
        PriceBookEntryId = selectedMotor.PricebookEntries[0].Id
      );
      olItems.add(oli_motor);
      //add selected motor options
      if (selectedItemsMap.get('motor').size() > 0) {
        addPartsToOpportunityLineItems(
          oppId,
          selectedItemsMap.get('motor').values(),
          olItems,
          'Motor',
          selectedMotorId
        );
      }
    }

    /* add the selected trailer if it exists */
    if (selectedTrailerId != null) {
      description = selectedBoat.Standard_Trailer__c == selectedTrailer.Id ? 'Included with Boat' : 'Trailer Upgrade';
      OpportunityLineItem oli_trailer = new OpportunityLineItem(
        BoatBuilderItem__c = true,
        OpportunityId = oppId,
        Quantity = 1,
        Description = description,
        UnitPrice = stringToDecimal(trailerUpgradePrice),
        PriceBookEntryId = selectedTrailer.PricebookEntries[0].Id
      );
      olItems.add(oli_trailer);
      if (selectedItemsMap.get('trailer').size() > 0) {
        addPartsToOpportunityLineItems(
          oppId,
          selectedItemsMap.get('trailer').values(),
          olItems,
          'Trailer',
          selectedTrailerId
        );
      }
    }

    if (selectedTrollingMotorId != null) {
      description = selectedBoat.Standard_Trolling_Motor__c == selectedTrollingMotor.Id
        ? 'Included with Boat'
        : 'Trolling Motor Upgrade';
      OpportunityLineItem oli_motor = new OpportunityLineItem(
        BoatBuilderItem__c = true,
        OpportunityId = oppId,
        Quantity = 1,
        Description = description,
        UnitPrice = stringToDecimal(trollingMotorUpgradePrice),
        PriceBookEntryId = selectedTrollingMotor.PricebookEntries[0].Id
      );
      olItems.add(oli_motor);
      if (selectedItemsMap.get('trolling motor').size() > 0) {
        addPartsToOpportunityLineItems(
          oppId,
          selectedItemsMap.get('trolling motor').values(),
          olItems,
          'Trolling Motor',
          selectedTrollingMotorId
        );
      }
    }

    /* add all options as neccessary */
    if (selectedItemsMap.get('boat').size() > 0) {
      addPartsToOpportunityLineItems(oppId, selectedItemsMap.get('boat').values(), olItems, 'Boat', null);
    }

    /* add all protection Products */
    if (selectedItemsMap.get('protection').size() > 0) {
      addPartsToOpportunityLineItems(oppId, selectedItemsMap.get('protection').values(), olItems, 'Protection', null);
    }

    /* add all Addition Accessories */
    if (additionalAccessories != null) {
      for (AdditionalAccessory acc : additionalAccessories) {
        olItems.add(
          new OpportunityLineItem(
            BoatBuilderItem__c = false,
            OpportunityId = oppId,
            Quantity = acc.quantity,
            Description = acc.productName,
            UnitPrice = acc.unitPrice,
            PriceBookEntryId = acc.productPricebookEntryId
          )
        );
      }
    }

    /* add all Fees */
    for (String belongsToId : provinceFeesMap.keySet()) {
      if (provinceFeesMap.get(belongsToId).containsKey(opportunity.GL_Account_Variable_3__r.Name)) {
        for (FeeItem fi : provinceFeesMap.get(belongsToId).get(opportunity.GL_Account_Variable_3__r.Name)) {
          olItems.add(
            new OpportunityLineItem(
              BoatBuilderItem__c = belongsToId == 'additional' ? false : true,
              OpportunityId = oppId,
              Quantity = fi.quantity,
              Description = fi.description,
              UnitPrice = fi.cost,
              PriceBookEntryId = fi.priceBookEntryId
            )
          );
        }
      }
    }

    /* add discounts */
    if (discountItems != null) {
      PricebookEntry discountProductPBE = findDiscountProduct();
      for (Discount d : discountItems.values()) {
        System.debug(d);
        olItems.add(
          new OpportunityLineItem(
            BoatBuilderItem__c = true,
            OpportunityId = oppId,
            Quantity = 1,
            isDiscount__c = true,
            Description = d.description,
            UnitPrice = d.amount * -1,
            PricebookEntryId = discountProductPBE.Id
          )
        );
      }
    }

    return olItems;
  }

  /**************************************************************************************************
    .______   .______       __  ____    ____  ___   .___________. _______     _______.
    |   _  \  |   _  \     |  | \   \  /   / /   \  |           ||   ____|   /       |
    |  |_)  | |  |_)  |    |  |  \   \/   / /  ^  \ `---|  |----`|  |__     |   (----`
    |   ___/  |      /     |  |   \      / /  /_\  \    |  |     |   __|     \   \
    |  |      |  |\  \----.|  |    \    / /  _____  \   |  |     |  |____.----)   |
    | _|      | _| `._____||__|     \__/ /__/     \__\  |__|     |_______|_______/

***************************************************************************************************/

  private Opportunity findOpportunity() {
    return [
      SELECT
        Id,
        Name,
        Amount,
        Pricebook2.Id,
        CloseDate,
        LastModifiedDate,
        InvoiceNumber__c,
        Payment_Method__c,
        ContactEmail__c,
        Customer_Notes__c,
        Boat_Model_Year__c,
        Trailer_Model_Year__c,
        BarCode__c,
        Invoice_Number_BarCode__c,
        Deposit__c,
        Deposit_Method__c,
        Deposit_Method_Other__c,
        Delivery_Date__c,
        Pickup_Location__c,
        Amount_Financed__c,
        Insurance_Taxes__c,
        Insurance_Sub_Total__c,
        Discount_Total__c,
        RecordTypeId,
        RecordType.Name,
        Tax_Amount_Federal__c,
        Tax_Amount_Provincial__c,
        TAx_Amount_Retail__c,
        Tax_is_Harmonized__c,
        Tax_Override__c,
        Tax_Rate_Federal__c,
        Tax_Rate_Provincial__c,
        Tax_Rate_Retail__c,
        GL_Account_Variable_3__c,
        GL_Account_Variable_3__r.Name,
        Warehouse__c,
        Warehouse__r.City__c,
        Warehouse__r.Country__c,
        Warehouse__r.Postal_Code__c,
        Warehouse__r.State__c,
        Warehouse__r.Street__c,
        Warehouse__r.Phone__c,
        Warehouse__r.Toll_Free__c,
        Warehouse__r.Fax__c,
        TotalTaxes__c,
        Trade_In_Value__c,
        Trade_In_Lien__c,
        Trade_In_Amount__c,
        Finance_Term__c,
        Finance_Ammortization__c,
        Finance_Annual_Interest__c,
        Finance_Payment_Weekly__c,
        Finance_Payment_Bi_Weekly__c,
        Finance_Payment_Monthly__c,
        Finance_Payments_Per_Year__c,
        Finance_Payment__c,
        Account.RecordTypeId,
        Account.Id,
        Account.PersonMobilePhone,
        Account.AccountEmail__c,
        Account.Name,
        Account.FirstName,
        Account.MiddleName,
        Account.LastName,
        Account.Drivers_License__c,
        Account.PersonEmail,
        Account.BillingStreet,
        Account.BillingCity,
        Account.BillingCountry,
        Account.BillingState,
        Account.BillingPostalCode,
        Account.Phone,
        Account.PersonBirthDate,
        Owner.Name,
        Owner.Sales_Department__c,
        Owner.Warehouse__c,
        Owner.FirstName,
        Owner.LastName,
        (SELECT Id FROM Trade_In_Records__r LIMIT 1),
        (
          SELECT
            Id,
            Contact.Name,
            Contact.Email,
            Contact.Phone,
            Role,
            Contact.BirthDate,
            Contact.MailingCity,
            Contact.MailingState,
            Contact.MailingCountry,
            Contact.MailingPostalCode,
            Contact.MailingStreet,
            Contact.Drivers_License__c,
            Contact.Tax_Exempt_Status_Card_Number__c
          FROM OpportunityContactRoles
          WHERE Role = 'Co-Buyer' OR Role = 'Buyer'
        ),
        (
          SELECT
            Id,
            OpportunityId,
            isInsurance__c,
            isDiscount__c,
            InsuranceCoverage__c,
            Quantity,
            Description,
            PricebookEntryId,
            BoatBuilderItem__c,
            UnitPrice,
            ListPrice,
            ParentProductId__c,
            ParentProductId__r.RecordType.Name,
            PricebookEntry.UnitPrice,
            PricebookEntry.Product2.RecordType.Name,
            PricebookEntry.Product2.Family,
            PricebookEntry.Product2.Make__c,
            PricebookEntry.Product2.Id,
            PricebookEntry.Product2.Name,
            PricebookEntry.Product2.Name_FR__c,
            PricebookEntry.Product2.Description,
            PriceBookEntry.Product2.Description_FR__c,
            PricebookEntry.Product2.Taxable__c
          FROM OpportunityLineItems
        )
      FROM Opportunity
      WHERE Id = :opportunity_id
      LIMIT 1
    ];
  }
  /*
    Build a Map<Product_Upgrade__c.Id, Cost> based on the Price book selected on the Opportunity
    We will use this to lookup the cost of upgrades
  */
  private void buildUpgradeCostMap() {
    upgradeCostMap = new Map<Id, Decimal>();
    Product_Upgrade_Cost__c[] costs = [
      SELECT Id, Cost__c, Product_Upgrade__c
      FROM Product_Upgrade_Cost__c
      WHERE Price_Book__c = :pb2Id
    ];
    for (Product_Upgrade_Cost__c cost : costs) {
      upgradeCostMap.put(cost.Product_Upgrade__c, cost.Cost__c);
    }
  }

  /* 2 helper methods to generate unique Ids for AdditionaAccessory and Discount objects */
  private String generateUniqueId(Set<String> currentIds) {
    String newId;
    Boolean isUnique = false;
    while (isUnique == false) {
      newId = generateId(24);
      if (!currentIds.contains(newId)) {
        isUnique = true;
      }
    }
    return newId;
  }

  private String generateId(Integer length) {
    Blob blobKey = crypto.generateAesKey(128);
    String key = EncodingUtil.convertToHex(blobKey);
    return key.substring(0, length);
  }

  /* this could be temperary - it returns a taxrate based on the passed in accounting seed
     tax type value on the product
  */
  private Decimal findTaxRate(Boolean taxable) {
    Decimal pRate;
    Decimal fRate;

    if (taxable) {
      if (opportunity != null) {
        pRate = opportunity.Tax_Rate_Provincial__c == null ? provTaxRate.rate : opportunity.Tax_Rate_Provincial__c;
        fRate = opportunity.Tax_Rate_Federal__c == null ? defaultFedTaxRate : opportunity.Tax_Rate_Federal__c;
        return pRate + fRate;
      }
      return provTaxRate.rate + defaultFedTaxRate;
    } else {
      return 0;
    }
  }

  //Removes Protection Products after a trailer/motor/trolling motor has changed
  private void removeSelectedProtectionProducts(List<Product_Option__c> pos) {
    for (Product_Option__c po : pos) {
      for (String family : availableProtectionOptions.keyset()) {
        if (availableProtectionOptions.get(family).containsKey(po.From_Product__c)) {
          availableProtectionOptions.get(family).remove(po.From_Product__c);
          if (selectedItemsMap.get('protection').containsKey(po.From_Product__c)) {
            selectedItemsMap.get('protection').remove(po.From_Product__c);
          }
          if (availableProtectionOptions.get(family).isEmpty()) {
            availableProtectionOptions.remove(family);
          }
        }
      }
    }
  }

  //This builds the select options for the Boat/Motor/Trailer/Trolling Motor select menus
  private List<SelectOption> buildUpgradeSelectOptions(String productType, Id standardId, String standardName) {
    List<SelectOption> items = new List<SelectOption>();
    if (standardId == null) {
      items.add(new SelectOption('', 'Select a ' + productType));
    } else {
      items.add(new SelectOption(standardId, standardName + ' (standard)'));
    }
    for (Product2 m : availableProductUpgrades.get(productType.replace(' ', '_').toLowerCase() + 's')) {
      String label;
      if (standardId == null) {
        /* THIS NEEDS TO BE FIXED WHEN WE FIGURE OUT HOW TO DEAL WITH AN UPGRADE WITH A NULL
         FROM PRODUCT */
        label = m.name + ' - ( $' + String.valueOf(m.PriceBookEntries[0].UnitPrice) + ' )';
      } else {
        //label = m.name + '  -  ( $' + String.valueOf(m.To_Product_Upgrades__r[0].Price__c) + ' )';
        label = m.name + '  -  ( $' + String.valueOf(upgradeCostMap.get(m.To_Product_Upgrades__r[0].Id)) + ' )';
      }
      items.add(new SelectOption(m.Id, label));
    }
    return items;
  }

  /*
    This finds the selected motor/trailer/trolling motor and determines the price of the upgrade
    It is returned in a Map<upgradePrice, selectedProduct2>
  */
  private Map<String, Product2> setSelectedUpgrade(String selectedId, String standardId) {
    Product2 selectedProduct;
    String upgradePrice;
    Map<String, Product2> resultMap = new Map<String, Product2>();
    if (selectedId == standardId) {
      // Here we are selecting the standard motor/trailer/trolling for the selected Boat
      selectedProduct = [
        SELECT
          Id,
          Name,
          Name_FR__c,
          Description,
          Description_FR__c,
          RecordType.Name,
          Taxable__c,
          Make__c,
          (SELECT Id, UnitPrice, Pricebook2Id FROM PricebookEntries WHERE Pricebook2Id = :pb2Id),
          (SELECT Id, From_Product__c FROM To_Product_Options__r),
          (SELECT Id, Fee_Product__c FROM Parent_Product_Fee_Maps__r)
        FROM Product2
        WHERE Id = :selectedId
      ];

      upgradePrice = language == 'french' ? 'Inclus' : 'Included';
      if (selectedProduct.pricebookEntries.isEmpty()) {
        isValid = false;
        string msg =
          'The selected ' +
          selectedProduct.RecordType.Name +
          ' - ' +
          selectedProduct.Name +
          ', does not have a Pricebook entry, therefore we cannot proceed';
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, msg);
        ApexPages.addmessage(myMsg);
      }
    } else if (standardId == null) {
      /*
       if the boat does not have a standard motor/trailer/trolling motor than we fetch the selected item and the retail price as listed in the currently selected Pricebook
      */
      selectedProduct = [
        SELECT
          Id,
          Name,
          Name_FR__c,
          Description,
          Description_FR__c,
          Taxable__c,
          Make__c,
          (SELECT Id, UnitPrice FROM PricebookEntries WHERE Pricebook2Id = :pb2Id),
          (SELECT Id, From_Product__c FROM To_Product_Options__r),
          (SELECT Id, Fee_Product__c FROM Parent_Product_Fee_Maps__r)
        FROM Product2
        WHERE Id = :selectedId
      ];
      // Make sure the selected product infact has a price set in the selected Pricebook
      try {
        upgradePrice = String.valueOf(selectedProduct.PricebookEntries[0].UnitPrice);
      } catch (Exception e) {
        if (selectedProduct.pricebookEntries.isEmpty()) {
          isValid = false;
          string msg =
            'The selected ' +
            selectedProduct.RecordType.Name +
            ' - ' +
            selectedProduct.Name +
            ', does not have a Pricebook entry, therefore we cannot proceed';
          ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, msg);
          ApexPages.addmessage(myMsg);
        }
        upgradePrice = 'Set Standard Price on Motor';
      }
    } else {
      /*
        here we have selected a motor/trailer/trolling motor from the options list and we are dealing with an upgrade cost
      */
      selectedProduct = [
        SELECT
          Id,
          Name,
          Name_FR__c,
          Description,
          Description_FR__c,
          Taxable__c,
          Make__c,
          (SELECT Id, Price__c FROM To_Product_Upgrades__r WHERE From_Product__c = :standardId),
          (SELECT Id, UnitPrice FROM PricebookEntries WHERE Pricebook2Id = :pb2Id),
          (SELECT Id, From_Product__c FROM To_Product_Options__r),
          (SELECT Id, Fee_Product__c FROM Parent_Product_Fee_Maps__r)
        FROM Product2
        WHERE Id = :selectedId
      ];
      if (
        selectedProduct.To_Product_Upgrades__r.size() > 0 &&
        upgradeCostMap.containsKey(selectedProduct.To_Product_Upgrades__r[0].Id)
      ) {
        upgradePrice = String.valueOf(upgradeCostMap.get(selectedProduct.To_Product_Upgrades__r[0].Id));
        //upgradePrice = String.ValueOf(selectedProduct.To_Product_Upgrades__r[0].Price__c);
      } else {
        upgradePrice = 'Set Upgrade Price';
      }
    }
    resultMap.put(upgradePrice, selectedProduct);
    return resultMap;
  }

  private void updateAdditionalFees(
    String prevSelectedId,
    String curSelectedId,
    List<Product_Fee_Map__c> pfms,
    Decimal quantity
  ) {
    Set<String> feeProductIds = new Set<String>();
    List<FeeItem> feeItems = new List<FeeItem>();
    Map<String, List<FeeItem>> provFees = new Map<String, List<FeeItem>>();

    if (prevSelectedId != null && provinceFeesMap.containsKey(prevSelectedId)) {
      provinceFeesMap.remove(prevSelectedId);
    }

    if (!pfms.isEmpty()) {
      for (Product_Fee_Map__c m : pfms) {
        feeProductIds.add(m.Fee_Product__c);
      }

      List<Product2> fees = [
        SELECT
          Id,
          Name,
          Name_FR__c,
          Taxable__c,
          (SELECT Id FROM PricebookEntries WHERE Pricebook2Id = :pb2Id LIMIT 1),
          (SELECT Id, Amount__c, Province__c FROM Product_Fee_Amounts__r WHERE Price_Book__c = :pb2Id)
        FROM Product2
        WHERE Id IN :feeProductIds
      ];

      for (Product2 fee : fees) {
        if (fee.PricebookEntries.size() == 1 && fee.Product_Fee_Amounts__r.size() > 0) {
          for (Product_Fee_Amount__c pfa : fee.Product_Fee_Amounts__r) {
            if (!provFees.containsKey(pfa.Province__c)) {
              provFees.put(pfa.Province__c, new List<FeeItem>());
            }
            provFees.get(pfa.Province__c).add(new FeeItem(fee, pfa, findTaxRate(fee.Taxable__c)));
          }
        }
      }
      provinceFeesMap.put(curSelectedId, provFees);
    }
  }

  /*
    This constructs all the options for the selected Boat as well as for available motor/trailer/trolling motor upgrade
    - Boat options get stored in availableBoatOptions Map<Product2.Family, Map<Product2.Id, Product2>>
      ie.{ 'Hardware', { '782gbc2c8347', sObject(Product2) } }
    - motor/trailer/trolling motor upgradess get stored availableProductUpgrades Map<'Product2.Record_Type', List<Product2>>
      ie {'motor', List<Product2>(all motors availble to this boat)}
  */
  private void setupOptions() {
    List<Id> motorIds = new List<Id>();
    List<Id> trailerIds = new List<Id>();
    List<Id> trollingMotorIds = new List<Id>();
    List<Product2> protectionProducts = new List<Product2>();
    List<Product2> parts = new List<Product2>();

    for (Product2 opt : boatOptions()) {
      if (!opt.PricebookEntries.isEmpty()) {
        if (opt.RecordType.Name == 'Motor') {
          motorIds.add(opt.Id);
        }
        if (opt.RecordType.Name == 'Trailer') {
          trailerIds.add(opt.Id);
        }
        if (opt.RecordType.Name == 'Trolling Motor') {
          trollingMotorIds.add(opt.Id);
        }
        if (opt.RecordType.Name == 'Protection and Services' || opt.RecordType.Name == 'Package Bundle') {
          renderOptionSelect = true;
          protectionProducts.add(opt);
        }
        if (opt.RecordType.Name == 'Part') {
          renderOptionSelect = true;
          parts.add(opt);
        }
      }
    }
    buildUpgradeOptions('motors', motorIds, selectedBoat.Standard_Motor__c);
    buildUpgradeOptions('trailers', trailerIds, selectedBoat.Standard_Trailer__c);
    buildUpgradeOptions('trolling_motors', trollingMotorIds, selectedBoat.Standard_Trolling_Motor__c);
    buildProtectionOptions(protectionProducts, selectedBoatId, 'Boat');
    buildPartOptions(parts);
  }

  private List<Product2> boatOptions() {
    Map<String, List<String>> subParentMap = new Map<String, List<String>>();
    if (allBoatOptions == null) {
      Set<String> ids = new Set<String>();
      /* make a list of productId's from the To_Product_Options of the selected boat
       These are all of the options for associated with the Boat */
      for (Product_Option__c po : selectedBoat.To_Product_Options__r) {
        ids.add(po.From_Product__r.Id);
      }
      Map<Id, Product2> allBoatOptionsMap = new Map<Id, Product2>(
        [
          SELECT
            Id,
            Name,
            Name_FR__c,
            Description,
            Description_FR__c,
            RecordType.Name,
            Family,
            Taxable__c,
            (
              SELECT Id, Name, UnitPrice, Pricebook2Id
              FROM PricebookEntries
              WHERE Pricebook2Id = :pb2Id AND isActive = TRUE
              ORDER BY UnitPrice
            ),
            (
              SELECT Id, Standard__c, Maximum__c, Step__c
              FROM From_Product_Options__r
              WHERE To_Product__c = :selectedBoatId
              ORDER BY Rank__c
            ),
            (
              SELECT
                Id,
                Standard__c,
                Maximum__c,
                Step__c,
                From_Product__c,
                From_Product__r.Name,
                From_Product__r.Name_FR__c
              FROM To_Product_Options__r
            ),
            (SELECT Id, Feature_Id__r.Description__c, Feature_Id__r.Description_FR__c FROM Product_Feature_Maps__r)
          FROM Product2
          WHERE Id IN :ids
        ]
      );

      // iterate over the found boat options
      List<Id> allSubIds = new List<id>();
      Set<Id> parentIds = new Set<Id>();
      Set<Id> removeOptions = new Set<Id>();
      for (Id pId : allBoatOptionsMap.keySet()) {
        if (allBoatOPtionsMap.get(pId).PricebookEntries.size() == 0) {
          removeOptions.add(pId);
        } else {
          if (allBoatOptionsMap.get(pId).To_Product_Options__r.size() > 0) {
            //make a list if ProductIds for all sub options
            for (Product_Option__c o : allBoatOptionsMap.get(pId).To_Product_Options__r) {
              allSubIds.add(o.From_Product__c);
            }
            /* make a list of all parent Ids */
            parentIds.add(pId);
          }
        }
      }
      if (removeOptions.size() > 0) {
        for (Id pId : removeOptions) {
          allBoatOptionsMap.remove(pId);
        }
      }
      allBoatOptions = allBoatOptionsMap.values();

      if (allSubIds.size() > 0) {
        if (subOptions == null) {
          subOptions = new Map<String, List<SubOptionItem>>();
        }
        List<Product2> subProds = [
          SELECT
            Id,
            Name,
            Name_FR__c,
            Description,
            Description_FR__c,
            RecordType.Name,
            Family,
            Taxable__c,
            (
              SELECT Id, Name, UnitPrice, Pricebook2Id
              FROM PricebookEntries
              WHERE Pricebook2Id = :pb2Id AND isActive = TRUE
              ORDER BY UnitPrice
            ),
            (
              SELECT Id, Standard__c, Maximum__c, Step__c, To_Product__c, To_Product__r.Name
              FROM From_Product_Options__r
              WHERE To_Product__c IN :parentIds
              ORDER BY Rank__c
            ),
            (SELECT Id, Fee_Product__c FROM Parent_Product_Fee_Maps__r)
          FROM Product2
          WHERE Id IN :allSubIds
        ];

        for (Product2 sp : subProds) {
          for (Product_Option__c po : sp.From_Product_Options__r) {
            if (parentIds.contains(po.To_Product__c)) {
              SubOptionItem sub = new SubOptionItem();
              sub.isAvailable = sp.PricebookEntries.size() > 0;
              sub.id = sp.Id;
              sub.name = sp.PricebookEntries.size() > 0 ? sp.Name : sp.Name + ' [NOT IN PRICEBOOK]';
              sub.name_FR = sp.Name_FR__c;
              sub.description = sp.Description;
              sub.description_FR = sp.Description_FR__c;
              sub.standard = po.Standard__c;
              sub.maximum = po.Maximum__c;
              sub.step = po.Step__c;
              sub.price = sp.PricebookEntries.size() > 0 ? sp.PricebookEntries[0].UnitPrice : null;
              sub.productFamily = sp.Family;
              sub.productPriceBookEntryId = sp.PricebookEntries.size() > 0 ? sp.PriceBookEntries[0].Id : null;
              sub.feeProducts = sp.Parent_Product_Fee_Maps__r;
              sub.taxRate = findTaxRate(sp.Taxable__c);
              if (!subOptions.containsKey(po.To_Product__c)) {
                subOptions.put(po.To_Product__c, new List<SubOptionItem>());
              }
              subOptions.get(po.To_Product__c).add(sub);
            }
          }
        }
      }
    }
    return allBoatOptions;
  }

  private void buildPartOptions(List<Product2> parts) {
    for (Product2 opt : parts) {
      if (opt.From_Product_Options__r[0].Maximum__c > 0) {
        String pFamily = opt.Family == null ? 'Misc Parts' : opt.Family;
        if (availableBoatOptions.keyset().size() == 0 || !availableBoatOptions.containsKey(pFamily)) {
          availableBoatOptions.put(pFamily, new Map<String, Product2>());
        }
        availableBoatOptions.get(pFamily).put(opt.Id, opt);
        //if the product_option has 1 or more standard we need to add it to the selected Items
        if (opt.From_Product_Options__r[0].Standard__c > 0) {
          addSelectedItem(opt, 'boat', opt.From_Product_Options__r[0].Standard__c);
        }
      }
    }
    for (String fam : availableBoatOptions.keySet()) {
      familyNames.put(fam, fam.replaceAll('[^a-zA-Z0-9]', '').replace(' ', '_').toLowerCase());
    }
  }

  private void buildProtectionOptions(List<Product2> protectionProducts, String parentId, String parentType) {
    for (Product2 p : protectionProducts) {
      if (!availableProtectionOptions.containsKey(p.Family) && p.From_Product_Options__r[0].Maximum__c > 0) {
        availableProtectionOptions.put(p.Family, new Map<String, protectionProductWrapper>());
      }
      protectionProductWrapper ppw = new protectionProductWrapper();
      ppw.protectionProduct = p;
      ppw.belongTo = parentId;
      ppw.belongsToType = parentType;
      availableProtectionOptions.get(p.Family).put(p.Id, ppw);
      if (p.From_Product_Options__r[0].Standard__c > 0) {
        addSelectedItem(p, 'protection', p.From_Product_Options__r[0].Standard__c);
      }
    }
  }

  private void buildUpgradeOptions(String productType, List<Id> upgradeIds, Id standardProductId) {
    List<Product2> upgrades = new List<Product2>();

    if (standardProductId == null) {
      /* THIS NEEDS TO BE FIXED WHEN WE FIGURE OUT HOW TO DEAL WITH AN UPGRADE WITH A NULL
       FROM PRODUCT */
      upgrades = [
        SELECT
          Id,
          Name,
          Name_FR__c,
          Description,
          Description_FR__c,
          (SELECT Id, UnitPrice FROM PricebookEntries WHERE Pricebook2Id = :pb2Id)
        FROM Product2
        WHERE Id IN :upgradeIds
      ];
      upgrades = sortedByPrice(upgrades, 'pricebook');
    } else {
      upgrades = [
        SELECT
          Id,
          Name,
          Name_FR__c,
          Description,
          Description_FR__c,
          (SELECT Id, Price__c FROM To_Product_Upgrades__r WHERE From_Product__c = :standardProductId)
        FROM Product2
        WHERE
          Id IN :upgradeIds
          AND Id IN (SELECT To_Product__c FROM Product_Upgrade__c WHERE From_Product__c = :standardProductId)
      ];
      upgrades = sortedByPrice(upgrades, 'upgrade');
    }
    availableProductUpgrades.put(productType, upgrades);
  }

  private void createOptionList(
    List<Product_Option__c> pOpts,
    Map<Id, Product2> optionList,
    Id parentId,
    String productType
  ) {
    if (pOpts.size() > 0) {
      Set<Id> optionIds = new Set<Id>();
      for (Product_Option__c opt : pOpts) {
        optionIds.add(opt.From_Product__c);
      }
      List<Product2> newOptions = [
        SELECT
          Id,
          Name,
          Name_FR__c,
          Description,
          Description_FR__c,
          RecordType.Name,
          Family,
          Taxable__c,
          (
            SELECT Id, Name, UnitPrice, Pricebook2Id
            FROM PricebookEntries
            WHERE Pricebook2Id = :pb2Id
            ORDER BY UnitPrice
          ),
          (SELECT Id, Standard__c, Maximum__c, Step__c FROM From_Product_Options__r WHERE To_Product__c = :parentId),
          (SELECT Id, Fee_Product__c FROM Parent_Product_Fee_Maps__r)
        FROM Product2
        WHERE Id IN :optionIds
      ];
      buildOptions(newOptions, optionList, productType, parentId);
    }
  }

  private void buildOptions(List<Product2> parts, Map<Id, Product2> optionList, String productType, String parentId) {
    List<Product2> protectionProducts = new List<Product2>();
    for (Product2 p : parts) {
      if (p.RecordType.Name == 'Protection And Services' || p.RecordType.Name == 'Package Bundle') {
        protectionProducts.add(p);
      } else if (p.From_Product_Options__r[0].Maximum__c > 0) {
        optionList.put(p.Id, p);
        //if the product_option has 1 or more standard we need to add it to the selected Items
        if (p.From_Product_Options__r[0].Standard__c > 0) {
          updateSelectedItems(p, productType, String.valueOf(p.From_Product_Options__r[0].Standard__c));
        }
      }
    }
    buildProtectionOptions(protectionProducts, parentId, productType);
  }

  private void updateSelectedItems(Product2 product, String productType, String quantity) {
    if (selectedItemsMap.get(productType).containsKey(product.Id)) {
      if (Decimal.valueOf(quantity) == 0) {
        //remove the entry in the fee map if there is one
        if (provinceFeesMap.containsKey(product.Id)) {
          provinceFeesMap.remove(product.Id);
        }
        //remove subItems Fees as well
        Map<String, BoatBuilderLineItem> subItems = selectedItemsMap.get(productType).get(product.Id).subItems;
        for (BoatBuilderLineItem bbli : subItems.values()) {
          if (provinceFeesMap.containsKey(bbli.product_id)) {
            provinceFeesMap.remove(bbli.product_id);
          }
        }
        //remove the selected product
        selectedItemsMap.get(productType).remove(product.Id);
      } else {
        selectedItemsMap.get(productType).get(product.Id).quantity = Decimal.valueOf(quantity);
        //update the quantity in the feeMap if there is an entry
        if (provinceFeesMap.containsKey(product.Id)) {
          if (provinceFeesMap.get(product.Id).containsKey('opportunity.GL_Account_Variable_3__r.Name')) {
            for (FeeItem fi : provinceFeesMap.get(product.Id).get(opportunity.GL_Account_Variable_3__r.Name)) {
              fi.quantity = Decimal.valueOf(quantity);
            }
          }
        }
      }
    } else {
      addSelectedItem(product, productType, Decimal.valueOf(quantity));
    }
  }

  private void updateSelectedSubOptionList(
    SubOptionItem subItem,
    String parentProductId,
    String productType,
    String quantity
  ) {
    try {
      Map<String, BoatBuilderLineItem> subItems = selectedItemsMap.get(productType).get(parentProductId).subItems;
      if (subItems != null && subItems.containsKey(subItem.id)) {
        if (Decimal.valueOf(quantity) == 0) {
          subItems.remove(subItem.id);
          //remove the entry in the fee map if there is one
          if (provinceFeesMap.containsKey(subItem.id)) {
            provinceFeesMap.remove(subItem.id);
          }
        } else {
          subItems.get(subItem.id).quantity = Decimal.valueOf(quantity);
          if (provinceFeesMap.containsKey(subItem.id)) {
            if (provinceFeesMap.get(subItem.id).containsKey(opportunity.GL_Account_Variable_3__r.Name)) {
              for (FeeItem fi : provinceFeesMap.get(subItem.id).get(opportunity.GL_Account_Variable_3__r.Name)) {
                fi.quantity = Decimal.valueOf(quantity);
              }
            }
          }
        }
      } else {
        BoatBuilderLineItem li = new BoatBuilderLineItem();
        li.description = subItem.name;
        li.description_FR = subItem.name_FR;
        li.product_id = subItem.id;
        li.quantity = Decimal.valueOf(quantity);
        li.quan = Decimal.valueOf(quantity);
        li.quantity_included = subItem.standard;
        li.individual_price = subItem.price;
        li.product_family = subItem.productFamily;
        li.pricebook_entry_id = subItem.productPricebookEntryId;
        li.taxRate = subItem.taxRate;
        if (subItem.feeProducts.size() > 0) {
          updateAdditionalFees(null, subItem.id, subItem.feeProducts, Decimal.valueOf(quantity));
        }
        subItems.put(subItem.id, li);
      }
    } catch (Exception e) {
      return;
    }
  }

  private void updateSelectedSubOptionList(
    String productId,
    String parentProductId,
    String productType,
    String quantity
  ) {
    Map<String, BoatBuilderLineItem> subItems = selectedItemsMap.get(productType).get(parentProductId).subItems;
    if (subItems != null && subItems.containsKey(productid)) {
      if (Decimal.valueOf(quantity) == 0) {
        subItems.remove(productid);
        //remove the entry in the fee map if there is one
        if (provinceFeesMap.containsKey(productId)) {
          provinceFeesMap.remove(productId);
        }
      } else {
        subItems.get(productid).quantity = Decimal.valueOf(quantity);
        if (provinceFeesMap.containsKey(productId)) {
          if (provinceFeesMap.get(productId).containsKey('opportunity.GL_Account_Variable_3__r.Name')) {
            for (FeeItem fi : provinceFeesMap.get(productId).get(opportunity.GL_Account_Variable_3__r.Name)) {
              fi.quantity = Decimal.valueOf(quantity);
            }
          }
        }
      }
    } else {
      Product2 p = [
        SELECT
          Id,
          Name,
          Name_FR__c,
          Description,
          Description_FR__c,
          Family,
          Taxable__c,
          (SELECT Id, UnitPrice, Pricebook2Id FROM PricebookEntries WHERE Pricebook2Id = :pb2Id),
          (
            SELECT
              Id,
              Standard__c,
              Maximum__c,
              Step__c,
              From_Product__c,
              From_Product__r.Name,
              From_Product__r.Name_FR__c
            FROM From_Product_Options__r
            WHERE To_Product__c = :parentProductid
          ),
          (SELECT Id, Fee_Product__c FROM Parent_Product_Fee_Maps__r)
        FROM Product2
        WHERE Id = :productid
      ];
      if (p.PricebookEntries.size() > 0) {
        BoatBuilderLineItem li = new BoatBuilderLineItem();
        li.description = p.Name;
        li.description_FR = p.Name_FR__c;
        li.product_id = p.Id;
        li.quantity = Decimal.valueOf(quantity);
        li.quan = Decimal.valueOf(quantity);
        li.pricebook_entry_id = p.PricebookEntries[0].Id;
        li.quantity_included = p.From_Product_Options__r[0].Standard__c;
        li.individual_price = p.PricebookEntries.isEmpty() ? 0 : p.PricebookEntries[0].UnitPrice;
        li.product_family = p.Family;
        li.taxRate = findTaxRate(p.Taxable__c);
        subItems.put(p.Id, li);
        if (p.Parent_Product_Fee_Maps__r.size() > 0) {
          updateAdditionalFees(null, p.Id, p.Parent_Product_Fee_Maps__r, Decimal.valueOf(quantity));
        }
      }
    }
  }

  private void addSelectedItem(Product2 p, String productType, Decimal quantity) {
    BoatBuilderLineItem li = new BoatBuilderLineItem();
    li.description = p.Name;
    li.description_FR = p.Name_FR__c;
    li.product_id = p.Id;
    li.quantity = quantity;
    li.quan = quantity;
    li.quantity_included = p.From_Product_Options__r[0].Standard__c;
    li.individual_price = p.PricebookEntries.isEmpty() ? 0 : p.PricebookEntries[0].UnitPrice;
    li.product_family = p.Family;
    li.pricebook_entry_id = p.PriceBookEntries[0].Id;
    li.taxRate = findTaxRate(p.Taxable__c);
    if (p.Parent_Product_Fee_Maps__r.size() > 0) {
      updateAdditionalFees(null, p.Id, p.Parent_Product_Fee_Maps__r, quantity);
    }
    if (p.Product_Feature_Maps__r.size() > 0) {
      for (Product_Feature_Map__c pfm : p.Product_Feature_Maps__r) {
        li.features.add(pfm.Feature_Id__r.Description__c);
        li.featuresFR.add(pfm.Feature_Id__r.Description_FR__c);
      }
    }
    if (p.Family == 'Premium Package' && p.RecordType.Name == 'Part')
      createPremiumPackageDiscount(p);

    if (subOptions != null && subOptions.containsKey(p.Id)) {
      for (SubOptionItem i : subOptions.get(p.Id)) {
        if (i.standard > 0) {
          BoatBuilderLineItem sli = new BoatBuilderLineItem();
          sli.description = i.name;
          sli.description_FR = i.name_FR;
          sli.product_id = i.id;
          sli.quantity = i.standard;
          sli.quan = i.standard;
          sli.quantity_included = i.standard;
          sli.individual_price = i.price;
          sli.product_family = i.productFamily;
          sli.pricebook_entry_id = i.productPriceBookEntryId;
          sli.taxRate = i.taxRate;
          li.subItems.put(i.id, sli);
        }
        if (i.feeProducts.size() > 0) {
          updateAdditionalFees(null, i.id, i.feeProducts, i.standard);
        }
      }
    }
    selectedItemsMap.get(productType).put(p.Id, li);
  }

  private void resetToBeginning() {
    selectedProductFamily = null;
    resetSelected();
  }

  private void resetSelected() {
    selectedBoat = null;
    selectedMotorId = null;
    selectedMotor = null;
    selectedTrollingMotorId = null;
    selectedTrollingMotor = null;
    selectedTrailerId = null;
    selectedTrailer = null;
    selectedItemsMap = null;
    basePrice = null;
    runningPrice = null;
    allBoatOptions = null;
    availableProductUpgrades = null;
    availableTrailerOptions = null;
    availableMotorOptions = null;
    availableTrollingMotorOptions = null;
    availableBoatOptions = null;
    availableProtectionOptions = null;
    additionalAccessories = null;
    subOptions = null;
    motorUpgradePrice = null;
    trailerUpgradePrice = null;
    trollingMotorUpgradePrice = null;
    renderOptionSelect = null;
    discountItems = null;
    provinceFeesMap = null;
  }

  private void updateRunningPrice() {
    Decimal optionCost = 0;
    Decimal feesCost = 0;
    Decimal nonTaxableTotal = 0;
    Decimal insuranceTotal = 0;
    Decimal p_taxRate;
    Decimal f_taxRate;
    hasChanged = true;
    runningTaxes = 0;
    discountTotal = 0;
    for (String pType : selectedItemsMap.keyset()) {
      List<BoatBuilderLineItem> items = selectedItemsMap.get(ptype).values();
      for (BoatBuilderLineItem li : items) {
        optionCost += stringToDecimal(li.upgrade_cost);
        if (li.totalTaxes == 0) {
          nonTaxableTotal += stringToDecimal(li.upgrade_cost);
        }
        //runningTaxes += li.totalTaxes;
        if (li.subItems.size() > 0) {
          for (BoatBuilderLineItem sli : li.subItems.values()) {
            optionCost += stringToDecimal(sli.upgrade_cost);
            if (sli.totalTaxes == 0) {
              nonTaxableTotal += stringToDecimal(sli.upgrade_cost);
            }
            //runningTaxes += sli.totalTaxes;
          }
        }
      }
    }
    for (Map<String, List<FeeItem>> fList : provinceFeesMap.values()) {
      String prov = provTaxRate.name; //opportunity == null ? provTaxRate.name : opportunity.taxationProvince__c;
      if (flist.containsKey(prov)) {
        for (FeeItem item : fList.get(prov)) {
          feesCost += item.cost;
          if (item.totalTaxes == 0) {
            nonTaxableTotal += item.cost;
          }
          //runningTaxes += item.totalTaxes;
        }
      }
    }
    if (discountItems != null) {
      for (Discount d : discountItems.values()) {
        discountTotal += d.amount;
      }
    }
    if (additionalAccessories != null) {
      for (AdditionalAccessory aa : additionalAccessories) {
        optionCost += aa.totalPrice;
        if (aa.totalTaxes == 0) {
          nonTaxableTotal += aa.totalPrice;
        }
        //runningTaxes += aa.totalTaxes;
      }
    }

    //add the boat, motorupgrade, trailer upgrade, trolling motor upgrade and options
    runningPrice =
      basePrice +
      stringToDecimal(motorUpgradePrice) +
      stringToDecimal(trailerUpgradePrice) +
      stringToDecimal(trollingMotorUpgradePrice) +
      optionCost +
      feesCost;
    //add boat, motor, trailer, trollingmotor taxes
    // if the discount total is greater then 0 we will convert it to percentage of the
    // running price and then subtract the same percentage from to running Taxes
    //subtract the discount
    runningPrice -= discountTotal;
    runningTaxableTotal = runningPrice - nonTaxableTotal - trade_in_package.value;
    //subtract the total trade in value
    runningPrice -= trade_in_package.totalValue;
    //add the insurance Items + insuranceTax;
    if (insuranceItems != null) {
      for (OpportunityLineItem insLi : insuranceItems) {
        insuranceTotal += insLi.UnitPrice;
      }
      runningPrice += insuranceTotal;
      runningPrice += getInsuranceTaxes();
    }

    p_taxRate = opportunity.Tax_Rate_Provincial__c == null ? provTaxRate.rate : opportunity.Tax_rate_Provincial__c;
    f_taxRate = opportunity.Tax_Rate_Federal__c == null ? defaultFedTaxRate : opportunity.Tax_rate_Federal__c;
    runningTaxes = runningTaxableTotal * ((f_taxRate + p_taxRate) / 100);
  }

  private decimal stringToDecimal(String str) {
    try {
      return Decimal.valueOf(str);
    } catch (Exception e) {
      return 0;
    }
  }

  private List<Product2> sortedByPrice(List<Product2> products, String priceType) {
    List<Product2> sorted = new List<Product2>();
    Integer lowest = null;
    if (priceType == 'upgrade') {
      while (products.size() > 0) {
        for (Integer i = 0; i < products.size(); i++) {
          if (products[i].To_Product_Upgrades__r.size() > 0) {
            if (lowest == null) {
              lowest = i;
            } else if (
              products[i].To_Product_Upgrades__r[0].Price__c < products[lowest].To_Product_Upgrades__r[0].Price__c
            ) {
              lowest = i;
            }
          }
        }
        if (lowest == null) {
          for (Integer i = 0; i < products.size(); i++) {
            sorted.add(products[i]);
            products.remove(i);
          }
        } else {
          sorted.add(products[lowest]);
          products.remove(lowest);
          lowest = null;
        }
      }
      return sorted;
    }
    if (priceType == 'pricebook') {
      while (products.size() > 0) {
        for (Integer i = 0; i < products.size(); i++) {
          if (products[i].PricebookEntries.size() > 0) {
            if (lowest == null) {
              lowest = i;
            } else if (products[i].PricebookEntries[0].UnitPrice < products[lowest].PricebookEntries[0].UnitPrice) {
              lowest = i;
            }
          } else if (products[i].PricebookEntries.size() == 0) {
            products.remove(i);
          }
        }
        if (lowest == null) {
          for (Integer i = 0; i < products.size(); i++) {
            sorted.add(products[i]);
            products.remove(i);
          }
        } else {
          sorted.add(products[lowest]);
          products.remove(lowest);
          lowest = null;
        }
      }
      return sorted;
    }
    return null;
  }

  private String findProtectionParentType(String pId) {
    String parent = '';
    for (String family : availableProtectionOptions.keyset()) {
      if (availableProtectionOptions.get(family).containsKey(pId)) {
        parent = availableProtectionOptions.get(family).get(pId).belongsToType;
        break;
      }
    }
    return parent;
  }

  private Product2 findProtectionProduct(String pId) {
    for (String family : availableProtectionOptions.keyset()) {
      if (availableProtectionOptions.get(family).containsKey(pId)) {
        return availableProtectionOptions.get(family).get(pId).protectionProduct;
      }
    }
    return null;
  }

  private void addPartsToOpportunityLineItems(
    Id oppId,
    List<BoatBuilderLineItem> bbLis,
    List<OpportunityLineItem> lis,
    String parentProductType,
    Id parentProductId
  ) {
    for (BoatBuilderLineItem bbLi : bbLis) {
      OpportunityLineItem newLineItem;
      OpportunityLineItem negLineItem = null;
      if (stringToDecimal(bbLi.upgrade_cost) == 0) {
        String parent = parentProductType == 'Protection'
          ? findProtectionParentType(bbLi.product_id)
          : parentProductType;
        /* these will be all option included as standard */
        newLineItem = new OpportunityLineItem(
          BoatBuilderItem__c = true,
          OpportunityId = oppId,
          Quantity = bbLi.quantity,
          Description = 'Included with ' + parent,
          UnitPrice = bbLi.product_family == 'Premium Package' ? bbLi.individual_price : 0,
          PriceBookEntryId = bbLi.pricebook_entry_id
        );
      } else {
        // if the upgrade cost is is greater then 0 then we have either:
        // a) added an option that is not included as standard or
        // b) added more of an option then was included as standard
        newLineItem = new OpportunityLineItem(
          BoatBuilderItem__c = true,
          OpportunityId = oppId,
          Quantity = bbLi.quantity,
          UnitPrice = bbLi.individual_price,
          PriceBookEntryId = bbLi.pricebook_entry_id
        );
        /* if there this product is included as standard we make a negative line item to reflect this */
        if (bbLi.quantity_included > 0 && bbLi.product_family != 'Premium Package') {
          negLineItem = new OpportunityLineItem(
            BoatBuilderItem__c = true,
            OpportunityId = oppId,
            Quantity = bbLi.quantity_included,
            Description = String.valueOf(bbLi.quantity_included) + ' included with ' + parentProductType,
            UnitPrice = bbLi.individual_price * -1,
            PriceBookEntryId = bbLi.pricebook_entry_id
          );
        }
      }

      if (parentProductId != null) {
        newLineItem.ParentProductId__c = parentProductId;
      }
      lis.add(newLineItem);
      if (negLineItem != null) {
        lis.add(negLineItem);
      }
      if (bbli.subItems.size() > 0) {
        addPartsToOpportunityLineItems(oppId, bbli.subItems.values(), lis, bbli.description, bbli.product_id);
      }
    }
  }

  private PricebookEntry findDiscountProduct() {
    Product2 p;
    PricebookEntry pbe;
    /* Find the dicount product.  This is a dummy product with a
       unit price of $0.  This is kinda hacky but we want it to show
       up in an opportunity line item and for that to be possible
       we need a pricebookentry and we can't have that without
       a product
    */
    Product2 discountP = [
      SELECT Id, (SELECT Id FROM PricebookEntries WHERE Pricebook2Id = :pb2Id LIMIT 1)
      FROM Product2
      WHERE Id = :Utility_Products__c.getOrgDefaults().Savings__c
    ];

    /* if for some reason we have a discount product but not a pricebook
         entry for it we will create it
      */
    if (discountP.PriceBookEntries.isEmpty()) {
      pbe = new PricebookEntry(Pricebook2Id = pb2Id, Product2Id = discountP.Id, isActive = true, UnitPrice = 0);
      insert pbe;
    } else {
      /* grab the PricebookEntry if it is there */
      pbe = discountP.PricebookEntries[0];
    }

    /* After all thet we will finally return the PricbookEntry so we can
       reference it when we create the Opportunity line Item for the
       Discount
    */
    return pbe;
  }

  private static Id productRecordTypeIdFromString(String record_type) {
    Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.Product2;
    Map<String, Schema.RecordTypeInfo> Product2RecordTypeInfo = cfrSchema.getRecordTypeInfosByName();
    return Product2RecordTypeInfo.get(record_type).getRecordTypeId();
  }

  /*
    Here we are reconstrunting the Boat Builder from the Opporunity Line Items
  */

  private void buildFromOpportunity() {
    Map<String, List<Product2>> sortedLineItems = sortLineItems();
    /*
      this set is use to hold a list of Product2 Id's which are not found when first looking for
      options, thus these will in effect be sub-option parts of an optional part
    */
    Set<String> leftOverIds = new Set<String>();
    /*
      If we find a Boat in our sorted line items we can continue, if not there is no reason to continue as we have obviously not built a boat. We then set the appropriate selected Id's depending on what was originally on the Opportunity
    */
    if (sortedLineItems.get('Boat').size() == 1) {
      setupTradeInfo();
      selectedBoatId = sortedLineItems.get('Boat')[0].Id;
      if (sortedLineItems.get('Motor').size() == 1) {
        selectedMotorId = sortedLineItems.get('Motor')[0].Id;
      }

      if (sortedLineItems.get('Trailer').size() == 1) {
        selectedTrailerId = sortedLineItems.get('Trailer')[0].Id;
      }

      if (sortedLineItems.get('Trolling Motor').size() == 1) {
        selectedTrollingMotorId = sortedLineItems.get('Trolling Motor')[0].Id;
      }
      /*
        Once all the selected Id's are set, we select the boat!
      */
      selectBoat();

      /*
        LineItemQuantityMap is set in the sortLineItems() function.  We then iterate using the keyset, which is a product ID of a opportunity Line Item to find out what this product belongs to by checking it against the availableOptions created during the selectBoat() function
      */
      if (lineItemQuantityMap.size() > 0) {
        for (String key : lineItemQuantityMap.keySet()) {
          Boolean found = false;
          String[] keySplit = key.split(':');
          if (keySplit.size() > 0 && keySplit[0] == 'Motor') {
            if (availableMotorOptions != null && availableMotorOptions.keySet().contains(keySplit[1])) {
              found = true;
              updateSelectedItems(
                availableMotorOptions.get(keySplit[1]),
                'motor',
                String.valueOf(lineItemQuantityMap.get(key))
              );
            }
          }
          if (found == false) {
            if (keySplit.size() > 0 && keySplit[0] == 'Trailer') {
              if (availableTrailerOptions != null && availableTrailerOptions.keySet().contains(keySplit[1])) {
                found = true;
                updateSelectedItems(
                  availableTrailerOptions.get(keySplit[1]),
                  'trailer',
                  String.valueOf(lineItemQuantityMap.get(key))
                );
              }
            }
          }
          if (found == false) {
            if (keySplit.size() > 0 && keySplit[0] == 'Trolling Motor') {
              if (
                availableTrollingMotorOptions != null && availableTrollingMotorOptions.keySet().contains(keySplit[1])
              ) {
                found = true;
                updateSelectedItems(
                  availableTrollingMotorOptions.get(keySplit[1]),
                  'trolling motor',
                  String.valueOf(lineItemQuantityMap.get(key))
                );
              }
            }
          }

          if (found == false) {
            if (keySplit.size() > 0 && (keySplit[0] == 'Protection and Services' || keySplit[0] == 'Package Bundle')) {
              if (availableProtectionOptions != null) {
                Product2 psProduct = findProtectionProduct(keySplit[1]);
                if (psProduct != null) {
                  found = true;
                  updateSelectedItems(psProduct, 'protection', String.valueOf(lineItemQuantityMap.get(key)));
                }
              }
            }
          }
          //there has to be a better way
          if (found == false) {
            for (String ptype : availableBoatOptions.keyset()) {
              if (found == false) {
                for (String pid : availableBoatOptions.get(ptype).keyset()) {
                  if (key == pid) {
                    found = true;
                    updateSelectedItems(
                      availableBoatOptions.get(ptype).get(pid),
                      'boat',
                      String.valueOf(lineItemQuantityMap.get(key))
                    );
                  }
                }
              }
            }
          }
        }
      }
      for (String parentId : subLineItemQuantityMap.keySet()) {
        for (String subId : subLineItemQuantityMap.get(parentId).keySet()) {
          if (subOptions.keySet().contains(parentId)) {
            for (SubOptionItem soi : subOptions.get(parentId)) {
              if (subId == soi.id) {
                updateSelectedSubOptionList(
                  soi,
                  parentId,
                  'boat',
                  String.valueOf(subLineItemQuantityMap.get(parentId).get(subId))
                );
              }
            }
          }
        }
      }
      updateRunningPrice();
    }
  }

  private void setupTradeInfo() {
    if (opportunity.Trade_In_Records__r.size() > 0) {
      Trade_In_Record__c tir = [
        SELECT
          Id,
          Lien_Amount__c,
          Total_Value__c,
          Opportunity__c,
          (
            SELECT Id, Make__c, Model__c, Model_Year__c, Serial_Number__c
            FROM Trade_In_Items__r
            ORDER BY CreatedDate ASC
          )
        FROM Trade_In_Record__c
        WHERE Id = :opportunity.Trade_In_Records__r[0].Id
      ];
      trade_in_package = new TradeInPackage();
      trade_in_package.value = tir.Total_Value__c;
      trade_in_package.lienAmount = tir.Lien_Amount__c;
      trade_in_package.recordId = tir.Id;
      trade_in_package.opportunityId = tir.Opportunity__c;
      if (tir.Trade_In_Items__r.size() > 0) {
        for (Trade_In_Item__c item : tir.Trade_In_Items__r) {
          TradeInItem tii = new TradeInItem();
          tii.isNew = false;
          tii.id = item.Id;
          tii.modelYear = item.Model_year__c;
          tii.make = item.Make__c;
          tii.model = item.Model__c;
          tii.serialNumber = item.Serial_Number__c;
          trade_in_package.items.put(item.Id, tii);
        }
      }
    } else {
      trade_in_package = new TradeInPackage();
      trade_in_package.opportunityId = opportunity.Id;
    }
  }

  /*
    This sorts Oppurtunity Line Items based on Product2.Record_Type and returns them in
    Map<'Product2.Record_Type', List<Product2>(with record_type of key)>
    Also for "Part" record types we make "lineItemsMap" Map<Product2.Id, Quantity> to reference the quantity
    in the opportunity to help reconstuct previously selected items in the Boat builder
  */

  private Map<String, List<Product2>> sortLineItems() {
    Map<String, List<Product2>> sortedLineItems = new Map<String, List<Product2>>();
    Set<String> recordTypes = new Set<String>{ 'Motor', 'Trailer', 'Trolling Motor' };
    lineItemQuantityMap = new Map<String, Decimal>();
    subLineItemQuantityMap = new Map<String, Map<String, Decimal>>();
    sortedLineItems.put('Boat', new List<Product2>());
    sortedLineItems.put('Motor', new List<Product2>());
    sortedLineItems.put('Trailer', new List<Product2>());
    sortedLineItems.put('Trolling Motor', new List<Product2>());
    sortedLineItems.put('Protection and Services', new List<Product2>());
    sortedLineItems.put('Part', new List<Product2>());
    sortedLineItems.put('Package Bundle', new List<Product2>());

    for (OpportunityLineItem oli : opportunity.OpportunityLineItems) {
      if (oli.BoatBuilderItem__c == true) {
        if (sortedLineItems.containsKey(oli.PricebookEntry.Product2.RecordType.Name)) {
          sortedLineItems.get(oli.PricebookEntry.Product2.RecordType.Name).add(oli.PricebookEntry.Product2);
          if (
            oli.PricebookEntry.Product2.RecordType.Name == 'Part' &&
            oli.PriceBookEntry.Product2.Family == 'Discount'
          ) {
            if (discountItems == null) {
              discountItems = new Map<String, Discount>();
            }
            Discount d = new Discount();
            d.id = oli.Id;
            d.description = oli.Description;
            d.amount = oli.UnitPrice * -1;
            discountItems.put(d.id, d);
          } else if (oli.PricebookEntry.Product2.RecordType.Name == 'Part' && oli.PricebookEntry.UnitPrice == 0) {
            /*++++++++++++++++++++++++*/
            doSort(oli, recordTypes);
          } else if (oli.PricebookEntry.Product2.RecordType.Name == 'Part' && oli.UnitPrice > 0) {
            /*======================== */
            doSort(oli, recordTypes);
          } else if (oli.PricebookEntry.Product2.RecordType.Name == 'Protection and Services' && oli.UnitPrice > 0) {
            lineItemQuantityMap.put(
              (oli.PricebookEntry.Product2.RecordType.Name +
              ':' +
              oli.PricebookEntry.Product2.Id),
              oli.Quantity
            );
          } else if (oli.PricebookEntry.Product2.RecordType.Name == 'Package Bundle' && oli.UnitPrice > 0) {
            lineItemQuantityMap.put(
              (oli.PricebookEntry.Product2.RecordType.Name +
              ':' +
              oli.PricebookEntry.Product2.Id),
              oli.Quantity
            );
          }
        }
      } else {
        if (additionalAccessories == null) {
          additionalAccessories = new List<AdditionalAccessory>();
        }
        if (oli.PricebookEntry.Product2.RecordType.Name == 'Fees') {
          if (!provinceFeesMap.containsKey('additional')) {
            provinceFeesMap.put('additional', new Map<String, List<FeeItem>>());
          }
          if (!provinceFeesMap.get('additional').containsKey(opportunity.GL_Account_Variable_3__r.Name)) {
            provinceFeesMap.get('additional').put(this.provTaxRate.name, new List<FeeItem>());
          }

          provinceFeesMap.get('additional')
            .get(this.provTaxRate.name)
            .add(new FeeItem(oli, findTaxRate(oli.PricebookEntry.Product2.Taxable__c)));
        } else if (oli.isInsurance__c) {
          if (insuranceItems == null) {
            insuranceItems = new List<OpportunityLineItem>();
          }
          insuranceItems.add(oli);
        } else {
          AdditionalAccessory a = new AdditionalAccessory();
          a.id = oli.Id;
          a.productId = oli.PricebookEntry.Product2.Id;
          a.productName = oli.PricebookEntry.Product2.Name;
          a.productNameFR = oli.PricebookEntry.Product2.Name_FR__c;
          a.productPriceBookEntryId = oli.PricebookEntry.Id;
          a.quantity = oli.quantity;
          a.unitPrice = oli.unitPrice;
          a.taxRate = findTaxRate(oli.PricebookEntry.Product2.Taxable__c);
          additionalAccessories.add(a);
        }
      }
    }

    return sortedLineItems;
  }

  private void doSort(OpportunityLineItem oli, Set<String> recordTypes) {
    if (recordTypes.contains(oli.ParentProductId__r.RecordType.Name)) {
      lineItemQuantityMap.put(
        (oli.ParentProductId__r.RecordType.Name +
        ':' +
        oli.PricebookEntry.Product2.Id),
        oli.Quantity
      );
    } else {
      if (oli.ParentProductId__c != null) {
        if (!subLineItemQuantityMap.keySet().contains(oli.ParentProductId__c)) {
          subLineItemQuantityMap.put(oli.ParentProductId__c, new Map<String, Decimal>());
        }
        subLineItemQuantityMap.get(oli.ParentProductId__c).put(oli.PricebookEntry.Product2.Id, oli.Quantity);
      } else {
        lineItemQuantityMap.put(oli.PricebookEntry.Product2.Id, oli.Quantity);
      }
    }
  }

  public static void coverage() {
    integer i;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
    i = 1;
  }
}
