global with sharing class RetailCounterSaleController {
    global Decimal fedTaxRate {
    get {
      return Legend_Settings__c.getOrgDefaults().FederalTaxRate__c;
      }
    private set;
  }
  global class MyException extends Exception {}

  global class LineItemWrapper {

    public String id { get; set; }
    public String lineItemId { get; set; }
    public String opportunityId{ get; set; }
    public String productRecordType { get; set; }
    public String productFamily { get; set; }
    public Decimal quantity { get; set; }
    public Decimal listPrice { get; set; }
    public Decimal unitPrice { get; set; }
    public String pricebookEntryId { get; set; }
    public String description { get; set; }
    public String name { get; set; }
    public String nameFR { get; set; }
    public String descriptionFR { get; set; }
    public String productCode { get; set; }
    public Boolean isTaxableProduct { get; set; }
    public Boolean isKit { get; set; }
    public List<Product_Option__c> kitComponents { get; set; }

    global LineItemWrapper(Product2 prod, OpportunityLineItem oli)
    {
      this.isKit = false;
      this.id = prod.Id;
      this.lineItemId = oli.Id;
      this.opportunityId = oli.OpportunityId;
      this.quantity = oli.Quantity;
      this.listPrice = oli.PricebookEntry.UnitPrice;
      this.unitPrice = oli.UnitPrice;
      this.pricebookEntryId = oli.PricebookEntryId;
      this.name = oli.Description;
      this.nameFR = oli.PricebookEntry.Product2.Name_FR__c;
      this.productCode = prod.ProductCode == null ? '-' : prod.ProductCode;
      this.productRecordType = prod.recordType.Name;
      this.isTaxableProduct =  oli.PricebookEntry.Product2.AcctSeed__Accounting_Type__c == 'Taxable Product' ? true : false;
      processKitComponents(prod.To_Product_Options__r);
    }

    global LineItemWrapper(Product_Fee_Amount__c pfa, Id pbEntryId)
    {
      this.Id = pfa.Fee_Product__c;
      this.isKit = false;
      this.productRecordType = 'Fees';
      this.quantity = 1;
      this.name = pfa.Fee_Product__r.Name;
      this.nameFR = pfa.Fee_Product__r.Name_FR__c;
      this.description = pfa.Fee_Product__r.Description;
      this.descriptionFR = pfa.Fee_Product__r.Description_FR__c;
      this.productFamily = pfa.Fee_Product__r.Family;
      this.productCode = pfa.Fee_Product__r.ProductCode;
      this.isTaxableProduct = pfa.Fee_Product__r.AcctSeed__Accounting_Type__c == 'Taxable Product' ? true : false;
      this.pricebookEntryId = pbEntryId;
      this.listPrice = pfa.Amount__c;
      this.unitPrice = pfa.Amount__c;
    }

    global LineItemWrapper(Product2 prod)
    {
      this.Id = prod.Id;
      this.isKit = false;
      this.productCode = prod.ProductCode == null ? '-' : prod.ProductCode;
      this.quantity = 1;
      this.productRecordType = prod.RecordType.Name;
      this.productFamily = prod.Family;
      this.name = prod.Name;
      this.nameFR = prod.Name_FR__c;
      this.description = prod.Description;
      this.descriptionFR = prod.Description_FR__c;
      this.isTaxableProduct =  prod.AcctSeed__Accounting_Type__c == 'Taxable Product' ? true : false;
      if(prod.pricebookEntries.size() > 0)
      {
        this.listPrice = prod.pricebookEntries[0].UnitPrice;
        this.unitPrice = prod.pricebookEntries[0].UnitPrice;
        this.pricebookEntryId = prod.pricebookEntries[0].Id;
      }
      processKitComponents(prod.To_Product_Options__r);
    }

    private void processKitComponents(List<Product_Option__c> components)
    {
      if( components.size() > 0 )
      {
        this.kitComponents = new List<Product_Option__c>();
        for( Product_Option__c po : components )
        {
          if( po.Standard__c > 0 && po.Standard__c == po.Maximum__c )
          {
            this.kitComponents.add(po);
          }
        }
        if( this.kitComponents.size() > 0 )
        {
          this.isKit = true;
        }
        else
        {
          this.kitComponents = null;
        }
      }
    }

  }

  static Id personTypeAccountId;
  static Id retailCounterSaleOppTypeId;
  static Id defaultRetailPriceBookId;

  static {
    personTypeAccountId = LGND_Utilities.recordTypeIdFromName('Account', 'Person Account');
    retailCounterSaleOppTypeId = LGND_Utilities.recordTypeIdFromName('Opportunity', 'Retail Counter Sale');
    defaultRetailPriceBookId = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
  }

  /* we need to run the init method in OppId setter method as this
     is called as a component controller and the "assignTo" setter
     method from the component runs AFTER the class constructor
     so oppId is null when the constructor is fired
  */
  public String oppId {
    get {
      return oppId;
    }
    set {
      oppId = value;
      init();
    }
  }
  public Opportunity opp { get; set; }
  public List<LineItemWrapper> lineItems { get; set; }
  public LGND_Store lgnd_store { get; set; }
  public Decimal currentTaxRate { get; set; }
  public TaxRate__C provTaxRate { get; set; }

	global RetailCounterSaleController() {

	}

  global RetailCounterSaleController(ApexPages.StandardController std) {
    oppId = std.getId();
  }

  public void init() {
    User currentUser = [SELECT Id, Name, Sales_Department__c
                        FROM User
                        WHERE Id = :UserInfo.getUserId()];
    if( oppId != null )
    {
      this.opp = [SELECT Id,
                         CreatedDate,
                         Pricebook2Id,
                         Payment_Method__c,
                         Amount,
                         TaxOverRideRate__c,
                         TaxOverRide__c,
                         TaxationProvince__c,
                         TotalTaxRate__c,
                         TotalTaxes__c,
                         Total_Amount__c,
                         TaxableTotal_LineItems__c,
                         FederalTaxAmount__c,
                         ProvincialTaxTotal__c,
                         AccountId,
                         Owner.FirstName,
                         Owner.LastName,
                         Owner.Sales_Department__c,
                         ContactEmail__c,
                         CloseDate,
                         InvoiceNumber__c,
                         Account.Phone,
                         Account.PersonHomePhone,
                         Account.PersonMobilePhone,
                         Account.FirstName,
                         Account.LastName,
                         Account.PersonEmail,
                         Pricebook2.Id,
                         Account.Name,
                         Account.BillingCity,
                         Account.BillingState,
                         Account.BillingStateCode,
                         Account.BillingStreet,
                         Account.BillingCountry,
                         Account.BillingCountryCode,
                         Account.BillingPostalCode,
        (SELECT Id,
                PricebookEntryId,
                Description,
                OpportunityId,
                Quantity,
                UnitPrice,
                PricebookEntry.Product2Id,
                PricebookEntry.UnitPrice,
                PricebookEntry.Product2.Name_FR__c,
                PricebookEntry.Product2.Description_FR__c,
                PricebookEntry.Product2.AcctSeed__Accounting_Type__c
          FROM OpportunityLineItems)
        FROM Opportunity
        WHERE Id = :oppId];
      if( opp.OpportunityLineItems.size() > 0 )
      {
        lineItems = buildLineItems(opp.OpportunityLineItems, opp.Pricebook2Id );
      }
      lgnd_store = new LGND_Store( this.opp.Owner.Sales_Department__c);
    }
    else {
      lgnd_store = new LGND_Store(currentUser.Sales_Department__c);
      opp = new Opportunity(Pricebook2Id = defaultRetailPriceBookId,
                                    RecordTypeId = retailCounterSaleOppTypeId,
                                    TaxationProvince__c = lgnd_store.Province,
                                    TaxOverRide__c = false,
                                    Account = new Account(RecordTypeId = personTypeAccountId,
                                                          BillingCountryCode = '',
                                                          BillingStateCode = '')
                                    );
    }
    provTaxRate = TaxRate__c.getAll().get(opp.taxationProvince__c);
    //find current Tax Rate
    currentTaxRate = opp.TaxOverRide__c == true ?
      opp.TaxOverRideRate__c :
      TaxRate__c.getAll().get(opp.taxationProvince__c).ProvincialRate__c + fedTaxRate;
  }

  public String getOpportunityJSON(){
    if( opp == null){
      return null;
    }
    return JSON.serialize(opp);
  }

  public String getLineItemsJSON()
  {
    if( lineItems == null )
    {
      return null;
    }
    return JSON.serialize( lineItems );
  }

  public List<SelectOption> getProvinceOptions()
  {
    List<SelectOption> options = new List<SelectOption>();
    options.add( new SelectOption('', '-- Select --') );
    for( String prov : TaxRate__c.getAll().keySet() )
    {
      options.add( new SelectOption(prov, prov) );
    }
    return options;
  }

  public String getProvincialTaxRates()
  {
    Map<String, String> result = new Map<String, String>();
    Decimal total;
    for(String prov : taxRate__c.getAll().keySet() )
    {
      total = prov == 'Tax Exempt' ? 0 : TaxRate__c.getAll().get(prov).ProvincialRate__c + fedTaxRate;
      result.put( prov, String.valueOf(total) );
    }
    return JSON.serialize(result);
  }

  public PageReference getCancelURL(){
    if( opp == null || opp.Id == null){
      return new PageReference('/');
    }
    return new PageReference('/'+opp.Id);
  }

  public List<Pricebook2> getPriceBooks(){
    return [SELECT Id, Name FROM Pricebook2 WHERE IsStandard = false AND IsActive = true ORDER BY Name DESC];
  }

  /*
    @params String searchString = the string to query for
            String pricebookId = ID of the pricebook we are working with

    returns List<Product2> - where Name or Product code contains the passed in string
                             and there is an entry in the pricebook we are working with

    used on a form with javascript remoting

  */
  @RemoteAction
  global static List<LineItemWrapper> productSearch(String searchString, String pricebookId) {
    List<LineItemWrapper> result = new List<LineItemWrapper>();
    Id feeRT = LGND_Utilities.recordTypeIdFromName('Product2', 'Fees');
    String s = '%' + searchString + '%';
    List<Product2> products = [SELECT Id, Name, Name_FR__c, ProductCode, Description, Description_FR__c, Family, RecordType.Name, AcctSeed__Accounting_Type__c, AcctSeed__Inventory_Type__c,
            (SELECT Id,
                    Standard__c,
                    Maximum__c,
                    From_Product__r.Id,
                    From_Product__r.Name,
                    From_Product__r.Name_FR__c,
                    From_Product__r.RecordType.Name,
                    From_Product__r.Family
             FROM To_Product_Options__r
             ORDER BY From_Product__r.Name),
            (SELECT Id, UnitPrice
              FROM PricebookEntries
              WHERE Pricebook2Id = :pricebookId
              AND isActive = true
              AND UnitPrice != null
              AND UnitPrice > 0
              LIMIT 1)
            FROM Product2
            WHERE ( Name LIKE :s OR ProductCode LIKE :s OR IEM_Unique_Part_Number__c LIKE :s)
            AND isActive = true
            AND RecordTypeId <> :feeRT
            AND Id IN (SELECT Product2Id FROM PricebookEntry WHERE Product2Id != '' AND Pricebook2Id =:pricebookId
              AND isActive = true
              AND UnitPrice != null
              AND UnitPrice > 0)];
    for(Product2 p : products)
    {
      result.add( new LineItemWrapper(p) );
    }
    return result;
  }

  @RemoteAction
  global static List<Account> accountSearch(String searchString){
    String s = '%' + searchString + '%';
    System.debug('****************** ' + s);
    return [SELECT Id,
                   Name,
                   PersonEmail,
                   FirstName,
                   LastName,
                   Phone,
                   PersonHomePhone,
                   PersonMobilePhone,
                   BillingCity,
                   BillingCountryCode,
                   BillingStreet,
                   BillingStateCode,
                   BillingPostalCode
            FROM Account
            WHERE ( Name LIKE :s OR PersonHomePhone Like :s OR PersonMobilePhone Like :s )
            AND RecordTypeId = :personTypeAccountId];
  }

  @RemoteAction
  global static Map<String, Map<String, LineItemWrapper>> fetchFees(String pricebookId)
  {
    Map<String, Map<String, LineItemWrapper>> result = new Map<String, Map<String, LineItemWrapper>>();
    for( String prov : TaxRate__c.getAll().keySet() )
    {
      result.put(prov, new Map<String, LineItemWrapper>() );
    }
    Id feeRT = LGND_Utilities.recordTypeIdFromName('Product2', 'Fees');
    Set<Id> prodIds = new Set<Id>();
    List<Product_Fee_Amount__c> feeAmounts = [SELECT Id,
                                                     Province__c,
                                                     Amount__c,
                                                     Fee_Product__c,
                                                     Fee_Product__r.Name,
                                                     Fee_Product__r.Name_FR__c,
                                                     Fee_Product__r.Description,
                                                     Fee_Product__r.Description_FR__c,
                                                     Fee_Product__r.ProductCode,
                                                     Fee_Product__r.Family,
                                                     Fee_Product__r.AcctSeed__Accounting_Type__c,
                                                     Fee_Product__r.AcctSeed__Inventory_Type__c
                                              FROM Product_Fee_Amount__c
                                              WHERE Price_Book__c = :pricebookId];
    for( Product_Fee_Amount__c pfa : feeAmounts )
    {
      prodIds .add( pfa.Fee_Product__c);
    }
    Map<Id, Id> prodPbMap = new Map<Id, Id>();
    for( PricebookEntry pbe : [SELECT Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id = : pricebookId AND Product2Id IN : prodIds] )
    {
      prodPbMap.put( pbe.Product2Id, pbe.Id );
    }
    for( Product_Fee_Amount__c pfa : feeAmounts )
    {
      if( result.containsKey(pfa.Province__c) )
      {
        result.get(pfa.Province__c).put( pfa.Id, new LineItemWrapper(pfa, prodPbMap.get(pfa.Fee_Product__c) ) );
      }
    }
    return result;
  }


  @RemoteAction
  global static PageReference createSale(String accountData,
                                         String products,
                                         String oppDataJSON)
  {
    Account acct = (Account)JSON.deserializeStrict(accountData, Account.class);
    Map<String, String> oppData = (Map<String, String>)JSON.deserialize(oppDataJSON, Map<String,String>.class);
    List<OpportunityLineItem> lineItems = (List<OpportunityLineItem>)JSON.deserialize(products, List<OpportunityLineItem>.class);

    String stage;
    if( oppData.get('Payment_Method__c') == 'Pending' )
    {
      stage = 'Pending Pickup';
      //paymentMethod = null;
    }
    else
    {
      stage = 'Picked Up / Won';
    }
    //if there is no Id then we have a new record, but we have to figure out the Record Type Id
    if(acct.Id == null)
    {
      acct.RecordTypeId = personTypeAccountId;
    }

    try
    {
       upsert acct;
    }
    catch(Exception e)
    {
      throw new MyException( e.getMessage() );
      return null;
    }

    Opportunity opp;
    if( oppData.get('Id') == null ){
      opp = new Opportunity(
        Name = 'Counter Sale - ' + String.valueOf(Date.today()) + ' - ' + acct.LastName,
        RecordTypeId = retailCounterSaleOppTypeId,
        Payment_Method__c = oppData.get('Payment_Method__c'),
        TaxationProvince__c = oppData.get('TaxationProvince__c'),
        TaxOverRide__c = Boolean.valueOf(oppData.get('TaxOverRide__c')),
        TaxOverRideRate__c = oppData.get('TaxOverRide__c') == 'true' ?
                              Decimal.valueOf( oppData.get('TaxOverRideRate__c') ) :
                              null,
        CloseDate= Date.today(),
        StageName = stage,
        AccountId = acct.Id
      );
      try
      {
        insert opp;
        opp.pricebook2Id = oppData.get('Pricebook2Id');
        update opp;

        // Save the line items
        for( Integer i=0; i<lineItems.size();i++)
        {
          if( lineItems.get(i).Quantity > 0 )
          {
            if( lineItems.get(i).Id == null )
            {
              lineItems.get(i).OpportunityId = opp.Id;
            }
          }
          else
          {
            lineItems.remove(i);
          }
        }
        if( lineItems.size() > 0 )
        {
          try
          {
            upsert lineItems;
          }
          catch(Exception e)
          {
            throw new MyException( e.getMessage() );
            return null;
          }
        }
      }

      catch(Exception e)
      {
        throw new MyException( e.getMessage() );
        return null;
      }
      //CommissionRecord.createCounterSaleCommissionRecord(opp.Id);
    } // End of Saving new Opportunity
    else
    {
      opp = [SELECT Id, Payment_Method__c, Pricebook2Id,
             ( SELECT Id FROM OpportunityLineItems )
             FROM Opportunity
             WHERE Id = :oppData.get('Id')];
      Boolean pbChanged = false;

      if( opp.Payment_Method__c != oppData.get('Payment_Method__c') )
      {
        opp.Payment_Method__c = oppData.get('Payment_Method__c');
        opp.StageName = stage;
      }
      opp.TaxationProvince__c = oppData.get('TaxationProvince__c');
      opp.TaxOverRide__c = Boolean.valueOf(oppData.get('TaxOverRide__c'));
      opp.TaxOverRideRate__c = oppData.get('TaxOverRide__c') == 'true' ?
                            Decimal.valueOf( oppData.get('TaxOverRideRate__c') ) :
                            null;

      Set<String> oLineItemids = new Set<String>();

      if( oppData.get('Pricebook2Id') != opp.Pricebook2Id )
      // if there is a new pricebook we first need to delete the OpportunityLineItems
      {
        pbChanged = true;

        for(OpportunityLineItem oli : opp.OpportunityLineItems )
        {
          oLineItemids.add(oli.Id);
        }
        try
        {
          delete opp.OpportunityLineItems;
        }
        catch(Exception e)
        {
          throw new MyException( e.getMessage() );
          return null;
        }
        opp.Pricebook2Id = oppData.get('Pricebook2Id');

      }// endIf pricebook conflict

      //Update Opportunity
      try {
        update opp;
      }
      catch(Exception e){
        if( pbChanged == true )
        {
          List<OpportunityLineItem> olis = [SELECT Id
                                             FROM OpportunityLineItem
                                             WHERE OpportunityId = :oppData.get('Id')
                                             ALL ROWS];
          undelete olis;
        }
        throw new MyException( e.getMessage() );
        return null;
      }

      //Save The Line Items

      List<OpportunityLineItem> deletedLineItems = new List<OpportunityLineItem>();
      List<OpportunityLineItem> goodLineItems = new List<OpportunityLineItem>();

      for( Integer i=0; i<lineItems.size(); i++ ){
        System.debug('9999999 ' + lineItems.get(i) );
        if( lineItems.get(i).Quantity == 0.0 )
        {
          System.debug('this item ' + lineItems.get(i).Description + ' has quantity of zero');
          if( lineItems.get(i).Id != null && !oLineItemids.contains(lineItems.get(i).Id) )
          {
            System.debug('this item  ' + lineItems.get(i).Description + ' needs deleting');
            deletedLineItems.add(lineItems.get(i));
          }
          //lineItems.remove(i);
        }
        else
        {
          goodLineItems.add( lineItems.get(i) );
        }
      }

      for( OpportunityLineItem oli : goodLineItems )
      {
        if( oli.Id == null )
        {
          oli.OpportunityId = opp.Id;
        }
      }

      if( deletedLineItems.size() > 0 ){
        try
        {
          delete deletedLineItems;
        }
        catch(Exception e){
          List<OpportunityLineItem> olis = [SELECT Id
                                             FROM OpportunityLineItem
                                             WHERE OpportunityId = :oppData.get('Id')
                                             ALL ROWS];
          undelete olis;
          throw new MyException( 'Cause we already deleted them -- ' + e.getMessage() );
          return null;
        }
      }
      if( goodLineItems.size() > 0 )
      {
        System.debug('OPP LINE ITEMS = ' + goodLineItems);
        try
        {
          upsert goodLineItems;
        }
        catch(Exception e)
        {
          throw new MyException( ' We are failing at the end '  + e.getMessage() );
          return null;
        }
      }
      //CommissionRecord.updateCounterSaleCommisionRecord(opp.Id);
    }// End Updating an Opportunity

    PageReference view = Page.Opportunity_CounterSaleView;
    view.getParameters().put('id', opp.Id);
    return view;

  }

  private LineItemWrapper[] buildLineItems(OpportunityLineItem[] items, Id pbId)
  {
    LineItemWrapper[] result = new List<LineItemWrapper>();
    Set<Id> productIds = new Set<Id>();
    for( OpportunityLineItem oli : items )
    {
      productIds.add(oli.PricebookEntry.Product2Id);
    }
    Map<Id, Product2> prods = new Map<Id, Product2>([SELECT Id,
                               Name,
                               Name_FR__c,
                               Description,
                               Description_FR__c,
                               Family,
                               RecordType.Name,
                               ProductCode,
                               AcctSeed__Accounting_Type__c,
                               AcctSeed__Inventory_Type__c,
                        (SELECT Id,
                                Standard__c,
                                Maximum__c,
                                From_Product__r.Id,
                                From_Product__r.Name,
                                From_Product__r.Name_FR__c,
                                From_Product__r.RecordType.Name,
                                From_Product__r.ProductCode,
                                From_Product__r.Family
                         FROM To_Product_Options__r
                         ORDER BY From_Product__r.Name)
                        FROM Product2
                        WHERE Id IN :productIds ]);
    for( OpportunityLineItem oli : items )
    {
      result.add( new LineItemWrapper( prods.get(oli.PricebookEntry.Product2Id), oli) );
    }
    return result;
  }

}