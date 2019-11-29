public without sharing class Boat {

	public String Id { get; set; }
  public String Name { get; set; }
  public String Family { get; set; }
  public Map<String, String> DefaultImages { get; set; }
  //public Decimal CurrentPrice { get; set; }
  public Decimal RetailPrice { get; set; }
  public Decimal PartnerPrice { get; set; }
  public String DefaultImage { get; set; }
  /* other boat related detail fields */
  //public Map<String, Decimal> Prices { get; set; }
  public UpgradeProduct StandardMotor { get; set; }
  public SampleRetailSale SampleRetailSale { get; set; }
  public UpgradeProduct StandardTrailer { get; set; }
  public UpgradeProduct StandardTrollingMotor { get; set; }
  public Map<String, List<PartProduct>> OptionalProducts { get; set; }
  public List<UpgradeProduct> MotorUpgrades { get; set; }
  public List<UpgradeProduct> TrailerUpgrades { get; set; }
  public List<UpgradeProduct> TrollingMotorUpgrades { get; set; }
  public List<MarketingImage> MarketingImages { get; set; }
  public Map<string, List<String>> Features { get; set; }
  public Map<String, List<FeeProduct>> Fees { get; set; }
  static Map<Id, Product2> allProductOptions;
  static String retailPartnerFilter;

  static Id retailPricebookId;
  static Id partnerPricebookId;
  static Map<Id, String> pricebookMap;
  static Map<String, Id> pricebookNameMap;
  static {
    retailPricebookId = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
    partnerPricebookId = Legend_Settings__c.getOrgDefaults().Default_Partner_Pricebook__c;
    pricebookMap = new Map<Id, String>();
    pricebookMap.put(retailPricebookId, 'retail');
    pricebookMap.put(partnerPricebookId, 'partner');
    pricebookNameMap = new Map<String, Id>();
    pricebookNameMap.put('retail', retailPricebookId);
    pricebookNameMap.put('partner', partnerPricebookId);
  }

  public Boat(Id pId){
    System.debug('*************** i received an Id of ' + pId);
    init( findBoat(pid, true ) );
  }

  public Boat(Id pId, String retail_or_partner)
  {
    if( pricebookNameMap.containsKey( retail_or_partner ) )
    {
      retailPartnerFilter = retail_or_partner;
    }
    init( findBoat( pid, true ) );
  }

  public Boat(Id pId, Boolean fullResponse){
    init(findBoat(pId, fullResponse) );
  }

  public Boat(Product2 boat)
  {
    init(boat);
  }

  public void init(Product2 boat){
    if( boat != null )
    {
      this.Id = boat.Id;
      this.Name = boat.Name;
      this.Family = boat.Family;
      this.DefaultImage = boat.Default_Gallery_Image__c;
      //this.Price = boat.PricebookEntries[0].UnitPrice;
      this.processPriceBooks(boat);
      this.processStandardProducts(boat);
      this.processOptions(boat);
      this.processFeatures(boat);
      this.processFees(boat);
      this.processImages(boat);
      this.processSampleRetailSale(boat);
    }
    else
    {
      System.debug('****************************** No Boat was found');
    }
  }

  public static PricebookEntry[] findByStyle(String style)
  {
    Id pbId = Legend_Settings__c.getOrgDefaults().Default_Retail_Pricebook__c;
    Id boatRT = LGND_Utilities.recordTypeIdFromName('Product2', 'Boat');
    try
    {
      return [SELECT Id,
                     UnitPrice,
                     Product2.Id,
                     Product2.Name,
                     Product2.Description__c,
                     Product2.Legend_Gallery_Image__r.Active_S3_Object__r.URL_Gallery__c
              FROM PricebookEntry
              WHERE Product2.Family = : style
              AND Product2.RecordTypeId = : boatRT
              AND Product2.isActive = true
              AND Pricebook2Id = : pbId ];
    }
    catch(Exception e)
    {
      return new List<PricebookEntry>();
    }
  }

  private Product2 findBoat(String boatId, Boolean fullResponse) {
    try {
      String[] commonProductFields = new String[]{'Id', 'Name', 'Family', 'RecordType.Name', 'Legend_Gallery_Image__r.Active_S3_Object__r.URL_Original__c', 'Default_Gallery_Image__c', 'Legend_Gallery_Image__r.Active_S3_Object__r.URL_500x500__c', 'Legend_Gallery_Image__r.Active_S3_Object__r.URL_700w__c', 'Legend_Gallery_Image__r.Active_S3_Object__r.URL_1280w__c'};
      String selectedBoatFields = fieldsToString(commonProductFields, '');
      String standardMotorFields = fieldsToString(commonProductFields, 'Standard_Motor__r.');
      String standardTrailerFields = fieldsToString(commonProductFields, 'Standard_Trailer__r.');
      String standardTrollingMotorFields = fieldsToString(commonProductFields, 'Standard_Trolling_Motor__r.');
      String query = 'SELECT ' +  selectedBoatFields;
       //',(SELECT Marketing_Image__r.Active_S3_Object__r.URL_500x500__c, Marketing_Image__r.Active_S3_Object__r.URL_Gallery__c, Marketing_Image__r.Active_S3_Object__r.URL_700w__c, Marketing_Image__r.Active_S3_Object__r.URL_Original__c,  Marketing_Image__r.Active_S3_Object__r.URL_1280w__c, Marketing_Image__r.Name, Marketing_Image__r.ENG_Description__c, Marketing_Image__r.FR_Description__c FROM Product_images__r)';
      if( fullResponse )
      {
        query += ', ' + standardMotorFields + ', ' + standardTrailerFields + ', ' + standardTrollingMotorFields + ', ' +
          '(SELECT  Pricebook2Id, PriceBook2.Name, UnitPrice, CreatedDate FROM PricebookEntries WHERE Pricebook2.isStandard = false AND isActive = true AND Pricebook2.isActive = true ORDER BY CreatedDate DESC),' +
          '(SELECT Id, Feature_ID__r.Description__c, Feature_ID__r.Category__c FROM Product_Feature_Maps__r),' +
          '(SELECT Id, Standard__C, Maximum__c, From_Product__r.Id, From_Product__r.Name, From_Product__r.RecordType.Name, From_Product__r.Family FROM To_Product_Options__r ORDER BY From_Product__r.Name),' +
          '(SELECT Id, Fee_Product__c FROM Parent_Product_Fee_Maps__r),' +
          '(SELECT Id, BatteryCost__C, BoatShowDiscount__c, MercuryEngineRebate__c, Motor_Upgrade__c, Motor_Upgrade__r.Name, PropCost__c, xl_VolumeDiscount__c, l_VolumeDiscount__c, m_VolumeDiscount__c, s_VolumeDiscount__c, WOW_VolumeDiscount__c FROM Sample_Retail_Sales__r)';
      }
      query += ' FROM Product2 WHERE Id = \'' + boatId + '\' AND isActive = true LIMIT 1';
      System.debug('^^^^^^^^^^^^ ' + query);
      return Database.query(query);
    } catch (exception e) {
      System.debug('&&&&&&&&&&&&&&&&&&&&&&&&&&&&& ' + e.getMessage() );
        return null;
    }

  }

  private void processSampleRetailSale(Product2 b)
  {
    this.SampleRetailSale = new SampleRetailSale(b, this.Fees, this.MotorUpgrades, allProductOptions);
  }

  private String fieldsToString(String[] fields, String prefix){
    String qString = '';
    for( String f : fields ){
      qString += prefix + f + ', ';
    }
    return qString.removeEnd(', ');
  }

  private Boat processPriceBooks(Product2 b)
  {
    try
    {
      if( b.PricebookEntries != null && !b.PricebookEntries.isEmpty() )
      {
        //this.Prices = new Map<String, Decimal>();
        for( PricebookEntry pbe : b.PricebookEntries )
        {
         // this.Prices.put(pbe.Pricebook2.Name, pbe.UnitPrice);
          if( pricebookMap.containsKey(pbe.Pricebook2Id) )
          {
            if( pricebookMap.get(pbe.Pricebook2Id) == 'retail' )
            {
              RetailPrice = pbe.UnitPrice;
            }
            if( pricebookMap.get(pbe.Pricebook2Id) == 'partner' )
            {
              PartnerPrice = pbe.UnitPrice;
            }
          }
        }
      }
    }
    catch(Exception e){}
    return this;
  }

  public Boat processStandardProducts(Product2 b){
    try
    {
      Set<String> standardIds = new Set<String>();
      standardIds.add(b.Standard_Motor__r.Id);
      standardIds.add(b.Standard_Trailer__r.Id);
      standardIds.add(b.Standard_Trolling_Motor__r.Id);

      List<Product2> standards = [SELECT Id, Name, RecordType.Name, Default_Gallery_Image__c,
                                (SELECT Id, UnitPrice, Pricebook2Id FROM PricebookEntries WHERE isActive = true AND Pricebook2.isActive = true),
                                (SELECT Id, Standard__c, Maximum__c, From_Product__r.Id, From_Product__r.Name FROM To_Product_Options__r ORDER BY From_Product__r.Name)
                               FROM Product2
                               WHERE Id IN :standardIds
                               ];
      for( Product2 p : standards ){
        if(p.RecordType.Name == 'Motor'){
          setStandardMotor(p);
        }
        if(p.RecordType.Name == 'Trailer'){
          setStandardTrailer(p);
        }
        if(p.RecordType.Name == 'Trolling Motor'){
          setStandardTrollingMotor(p);
        }
      }
    }
    catch(Exception e){}
    return this;
  }

  private Boat processOptions(Product2 parentProduct){
    try
    {
      if(parentProduct.To_Product_Options__r != null || !parentProduct.To_Product_Options__r.isEmpty()){

        Set<String> standardIds = new Set<String>();
        if(this.StandardMotor != null){
          standardIds.add( this.StandardMotor.Id );
        }
        if(this.StandardTrailer != null){
          standardIds.add( this.StandardTrailer.Id );
        }
        if(this.StandardTrollingMotor != null){
          standardIds.add( this.StandardTrollingMotor.Id );
        }

        Map<String,List<Product2>> optionsMap = new Map<String, List<Product2>>();
        for(String t : new Set<String>{'Part', 'Motor', 'Trailer', 'Trolling Motor'}) {
          optionsMap.put(t, new List<Product2>() );
        }
        List<String> pIds = new List<String>();
        for( Product_Option__c po : parentProduct.To_Product_Options__r){
          pIds.add(po.From_Product__c);
        }
        allProductOptions = new Map<Id, Product2>([SELECT Id, Name, Family, RecordType.Name, Default_Gallery_Image__c,
                                (SELECT Id, UnitPrice, Pricebook2Id, Pricebook2.Name FROM PricebookEntries WHERE isActive = true AND Pricebook2.isActive = true),
                                (SELECT Id, Standard__c, Maximum__c FROM From_Product_Options__r WHERE To_Product__c = :parentProduct.Id LIMIT 1),
                                (SELECT Id, Standard__C, Maximum__c, From_Product__r.Id, From_Product__r.Name FROM To_Product_Options__r ORDER BY From_Product__r.Name),
                                (SELECT Id, Price__c, From_Product__r.RecordType.Name FROM To_Product_Upgrades__r WHERE From_Product__c IN :standardIds ORDER BY Price__c ASC)
                               FROM Product2
                               WHERE Id IN :pIds
                               ]);
        List<Product2> prods = allProductOptions.values();
        Set<Id> upgradeIds = new Set<Id>();
        for( Product2 p : prods ){
          if( optionsMap.containsKey(p.RecordType.Name) )
          {
            optionsMap.get(p.RecordType.Name).add(p);
          }
          for( Product_Upgrade__c pu : p.To_Product_Upgrades__r)
          {
            upgradeIds.add(pu.Id);
          }
        }
        Map<Id, Product_Upgrade__c> upgrades = new Map<Id, Product_Upgrade__c>(
          [SELECT Id, From_Product__r.RecordType.Name,
            ( SELECT Price_Book__c, Cost__c
              FROM Product_Upgrade_Costs__r
              WHERE Price_Book__c IN :pricebookMap.keySet() )
           FROM Product_Upgrade__c
           WHERE Id IN :upgradeIds ]
        );

        this.OptionalProducts = buildOptionalProducts( optionsMap.get('Part') );
        this.MotorUpgrades = buildMotorUpgrades( optionsMap.get('Motor'), upgrades );
        this.TrailerUpgrades = buildTrailerUpgrades( optionsMap.get('Trailer'), upgrades );
        this.TrollingMotorUpgrades = buildTrollingMotorUpgrades( optionsMap.get('Trolling Motor'), upgrades );
      }
    }
    catch(Exception e){}
    return this;
  }

  private Boat processFeatures(Product2 p){
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

  private Boat processFees(Product2 p)
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
        List<Product2> fees = [SELECT Id, Name, Family,
                              (SELECT Id, UnitPrice, Pricebook2.Name
                                FROM PricebookEntries
                                WHERE Pricebook2Id IN :pricebookMap.keySet() )
                              FROM Product2
                              WHERE Id IN :ids];
        for( Product2 f : fees )
        {
          if( !this.Fees.containsKey(f.Family) )
          {
            this.fees.put(f.Family, new List<FeeProduct>() );
          }
          this.Fees.get(f.Family).add( new FeeProduct(f) );
        }
      }
    }
    catch(Exception e){}
    return this;
  }

  private Boat processImages(Product2 p){
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
      if( imageMAps.size() > 0 ){
        this.MarketingImages = new List<MarketingImage>();
        for(Legend_Gallery_Image_Map__c lgim : imageMaps ){
          this.MarketingImages.add( new MarketingImage(lgim) );
        }
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

    return ppMap;
  }

  private List<UpgradeProduct> buildMotorUpgrades(List<Product2> motors,
                                                Map<Id, Product_Upgrade__c> upgrades){
    if( motors.isEmpty() ){
      return null;
    }
    List<UpgradeProduct> mList = new List<UpgradeProduct>();
    for( Product2 p : motors){
      mList.add(new UpgradeProduct(p, upgrades) );
    }
    return mList;
  }

  private List<UpgradeProduct> buildTrailerUpgrades(List<Product2> trailers,
                                                    Map<Id, Product_Upgrade__c> upgrades)
  {
    if( trailers.isEmpty() ){
      return null;
    }
    List<UpgradeProduct> tList = new List<UpgradeProduct>();
    for( Product2 p : trailers){
      tList.add( new UpgradeProduct( p, upgrades ) );
    }
    return tList;
  }

  private List<UpgradeProduct> buildTrollingMotorUpgrades(List<Product2> trollinMotors,
                                                                Map<Id, Product_Upgrade__c> upgrades)
  {
    if( trollinMotors.isEmpty() ){
      return null;
    }
    List<UpgradeProduct> trList = new List<UpgradeProduct>();
    for( Product2 p : trollinMotors){
      trList.add(new UpgradeProduct(p, upgrades));
    }
    return trList;
  }

  private void setStandardMotor(Product2 motor){
    this.standardMotor = new UpgradeProduct(motor);
  }

   private void setStandardTrailer(Product2 trailer){
    this.standardTrailer = new UpgradeProduct(trailer);
  }

  private void setStandardTrollingMotor(Product2 trollingMotor){
    this.standardTrollingMotor = new UpgradeProduct(trollingMotor);
  }


  /* -------------------- UpgradeProduct Class ------------------------ */
  public Class UpgradeProduct {

    public String Id { get; set; }
    public String Name { get; set; }
    public String Family { get; set; }
    public String DefaultImage { get; set; }
    public Decimal RetailPrice { get; set; }
    public Decimal PartnerPrice { get; set; }
    public Decimal RetailUpgradeCost { get; set; }
    public Decimal PartnerUpgradeCost { get; set; }
    /* other motor related detail fields */
    public Map<String, List<PartProduct>> OptionalProducts { get; set; }

    public UpgradeProduct(Product2 m) {
      this.Name = m.Name;
      this.Family = m.RecordType.Name;
      this.Id = m.Id;
      this.DefaultImage = m.Default_Gallery_Image__c;
      this.processOptions(m);
      this.processPrices(m);
    }

    public UpgradeProduct(Product2 m, Map<Id, Product_Upgrade__c> upgrades) {
      this.Name = m.Name;
      this.Family = m.RecordType.Name;
      this.Id = m.Id;
      this.DefaultImage = m.Default_Gallery_Image__c;
      //this.RetailPrice = m.PricebookEntries[0].UnitPrice;
      if( m.To_Product_Upgrades__r != null &&
          !m.To_Product_Upgrades__r.isEmpty() &&
          upgrades != null ){
        //this.UpgradeCost = m.To_Product_Upgrades__r[0].Price__c;
        this.processUpgrades(m, upgrades);
      }
      this.processOptions(m);
      this.processPrices(m);
    }

    private UpgradeProduct processUpgrades(Product2 m,
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
             if( pricebookMap.get(puc.Price_Book__c) == 'partner' )
            {
              this.PartnerUpgradeCost = puc.Cost__c;
            }
          }
        }
      }
      return this;
    }

    private UpgradeProduct processPrices(Product2 m)
    {
      for(PricebookEntry pbe : m.PricebookEntries)
      {
        if( pricebookMap.containsKey(pbe.Pricebook2Id) )
        {
          if( pricebookMap.get(pbe.Pricebook2Id) == 'retail' )
          {
            this.RetailPrice = pbe.UnitPrice;
          }
          if( pricebookMap.get(pbe.Pricebook2Id) == 'partner' )
          {
            this.PartnerPrice = pbe.UnitPrice;
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
                                (SELECT Id, Standard__c, Maximum__c FROM From_Product_Options__r WHERE To_Product__c = :parentProduct.Id LIMIT 1),
                                (SELECT Id, Standard__C, Maximum__c, From_Product__r.Id, From_Product__r.Name FROM To_Product_Options__r ORDER BY From_Product__r.Name)
                               FROM Product2
                               WHERE Id IN :pIds
                               ];
        this.OptionalProducts = Boat.buildOptionalProducts( prods );
      }
      return this;
    }

  }

  /* -------------------- FeeProduct Class ------------------------- */
  public Class FeeProduct {

    public String Id { get; set; }
    public String Name { get; set; }
    public Decimal RetailPrice { get; set; }
    public Decimal PartnerPrice { get; set; }
   // public Map<String,Decimal> Prices { get; set; }

    public FeeProduct(Product2 p)
    {
      this.Id = p.Id;
      this.Name = p.Name;
      processPriceBooks( p );
    }

    private FeeProduct processPriceBooks(Product2 b)
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
            if( pricebookMap.get(pbe.Pricebook2Id) == 'partner' )
            {
              this.PartnerPrice = pbe.UnitPrice;
            }
          }
        }
      }
      catch(Exception e){}
      return this;
    }
  }

  /* -------------------- PartProduct Class ------------------------ */
  public Class PartProduct {

    public String Id { get; set; }
    public String Name { get; set; }
    public Boolean HasOptions { get; set; }
    public Decimal CurrentPrice { get; set; }
    public Decimal RetailPrice { get; set; }
    public Decimal PartnerPrice { get; set; }
    public String DefaultImage { get; set; }
    //public Map<String, Decimal> Prices { get; set ;}
    public Integer QuantityStandard { get; set; }
    public Integer MaximumQuantity { get; set; }
    /* other motor related detail fields */
    //spublic Map<String,List<PartProduct>> OptionalProducts { get; set; }


    public PartProduct(Product2 p) {
      this.HasOptions = false;
      this.Name = p.Name;
      this.Id = p.Id;
      this.DefaultImage = p.Default_Gallery_Image__c;
      this.processPriceBooks(p);
      if( p.From_Product_Options__r != null && !p.From_Product_Options__r.isEmpty() ){
        this.QuantityStandard = Integer.valueOf( p.From_Product_Options__r[0].Standard__c );
        this.MaximumQuantity = Integer.valueOf( p.From_Product_Options__r[0].Maximum__c );
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
            }
            if( pricebookMap.get(pbe.Pricebook2Id) == 'partner' )
            {
              this.PartnerPrice = pbe.UnitPrice;
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
    public Decimal retail_factory_freight { get; set; }
    public Decimal partner_factory_freight { get; set; }
    public Decimal retail_admin_fee { get; set; }
    public Decimal partner_admin_fee { get; set; }
    public Decimal retail_rigging_and_prep { get; set; }
    public Decimal partner_rigging_and_prep { get; set; }
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
      if( fees.containsKey('Freight') )
      {
        this.retail_factory_freight = fees.get('Freight')[0].RetailPrice;
        this.partner_factory_freight = fees.get('Freight')[0].PartnerPrice;
      }
      if( fees.containsKey('Rigging and Preparation') )
      {
        this.retail_rigging_and_prep = fees.get('Rigging and Preparation')[0].RetailPrice;
        this.partner_rigging_and_prep = fees.get('Rigging and Preparation')[0].PartnerPrice;
      }
      if( fees.containsKey('Documentation Fee') )
      {
        this.retail_admin_fee = fees.get('Documentation Fee')[0].RetailPrice;
        this.partner_admin_fee = fees.get('Documentation Fee')[0].PartnerPrice;
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
          System.debug('*************************** ' + optionalProducts.get(  xProd.Product_Option__r.From_Product__c ));
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
            }
            if( pricebookMap.get(pbe.Pricebook2Id) == 'partner' )
            {
              this.PartnerPrice = pbe.UnitPrice;
            }
          }
        }
      }
      catch(Exception e){}
      return this;
    }
    }




}