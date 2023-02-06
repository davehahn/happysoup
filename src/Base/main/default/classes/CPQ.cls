public class CPQ {
  public class CPQ_Exception extends Exception {
  }

  public String saleType;
  public String saleProvince { get; set; }
  public Id activePricebookId;
  public String baseProductRecordType_Name;
  public Id baseProductRecordType_Id;
  public String baseProductFamily;
  public Decimal deposit;
  public Decimal term;
  public Decimal amort;
  public Decimal interestRate;
  public List<CPQ_Lib_dh.OptionsWrapper> baseProductOptions;
  public String boatId;
  public SObject boatLine;
  public String motorId;
  public SObject motorLine;
  public String trailerId;
  public SObject trailerLine;
  public String trollingMotorId;
  public SObject trollingMotorLine;
  public CPQ_Lib_dh.Boat theBoat { get; set; }
  public CPQ_Lib_dh.UpgradeProduct theMotor { get; set; }
  public CPQ_Lib_dh.UpgradeProduct theTrailer { get; set; }
  public CPQ_Lib_dh.UpgradeProduct theTrollingMotor { get; set; }
  public List<CPQ_Lib_dh.OptionProduct> selectedOptions;
  public List<CPQ_Lib_dh.SavingsLine> savings { get; set; }
  public List<CPQ_Lib_dh.AdditionalAccessory> additionalAccessories { get; set; }
  public List<CPQ_Lib_dh.InsuranceProduct> insuranceProducts { get; set; }
  public List<CPQ_Lib_dh.CustomProduct> customProducts { get; set; }
  public List<CPQ_Lib_dh.WarrantyOptionProduct> warrantyOptions { get; set; }
  public List<CPQ_Lib_dh.MaintenanceServicePlanOptionProduct> maintenanceServicePlanOptions { get; set; }
  public CPQ_Lib_dh.TradeIn tradeIn;
  //public List<CPQ_Lib_dh> motorUpgradeOptions;
  //public List<CPQ_Lib_dh> trailerUpgradeOptions;
  //public List<CPQ_Lib_dh> trollingMotorUpgradeOptions;
  public String saveToRecordId;
  public List<CPQ_Lib_dh.SaleLineItem> saleItems { get; set; }
  public String quoteName { get; set; }
  public String quoteExpirationDate { get; set; }
  public CPQ_Lib_dh.TaxZone taxZone { get; set; }
  public Boolean isTaxExempt { get; set; }
  public Boolean isTaxExemptStatusFixed { get; set; }
  public Set<Id> selectedProductIds { get; set; }

  public static Map<String, Id> defaultPricebooks = CPQ_Lib_dh.defaultPricebooks;

  public String locale = 'en_US';
  public Boolean allowInsurance {get; set;}

  private void reset(){
    this.motorId = null;
    this.trailerId = null;
    this.trollingMotorId = null;
    this.boatLine = null;
    this.motorLine = null;
    this.trailerLine  = null;
    this.trollingMotorLine = null;
    this.theBoat = null;
    this.theMotor = null;
    this.theTrailer = null;
    this.theTrollingMotor = null;
    this.baseProductOptions = new List<CPQ_Lib_dh.OptionsWrapper>();
    this.warrantyOptions = new List<CPQ_Lib_dh.WarrantyOptionProduct>();
    this.maintenanceServicePlanOptions = new List<CPQ_Lib_dh.MaintenanceServicePlanOptionProduct>();
    this.selectedOptions = new List<CPQ_Lib_dh.OptionProduct>();
    this.savings = new List<CPQ_Lib_dh.SavingsLine>();
    this.additionalAccessories = new List<CPQ_Lib_dh.AdditionalAccessory>();
    this.insuranceProducts = new List<CPQ_Lib_dh.InsuranceProduct>();
    this.customProducts = new List<CPQ_Lib_dh.CustomProduct>();
    this.saleItems = new List<CPQ_Lib_dh.SaleLineItem>();
  }

  public CPQ(String saleType) {
    init(saleType);
  }

  public CPQ(String saleType, String recordId) {
    init(saleType);
    this.saveToRecordId = recordId;
    this.populateExisting();
  }

  //  public CPQ(String saleType, String recordId, String locale) {
  //    init(saleType);
  //    this.saveToRecordId = recordId;
  //    this.locale = locale;
  //    this.populateExisting();
  //  }

  public CPQ(String saleType, String recordId, String opportunityId) {
    init(saleType);
    if (opportunityId != null) {
      Opportunity opp = [SELECT Id, IsAccountTaxExempt__c FROM Opportunity WHERE Id = :opportunityId];
      this.isTaxExempt = opp.IsAccountTaxExempt__c;
      this.isTaxExemptStatusFixed = true;
    }
    if (recordId != null) {
      this.saveToRecordId = recordId;
      this.populateExisting();
    }
  }

  public CPQ(String saleType, String recordId, String opportunityId, String locale) {
    init(saleType);
    this.locale = locale;
    if (opportunityId != null) {
      Opportunity opp = [SELECT Id, IsAccountTaxExempt__c FROM Opportunity WHERE Id = :opportunityId];
      this.isTaxExempt = opp.IsAccountTaxExempt__c;
      this.isTaxExemptStatusFixed = true;
    }
    if (recordId != null) {
      this.saveToRecordId = recordId;
      this.populateExisting();
    }
  }

  public void selectBoat() {
    if (this.boatLine != null) {
      if( this.boatLine.getSObject('PricebookEntry').get('Product2Id') == this.boatId )
      {
        this.theBoat = new CPQ_Lib_dh.Boat(this.boatLine, this.saleProvince, this.locale);
      } else {
        this.reset();
      }
    }
    if(this.boatLine == null ){
      this.theBoat = new CPQ_Lib_dh.Boat(this.boatId, this.saleProvince, this.locale);
    }
    if (this.motorId == null)
      this.motorId = this.theBoat.standardMotorId;
    //this.theMotor = null;
    if (this.trailerId == null)
      this.trailerId = this.theBoat.standardTrailerId;
    //this.theTrailer = null;
    if (this.trollingMotorId == null)
      this.trollingMotorId = this.theBoat.standardTrollingMotorId;
    //this.theTrollingMotor = null;
    if (this.selectedOptions.isEmpty())
      this.selectedOptions = new List<CPQ_Lib_dh.OptionProduct>();
    //this.savings = new List<CPQ_Lib_dh.SavingsLine>();
    //this.customProducts = new List<CPQ_Lib_dh.CustomProduct>();
    List<CPQ_Lib_dh.OptionProduct> options = CPQ.fetchAllOptions(this.theBoat.id, this.activePricebookId);
    if (this.saleType == 'retail') {
      Set<String> saleItemProductIds = new Set<String>();
      for (CPQ_Lib_dh.SaleLineItem saleItem : this.saleItems) {
        saleItemProductIds.add(saleItem.productId);
      }
      for (CPQ_Lib_dh.OptionProduct opt : options) {
        if (opt.isSelected) {
          this.selectedOptions.add(opt);
          if (!saleItemProductIds.contains(opt.Id)) {
            this.saleItems.add(new CPQ_Lib_dh.SaleLineItem(opt));
            System.debug('Option Family = ' + opt.family);
            if (opt.family == 'Premium Package') {
              CPQ_Lib_dh.SavingsLine ppSaving = new CPQ_Lib_dh.SavingsLine();
              ppSaving.description = 'Premium Package Savings';
              ppSaving.amount = -1 * opt.retailPrice;
              if (this.savings == null) {
                this.savings = new List<CPQ_Lib_dh.SavingsLine>();
              }
              this.savings.add(ppSaving);
            }
          }
        }
      }
    }
    this.baseProductOptions = groupOptions(options);
  }

  public List<CPQ_Lib_dh.UpgradeProduct> buildUpgrades(String upgradeType) {
    CPQ_Lib_dh.UpgradeProduct[] result = new List<CPQ_Lib_dh.UpgradeProduct>();
    switch on upgradeType {
      when 'Motor' {
        result = this.constructUpgradeOptions(
          this.theBoat.standardMotorId,
          LGND_Constants.productRtId_Motor,
          this.activePricebookId,
          this.saleProvince
        );
      }
      when 'Trailer' {
        result = constructUpgradeOptions(
          this.theBoat.standardTrailerId,
          LGND_Constants.productRtId_Trailer,
          this.activePricebookId,
          this.saleProvince
        );
      }
      when 'TrollingMotor' {
        result = constructUpgradeOptions(
          this.theBoat.standardTrollingMotorId,
          LGND_Constants.productRtId_TrollingMotor,
          this.activePricebookId,
          this.saleProvince
        );
      }
    }
    return result;
  }

  public String save() {
    try {
      String sObjType = LGND_Utilities.sObjectNameFromId(Id.valueOF(this.saveToRecordId));
      switch on sObjType {
        when 'Quote' {
          return this.saveToQuote();
        }
        when 'Opportunity' {
          return this.saveToOpp();
        }
        when else {
          throw new CPQ.CPQ_Exception('Invalid Id Supplied! CPQ can only be saved to an Opportunity OR Quote');
        }
      }
    } catch (Exception e) {
      if (e.getTypeName() == 'CPQ.CPQ_Exception') {
        throw e;
      } else {
        throw new CPQ.CPQ_Exception('Save RecordId did not resolve to an actual sObject Type');
      }
    }
  }

  /* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */
  /*               PUBLIC  STATIC                             */
  /* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */

  public static List<Map<String, String>> fetchMajorProductSelectOptions(
    String rtName,
    String family,
    String activePricebookId,
    Boolean allowInactiveEntries
  ) {
    Id rtId = LGND_Utilities.recordTypeIdFromName('Product2', rtName);
    return CPQ.fetchProducts(rtId, activePricebookId, allowInactiveEntries, rtName, family);
  }

//  public static List<CPQ_Lib_dh.Fee> findAllFees(String parentProductId, String prov) {
//    Map<Id, Product_Fee_Map__c> prodMap = new Map<Id, Product_Fee_Map__c>();
//    Map<Id, CPQ_Lib_dh.Fee> result = new Map<Id, CPQ_Lib_dh.Fee>();
//    for (Product_Fee_Map__c fm : [
//      SELECT Id, Fee_Product__c, Fee_Product__r.Name, Fee_Product__r.Name_FR__c, Fee_Product__r.Taxable__c
//      FROM Product_Fee_Map__c
//      WHERE Parent_Product__c = :parentProductId
//    ]) {
//      prodMap.put(fm.Fee_Product__c, fm);
//    }
//    for (Product_Fee_Amount__c pfa : [
//      SELECT Id, Amount__c, Fee_Product__c, Price_Book__c
//      FROM Product_Fee_Amount__c
//      WHERE
//        Fee_Product__c IN :prodMap.keySet()
//        AND Price_Book__c IN :CPQ_Lib_dh.defaultPricebooks.values()
//        AND Province__c = :prov
//    ]) {
//      CPQ_lib_dh.Fee f;
//      if (!result.containsKey(pfa.Fee_Product__c)) {
//        CPQ_lib_dh.Fee nf = new CPQ_Lib_dh.Fee();
//        nf.feeName = prodMap.get(pfa.Fee_Product__c).Fee_Product__r.Name;
//        nf.feeProductId = prodMap.get(pfa.Fee_Product__c).Fee_Product__c;
//        nf.taxable = prodMap.get(pfa.Fee_Product__c).Fee_Product__r.Taxable__c;
//        result.put(pfa.Fee_Product__c, nf);
//      }
//      f = result.get(pfa.Fee_Product__c);
//      if (pfa.Price_Book__c == CPQ_Lib_dh.defaultPricebooks.get('retail'))
//        f.retailAmount = pfa.Amount__c;
//      if (pfa.Price_Book__c == CPQ_Lib_dh.defaultPricebooks.get('partner'))
//        f.partnerAmount = pfa.Amount__c;
//      result.put(pfa.Fee_Product__c, f);
//    }
//    return result.values();
//  }

  public static List<CPQ_Lib_dh.Fee> findAllFees(String parentProductId, String prov, String locale) {
    Map<Id, Product_Fee_Map__c> prodMap = new Map<Id, Product_Fee_Map__c>();
    Map<Id, CPQ_Lib_dh.Fee> result = new Map<Id, CPQ_Lib_dh.Fee>();
    for (Product_Fee_Map__c fm : [
      SELECT Id, Fee_Product__c,  Fee_Product__r.Id, Fee_Product__r.Name, Fee_Product__r.Name_FR__c, Fee_Product__r.Taxable__c
      FROM Product_Fee_Map__c
      WHERE Parent_Product__c = :parentProductId
    ]) {
      prodMap.put(fm.Fee_Product__c, fm);
    }
    for (Product_Fee_Amount__c pfa : [
      SELECT Id, Amount__c, Fee_Product__c, Price_Book__c
      FROM Product_Fee_Amount__c
      WHERE
      Fee_Product__c IN :prodMap.keySet()
      AND Price_Book__c IN :CPQ_Lib_dh.defaultPricebooks.values()
      AND Province__c = :prov
    ]) {
      CPQ_lib_dh.Fee f;
      if (!result.containsKey(pfa.Fee_Product__c)) {
        CPQ_lib_dh.Fee nf = new CPQ_Lib_dh.Fee();
        Product2 feeProd = prodMap.get(pfa.Fee_Product__c).Fee_Product__r;
        nf.feeName = (locale == 'fr' && feeProd.Name_FR__c != null) ? feeProd.Name_FR__c : feeProd.Name;
        nf.feeProductId = feeProd.Id;
        nf.taxable = feeProd.Taxable__c;
        result.put(pfa.Fee_Product__c, nf);
      }
      f = result.get(pfa.Fee_Product__c);
      if (pfa.Price_Book__c == CPQ_Lib_dh.defaultPricebooks.get('retail'))
        f.retailAmount = pfa.Amount__c;
      if (pfa.Price_Book__c == CPQ_Lib_dh.defaultPricebooks.get('partner'))
        f.partnerAmount = pfa.Amount__c;
      result.put(pfa.Fee_Product__c, f);
    }
    return result.values();
  }

  public static CPQ_Lib_dh.UpgradeProduct setUpgrade(
    String fromId,
    String toId,
    String activePricebookId,
    String prov
  ) {
    if (String.isBlank(toId))
      return null;
    try {
      return new CPQ_Lib_dh.UpgradeProduct(fromId, toId, activePricebookId, prov);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  public static CPQ_Lib_dh.UpgradeProduct setUpgrade(
    String fromId,
    String toId,
    String activePricebookId,
    String prov,
    String locale
  ) {
    if (String.isBlank(toId))
      return null;
    try {
      return new CPQ_Lib_dh.UpgradeProduct(fromId, toId, activePricebookId, prov, locale);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  public static CPQ_Lib_dh.OptionProduct[] fetchAllOptions(String parentProductId, String activePricebookId) {
    CPQ_Lib_dh.addRetailOverridePricebook(activePricebookId);
    Map<Id, Product_Option__c> optionMap = new Map<Id, Product_Option__c>();
    List<CPQ_Lib_dh.OptionProduct> result = new List<CPQ_Lib_dh.OptionProduct>();
    //Id partId = LGND_Constants.productRtId_Part;
  Application_RecordType.ProductRTs prodRts = Application_RecordType.getInstance().getProductRecordTypes();
    Set<Id> optionRtIds = new Set<Id>{
      prodRts.getPartId(),
      prodRts.getProtectionAndServiceId()
    };
    for (Product_Option__c po : [
      SELECT Id, From_Product__c, Standard__c, Maximum__c
      FROM Product_Option__c
      WHERE To_Product__c = :parentProductId AND From_Product__r.RecordTypeId IN :optionRtIds
    ]) {
      /*
        don't allow selected and not selectable options ( standard == maximum)
        if this is for a partner
        ***** CURRENTLY ONLY IN SAMPLE RETAIL CALCULATOR ********
      */
      if (!(CPQ_Lib_dh.defaultPricebooks.get('partner') == activePricebookId && po.Standard__c == po.Maximum__c))
        optionMap.put(po.From_Product__c, po);
    }
    for (Product2 p : [
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
      WHERE Id IN :optionMap.keySet()
    ]) {
      CPQ_Lib_dh.OptionProduct op = new CPQ_Lib_dh.OptionProduct(
        p,
        parentProductId,
        optionMap.get(p.Id).Standard__c,
        optionMap.get(p.Id).Maximum__c
      );
      /*
        If this for a partner and there is no partner price ( not in partner PB )
        then we do not want it
      */
      if (
        CPQ_Lib_dh.defaultPricebooks.get('partner') == activePricebookId &&
        op.partnerPrice != null &&
        op.partnerPricebookEntryIsActive
      ) {
        result.add(op);
      }
      if (
        CPQ_Lib_dh.defaultPricebooks.get('retail') == activePricebookId &&
        op.retailPrice != null &&
        op.retailPricebookEntryIsActive
      ) {
        result.add(op);
      }
    }
    return result;
  }

  public static List<CPQ_Lib_dh.OptionsWrapper> groupOptions(CPQ_Lib_dh.OptionProduct[] options) {
    Map<String, List<CPQ_lib_dh.OptionProduct>> temp = new Map<String, List<CPQ_Lib_dh.OptionProduct>>();
    List<CPQ_Lib_dh.OptionsWrapper> result = new List<CPQ_Lib_dh.OptionsWrapper>();
    for (CPQ_Lib_dh.OptionProduct op : options) {
      String fam = String.isEmpty(op.family) ? 'Misc' : op.family;
      if (!temp.containsKey(fam)) {
        temp.put(fam, new List<CPQ_Lib_dh.OptionProduct>());
      }
      temp.get(fam).add(op);
    }

    for (String fam : temp.keySet()) {
      CPQ_Lib_dh.OptionsWrapper r = new CPQ_Lib_dh.OptionsWrapper();
      r.family = fam;
      r.items = temp.get(fam);
      r.count = r.items.size();
      result.add(r);
    }
    result.sort();
    return result;
  }

  /* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */
  /*                        PRIVATE                           */
  /* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */

  private void init(String saleType) {
    this.deposit = 0;
    this.amort = 120;
    this.term = 60;
    this.interestRate = 6.99;
    this.isTaxExempt = false;
    this.isTaxExemptStatusFixed = false;
    this.saleType = saleType;
    this.activePricebookId = CPQ.defaultPricebooks.get(this.saleType);
    this.selectedOptions = new List<CPQ_Lib_dh.OptionProduct>();
    this.warrantyOptions = new List<CPQ_Lib_dh.WarrantyOptionProduct>();
    this.maintenanceServicePlanOptions = new List<CPQ_Lib_dh.MaintenanceServicePlanOptionProduct>();
    this.savings = new List<CPQ_Lib_dh.SavingsLine>();
    this.additionalAccessories = new List<CPQ_Lib_dh.AdditionalAccessory>();
    this.insuranceProducts = new List<CPQ_Lib_dh.InsuranceProduct>();
    this.customProducts = new List<CPQ_Lib_dh.CustomProduct>();
    this.tradeIn = new CPQ_Lib_dh.TradeIn();
    this.saleItems = new List<CPQ_Lib_dh.SaleLineItem>();
    this.saleProvince = findSaleProvince();
    this.taxZone = findTaxZone(this.saleProvince);
    this.allowInsurance = false;
    this.selectedProductIds = new Set<Id>();
  }

  private String findSaleProvince() {
    User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
    /* this is just Temperary */
    if (currentUser.AccountId == null)
      return 'Ontario';
    else {
      Account userAcct = [SELECT Id, BillingState FROM Account WHERE Id = :currentUser.AccountId];
      if (userAcct.BillingState == null)
        throw new CPQ.CPQ_Exception(
          'Current user\'s Account does not have the address set correctly. \b\r Please Add all address information'
        );
      else
        return userAcct.BillingState;
    }
  }

  private CPQ_Lib_dh.TaxZone findTaxZone(String prov) {
    try {
      AcctSeed__Accounting_Variable__c aVar = [
        SELECT Id, Name, Tax_is_Harmonized__c, Tax_Rate_Provincial_Statutory__c, Tax_Rate_Retail__c
        FROM AcctSeed__Accounting_Variable__c
        WHERE AcctSeed__Type__c = 'GL Account Variable 3' AND Name = :prov
        LIMIT 1
      ];
      return new CPQ_Lib_dh.TaxZone(aVar);
    } catch (Exception e) {
      return null;
    }
  }

  private void populateExisting() {
    String sObjectType = LGND_Utilities.sObjectNameFromId(this.saveToRecordId);
    this.allowInsurance = UserInfo.getUserType() == 'Standard' && this.saveToRecordId != null;
    switch on sObjectType {
      when 'Opportunity' {
        populateFromOpportunity();
      }
      when 'Quote' {
        populateFromQuote();
      }
      when else {
        throw new CPQ_Exception('Unsupported record Id provided');
      }
    }
  }

  private void populateFromQuote() {
    Application_RecordType.ProductRTs productRts = Application_RecordType.getInstance().getProductRecordTypes();
    Map<Id, List<CPQ_Lib_dh.SaleLineItem>> subSaleItemsMap = new Map<Id, List<CPQ_Lib_dh.SaleLineItem>>();
    Set<Id> serializedIds = new Set<Id>();
    Id customProdId = LGND_Constants.partnerCustomProductId;
    Id savingsProductId = LGND_Constants.savingsProductId;
    QuoteLineItem[] options = new List<QuoteLineItem>();
    Quote q = [
      SELECT
        Id,
        Finance_Ammortization__c,
        Deposit__c,
        Finance_Term__c,
        Finance_Annual_Interest__c,
        Name,
        ExpirationDate,
        Opportunity.IsAccountTaxExempt__c,
        GL_Account_Variable_3__c,
        GL_Account_Variable_3__r.Id,
        GL_Account_Variable_3__r.Name,
        GL_Account_Variable_3__r.Tax_is_Harmonized__c,
        GL_Account_Variable_3__r.Tax_Rate_Provincial_Statutory__c,
        GL_Account_Variable_3__r.Tax_Rate_Retail__c,
        Pricebook2Id,
        (
          SELECT
            Id,
            Description,
            Taxable_Provincial__c,
            ParentProductId__c,
            ParentProductId__r.RecordType.Name,
            PricebookEntryId,
            PricebookEntry.UnitPrice,
            PricebookEntry.Product2Id,
            PricebookEntry.Product2.Name,
            PricebookEntry.Product2.Name_FR__c,
            PricebookEntry.Product2.Family,
            PricebookEntry.Product2.RecordTypeId,
            PricebookEntry.Product2.RecordType.Name,
            PricebookEntry.Product2.Taxable__c,
            PricebookEntry.Product2.Is_Residual_Insurance__c,
            PricebookEntry.Product2.InsurancePlan__c,
            PricebookEntry.Product2.isPrepayable__c,
            Quantity,
            UnitPrice,
            InsuranceCoverage__c,
            Insurance_Rate__c,
            IsPrepaid__c
          FROM QuoteLineItems
        )
      FROM Quote
      WHERE Id = :this.saveToRecordId
    ];

    if (!CPQ_Lib_dh.defaultPricebooks.containsKey('active')) {
      CPQ_Lib_dh.addRetailOverridePricebook(q.Pricebook2Id);
    }
    if (q.GL_Account_Variable_3__r != null) {
      this.taxZone = new CPQ_Lib_dh.TaxZone(q.GL_Account_Variable_3__r);
      this.saleProvince = q.GL_Account_Variable_3__r.Name;
    }
    this.deposit = q.Deposit__c;
    this.term = q.Finance_Term__c;
    this.amort = q.Finance_Ammortization__c;
    this.interestRate = q.Finance_Annual_Interest__c;
    this.quoteName = q.Name;
    this.isTaxExempt = q.Opportunity.IsAccountTaxExempt__c;
    this.isTaxExemptStatusFixed = true;
    if (q.ExpirationDate != null) {
      DateTime dt = DateTime.newInstance(q.ExpirationDate.year(), q.ExpirationDate.month(), q.ExpirationDate.day());
      this.quoteExpirationDate = dt.format('yyyy-MM-dd');
    }
    if (this.activePricebookId != q.Pricebook2Id) {
      this.activePricebookId = q.Pricebook2Id;
    }
    // Sort the Opportunity Line Items
    for (QuoteLineItem qli : q.QuoteLineItems) {
      Id productRtId = qli.PricebookEntry.Product2.RecordTypeId;
      this.selectedProductIds.add(qli.PricebookEntry.Product2Id);
      if( qli.PricebookEntry.Product2.Family == 'Extended Warranty' ){
        this.warrantyOptions.add(new CPQ_Lib_dh.WarrantyOptionProduct(qli));
        continue;
      }
      if (productRtId == productRts.getBoatId()) {
        serializedIds.add(qli.PricebookEntry.Product2Id);
        this.boatId = qli.PricebookEntry.Product2Id;
        this.baseProductFamily = qli.PricebookEntry.Product2.Family;
        this.baseProductRecordType_Name = qli.PricebookEntry.Product2.RecordType.Name;
        this.baseProductRecordType_Id = qli.PricebookEntry.Product2.RecordTypeId;
        this.boatLine = qli;
        continue;
      }
      if (productRtId == productRts.getMotorId()) {
        serializedIds.add(qli.PricebookEntry.Product2Id);
        this.motorId = qli.PricebookEntry.Product2Id;
        this.motorLine = qli;
        continue;
      }
      if (productRtId == productRts.getTrailerId()) {
        serializedIds.add(qli.PricebookEntry.Product2Id);
        this.trailerId = qli.PricebookEntry.Product2Id;
        this.trailerLine = qli;
        continue;
      }
      if (productRtId == productRts.getTrollingMotorId()) {
        serializedIds.add(qli.PricebookEntry.Product2Id);
        this.trollingMotorId = qli.PricebookEntry.Product2Id;
        this.trollingMotorLine = qli;
        continue;
      }
      if(productRtId == productRts.getInsuranceId()){
        this.insuranceProducts.add( new CPQ_Lib_dh.InsuranceProduct(qli));
        continue;
      }
      if(productRtId == productRts.getProtectionAndServiceId() || productRtId == productRts.getPackageBundleId() ){
        this.maintenanceServicePlanOptions.add( new CPQ_Lib_dh.MaintenanceServicePlanOptionProduct(qli));
        continue;
      }
      if (productRtId == productRts.getPartId()) {
        if (qli.PricebookEntry.Product2Id == customProdId) {
          this.customProducts.add(new CPQ_Lib_dh.CustomProduct(qli));
        } else if (qli.PricebookEntry.Product2Id == savingsProductId) {
          this.savings.add(new CPQ_Lib_dh.SavingsLine(qli));
        } else if (qli.ParentProductId__c == null ){
          this.additionalAccessories.add( new CPQ_Lib_dh.AdditionalAccessory(qli));
        } else {
          options.add(qli);
        }
        continue;
      }

    }

    // Build Sale Items from the options and find the subOptions
    for (QuoteLineItem qli : options) {
      if (qli.ParentProductId__c != null && !serializedIds.contains(qli.ParentProductId__c)) {
        if (!subSaleItemsMap.containsKey(qli.ParentProductId__c)) {
          subSaleItemsMap.put(qli.ParentProductId__c, new List<CPQ_Lib_dh.SaleLineItem>());
        }
        subSaleItemsMap.get(qli.ParentProductId__c).add(new CPQ_Lib_dh.SaleLineItem(qli, locale));
      } else {
        this.saleItems.add(new CPQ_Lib_dh.SaleLineItem(qli, locale));
      }
    }

    //attach any subOptions to their parent option
    for (CPQ_Lib_dh.SaleLineItem sli : this.saleItems) {
      if (subSaleItemsMap.containsKey(sli.productId)) {
        sli.subSaleItems.addAll(subSaleItemsMap.get(sli.productId));
      }
    }

    //Trade In Stuff
    try {
      Trade_In_record__c tr = [
        SELECT
          Id,
          Lien_Amount__c,
          Total_Value__c,
          (SELECT Id, Trade_In_Record__c, Make__c, Model__c, Model_Year__c, Serial_Number__c FROM Trade_In_Items__r)
        FROM Trade_In_Record__c
        WHERE Quote__c = :this.saveToRecordId
      ];
      this.tradeIn = new CPQ_Lib_dh.TradeIn(tr);
    } catch (Exception e) {
    }
  }

  private void populateFromOpportunity() {
    Map<Id, List<CPQ_Lib_dh.SaleLineItem>> subSaleItemsMap = new Map<Id, List<CPQ_Lib_dh.SaleLineItem>>();
    Set<Id> serializedIds = new Set<Id>();
    Id customProdId = LGND_Constants.partnerCustomProductId;
    Id savingsProductId = LGND_Constants.savingsProductId;
    OpportunityLineItem[] options = new List<OpportunityLineItem>();
    Opportunity opp = [
      SELECT
        Id,
        Finance_Ammortization__c,
        Deposit__c,
        Finance_Term__c,
        Finance_Annual_Interest__c,
        IsAccountTaxExempt__c,
        Pricebook2Id,
        (
          SELECT
            Id,
            Description,
            Taxable_Provincial__c,
            ParentProductId__c,
            ParentProductId__r.RecordType.Name,
            PricebookEntryId,
            PricebookEntry.UnitPrice,
            PricebookEntry.Product2Id,
            PricebookEntry.Product2.Name,
            PricebookEntry.Product2.Name_FR__c,
            PricebookEntry.Product2.Family,
            PricebookEntry.Product2.RecordTypeId,
            PricebookEntry.Product2.RecordType.Name,
            PricebookEntry.Product2.Make__c,
            Quantity,
            UnitPrice
          FROM OpportunityLineItems
        )
      FROM Opportunity
      WHERE Id = :this.saveToRecordId
    ];
    Set<Id> pbIds = new Set<Id>(defaultPricebooks.values());
    if (!pbIds.contains(opp.Pricebook2Id)) {
      CPQ_Lib_dh.addRetailOverridePricebook(opp.Pricebook2Id);
    }
    this.deposit = opp.Deposit__c;
    this.term = opp.Finance_Term__c;
    this.amort = opp.Finance_Ammortization__c;
    this.interestRate = opp.Finance_Annual_Interest__c;
    this.isTaxExempt = opp.IsAccountTaxExempt__c;
    this.isTaxExemptStatusFixed = true;
    // Sort the Opportunity Line Items
    for (OpportunityLineItem oli : opp.OpportunityLineItems) {
      if (oli.PricebookEntry.Product2.RecordType.Name == 'Boat') {
        serializedIds.add(oli.PricebookEntry.Product2Id);
        this.boatId = oli.PricebookEntry.Product2Id;
        this.baseProductFamily = oli.PricebookEntry.Product2.Family;
        this.baseProductRecordType_Name = oli.PricebookEntry.Product2.RecordType.Name;
        this.baseProductRecordType_Id = oli.PricebookEntry.Product2.RecordTypeId;
      }
      if (oli.PricebookEntry.Product2.RecordType.Name == 'Motor') {
        serializedIds.add(oli.PricebookEntry.Product2Id);
        this.motorId = oli.PricebookEntry.Product2Id;
      }
      if (oli.PricebookEntry.Product2.RecordType.Name == 'Trailer') {
        serializedIds.add(oli.PricebookEntry.Product2Id);
        this.trailerId = oli.PricebookEntry.Product2Id;
      }
      if (oli.PricebookEntry.Product2.RecordType.Name == 'Trolling Motor') {
        serializedIds.add(oli.PricebookEntry.Product2Id);
        this.trollingMotorId = oli.PricebookEntry.Product2Id;
      }
      if (oli.PricebookEntry.Product2.RecordType.Name == 'Part') {
        if (oli.PricebookEntry.Product2Id == customProdId) {
          this.customProducts.add(new CPQ_Lib_dh.CustomProduct(oli));
        } else if (oli.PricebookEntry.Product2Id == savingsProductId) {
          this.savings.add(new CPQ_Lib_dh.SavingsLine(oli));
        } else {
          options.add(oli);
        }
      }
    }

    // Build Sale Items from the options and find the subOptions
    for (OpportunityLineItem oli : options) {
      if (oli.ParentProductId__c != null && !serializedIds.contains(oli.ParentProductId__c)) {
        if (!subSaleItemsMap.containsKey(oli.ParentProductId__c)) {
          subSaleItemsMap.put(oli.ParentProductId__c, new List<CPQ_Lib_dh.SaleLineItem>());
        }
        subSaleItemsMap.get(oli.ParentProductId__c).add(new CPQ_Lib_dh.SaleLineItem(oli, locale));
      } else {
        this.saleItems.add(new CPQ_Lib_dh.SaleLineItem(oli, locale));
      }
    }

    //attach any subOptions to their parent option
    for (CPQ_Lib_dh.SaleLineItem sli : this.saleItems) {
      if (subSaleItemsMap.containsKey(sli.productId)) {
        sli.subSaleItems.addAll(subSaleItemsMap.get(sli.productId));
      }
    }

    //Trade In Stuff
    try {
      Trade_In_record__c tr = [
        SELECT
          Id,
          Lien_Amount__c,
          Total_Value__c,
          (SELECT Id, Trade_In_Record__c, Make__c, Model__c, Model_Year__c, Serial_Number__c FROM Trade_In_Items__r)
        FROM Trade_In_Record__c
        WHERE Opportunity__c = :this.saveToRecordId
      ];
      this.tradeIn = new CPQ_Lib_dh.TradeIn(tr);
    } catch (Exception e) {
    }
  }

  private Map<Id, Product2> findParts(Set<Id> prodIds, Id pbId) {
    return new Map<Id, Product2>(
      [
        SELECT
          Id,
          Name,
          RecordType.Name,
          Family,
          Standard_Motor__c,
          Standard_Trailer__c,
          Standard_Trolling_Motor__c,
          Default_Image_Thumb__c,
          Taxable__c,
          (SELECT Id, UnitPrice, Pricebook2Id FROM PricebookEntries WHERE Pricebook2Id = :pbId),
          (SELECT Id, Standard__c, Maximum__c, To_Product__c FROM From_Product_Options__r)
        FROM Product2
        WHERE Id = :prodIds
      ]
    );
  }

  private static List<Map<String, String>> fetchProducts(
    Id rtId,
    Id activePricebook,
    Boolean allowInactiveEntries,
    String rtName,
    String family
  ) {
    String userType = UserInfo.getUserType();
    List<Map<String, String>> result = new List<Map<String, String>>();
    String queryString =
      'SELECT Product2.Id, Product2.Name, Product2.Taxable__c, UnitPrice, IsActive, Product2.Available_For_Package_And_Save__c FROM PricebookEntry WHERE Product2.RecordTypeId =\'' +
      rtId +
      '\'';
    if (!allowInactiveEntries) {
      queryString += ' AND IsActive = true';
    }
    if (family != null) {
      queryString += ' AND Product2.Family = \'';
      queryString += family;
      queryString += '\'';
    }
    if (rtName == 'Boat') {
      queryString += 'AND Product2.Make__c LIKE \'%Legend%\'';
    }
    if (rtName == 'Motor') {
      queryString += ' AND Product2.Make__c = \'Mercury\'';
      if (userType != 'Standard')
        queryString += ' AND Product2.Available_For_Package_And_Save__c = true';
    }

    queryString += ' AND Product2.isActive = true AND Pricebook2Id = \'';
    queryString += activePricebook;
    queryString += '\' ORDER BY Product2.Name ASC';
    for (PricebookEntry pbe : Database.query(queryString)) {
      if (pbe.UnitPrice > 0) {
        Map<String, String> opt = new Map<String, String>();
        opt.put('id', pbe.Product2.Id);
        opt.put('name', pbe.Product2.Name);
        opt.put('cost', String.valueOf(pbe.UnitPrice));
        opt.put('packageAndSave', String.valueOf(pbe.Product2.Available_For_Package_And_Save__c));
        result.add(opt);
      }
    }
    return result;
  }

  private CPQ_Lib_dh.UpgradeProduct[] constructUpgradeOptions(
    String standardProductId,
    Id rtId,
    String activePricebookId,
    String prov
  ) {
    CPQ_Lib_dh.addRetailOverridePricebook(activePricebookId);
    LIST<CPQ_Lib_dh.UpgradeProduct> result = new List<CPQ_Lib_dh.UpgradeProduct>();
    Set<Id> prodIds = new Set<Id>();
    for (Product_Option__c opt : [
      SELECT Id, From_Product__c
      FROM Product_Option__c
      WHERE To_Product__c = :this.boatId AND From_Product__r.RecordTypeId = :rtId
    ]) {
      prodIds.add(opt.From_Product__c);
    }
    prodIds.add(standardProductId);
    Product2[] upgradeProds = [
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
      WHERE Id IN :prodIds
    ];
    Map<Id, List<Product_Upgrade_Cost__c>> costMap = new Map<Id, List<Product_Upgrade_Cost__c>>();
    for (Product_Upgrade_Cost__c puc : [
      SELECT Id, Cost__c, Price_book__c, Product_Upgrade__r.To_Product__c
      FROM Product_Upgrade_Cost__c
      WHERE
        Price_Book__c IN :CPQ_Lib_dh.defaultPricebooks.values()
        AND Product_Upgrade__r.From_Product__c = :standardProductId
        AND Product_Upgrade__r.To_Product__c IN :prodIds
    ]) {
      if (!costMap.containsKey(puc.Product_Upgrade__r.To_Product__c))
        costMap.put(puc.Product_Upgrade__r.To_Product__c, new List<Product_Upgrade_Cost__c>());
      costMap.get(puc.Product_Upgrade__r.To_Product__c).add(puc);
    }

    for (Product2 up : upgradeProds) {
      try {
        result.add(new CPQ_Lib_dh.UpgradeProduct(standardProductId, up, costMap.get(up.Id), prov));
      } catch (CPQ.CPQ_Exception ex) {
        System.debug(ex.getMessage());
      }
    }
    return result;
  }

  private String saveToQuote() {
    String qId = this.saveToRecordId;
    if (qId == null) {
      throw new AuraHandledException('NO Quote Id was Supplied \b\r Please connact your local Developer');
    }
    this.updateOppFinanceFields();
    List<QuoteLineItem> qLIs = new List<QuoteLineItem>();
    for (SObject obj : createLineItems('QuoteLineItem')) {
      obj.put('QuoteId', qId);
      qLIs.add((QuoteLineItem) obj);
    }
    validateActivePricebookEntries((List<SObject>) qLIs);
    removeOriginalLines('QuoteLineItem', 'QuoteId', qId);
    insert qLIs;
    this.tradeIn.save(qId);
    return this.saveToRecordId;
  }

  private void validateActivePricebookEntries(sObject[] lineItems) {
    Set<Id> pbEntries = new Set<Id>();
    for (sObject li : lineItems) {
      pbEntries.add((Id) li.get('PricebookEntryId'));
    }
    for (PricebookEntry pbe : [
      SELECT Id, Product2.Name, Pricebook2.Name, IsActive
      FROM PricebookEntry
      WHERE Id IN :pbEntries
    ]) {
      if (!pbe.IsActive) {
        throw new CPQ.CPQ_Exception(
          'The Pricebook Entry in ' +
          pbe.Pricebook2.Name +
          ' for ' +
          pbe.Product2.Name +
          ' is not active.'
        );
      }
    }
  }

  private String saveToOpp() {
    String oppId = this.saveToRecordId;
    if (oppId == null) {
      throw new AuraHandledException('NO Opportunity Id was Supplied \b\r Please connact your local Developer');
    }
    this.updateOppFinanceFields();
    List<OpportunityLineItem> oppyLIs = new List<OpportunityLineItem>();
    for (SObject obj : createLineItems('OpportunityLineItem')) {
      obj.put('OpportunityId', oppId);
      oppyLIs.add((OpportunityLineItem) obj);
    }
    removeOriginalLines('OpportunityLineItem', 'OpportunityId', oppId);
    insert oppyLIs;
    this.tradeIn.save(oppId);
    return this.saveToRecordId;
  }

  private List<SObject> createLineItems(String recordType) {
    List<SObject> result = new List<SObject>();
    if (this.theBoat != null) {
      result.addAll(this.theBoat.createLineItems(recordType));
    }
    if (this.theMotor != null) {
      result.addAll(
        this.theMotor.createLineItems(
          recordType,
          this.theBoat.standardMotorId == this.theMotor.Id ? 'Included with Boat' : 'Motor Upgrade'
        )
      );
    }
    if (this.theTrailer != null)
      result.addAll(
        this.theTrailer.createLineItems(
          recordType,
          this.theBoat.standardTrailerId == this.theTrailer.Id ? 'Included with Boat' : 'Trailer Upgrade'
        )
      );
    if (this.theTrollingMotor != null)
      result.addAll(
        this.theTrollingMotor.createLineItems(
          recordType,
          this.theBoat.standardTrollingMotorId == this.theTrollingMotor.Id
            ? 'Included with Boat'
            : 'Trolling Motor Upgrade'
        )
      );
    if (this.saleItems.size() > 0) {
      for (CPQ_Lib_dh.SaleLineItem saleItem : this.saleItems) {
        result.add(saleItem.createLineItem(recordType));
        if (saleItem.subSaleItems.size() > 0) {
          for (CPQ_Lib_dh.SaleLineItem subSaleItem : saleItem.subSaleItems) {
            result.add(subSaleItem.createLineItem(recordType));
          }
        }
      }
    }
    if (this.savings.size() > 0) {
      for (CPQ_Lib_dh.SavingsLine sl : this.savings) {
        result.add(sl.createLineItem(recordType));
      }
    }
    if (this.additionalAccessories.size() > 0) {
      for (CPQ_Lib_dh.AdditionalAccessory aa : this.additionalAccessories) {
        result.add(aa.createLineItem(recordType));
      }
    }
    if (this.customProducts.size() > 0) {
      for (CPQ_Lib_dh.CustomProduct sl : this.customProducts) {
        result.add(sl.createLineItem(recordType));
      }
    }

    if(this.insuranceProducts.size() > 0 ){
      for( CPQ_Lib_dh.InsuranceProduct ip : this.insuranceProducts){
        sObject insurance = ip.createLineItem(recordType);
        System.debug(insurance);
        result.add(insurance);
      }
    }

    if(this.warrantyOptions.size() > 0 ){
      for(CPQ_Lib_dh.WarrantyOptionProduct item : this.warrantyOptions){
        sObject lineItem = item.createLineItem(recordType);
        result.add(lineItem);
      }
    }

    if(this.maintenanceServicePlanOptions.size() > 0 ){
      for(CPQ_Lib_dh.MaintenanceServicePlanOptionProduct item : this.maintenanceServicePlanOptions){
        sObject lineItem = item.createLineItem(recordType);
        result.add(lineItem);
      }
    }
    return result;
  }

  private void removeOriginalLines(String recordType, String idField, String recordId) {
    String query = 'SELECT Id FROM ';
    query += recordType;
    query += ' WHERE ' + idField + ' =\'';
    query += recordId + '\'';
    delete Database.query(query);
  }

  private void mergeOppLines(OpportunityLineItem[] oppyLIs) {
    // at some point we need to deal with this but it is not easy
  }

  private void updateOppFinanceFields() {
    Id objId = Id.valueOf(this.saveToRecordId);
    SObject obj = objId.getSObjectType().newSObject(objId);
    obj.put('Deposit__c', this.deposit);
    obj.put('Finance_Ammortization__c', this.amort);
    obj.put('Finance_Term__c', this.term);
    obj.put('Finance_Annual_Interest__c', this.interestRate);

    upsert obj;
  }
}
