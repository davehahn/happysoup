public without sharing class LGND_APIv2_Product {

  public String Id { get; set; }
  public String Name { get; set; }
  public String Description { get; set; }
  public String DescriptionFR { get; set; }
  public String Family { get; set; }
  public String RecordTypeName { get; set; }
  public Map<String, String> DefaultImages { get; set; }
  public Decimal RetailPrice { get; set; }
  public Decimal RetailSpecialPrice { get; set; }
  public String RetailSpecialPriceDescription { get; set; }
  public Decimal PartnerPrice { get; set; }
  public Decimal PartnerSpecialPrice { get; set; }
  public String PartnerSpecialPriceDescription { get; set; }
  public Decimal FactoryPrice { get; set; }
  public Decimal FactorySpecialPrice { get; set; }
  public String FactorySpecialPriceDescription { get; set; }
  public Static Decimal ParentRetailPrice { get; set; }
  public String DefaultImage { get; set; }
  public UpgradeProduct StandardMotor { get; set; }
  public SampleRetailSale SampleRetailSale { get; set; }
  public UpgradeProduct StandardTrailer { get; set; }
  public UpgradeProduct StandardTrollingMotor { get; set; }
  public Boolean ExcludePartnerStandardTrailer { get; set; }
  public UpgradeProduct MaximumMotor { get; set; }
  public Map<String, List<PartProduct>> OptionalProducts { get; set; }
  public List<UpgradeProduct> MotorUpgrades { get; set; }
  public List<UpgradeProduct> TrailerUpgrades { get; set; }
  public List<UpgradeProduct> TrollingMotorUpgrades { get; set; }
  public List<MarketingImage> MarketingImages { get; set; }
  public Map<string, List<String>> Features { get; set; }
  public Map<String, List<FeeProduct>> Fees { get; set; }
  public PremiumPackage PremiumPackage { get; set; }
  public Map<String, String> BoatSpecs { get; set; }
  public String PricebookName { get; set; }
  static Map<Id, Product2> allProductOptions;
  static String retailPartnerFilter;
  static Id retailPricebookId;
  static Id partnerPricebookId;
  static Id factoryPricebookId;
  static Id devRetailPricebookId;
  static Map<Id, String> pricebookMap;
  static Map<String, Id> pricebookNameMap;
  static {
    retailPricebookId = gcConstants.idPricebookRetail;
    partnerPricebookId = gcConstants.idPricebookPartner;
    devRetailPricebookId = Legend_Settings__c.getOrgDefaults().Dev_Retail_Pricebook__c;
    factoryPricebookId = gcConstants.idPricebookFactory;
    pricebookMap = new Map<Id, String>();
    pricebookMap.put(retailPricebookId, 'retail');
    pricebookMap.put(partnerPricebookId, 'partner');
    pricebookMap.put(devRetailPricebookId, 'dev-retail');
    pricebookMap.put(factoryPricebookId, 'factory');
    pricebookNameMap = new Map<String, Id>();
    pricebookNameMap.put('retail', retailPricebookId);
    pricebookNameMap.put('dev-retail', devRetailPricebookId);
    pricebookNameMap.put('partner', partnerPricebookId);
    pricebookNameMap.put('factory', factoryPricebookId );
  }
  private Boolean excludeStandardTrailer = false;

  public LGND_APIv2_Product(Id pId, String recordTypeName){
    this.RecordTypeName = recordTypeName;
    init( findProd(pid, true ) );
  }

  public LGND_APIv2_Product(Id pId, Id pbId, String recordTypeName )
  {
    if( !pricebookMap.containsKey( pbId ) )
      throw new LGND_Utilities.LGND_Exception('Invalid pricebook specified');
    this.RecordTypeName = recordTypeName;
    retailPartnerFilter = pricebookMap.get(pbId);
    init( findProd( pId, true) );
  }

  public LGND_APIv2_Product(Id pId, String retail_or_partner, String recordTypeName)
  {
    this.RecordTypeName = recordTypeName;
    if( pricebookNameMap.containsKey( retail_or_partner ) )
    {
      retailPartnerFilter = retail_or_partner;
    }
    init( findProd( pid, true ) );
  }

  public LGND_APIv2_Product(Id pId, Boolean fullResponse, String recordTypeName){
    this.RecordTypeName = recordTypeName;
    init( findprod(pId, fullResponse) );
  }

  public LGND_APIv2_Product(Product2 prod, String recordTypeName)
  {
    this.RecordTypeName = recordTypeName;
    init(prod);
  }

  public void init(Product2 prod){
    System.debug( 'INIT ' + prod );
    if( prod != null )
    {
      if( retailPartnerFilter != null )
      {
        this.PricebookName = [SELECT Name FROM Pricebook2 WHERE Id  = :pricebookNameMap.get(retailPartnerFilter)].Name;
        if( retailPartnerFilter == 'partner' && prod.Exclude_Partner_Standard_Trailer__c == true)
          excludeStandardTrailer = true;
      }
      this.ExcludePartnerStandardTrailer = excludeStandardTrailer;
      this.Id = prod.Id;
      this.Name = prod.Name;
      this.Family = prod.Family;
      this.Description = prod.Description;
      this.DescriptionFR = prod.Description_FR__c;
      this.DefaultImage = prod.Default_Gallery_Image__c;
      this.processPriceBooks(prod);
      this.processStandardProducts(prod);
      this.processOptions(prod);
      this.processFeatures(prod);
      this.processFees(prod);
      this.processImages(prod);
      this.processSampleRetailSale(prod);
      this.processSpecs();
    }
    else
    {
      System.debug('****************************** No Product was found');
    }
  }

  private Product2 findProd(String prodId, Boolean fullResponse) {
    try {
      String standardMotorFields;
      String standardTrailerFields;
      String standardTrollingMotorFields;
      String[] commonProductFields = new String[]{'Id',
                                                  'Name',
                                                  'Family',
                                                  'Description',
                                                  'Description_FR__c',
                                                  'RecordType.Name',
                                                  'Exclude_Partner_Standard_Trailer__c',
                                                  'Legend_Gallery_Image__r.Active_S3_Object__r.URL_Original__c',
                                                  'Default_Gallery_Image__c',
                                                  'Legend_Gallery_Image__r.Active_S3_Object__r.URL_500x500__c',
                                                  'Legend_Gallery_Image__r.Active_S3_Object__r.URL_700w__c',
                                                  'Legend_Gallery_Image__r.Active_S3_Object__r.URL_1280w__c'};
      String selectedBoatFields = fieldsToString(commonProductFields, '');
      String query = 'SELECT ' +  selectedBoatFields;
      if( RecordTypeName == 'Boat')
      {
        standardMotorFields = fieldsToString(commonProductFields, 'Standard_Motor__r.');
        standardTrailerFields = fieldsToString(commonProductFields, 'Standard_Trailer__r.');
        standardTrollingMotorFields = fieldsToString(commonProductFields, 'Standard_Trolling_Motor__r.');
        //if( retailPartnerFilter == 'partner')
        //  query += ', Exclude_Partner_Standard_Trailer__c ';
      }
      //String query = 'SELECT ' +  selectedBoatFields;
      if( fullResponse )
      {
        if( standardMotorFields != null )
        {
          query += ', ' + standardMotorFields;
        }
        if( standardTrailerFields != null )
        {
          query += ', ' + standardTrailerFields;
        }
        if( standardTrollingMotorFields != null )
        {
          query += ', ' + standardTrollingMotorFields;
        }
        query += ', (SELECT  Pricebook2Id, PriceBook2.Name, UnitPrice, Special_Price__c, Special_Price_Description__c, CreatedDate FROM PricebookEntries WHERE Pricebook2.isStandard = false AND isActive = true AND Pricebook2.isActive = true ORDER BY CreatedDate DESC), ' +
          '(SELECT Id, Feature_ID__r.Description__c, Feature_ID__r.Category__c FROM Product_Feature_Maps__r),' +
          '(SELECT Id, Standard__C, Maximum__c, displayOnWeb__c, isBiggestMotor__c, From_Product__r.Id, From_Product__r.Name, From_Product__r.RecordType.Name, From_Product__r.Family FROM To_Product_Options__r ORDER BY From_Product__r.Name),' +
          '(SELECT Id, Fee_Product__c FROM Parent_Product_Fee_Maps__r)';
        if( RecordTypeName == 'Boat' )
        {
          query += ', (SELECT Id, BatteryCost__C, BoatShowDiscount__c, MercuryEngineRebate__c, Motor_Upgrade__c, Motor_Upgrade__r.Name, PropCost__c, xl_VolumeDiscount__c, l_VolumeDiscount__c, m_VolumeDiscount__c, s_VolumeDiscount__c, WOW_VolumeDiscount__c FROM Sample_Retail_Sales__r)';
        }
      }
      query += ' FROM Product2 WHERE Id = \'' + prodId + '\' AND isActive = true LIMIT 1';
      return Database.query(query);
    } catch (exception e) {
        return null;
    }

  }

  private String fieldsToString(String[] fields, String prefix){
    String qString = '';
    for( String f : fields ){
      qString += prefix + f + ', ';
    }
    return qString.removeEnd(', ');
  }
  /* **********************************************************
      TODO
      fix this so the dev-retail and retail price book can coexist
      currently it could return the wrong price if both have entries
      in custom settings
  ************************************************************** */

  private LGND_APIv2_Product processPriceBooks(Product2 prod)
  {
    try
    {
      if( prod.PricebookEntries != null && !prod.PricebookEntries.isEmpty() )
      {
        //this.Prices = new Map<String, Decimal>();
        for( PricebookEntry pbe : prod.PricebookEntries )
        {
         // this.Prices.put(pbe.Pricebook2.Name, pbe.UnitPrice);
          if( pricebookMap.containsKey(pbe.Pricebook2Id) )
          {
            if( pricebookMap.get(pbe.Pricebook2Id) == 'retail'  ||
                pricebookMap.get(pbe.Pricebook2Id) == 'dev-retail' )
            {
              RetailPrice = pbe.UnitPrice;
              ParentRetailPrice = pbe.UnitPrice;
              RetailSpecialPrice = pbe.Special_Price__c;
              RetailSpecialPriceDescription = pbe.Special_Price_Description__c;
            }
            if( pricebookMap.get(pbe.Pricebook2Id) == 'partner' )
            {
              PartnerPrice = pbe.UnitPrice;
              PartnerSpecialPrice = pbe.Special_Price__c;
              PartnerSpecialPriceDescription = pbe.Special_Price_Description__c;
            }
            if( pricebookMap.get(pbe.Pricebook2Id) == 'factory' )
            {
              FactoryPrice = pbe.UnitPrice;
              FactorySpecialPrice = pbe.Special_Price__c;
              FactorySpecialPriceDescription = pbe.Special_Price_Description__c;
            }
          }
        }
      }
    }
    catch(Exception e){}
    return this;
  }

  public LGND_APIv2_Product processStandardProducts(Product2 b){
    System.debug( 'processStandardProducts' );
    System.debug( this.RecordTypeName );
    if( this.RecordTypeName == 'Boat')
    {
      try
      {
        Set<String> standardIds = new Set<String>();
        standardIds.add(b.Standard_Motor__r.Id);
        standardIds.add(b.Standard_Trailer__r.Id);
        standardIds.add(b.Standard_Trolling_Motor__r.Id);

        List<Product2> standards = [SELECT Id, Name, RecordType.Name, Default_Gallery_Image__c, Available_For_Mercury_Partner_Discount__c,
                                  (SELECT Id, UnitPrice, Special_Price__c, Special_Price_Description__c, Pricebook2Id FROM PricebookEntries WHERE isActive = true AND Pricebook2.isActive = true),
                                  (SELECT Id, Standard__c, Maximum__c, From_Product__r.Id, From_Product__r.Name FROM To_Product_Options__r ORDER BY From_Product__r.Name)
                                 FROM Product2
                                 WHERE Id IN :standardIds
                                 ];
        for( Product2 p : standards ){
          if(p.RecordType.Name == 'Motor'){
            setStandardMotor(p);
            System.debug('STANDARD MOTOR = ' + p);
          }
          if(p.RecordType.Name == 'Trailer'){
            setStandardTrailer(p);
          }
          if(p.RecordType.Name == 'Trolling Motor'){
            setStandardTrollingMotor(p);
          }
        }
      }
      catch(Exception e){
        System.debug( e.getMessage());
      }
    }
    return this;
  }

  private LGND_APIv2_Product processOptions(Product2 parentProduct){
    try
    {
      if( parentProduct.To_Product_Options__r != null ||
          !parentProduct.To_Product_Options__r.isEmpty() )
      {
        Set<String> standardIds = new Set<String>();
        if( parentProduct.RecordType.Name == 'Boat' )
        {
          standardIds.add(parentProduct.Standard_Motor__r.Id);
          standardIds.add(parentProduct.Standard_Trailer__r.Id);
          standardIds.add(parentProduct.Standard_Trolling_Motor__r.Id);
        }
        Id maximumMotorId;
        Map<String,List<Product2>> optionsMap = new Map<String, List<Product2>>();
        for(String t : new Set<String>{'Part', 'Motor', 'Trailer', 'Trolling Motor'}) {
          optionsMap.put(t, new List<Product2>() );
        }
        List<String> pIds = new List<String>();
        for( Product_Option__c po : parentProduct.To_Product_Options__r){
          if( po.isBiggestMotor__c == true ) maximumMotorId = po.From_Product__c;
          pIds.add(po.From_Product__c);
        }
        allProductOptions = new Map<Id, Product2>([SELECT Id, Name, Family, RecordType.Name, Default_Gallery_Image__c, Available_For_Mercury_Partner_Discount__c,
                                (SELECT Id, UnitPrice, Special_Price__c, Special_Price_Description__c, Pricebook2Id, Pricebook2.Name FROM PricebookEntries WHERE isActive = true AND Pricebook2.isActive = true),
                                (SELECT Id, Standard__c, Maximum__c, displayOnWeb__c FROM From_Product_Options__r WHERE To_Product__c = :parentProduct.Id LIMIT 1),
                                (SELECT Id, Standard__C, Maximum__c, displayOnWeb__c, From_Product__r.Id, From_Product__r.Name FROM To_Product_Options__r ORDER BY From_Product__r.Name),
                                (SELECT Id, Price__c, From_Product__r.RecordType.Name FROM To_Product_Upgrades__r WHERE From_Product__c IN :standardIds ORDER BY Price__c ASC)
                               FROM Product2
                               WHERE Id IN :pIds
                               ORDER BY Name DESC
                               ]);
        List<Product2> prods = allProductOptions.values();
        Set<Id> upgradeIds = new Set<Id>();

        for( Product2 p : prods ){
          /* Break out the Premium Package */
          if( p.RecordType.Name == 'Part' &&
              p.Family == 'Premium Package' &&
              Integer.valueOf( p.From_Product_Options__r[0].Standard__c ) == 1 &&
              Integer.valueOf( p.From_Product_Options__r[0].Maximum__c ) == 1 )
          {
            this.PremiumPackage = processPremiumPackage( p );
          }
          else {
            if( optionsMap.containsKey(p.RecordType.Name) )
            {
              optionsMap.get(p.RecordType.Name).add(p);
            }
            for( Product_Upgrade__c pu : p.To_Product_Upgrades__r)
            {
              upgradeIds.add(pu.Id);
            }
          }
        }
        Set<Id> pbIdSearch = new Set<Id>();
        if( retailPartnerFilter != null )
          pbIdSearch.add( pricebookNameMap.get(retailPartnerFilter) );
        else
          pbIdSearch = pricebookMap.keySet();

        Set<Id> filteredUpgradeIds = new Set<Id>();
        //find only upgrade Ids that have Costs within the selected Pricebook(s)
        for( Product_Upgrade_Cost__c puc : [SELECT Id, Product_Upgrade__c
                                                 FROM Product_Upgrade_Cost__c
                                                 WHERE Price_Book__c IN :pbIdSearch
                                                 AND Product_Upgrade__c IN :upgradeIds] )
        {
          filteredUpgradeIds.add( puc.Product_Upgrade__c );
        }


        Map<Id, Product_Upgrade__c> upgrades = new Map<Id, Product_Upgrade__c>(
          [SELECT Id, From_Product__r.RecordType.Name, To_Product__c, To_Product__r.Name, To_Product__r.RecordType.Name,
            ( SELECT Price_Book__c, Cost__c
              FROM Product_Upgrade_Costs__r
              WHERE Price_Book__c IN : pbIdSearch )
           FROM Product_Upgrade__c
           WHERE Id IN :filteredUpgradeIds
           ORDER BY To_Product__r.Name ]
        );

        if( maximumMotorId != null )
        {
          this.MaximumMotor = new UpgradeProduct(allProductOptions.get(maximumMotorId), upgrades, false);
        }
        this.OptionalProducts = buildOptionalProducts( optionsMap.get('Part') );
        this.MotorUpgrades = buildMotorUpgrades( optionsMap.get('Motor'), upgrades );
        buildTrailerUpgrades( optionsMap.get('Trailer'), upgrades );
        this.TrollingMotorUpgrades = buildTrollingMotorUpgrades( optionsMap.get('Trolling Motor'), upgrades );
      }
    }
    catch(Exception e){}
    return this;
  }

  private PremiumPackage processPremiumPackage( Product2 p )
  {
    p = [SELECT Id,
                Name,
                Family,
                RecordType.Name,
                Default_Gallery_Image__c,
          (SELECT Id,
                  UnitPrice,
                  Special_Price__c,
                  Special_Price_Description__c,
                  Pricebook2Id,
                  Pricebook2.Name
           FROM PricebookEntries
           WHERE isActive = true
           AND Pricebook2.isActive = true),
          (SELECT Id,
                  Feature_Id__r.description__c,
                  Feature_Id__r.description_fr__c,
                  Feature_Id__r.Category__c
                  FROM Product_Feature_Maps__r )
         FROM Product2
         WHERE Id = :p.Id ];
    return new PremiumPackage(p);
  }

  private LGND_APIv2_Product processFeatures(Product2 p){
    try
    {
      if( p.Product_Feature_Maps__r != null && !p.Product_Feature_Maps__r.isEmpty() ){
        this.Features = new Map<String, List<String>>();
        for( Product_Feature_Map__c pfm : p.Product_Feature_Maps__r ){
          if( !this.Features.keySet().contains( pfm.Feature_ID__r.Category__c ) ){
            this.Features.put( pfm.Feature_ID__r.Category__c, new List<String>() );
          }
          this.Features.get( pfm.Feature_ID__r.Category__c ).add( pfm.Feature_ID__r.Description__c );
        }
      }
    }
    catch(Exception e){}
    return this;
  }

  private LGND_APIv2_Product processFees(Product2 p)
  {
    try
    {
      if( p.Parent_Product_Fee_Maps__r != null && !p.Parent_Product_Fee_Maps__r.isEmpty() )
      {
        this.Fees = new Map<String, List<FeeProduct>>();
        Set<Id> ids = new Set<Id>();
        for( Product_Fee_Map__c pfm : p.Parent_Product_Fee_Maps__r )
        {
          ids.add(pfm.Fee_Product__c);
        }
        Map<Id, Product2> fees = new Map<Id, Product2>([
          SELECT Id, Name, Family
          FROM Product2
          WHERE Id IN :ids
        ]);
        List<Product_Fee_Amount__c> feeAmounts = [SELECT Id, Amount__c, Province__c, Fee_Product__c, Price_Book__c
                                                  FROM Product_Fee_Amount__c
                                                  WHERE Fee_Product__c IN :fees.keySet()
                                                  AND Price_Book__c IN :pricebookMap.keySet() ];

        Map<Id, Map<String, List<Product_Fee_Amount__c>>> feeMap = new Map<Id, Map<String, List<Product_Fee_Amount__c>>>();
        for(Product_Fee_Amount__c pfa : feeAmounts )
        {
          if( !feeMap.containsKey( pfa.Fee_Product__c) )
          {
            feeMap.put( pfa.Fee_Product__c, new Map<String, List<Product_Fee_Amount__c>>() );
          }
          if( !feeMap.get( pfa.Fee_Product__c ).containsKey( pfa.Province__c) )
          {
            feeMap.get( pfa.Fee_Product__c ).put( pfa.Province__c, new List<Product_Fee_Amount__c>() );
          }
          feeMap.get( pfa.Fee_Product__c ).get( pfa.Province__c ).add( pfa );
        }
        for( Product2 f : fees.values() )
        {
          for( String prov : feeMap.get(f.Id).keySet() )
          {
            if( !this.Fees.containsKey(prov) )
            {
              this.Fees.put(prov, new List<FeeProduct>() );
            }
            this.Fees.get(prov).add( new FeeProduct( f, feeMap.get(f.Id).get(prov) ) );
          }
        }
      }
    }
    catch(Exception e){}
    return this;
  }

  private LGND_APIv2_Product processImages(Product2 p){
    try
    {
      if( p.Legend_Gallery_Image__r != null )
      {
        this.DefaultImages = new Map<String,String>();
        this.DefaultImages.put('500x500', p.Legend_Gallery_Image__r.Active_S3_Object__r.URL_500x500__c);
        this.DefaultImages.put('700w', p.Legend_Gallery_Image__r.Active_S3_Object__r.URL_700w__c);
        this.DefaultImages.put('1280w', p.Legend_Gallery_Image__r.Active_S3_Object__r.URL_1280w__c);
        this.DefaultImages.put('Original', p.Legend_Gallery_Image__r.Active_S3_Object__r.URL_Original__c);
      }
      List<Legend_Gallery_Image_Map__c> imageMaps = [SELECT Legend_Gallery_Image__r.Active_S3_Object__r.URL_500x500__c,
                                                            Legend_Gallery_Image__r.Active_S3_Object__r.URL_Gallery__c,
                                                            Legend_Gallery_Image__r.Active_S3_Object__r.URL_700w__c,
                                                            Legend_Gallery_Image__r.Active_S3_Object__r.URL_Original__c,
                                                            Legend_Gallery_Image__r.Active_S3_Object__r.URL_1280w__c,
                                                            Legend_Gallery_Image__r.Name, Legend_Gallery_Image__r.ENG_Description__c,
                                                             Legend_Gallery_Image__r.FR_Description__c
                                                     FROM Legend_Gallery_Image_Map__c
                                                     WHERE Parent_object_Id__c = :p.Id];

      if( imageMaps.size() > 0 ){
        this.MarketingImages = new List<MarketingImage>();
        for(Legend_Gallery_Image_Map__c lgim : imageMaps){
          this.MarketingImages.add( new MarketingImage(lgim) );
        }
      }
    }
    catch(Exception e){}
    return this;
  }

  private void processSampleRetailSale(Product2 b)
  {
    if( this.RecordTypeName == 'Boat' )
    {
      this.SampleRetailSale = new SampleRetailSale(b, this.Fees, this.MotorUpgrades, allProductOptions);
    }
  }

  private LGND_APIv2_Product processSpecs()
  {
    try {
      this.BoatSpecs = new Map<String, String>();
      String fieldSetName = this.Family.replace(' ', '_') + '_Specifications';
      Map<String, String> fieldSetMap = LGND_Utilities.fieldsFromFieldSet('Product2', fieldSetName );
      String queryString = 'SELECT Id, ';
      for( String fieldName : fieldSetMap.keySet() )
      {
        queryString += fieldName;
        queryString += ',';
      }
      queryString = queryString.removeEnd(',');
      queryString += ' FROM Product2 WHERE Id = \'';
      queryString += this.Id;
      queryString += '\'';

      Product2 boat = Database.query( queryString );
      for( String fieldName : fieldSetMap.keySet() )
      {
        this.BoatSpecs.put( fieldSetMap.get(fieldName), String.valueOf( boat.get( fieldName ) ) );
      }
    }
    catch(Exception e){}
    return this;
  }

  public static Map<String, List<PartProduct>> buildOptionalProducts(List<Product2> parts) {
    if( parts.isEmpty() ){
      return null;
    }
    Map<String, List<PartProduct>> ppMap = new Map<String, List<PartProduct>>();
    for( Product2 p : parts )
    {
       if( p.Family != null )
       {
        if( retailPartnerFilter != null )
        {
          for( PricebookEntry pbe : p.PricebookEntries )
          {
            if( pricebookNameMap.containsKey(retailPartnerFilter) &&
                pbe.Pricebook2Id == pricebookNameMap.get(retailPartnerFilter) )
            {
                if( !ppMap.keySet().contains(p.Family) ){
                  ppMap.put(p.Family, new List<PartProduct>() );
                }
                ppMap.get(p.Family).add(new PartProduct(p) );
            }
          }
        }
        else
        {
          if( !ppMap.keySet().contains(p.Family) ){
            ppMap.put(p.Family, new List<PartProduct>() );
          }
          ppMap.get(p.Family).add(new PartProduct(p) );
        }
      }
    }

    return ppMap;
  }

  private List<UpgradeProduct> buildMotorUpgrades(List<Product2> motors,
                                                Map<Id, Product_Upgrade__c> upgrades)
  {
    if( motors.isEmpty() ){
      return null;
    }
    List<UpgradeProduct> mList = new List<UpgradeProduct>();
    for( Product2 p : motors){
      UpgradeProduct u = new UpgradeProduct(p, upgrades, false);
      mList.add( u );
    }
    return mList;
  }

  private List<UpgradeProduct> buildTrailerUpgrades(List<Product2> trailers,
                                                    Map<Id, Product_Upgrade__c> upgrades)
  {
    if( trailers.isEmpty() ){
      return this.TrailerUpgrades;
    }
    if(this.TrailerUpgrades == null )
      this.TrailerUpgrades = new List<UpgradeProduct>();
    for( Product2 p : trailers){
      Boolean useTrailer = false;
      if( this.standardTrailer == null && excludeStandardTrailer == false )
        useTrailer = true;
      else
      {
        for(Product_Upgrade__c pu : upgrades.values() )
        {
          if( p.Id == pu.To_Product__c )
          {
            useTrailer = true;
            break;
          }
        }
      }
      if( useTrailer )
        this.TrailerUpgrades.add( new UpgradeProduct( p, upgrades, excludeStandardTrailer ) );
    }
    return this.TrailerUpgrades;
  }

  private List<UpgradeProduct> buildTrollingMotorUpgrades(List<Product2> trollinMotors,
                                                                Map<Id, Product_Upgrade__c> upgrades)
  {
    if( trollinMotors.isEmpty() ){
      return null;
    }
    List<UpgradeProduct> trList = new List<UpgradeProduct>();
    for( Product2 p : trollinMotors){
      trList.add(new UpgradeProduct(p, upgrades, false));
    }
    return trList;
  }

  private void setStandardMotor(Product2 motor){
    this.standardMotor = new UpgradeProduct(motor, false);
    this.standardMotor.DisplayOnWeb = true;
  }

  private void setStandardTrailer(Product2 trailer){
    if( excludeStandardTrailer )
    {
      if( this.TrailerUpgrades == null )
        this.TrailerUpgrades = new List<UpgradeProduct>();
      this.TrailerUpgrades.add( new UpgradeProduct(trailer, true) );
    }
    else
      this.standardTrailer = new UpgradeProduct(trailer, false);

    this.standardTrailer.DisplayOnWeb = true;
  }

  private void setStandardTrollingMotor(Product2 trollingMotor){
    this.standardTrollingMotor = new UpgradeProduct(trollingMotor, false);
    this.standardTrollingMotor.DisplayOnWeb = true;
  }


  /* -------------------- UpgradeProduct Class ------------------------ */
  public Class UpgradeProduct {

    public String Id { get; set; }
    public String Name { get; set; }
    public String Family { get; set; }
    public Boolean DisplayOnWeb { get; set; }
    public String DefaultImage { get; set; }
    public Decimal RetailPrice { get; set; }
    public Decimal PartnerPrice { get; set; }
    public Decimal RetailSpecialPrice { get; set; }
    public String RetailSpecialPriceDescription { get; set; }
    public Decimal PartnerSpecialPrice { get; set; }
    public String PartnerSpecialPriceDescription { get; set; }
    public Decimal RetailUpgradeCost { get; set; }
    public Decimal PartnerUpgradeCost { get; set; }
    public Decimal WeeklyUpgradeCost { get; set; }
    /* other motor related detail fields */
    public Map<String, List<PartProduct>> OptionalProducts { get; set; }
    public Boolean availableForMercDiscount { get; set; }

    //public UpgradeProduct(Product2 m)
    //{
    //  this.Name = m.Name;
    //  this.Family = m.RecordType.Name;
    //  this.Id = m.Id;
    //  this.DefaultImage = m.Default_Gallery_Image__c;
    //  this.processOptions(m);
    //  this.processPrices(m);
    //  this.WeeklyUpgradeCost = calcWeeklyCost();
    //}

    public UpgradeProduct(Product2 m, Boolean excludedStandard)
    {
      this.Name = m.Name;
      this.Family = m.RecordType.Name;
      this.Id = m.Id;
      this.DefaultImage = m.Default_Gallery_Image__c;
      this.processOptions(m);
      this.processPrices(m, excludedStandard);
      this.WeeklyUpgradeCost = calcWeeklyCost();
      this.availableForMercDiscount = m.Available_For_Mercury_Partner_Discount__c;
    }

    public UpgradeProduct(Product2 m,
                          Map<Id, Product_Upgrade__c> upgrades,
                          Boolean excludedStandard)
    {
      this.Name = m.Name;
      this.Family = m.RecordType.Name;
      this.Id = m.Id;
      this.DefaultImage = m.Default_Gallery_Image__c;
      //this.RetailPrice = m.PricebookEntries[0].UnitPrice;
      if( !excludedStandard &&
          m.To_Product_Upgrades__r != null &&
          !m.To_Product_Upgrades__r.isEmpty() &&
          upgrades != null ){
        //this.UpgradeCost = m.To_Product_Upgrades__r[0].Price__c;
        this.processUpgrades(m, upgrades);
      }
      if( m.From_Product_Options__r != null && !m.From_Product_Options__r.isEmpty() ){
        this.DisplayOnWeb =  m.From_Product_Options__r[0].displayOnWeb__c;
      }
      this.processOptions(m);
      this.processPrices(m, excludedStandard);
      this.WeeklyUpgradeCost = calcWeeklyCost();
      this.availableForMercDiscount = m.Available_For_Mercury_Partner_Discount__c;
    }

    //public UpgradeProduct(Product2 m,
    //                      Map<Id, Product_Upgrade__c> upgrades)
    //{
    //  this.Name = m.Name;
    //  this.Family = m.RecordType.Name;
    //  this.Id = m.Id;
    //  this.DefaultImage = m.Default_Gallery_Image__c;
    //  //this.RetailPrice = m.PricebookEntries[0].UnitPrice;
    //  if( m.To_Product_Upgrades__r != null &&
    //      !m.To_Product_Upgrades__r.isEmpty() &&
    //      upgrades != null ){
    //    //this.UpgradeCost = m.To_Product_Upgrades__r[0].Price__c;
    //    this.processUpgrades(m, upgrades);
    //  }
    //  if( m.From_Product_Options__r != null && !m.From_Product_Options__r.isEmpty() ){
    //    this.DisplayOnWeb =  m.From_Product_Options__r[0].displayOnWeb__c;
    //  }
    //  this.processOptions(m);
    //  this.processPrices(m);
    //  this.WeeklyUpgradeCost = calcWeeklyCost();
    //}

    private Decimal calcWeeklyCost()
    {
      /* calculate using this.RetailUpgradeCost and ParentRetailPrice */
      if( this.RetailUpgradeCost != null )
      {
        PaymentCalculator pc = new PaymentCalculator( this.RetailUpgradeCost + ParentRetailPrice );
        return pc.calculateWeeklyPayment( this.RetailUpgradeCost );
      }
      return null;
    }

    private UpgradeProduct processUpgrades( Product2 m,
                                            Map<Id, Product_Upgrade__c> upgrades)
    {
      if( upgrades.containsKey( m.To_Product_Upgrades__r[0].Id) )
      {
        Product_Upgrade__c pu = upgrades.get( m.To_Product_Upgrades__r[0].Id);
        for(Product_Upgrade_Cost__c puc : pu.Product_Upgrade_Costs__r)
        {
          if(pricebookMap.containsKey(puc.Price_Book__c) )
          {
            if( pricebookMap.get(puc.Price_Book__c) == 'retail' )
            {
              this.RetailUpgradeCost = puc.Cost__c;
            }
             if( pricebookMap.get(puc.Price_Book__c) == 'partner' ||
                 pricebookMap.get(puc.Price_Book__c) == 'factory' )
            {
              this.PartnerUpgradeCost = puc.Cost__c;
            }
          }
        }
      }
      return this;
    }

    private UpgradeProduct processPrices(Product2 m, Boolean excludedStandard)
    {
      for(PricebookEntry pbe : m.PricebookEntries)
      {
        if( pricebookMap.containsKey(pbe.Pricebook2Id) )
        {
          if( pricebookMap.get(pbe.Pricebook2Id) == 'retail' )
          {
            this.RetailPrice = pbe.UnitPrice;
            this.RetailSpecialPrice = pbe.Special_Price__c;
            this.RetailSpecialPriceDescription = pbe.Special_Price_Description__c;
          }
          if( pricebookMap.get(pbe.Pricebook2Id) == 'partner' )
          {
            this.PartnerPrice = pbe.UnitPrice;
            this.PartnerSpecialPrice = pbe.Special_Price__c;
            this.PartnerSpecialPriceDescription = pbe.Special_Price_Description__c;
            if( this.Family == 'Trailer' && excludedStandard == true )
              this.PartnerUpgradeCost = pbe.UnitPrice;
          }
          if( pricebookMap.get(pbe.Pricebook2Id) == 'factory' )
          {
            this.PartnerPrice = pbe.UnitPrice;
            if( this.Family == 'Trailer' && retailPartnerFilter == 'factory' )
              this.PartnerUpgradeCost = pbe.UnitPrice;
            if( this.Family == 'Trolling Motor' && retailPartnerFilter == 'factory' )
              this.PartnerUpgradeCost = pbe.UnitPrice;
          }
        }
      }
      return this;
    }

    private UpgradeProduct processOptions(Product2 parentProduct){
      if(parentProduct.To_Product_Options__r != null || !parentProduct.To_Product_Options__r.isEmpty()){

        List<String> pIds = new List<String>();
        for( Product_Option__c po : parentProduct.To_Product_Options__r){
          pIds.add(po.From_Product__c);
        }
        List<Product2> prods = [SELECT Id, Name, Family, Default_Gallery_Image__c,
                                (SELECT Id, UnitPrice, Pricebook2.Name FROM PricebookEntries WHERE isActive = true AND Pricebook2.isActive = true ORDER BY CreatedDate DESC),
                                (SELECT Id, Standard__c, Maximum__c, DisplayOnWeb__c FROM From_Product_Options__r WHERE To_Product__c = :parentProduct.Id LIMIT 1),
                                (SELECT Id, Standard__C, Maximum__c, From_Product__r.Id, From_Product__r.Name FROM To_Product_Options__r ORDER BY From_Product__r.Name)
                               FROM Product2
                               WHERE Id IN :pIds
                               ];
        this.OptionalProducts = LGND_APIv2_Product.buildOptionalProducts( prods );
      }
      return this;
    }

  }

  /* -------------------- Premium Package ------------------------- */
  public Class PremiumPackage {
    public String Id { get; set; }
    public String Name { get; set; }
    public Decimal RetailPrice { get; set; }
    public Decimal PartnerPrice { get; set; }
    public String DefaultImage { get; set; }
    public Map<String, List<Feature>> Contents { get; set; }

    public PremiumPackage(Product2 p) {
      this.Contents = new Map<String, List<Feature>>();
      this.Name = p.Name;
      this.Id = p.Id;
      this.DefaultImage = p.Default_Gallery_Image__c;
      this.processPriceBooks(p);
      processContents( p.Product_Feature_Maps__r );
    }

    private PremiumPackage processPriceBooks(Product2 b)
    {
      try
      {
        //this.Prices = new Map<String, Decimal>();
        for( PricebookEntry pbe : b.PricebookEntries )
        {
         // this.Prices.put(pbe.Pricebook2.Name, pbe.UnitPrice);
          if( pricebookMap.containsKey(pbe.Pricebook2Id) )
          {
            if( pricebookMap.get(pbe.Pricebook2Id) == 'retail' )
            {
              this.RetailPrice = pbe.UnitPrice;
            }
            if( pricebookMap.get(pbe.Pricebook2Id) == 'partner' ||
                 pricebookMap.get(pbe.Pricebook2Id) == 'factory')
            {
              this.PartnerPrice = pbe.UnitPrice;
            }
          }
        }
      }
      catch(Exception e){}
      return this;
    }

    private PremiumPackage processContents( Product_Feature_Map__c[] maps )
    {
      for( Product_Feature_Map__c pfm : maps )
      {
        if( !this.Contents.containsKey( pfm.Feature_Id__r.Category__c ) )
          this.Contents.put( pfm.Feature_Id__r.Category__c, new List<Feature>() );
        this.Contents.get( pfm.Feature_Id__r.Category__c ).add( new Feature( pfm ) );
      }
      return this;
    }

  }

  public Class Feature {
    public String Description { get; set; }
    public String Description_FR { get; set; }

    public Feature( Product_Feature_Map__c pfm )
    {
      this.Description = pfm.Feature_Id__r.description__c;
      this.Description_FR = pfm.Feature_Id__r.description_fr__c;
    }
  }

  /* -------------------- FeeProduct Class ------------------------- */
  public Class FeeProduct {

    public String Id { get; set; }
    public String Name { get; set; }
    public String Family { get; set; }
    public Decimal RetailPrice { get; set; }
    public Decimal PartnerPrice { get; set; }
    public Decimal FactoryPrice { get; set; }
    //public Map<String,Decimal> Prices { get; set; }

    public FeeProduct(Product2 p)
    {
      this.Id = p.Id;
      this.Name = p.Name;
      //processPriceBooks( p );
    }

    public FeeProduct(Product2 feeProduct, List<Product_Fee_Amount__c> feeAmounts)
    {
      this.Id = feeProduct.Id;
      this.Name = feeProduct.Name;
      this.Family = feeProduct.Family;
      for( Product_Fee_Amount__c pfa: feeAmounts )
      {
        if( pricebookMap.get(pfa.Price_Book__c) == 'retail' )
        {
          this.RetailPrice = pfa.Amount__c;
        }
        if( pricebookMap.get(pfa.Price_Book__c) == 'partner' )
        {
          this.PartnerPrice = pfa.Amount__c;
        }
        if( pricebookMap.get(pfa.Price_Book__c) == 'factory' )
        {
          this.FactoryPrice = pfa.Amount__c;
        }
      }
    }

    //private FeeProduct processPriceBooks(Product2 b)
    //{
    //  try
    //  {
    //    //this.Prices = new Map<String, Decimal>();
    //    for( PricebookEntry pbe : b.PricebookEntries )
    //    {
    //     // this.Prices.put(pbe.Pricebook2.Name, pbe.UnitPrice);
    //      if( pricebookMap.containsKey(pbe.Pricebook2Id) )
    //      {
    //        if( pricebookMap.get(pbe.Pricebook2Id) == 'retail' )
    //        {
    //          this.RetailPrice = pbe.UnitPrice;
    //        }
    //        if( pricebookMap.get(pbe.Pricebook2Id) == 'partner' )
    //        {
    //          this.PartnerPrice = pbe.UnitPrice;
    //        }
    //      }
    //    }
    //  }
    //  catch(Exception e){}
    //  return this;
    //}
  }

  /* -------------------- PartProduct Class ------------------------ */
  public Class PartProduct {

    public String Id { get; set; }
    public String Name { get; set; }
    public Boolean HasOptions { get; set; }
    public Decimal RetailPrice { get; set; }
    public Decimal PartnerPrice { get; set; }
    public Decimal FactoryPrice { get; set; }
    public Decimal FactorySpecialPrice { get; set; }
    public String FactorySpecialPriceDescription { get; set; }
    public Decimal RetailSpecialPrice { get; set; }
    public String RetailSpecialPriceDescription { get; set; }
    public Decimal PartnerSpecialPrice { get; set; }
    public String PartnerSpecialPriceDescription { get; set; }
    public String DefaultImage { get; set; }
    public Integer QuantityStandard { get; set; }
    public Integer MaximumQuantity { get; set; }
    public Boolean DisplayOnWeb { get; set; }


    public PartProduct(Product2 p) {
      this.HasOptions = false;
      this.Name = p.Name;
      this.Id = p.Id;
      this.DefaultImage = p.Default_Gallery_Image__c;
      this.processPriceBooks(p);
      if( p.From_Product_Options__r != null && !p.From_Product_Options__r.isEmpty() ){
        this.QuantityStandard = Integer.valueOf( p.From_Product_Options__r[0].Standard__c );
        this.MaximumQuantity = Integer.valueOf( p.From_Product_Options__r[0].Maximum__c );
        this.DisplayOnWeb = p.From_Product_Options__r[0].displayOnWeb__c;
      }
      this.processOptions(p);
    }

    private PartProduct processPriceBooks(Product2 b)
    {
      try
      {
        //this.Prices = new Map<String, Decimal>();
        for( PricebookEntry pbe : b.PricebookEntries )
        {
         // this.Prices.put(pbe.Pricebook2.Name, pbe.UnitPrice);
          if( pricebookMap.containsKey(pbe.Pricebook2Id) )
          {
            if( pricebookMap.get(pbe.Pricebook2Id) == 'retail' )
            {
              this.RetailPrice = pbe.UnitPrice;
              this.RetailSpecialPrice = pbe.Special_Price__c;
              this.RetailSpecialPriceDescription = pbe.Special_Price_Description__c;
            }
            if( pricebookMap.get(pbe.Pricebook2Id) == 'partner' )
            {
              this.PartnerPrice = pbe.UnitPrice;
              this.PartnerSpecialPrice = pbe.Special_Price__c;
              this.PartnerSpecialPriceDescription = pbe.Special_Price_Description__c;
            }
            if( pricebookMap.get(pbe.Pricebook2Id) == 'factory' )
            {
              this.FactoryPrice = pbe.UnitPrice;
              this.FactorySpecialPrice = pbe.Special_Price__c;
              this.FactorySpecialPriceDescription = pbe.Special_Price_Description__c;
            }
          }
        }
      }
      catch(Exception e){}
      return this;
    }

    private PartProduct processOptions(Product2 parentProduct){
      if(parentProduct.To_Product_Options__r != null && parentProduct.To_Product_Options__r.size() > 0)
      {
        this.HasOptions = true;
      }
      return this;
    }
  }

  public Class MarketingImage {
    public String Name { get; set; }
    public String EngDescription { get; set; }
    public String FrDescription { get; set; }
    public String AWS_Url_200_high { get; set; }
    public String AWS_Url_500x500 { get; set; }
    public String AWS_Url_700_wide { get; set; }
    public String AWS_Url_1280_wide { get; set; }
    public String AWS_Url_fullsize { get; set; }

    public MarketingImage(Legend_Gallery_Image_Map__c lgim)
    {
      this.Name = lgim.Legend_Gallery_Image__r.Name;
      this.EngDescription = lgim.Legend_Gallery_Image__r.ENG_Description__c;
      this.FrDescription = lgim.Legend_Gallery_Image__r.FR_Description__c;
      this.AWS_Url_fullsize = lgim.Legend_Gallery_Image__r.Active_S3_Object__r.URL_Original__c;
      this.AWS_Url_200_high = lgim.Legend_Gallery_Image__r.Active_S3_Object__r.URL_Gallery__c;
      this.AWS_Url_500x500 = lgim.Legend_Gallery_Image__r.Active_S3_Object__r.URL_500x500__c;
      this.AWS_Url_700_wide = lgim.Legend_Gallery_Image__r.Active_S3_Object__r.URL_700w__c;
      this.AWS_Url_1280_wide = lgim.Legend_Gallery_Image__r.Active_S3_Object__r.URL_1280w__c;
    }

  }

  public class SampleRetailSale {
    public Decimal small_volume_discount { get; set; }
    public Decimal medium_volume_discount { get; set; }
    public Decimal large_volume_discount { get; set; }
    public String motor_upgrade_name { get; set; }
    public Decimal motor_upgrade_partner_cost { get; set ;}
    public Decimal motor_upgrade_retail_cost { get; set ;}
    public Decimal xlarge_volume_discount { get; set; }
    public Decimal wow_volume_discount { get; set; }
    public Decimal boat_show_discount { get; set; }
    public Decimal mercury_engine_discount { get; set; }
    public Decimal battery_cost { get; set; }
    public Decimal prop_cost { get; set; }
    public Map<String, Decimal> retail_factory_freight {
      get {
        if( retail_factory_freight == null )
        {
          retail_factory_freight = new Map<String, Decimal>();
        }
        return retail_factory_freight;
      }
      set;
    }
    public Map<String, Decimal> partner_factory_freight {
      get {
        if( partner_factory_freight == null )
        {
          partner_factory_freight = new Map<String, Decimal>();
        }
        return partner_factory_freight;
      }
      set;
    }
    public Map<String, Decimal> retail_admin_fee {
      get {
        if( retail_admin_fee == null )
        {
          retail_admin_fee = new Map<String, Decimal>();
        }
        return retail_admin_fee;
      }
      set;
    }
    public Map<String, Decimal> partner_admin_fee {
      get {
        if( partner_admin_fee == null )
        {
          partner_admin_fee = new Map<String, Decimal>();
        }
        return partner_admin_fee;
      }
      set;
    }
    public Map<String, Decimal> retail_rigging_and_prep {
      get {
        if( retail_rigging_and_prep == null )
        {
          retail_rigging_and_prep = new Map<String, Decimal>();
        }
        return retail_rigging_and_prep;
      }
      set;
    }
    public Map<String, Decimal> partner_rigging_and_prep {
      get {
        if( partner_rigging_and_prep == null )
        {
          partner_rigging_and_prep = new Map<String, Decimal>();
        }
        return partner_rigging_and_prep;
      }
      set;
    }
    public ExampleProduct[] example_products { get; set; }

    public SampleRetailSale(Product2 boat,
                            Map<String, List<FeeProduct>> fees,
                            List<UpgradeProduct> motorUpgrades,
                            Map<Id, Product2> optionalProducts )
    {
      if( boat.Sample_Retail_Sales__r.size() > 0 )
      {
        this.example_products = new List<ExampleProduct>();
        this.small_volume_discount = boat.Sample_Retail_Sales__r[0].s_VolumeDiscount__c;
        this.medium_volume_discount = boat.Sample_Retail_Sales__r[0].m_VolumeDiscount__c;
        this.large_volume_discount = boat.Sample_Retail_Sales__r[0].l_VolumeDiscount__c;
        this.xlarge_volume_discount = boat.Sample_Retail_Sales__r[0].xl_VolumeDiscount__c;
        this.wow_volume_discount = boat.Sample_Retail_Sales__r[0].WOW_VolumeDiscount__c;
        this.boat_show_discount = boat.Sample_Retail_Sales__r[0].BoatShowDiscount__c;
        this.mercury_engine_discount = boat.Sample_Retail_Sales__r[0].MercuryEngineRebate__c;
        this.battery_cost = boat.Sample_Retail_Sales__r[0].BatteryCost__c;
        this.prop_cost = boat.Sample_Retail_Sales__r[0].PropCost__c;
        this.motor_upgrade_name = boat.Sample_Retail_Sales__r[0].Motor_Upgrade__r.Name;
        this.setMotorCost(boat.Sample_Retail_Sales__r[0].Motor_Upgrade__c, motorUpgrades);
        if( fees != null ) this.processFees(fees);
        this.processExampleProducts(boat.Sample_Retail_Sales__r[0].Id, optionalProducts);
      }
    }

    private SampleRetailSale setMotorCost( Id motorId, List<UpgradeProduct> motorUpgrades)
    {
      if( motorUpgrades != null )
      {
        for( UpgradeProduct p : motorUpgrades )
        {
          if(p.Id == motorId)
          {
            this.motor_upgrade_partner_cost = p.PartnerPrice;
            this.motor_upgrade_retail_cost = p.RetailUpgradeCost;
          }
        }
      }
      if( this.motor_upgrade_partner_cost == null )
      {
        try
        {
          PricebookEntry pe = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Product2Id = :motorId AND Pricebook2Id = :partnerPricebookId];
          this.motor_upgrade_partner_cost = pe.UnitPrice;
        }
        catch(Exception e){}
      }
      return this;
    }

    private SampleRetailSale processFees(Map<String, List<FeeProduct>> fees)
    {
      for( String prov : fees.keySet() )
      {
        for( FeeProduct fp : fees.get(prov) )
        {
          if( fp.Family.contains('Freight') )
          {
            this.retail_factory_freight.put(prov, fp.RetailPrice);
            this.partner_factory_freight.put(prov, fp.PartnerPrice);
          }
          if( fp.Family.contains('Rigging and Preparation') )
          {
            this.retail_rigging_and_prep.put(prov, fp.RetailPrice);
            this.partner_rigging_and_prep.put(prov, fp.PartnerPrice);
          }
          if( fp.Family.contains('Documentation Fee') )
          {
            this.retail_admin_fee.put(prov, fp.RetailPrice);
            this.partner_admin_fee.put(prov, fp.PartnerPrice);
          }
        }
      }
      return this;
    }

    private SampleRetailSale processExampleProducts(Id sampleRetailSaleId,
                                                    Map<Id, Product2> optionalProducts )
    {
      Boat_Sample_Retail_Sale_Example_Product__c[] xProds = [SELECT Id, Product_Option__r.From_Product__c
                                                             FROM Boat_Sample_Retail_Sale_Example_Product__c
                                                             WHERE Sample_Retail_Sale__c = :sampleRetailSaleId];
      for( Boat_Sample_Retail_Sale_Example_Product__c xProd :xProds )
      {
         if( optionalProducts.containsKey(xProd.Product_Option__r.From_Product__c) )
         {
          this.example_products.add( new ExampleProduct( optionalProducts.get(  xProd.Product_Option__r.From_Product__c ) ) );
         }
      }
      return this;
    }
  }

  public class ExampleProduct {
    public String Name { get; set; }
    public Decimal RetailPrice { get; set; }
    public Decimal PartnerPrice { get; set; }
    public Decimal RetailSpecialPrice { get; set; }
    public String RetailSpecialPriceDescription { get; set; }
    public Decimal PartnerSpecialPrice { get; set; }
    public String PartnerSpecialPriceDescription { get; set; }

    public ExampleProduct(Product2 p) {
      this.Name = p.Name;
      this.processPriceBooks(p);
    }

    private ExampleProduct processPriceBooks(Product2 b)
    {
      try
      {
        //this.Prices = new Map<String, Decimal>();
        for( PricebookEntry pbe : b.PricebookEntries )
        {
         // this.Prices.put(pbe.Pricebook2.Name, pbe.UnitPrice);
          if( pricebookMap.containsKey(pbe.Pricebook2Id) )
          {
            if( pricebookMap.get(pbe.Pricebook2Id) == 'retail' )
            {
              this.RetailPrice = pbe.UnitPrice;
              this.RetailSpecialPrice = pbe.Special_Price__c;
              this.RetailSpecialPriceDescription = pbe.Special_Price_Description__c;
            }
            if( pricebookMap.get(pbe.Pricebook2Id) == 'partner' ||
                pricebookMap.get(pbe.Pricebook2Id) == 'factory' )
            {
              this.PartnerPrice = pbe.UnitPrice;
              this.PartnerSpecialPrice = pbe.Special_Price__c;
              this.PartnerSpecialPriceDescription = pbe.Special_Price_Description__c;
            }
          }
        }
      }
      catch(Exception e){}
      return this;
    }
  }

}