/**
 * Created by Tim on 2021-06-15.
 */

public with sharing class FSInventory_Service {

    @AuraEnabled public String Id { get; set; }
    @AuraEnabled public String Name { get; set; }
    @AuraEnabled public String Family { get; set; }
    @AuraEnabled public String Series { get; set; }
    @AuraEnabled public String Description { get; set; }
    @AuraEnabled public String DescriptionFR { get; set; }
    @AuraEnabled public String DefaultImage { get; set; }
    @AuraEnabled public Decimal RetailPrice { get; set; }
    @AuraEnabled public Static Decimal ParentRetailPrice { get; set; }
    @AuraEnabled public Decimal RetailSpecialPrice { get; set; }
    @AuraEnabled public String RetailSpecialPriceDescription { get; set; }
    static Map<Id, Product2> allProductOptions;
    @AuraEnabled public Map<String, List<String>> Features { get; set; }
    @AuraEnabled public Map<String, List<PartProduct>> OptionalProducts { get; set; }
    @AuraEnabled public List<UpgradeProduct> MotorUpgrades { get; set; }
    @AuraEnabled public List<UpgradeProduct> TrailerUpgrades { get; set; }
    @AuraEnabled public UpgradeProduct MaximumMotor { get; set; }
//    @AuraEnabled public PremiumPackage PremiumPackage { get; set; }
//    @AuraEnabled public Map<String, List<FeeProduct>> Fees { get; set; }
    @AuraEnabled public Map<String, String> DefaultImages { get; set; }
    @AuraEnabled public Map<String, String> BoatSpecs { get; set; }
    
    static Id retailPricebookId;
    static Map<Id, String> pricebookMap;
    static Map<String, Id> pricebookNameMap;

    static {
        retailPricebookId = gcConstants.idPricebookRetail;
        pricebookMap = new Map<Id, String>();
        pricebookMap.put(retailPricebookId, 'retail');
        pricebookNameMap = new Map<String, Id>();
        pricebookNameMap.put('retail', retailPricebookId);
    }

    @AuraEnabled public List<RiggedBoat> riggedInventory;
//    @AuraEnabled public List<SObject> Serials;

    public FSInventory_Service(List<RiggedBoat> ri){
       // use this to get used
        riggedInventory = ri;
    }

    public FSInventory_Service(Id pid){
        init( findProd(pid, true) );
    }

    public void init(Product2 prod){
        if( prod != null )
        {
            this.Id = prod.Id;
            this.Name = prod.Name;
            this.Family = prod.Family;
            this.Series = prod.Series__c;
            this.Description = prod.Description;
            this.DescriptionFR = prod.Description_FR__c;
            this.DefaultImage = prod.Default_Gallery_Image__c;
            this.processPriceBooks(prod);
//            this.processStandardProducts(prod);
            this.processOptions(prod);
//            this.processFeatures(prod);
//            this.processFees(prod);
//            this.processImages(prod);
//            this.processSpecs();
        }
        else
        {
            System.debug('****************************** No Product was found');
        }
    }
    

    private FSInventory_Service processPriceBooks(Product2 prod)
    {
        try
        {
            if( prod.PricebookEntries != null && !prod.PricebookEntries.isEmpty() )
            {
                //this.Prices = new Map<String, Decimal>();
                for( PricebookEntry pbe : prod.PricebookEntries )
                {                
                        
                    RetailPrice = pbe.UnitPrice;
                    ParentRetailPrice = pbe.UnitPrice;
                    RetailSpecialPrice = pbe.Special_Price__c;
                    RetailSpecialPriceDescription = pbe.Special_Price_Description__c;                      
                    
                }
            }
        }
        catch(Exception e){}
        return this;
    }

//    public FSInventory_Service processStandardProducts(Product2 b){
//
//        try
//        {
//            Set<String> standardIds = new Set<String>();
//            standardIds.add(b.Standard_Motor__r.Id);
//            standardIds.add(b.Standard_Trailer__r.Id);
//            standardIds.add(b.Standard_Trolling_Motor__r.Id);
//
//            List<Product2> standards = [SELECT Id, Name, RecordType.Name, Default_Gallery_Image__c, Available_For_Mercury_Partner_Discount__c,
//            (SELECT Id, UnitPrice, Special_Price__c, Special_Price_Description__c, Pricebook2Id FROM PricebookEntries WHERE isActive = true AND Pricebook2.isActive = true),
//            (SELECT Id, Standard__c, Maximum__c, From_Product__r.Id, From_Product__r.Name FROM To_Product_Options__r ORDER BY From_Product__r.Name)
//            FROM Product2
//            WHERE Id IN :standardIds
//            ];
//            for( Product2 p : standards ){
//                if(p.RecordType.Name == 'Motor'){
//                    setStandardMotor(p);
//                }
//                if(p.RecordType.Name == 'Trailer'){
//                    setStandardTrailer(p);
//                }
//                if(p.RecordType.Name == 'Trolling Motor'){
//                    setStandardTrollingMotor(p);
//                }
//            }
//        }
//        catch(Exception e){
//            System.debug( e.getMessage());
//        }
//
//        return this;
//    }
//
    private FSInventory_Service processOptions(Product2 parentProduct){
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
//                        this.PremiumPackage = processPremiumPackage( p );
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
                pbIdSearch = pricebookMap.keySet();

                System.debug('**** pbIdSearch ****');
                System.debug(pbIdSearch);

//                if( retailPartnerFilter == 'retail')
//                {

                    Set<Id> filteredUpgradeIds = new Set<Id>();
                    //find only upgrade Ids that have Costs within the selected Pricebook(s)
                    for (Product_Upgrade_Cost__c puc : [ SELECT Id, Product_Upgrade__c
                    FROM Product_Upgrade_Cost__c
                    WHERE Price_Book__c IN :pbIdSearch
                    AND Product_Upgrade__c IN :upgradeIds ])
                    {
                        filteredUpgradeIds.add(puc.Product_Upgrade__c);
                    }
                    upgradeIds = filteredUpgradeIds;
//                }


                Map<Id, Product_Upgrade__c> upgrades = new Map<Id, Product_Upgrade__c>(
                [SELECT Id, From_Product__r.RecordType.Name, To_Product__c, To_Product__r.Name, To_Product__r.RecordType.Name,
                ( SELECT Price_Book__c, Cost__c
                FROM Product_Upgrade_Costs__r
                WHERE Price_Book__c IN : pbIdSearch )
                FROM Product_Upgrade__c
                WHERE Id IN :upgradeIds
                ORDER BY To_Product__r.Name ]
                );

                if( maximumMotorId != null )
                {
                    this.MaximumMotor = new UpgradeProduct(allProductOptions.get(maximumMotorId), upgrades, false);
                }
                this.OptionalProducts = buildOptionalProducts( optionsMap.get('Part') );
                this.MotorUpgrades = buildMotorUpgrades( optionsMap.get('Motor'), upgrades );
                buildTrailerUpgrades( optionsMap.get('Trailer'), upgrades );
//                buildTrollingMotorUpgrades( optionsMap.get('Trolling Motor'), upgrades );
            }
        }
        catch(Exception e){}
        return this;
    }
//
//    private PremiumPackage processPremiumPackage( Product2 p )
//    {
//        p = [SELECT Id,
//                Name,
//                Family,
//                RecordType.Name,
//                Default_Gallery_Image__c,
//        (SELECT Id,
//                UnitPrice,
//                Special_Price__c,
//                Special_Price_Description__c,
//                Pricebook2Id,
//                Pricebook2.Name
//        FROM PricebookEntries
//        WHERE isActive = true
//        AND Pricebook2.isActive = true),
//        (SELECT Id,
//                Name,
//                Feature_Id__c,
//                Feature_Id__r.Name,
//                Feature_Id__r.description__c,
//                Feature_Id__r.description_fr__c,
//                Feature_Id__r.Category__c,
//                Feature_Id__r.Value__c
//        FROM Product_Feature_Maps__r )
//        FROM Product2
//        WHERE Id = :p.Id ];
//        return new PremiumPackage(p);
//    }
//
//    private FSInventory_Service processFeatures(Product2 p){
//        try
//        {
//            if( p.Product_Feature_Maps__r != null && !p.Product_Feature_Maps__r.isEmpty() ){
//                this.Features = new Map<String, List<String>>();
//                for( Product_Feature_Map__c pfm : p.Product_Feature_Maps__r ){
//                    if( !this.Features.keySet().contains( pfm.Feature_ID__r.Category__c ) ){
//                        this.Features.put( pfm.Feature_ID__r.Category__c, new List<String>() );
//                    }
//                    this.Features.get( pfm.Feature_ID__r.Category__c ).add(
//                            pfm.Feature_Id__r.description__c
//                    );
//                }
//            }
//        }
//        catch(Exception e){}
//        return this;
//    }
//
//    private FSInventory_Service processFees(Product2 p)
//    {
//        try
//        {
//            if( p.Parent_Product_Fee_Maps__r != null && !p.Parent_Product_Fee_Maps__r.isEmpty() )
//            {
//                this.Fees = new Map<String, List<FeeProduct>>();
//                Set<Id> ids = new Set<Id>();
//                for( Product_Fee_Map__c pfm : p.Parent_Product_Fee_Maps__r )
//                {
//                    ids.add(pfm.Fee_Product__c);
//                }
//                Map<Id, Product2> fees = new Map<Id, Product2>([
//                        SELECT Id, Name, Family
//                        FROM Product2
//                        WHERE Id IN :ids
//                ]);
//                List<Product_Fee_Amount__c> feeAmounts = [SELECT Id, Amount__c, Province__c, Fee_Product__c, Price_Book__c
//                FROM Product_Fee_Amount__c
//                WHERE Fee_Product__c IN :fees.keySet()
//                AND Price_Book__c IN :pricebookMap.keySet() ];
//
//                Map<Id, Map<String, List<Product_Fee_Amount__c>>> feeMap = new Map<Id, Map<String, List<Product_Fee_Amount__c>>>();
//                for(Product_Fee_Amount__c pfa : feeAmounts )
//                {
//                    if( !feeMap.containsKey( pfa.Fee_Product__c) )
//                    {
//                        feeMap.put( pfa.Fee_Product__c, new Map<String, List<Product_Fee_Amount__c>>() );
//                    }
//                    if( !feeMap.get( pfa.Fee_Product__c ).containsKey( pfa.Province__c) )
//                    {
//                        feeMap.get( pfa.Fee_Product__c ).put( pfa.Province__c, new List<Product_Fee_Amount__c>() );
//                    }
//                    feeMap.get( pfa.Fee_Product__c ).get( pfa.Province__c ).add( pfa );
//                }
//                for( Product2 f : fees.values() )
//                {
//                    for( String prov : feeMap.get(f.Id).keySet() )
//                    {
//                        if( !this.Fees.containsKey(prov) )
//                        {
//                            this.Fees.put(prov, new List<FeeProduct>() );
//                        }
//                        this.Fees.get(prov).add( new FeeProduct( f, feeMap.get(f.Id).get(prov) ) );
//                    }
//                }
//            }
//        }
//        catch(Exception e){}
//        return this;
//    }
//
//    private FSInventory_Service processImages(Product2 p){
//        try
//        {
//            if( p.Legend_Gallery_Image__r != null )
//            {
//                this.DefaultImages = new Map<String,String>();
//                this.DefaultImages.put('500x500', p.Legend_Gallery_Image__r.Active_S3_Object__r.URL_500x500__c);
//                this.DefaultImages.put('700w', p.Legend_Gallery_Image__r.Active_S3_Object__r.URL_700w__c);
//                this.DefaultImages.put('1280w', p.Legend_Gallery_Image__r.Active_S3_Object__r.URL_1280w__c);
//                this.DefaultImages.put('Original', p.Legend_Gallery_Image__r.Active_S3_Object__r.URL_Original__c);
//            }
//            List<Legend_Gallery_Image_Map__c> imageMaps = [SELECT Legend_Gallery_Image__r.Active_S3_Object__r.URL_500x500__c,
//                    Legend_Gallery_Image__r.Active_S3_Object__r.URL_Gallery__c,
//                    Legend_Gallery_Image__r.Active_S3_Object__r.URL_700w__c,
//                    Legend_Gallery_Image__r.Active_S3_Object__r.URL_Original__c,
//                    Legend_Gallery_Image__r.Active_S3_Object__r.URL_1280w__c,
//                    Legend_Gallery_Image__r.Name, Legend_Gallery_Image__r.ENG_Description__c,
//                    Legend_Gallery_Image__r.FR_Description__c
//            FROM Legend_Gallery_Image_Map__c
//            WHERE Parent_object_Id__c = :p.Id];
//
////            if( imageMaps.size() > 0 ){
////                this.MarketingImages = new List<MarketingImage>();
////                for(Legend_Gallery_Image_Map__c lgim : imageMaps){
////                    this.MarketingImages.add( new MarketingImage(lgim) );
////                }
////            }
//        }
//        catch(Exception e){}
//        return this;
//    }
//
//    private FSInventory_Service processSpecs()
//    {
//        try {
//            this.BoatSpecs = new Map<String, String>();
//            String fieldSetName = this.Family.replace(' ', '_') + '_Specifications';
//            Map<String, String> fieldSetMap = LGND_Utilities.fieldsFromFieldSet('Product2', fieldSetName );
//            String queryString = 'SELECT Id, ';
//            for( String fieldName : fieldSetMap.keySet() )
//            {
//                queryString += fieldName;
//                queryString += ',';
//            }
//            queryString = queryString.removeEnd(',');
//            queryString += ' FROM Product2 WHERE Id = \'';
//            queryString += this.Id;
//            queryString += '\'';
//
//            Product2 boat = Database.query( queryString );
//            for( String fieldName : fieldSetMap.keySet() )
//            {
//                this.BoatSpecs.put( fieldSetMap.get(fieldName), String.valueOf( boat.get( fieldName ) ) );
//            }
//        }
//        catch(Exception e){}
//        return this;
//    }
//
    @AuraEnabled public static Map<String, List<PartProduct>> buildOptionalProducts(List<Product2> parts) {
        if( parts.isEmpty() ){
            return null;
        }
        Map<String, List<PartProduct>> ppMap = new Map<String, List<PartProduct>>();
        for( Product2 p : parts )
        {
            if( p.Family != null )
            {
//
                    for( PricebookEntry pbe : p.PricebookEntries )
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
//
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
//
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
//            if( this.standardTrailer == null && excludeStandardTrailer == false )
                useTrailer = true;
//            else
//            {
//                for(Product_Upgrade__c pu : upgrades.values() )
//                {
//                    if( p.Id == pu.To_Product__c )
//                    {
//                        useTrailer = true;
//                        break;
//                    }
//                }
//            }
            if( useTrailer )
//                this.TrailerUpgrades.add( new UpgradeProduct( p, upgrades, excludeStandardTrailer ) );
                this.TrailerUpgrades.add( new UpgradeProduct( p, upgrades, false ) );
        }
        return this.TrailerUpgrades;
    }
//
//    private List<UpgradeProduct> buildTrollingMotorUpgrades(List<Product2> trollingMotors,
//            Map<Id, Product_Upgrade__c> upgrades)
//    {
//        if( trollingMotors.isEmpty() ){
//            return this.TrollingMotorUpgrades;
//        }
//        if(this.TrollingMotorUpgrades == null )
//            this.TrollingMotorUpgrades = new List<UpgradeProduct>();
//        for( Product2 p : trollingMotors){
//            Boolean useTMotor = false;
//            if( this.standardTrollingMotor == null && excludeStandardTrollingMotor == false )
//                useTmotor = true;
//            else
//            {
//                for(Product_Upgrade__c pu : upgrades.values() )
//                {
//                    if( p.Id == pu.To_Product__c )
//                    {
//                        useTmotor = true;
//                        break;
//                    }
//                }
//            }
//            if( useTmotor )
//                this.TrollingMotorUpgrades.add( new UpgradeProduct( p, upgrades, excludeStandardTrollingMotor ) );
//        }
//        return this.TrollingMotorUpgrades;
//    }
//
//    private void setStandardMotor(Product2 motor){
//        this.standardMotor = new UpgradeProduct(motor, false);
//        this.standardMotor.DisplayOnWeb = true;
//    }
//
//    private void setStandardTrailer(Product2 trailer){
//        if( excludeStandardTrailer )
//        {
//            if( this.TrailerUpgrades == null )
//                this.TrailerUpgrades = new List<UpgradeProduct>();
//            this.TrailerUpgrades.add( new UpgradeProduct(trailer, true) );
//        }
//        else
//                this.standardTrailer = new UpgradeProduct(trailer, false);
//
//        this.standardTrailer.DisplayOnWeb = true;
//    }
//
//    private void setStandardTrollingMotor(Product2 trollingMotor){
//        this.standardTrollingMotor = new UpgradeProduct(trollingMotor, false);
//        this.standardTrollingMotor.DisplayOnWeb = true;
//    }
//
    public Product2 findProd(String prodId, Boolean fullResponse) {
        try {
            String standardMotorFields;
            String standardTrailerFields;
            String standardTrollingMotorFields;
            String[] commonProductFields = new String[]{'Id',
                    'Name',
                    'Family',
                    'Series__c',
                    'Description',
                    'Description_FR__c',
                    'RecordType.Name',
                    'Exclude_Partner_Standard_Trailer__c',
                    'Exclude_Partner_Standard_Trolling_Motor__c',
                    'Legend_Gallery_Image__r.Active_S3_Object__r.URL_Original__c',
                    'Default_Gallery_Image__c',
                    'Legend_Gallery_Image__r.Active_S3_Object__r.URL_500x500__c',
                    'Legend_Gallery_Image__r.Active_S3_Object__r.URL_700w__c',
                    'Legend_Gallery_Image__r.Active_S3_Object__r.URL_1280w__c'};
            String selectedBoatFields = fieldsToString(commonProductFields, '');
            String query = 'SELECT ' +  selectedBoatFields;

            standardMotorFields = fieldsToString(commonProductFields, 'Standard_Motor__r.');
            standardTrailerFields = fieldsToString(commonProductFields, 'Standard_Trailer__r.');
            standardTrollingMotorFields = fieldsToString(commonProductFields, 'Standard_Trolling_Motor__r.');
            //if( retailPartnerFilter == 'partner')
            //  query += ', Exclude_Partner_Standard_Trailer__c ';

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
                        '(SELECT Id, Feature_ID__r.Description__c, Feature_ID__r.Description_Fr__c,Feature_ID__r.Category__c, Feature_ID__r.Value__c FROM Product_Feature_Maps__r),' +
                        '(SELECT Id, Standard__C, Maximum__c, displayOnWeb__c, isBiggestMotor__c, From_Product__r.Id, From_Product__r.Name, From_Product__r.RecordType.Name, From_Product__r.Family FROM To_Product_Options__r ORDER BY From_Product__r.Name),' +
                        '(SELECT Id, Fee_Product__c FROM Parent_Product_Fee_Maps__r)';

                query += ', (SELECT Id, BatteryCost__C, BoatShowDiscount__c, MercuryEngineRebate__c, Motor_Upgrade__c, Motor_Upgrade__r.Name, PropCost__c, xl_VolumeDiscount__c, l_VolumeDiscount__c, m_VolumeDiscount__c, s_VolumeDiscount__c, WOW_VolumeDiscount__c FROM Sample_Retail_Sales__r)';
            }
            query += ' FROM Product2 WHERE Id = \'' + prodId + '\' AND isActive = true LIMIT 1';

            return Database.query(query);
        } catch (exception e) {
            return null;
        }

    }
//
    /* -------------------- UpgradeProduct Class ------------------------ */
    public Class UpgradeProduct {

        @AuraEnabled public String Id { get; set; }
        @AuraEnabled public String Name { get; set; }
        @AuraEnabled public String Family { get; set; }
        @AuraEnabled public Boolean DisplayOnWeb { get; set; }
        @AuraEnabled public String DefaultImage { get; set; }
        @AuraEnabled public Decimal RetailPrice { get; set; }
        @AuraEnabled public Decimal PartnerPrice { get; set; }
        @AuraEnabled public Decimal FactoryPrice { get; set; }
        @AuraEnabled public Decimal RetailSpecialPrice { get; set; }
        @AuraEnabled public String RetailSpecialPriceDescription { get; set; }
        @AuraEnabled public Decimal PartnerSpecialPrice { get; set; }
        @AuraEnabled public String PartnerSpecialPriceDescription { get; set; }
        @AuraEnabled public Decimal RetailUpgradeCost { get; set; }
        @AuraEnabled public Decimal PartnerUpgradeCost { get; set; }
        @AuraEnabled public Decimal FactoryUpgradeCost { get; set; }
        @AuraEnabled public Decimal WeeklyUpgradeCost { get; set; }
        /* other motor related detail fields */
        @AuraEnabled public Map<String, List<PartProduct>> OptionalProducts { get; set; }
        @AuraEnabled public Boolean availableForMercDiscount { get; set; }

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
                        if( pricebookMap.get(puc.Price_Book__c) == 'partner' )
                        {
                            this.PartnerUpgradeCost = puc.Cost__c;
                        }
                        if( pricebookMap.get(puc.Price_Book__c) == 'factory' )
                        {
                            this.FactoryUpgradeCost = puc.Cost__c;
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
                        this.PartnerPrice = pbe.UnitPrice.setScale(2);
                        this.PartnerSpecialPrice = pbe.Special_Price__c;
                        this.PartnerSpecialPriceDescription = pbe.Special_Price_Description__c;
                        if( (this.Family == 'Trailer' || this.Family == 'Trolling Motor') && excludedStandard == true )
                            this.PartnerUpgradeCost = pbe.UnitPrice.setScale(2);
                    }
                    if( pricebookMap.get(pbe.Pricebook2Id) == 'factory' )
                    {
                        this.FactoryPrice = pbe.UnitPrice;
                        if(this.Family == 'Trailer' || this.Family == 'Trolling Motor')
                            this.FactoryUpgradeCost = pbe.UnitPrice;
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
                (SELECT Id, UnitPrice, Pricebook2.Name, Special_Price__c, Special_Price_Description__c FROM PricebookEntries WHERE isActive = true AND Pricebook2.isActive = true ORDER BY CreatedDate DESC),
                (SELECT Id, Standard__c, Maximum__c, DisplayOnWeb__c FROM From_Product_Options__r WHERE To_Product__c = :parentProduct.Id LIMIT 1),
                (SELECT Id, Standard__C, Maximum__c, From_Product__r.Id, From_Product__r.Name FROM To_Product_Options__r ORDER BY From_Product__r.Name)
                FROM Product2
                WHERE Id IN :pIds
                ];
                this.OptionalProducts = FSInventory_Service.buildOptionalProducts( prods );
            }
            return this;
        }

    }
//
//    /* -------------------- Premium Package ------------------------- */
//    public Class PremiumPackage {
//        @AuraEnabled public String Id { get; set; }
//        @AuraEnabled public String Name { get; set; }
//        @AuraEnabled public Decimal RetailPrice { get; set; }
//        @AuraEnabled public Decimal PartnerPrice { get; set; }
//        @AuraEnabled public String DefaultImage { get; set; }
//        @AuraEnabled public Map<String, List<Feature>> Contents { get; set; }
//
//        public PremiumPackage(Product2 p) {
//            this.Contents = new Map<String, List<Feature>>();
//            this.Name = p.Name;
//            this.Id = p.Id;
//            this.DefaultImage = p.Default_Gallery_Image__c;
//            this.processPriceBooks(p);
//            processContents( p.Product_Feature_Maps__r );
//        }
//
//        private PremiumPackage processPriceBooks(Product2 b)
//        {
//            try
//            {
//                //this.Prices = new Map<String, Decimal>();
//                for( PricebookEntry pbe : b.PricebookEntries )
//                {
//                    // this.Prices.put(pbe.Pricebook2.Name, pbe.UnitPrice);
//                    if( pricebookMap.containsKey(pbe.Pricebook2Id) )
//                    {
//                        if( pricebookMap.get(pbe.Pricebook2Id) == 'retail' )
//                        {
//                            this.RetailPrice = pbe.UnitPrice;
//                        }
//                        if( pricebookMap.get(pbe.Pricebook2Id) == 'partner' ||
//                                pricebookMap.get(pbe.Pricebook2Id) == 'factory')
//                        {
//                            this.PartnerPrice = pbe.UnitPrice;
//                        }
//                    }
//                }
//            }
//            catch(Exception e){}
//            return this;
//        }
//
//        private PremiumPackage processContents( Product_Feature_Map__c[] maps )
//        {
//            for( Product_Feature_Map__c pfm : maps )
//            {
//                if( !this.Contents.containsKey( pfm.Feature_Id__r.Category__c ) )
//                    this.Contents.put( pfm.Feature_Id__r.Category__c, new List<Feature>() );
//                this.Contents.get( pfm.Feature_Id__r.Category__c ).add( new Feature( pfm ) );
//            }
//            return this;
//        }
//
//    }
//
//    public Class Feature {
//        @AuraEnabled public String Id { get; set; }
//        @AuraEnabled public String Name { get; set; }
//        @AuraEnabled public String Description { get; set; }
//        @AuraEnabled public String Description_FR { get; set; }
//        @AuraEnabled public Decimal Value { get; set; }
//
//        public Feature( Product_Feature_Map__c pfm )
//        {
//            this.Id = pfm.Feature_Id__c;
//            this.Name = pfm.Feature_Id__r.Name;
//            this.Description = pfm.Feature_Id__r.description__c;
//            this.Description_FR = pfm.Feature_Id__r.description_fr__c;
//            this.Value = pfm.Feature_Id__r.Value__c;
//        }
//    }
//
//    /* -------------------- FeeProduct Class ------------------------- */
//    public Class FeeProduct {
//
//        @AuraEnabled public String Id { get; set; }
//        @AuraEnabled public String Name { get; set; }
//        @AuraEnabled public String Family { get; set; }
//        @AuraEnabled public Decimal RetailPrice { get; set; }
//        @AuraEnabled public Decimal PartnerPrice { get; set; }
//        @AuraEnabled public Decimal FactoryPrice { get; set; }
//        //public Map<String,Decimal> Prices { get; set; }
//
//        public FeeProduct(Product2 p) {
//            this.Id = p.Id;
//            this.Name = p.Name;
//            //processPriceBooks( p );
//        }
//
//        public FeeProduct(Product2 feeProduct, List<Product_Fee_Amount__c> feeAmounts) {
//            this.Id = feeProduct.Id;
//            this.Name = feeProduct.Name;
//            this.Family = feeProduct.Family;
//            for (Product_Fee_Amount__c pfa : feeAmounts) {
//                if (pricebookMap.get(pfa.Price_Book__c) == 'retail') {
//                    this.RetailPrice = pfa.Amount__c;
//                }
//                if (pricebookMap.get(pfa.Price_Book__c) == 'partner') {
//                    this.PartnerPrice = pfa.Amount__c;
//                }
//                if (pricebookMap.get(pfa.Price_Book__c) == 'factory') {
//                    this.FactoryPrice = pfa.Amount__c;
//                }
//            }
//        }
//    }
//
    /* -------------------- PartProduct Class ------------------------ */
    public Class PartProduct {

        @AuraEnabled public String Id { get; set; }
        @AuraEnabled public String Name { get; set; }
        @AuraEnabled public Boolean HasOptions { get; set; }
        @AuraEnabled public Decimal RetailPrice { get; set; }
        @AuraEnabled public Decimal PartnerPrice { get; set; }
        @AuraEnabled public Decimal FactoryPrice { get; set; }
        @AuraEnabled public Decimal FactorySpecialPrice { get; set; }
        @AuraEnabled public String FactorySpecialPriceDescription { get; set; }
        @AuraEnabled public Decimal RetailSpecialPrice { get; set; }
        @AuraEnabled public String RetailSpecialPriceDescription { get; set; }
        @AuraEnabled public Decimal PartnerSpecialPrice { get; set; }
        @AuraEnabled public String PartnerSpecialPriceDescription { get; set; }
        @AuraEnabled public String DefaultImage { get; set; }
        @AuraEnabled public Integer QuantityStandard { get; set; }
        @AuraEnabled public Integer MaximumQuantity { get; set; }
        @AuraEnabled public Boolean DisplayOnWeb { get; set; }


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


    public static List<RiggedBoat> getSerialNumbers(String location, Integer year, String modelId){
        List<RiggedBoat> boats = new List<RiggedBoat>();
        for( GMBLASERP__Serial_Number__c b : [SELECT Id,
                                 Name,
                                 GMBLASERP__Product__r.Name,
                                 Model_Year__c,
                                 GMBLASERP__Product__r.Make__c
                          FROM GMBLASERP__Serial_Number__c
                          WHERE Location__c = :location
                          AND GMBLASERP__Product__r.Id = :modelId
                          AND Product_Record_Type__c = 'Boat'
                          AND GMBLASERP__Product__r.Make__c = 'Legend'
                          AND Model_Year__c >= :year
                          AND Status__c NOT IN ('Used', 'At Supplier', 'Return to Supplier')
                          AND Available_Retail__c = true
                          ORDER BY Model_Year__c ASC])
        {
            String serialId = b.Id;

            BoatModel boatModel = new BoatModel( b );

            List<Equipment> equipment = new List<Equipment>();
            for( GMBLASERP__Serial_Number__c e : [SELECT Id,
                                    Name,
                                    GMBLASERP__Product__r.Name,
                                    Model_Year__c,
                                    GMBLASERP__Product__r.Make__c,
                                    Current_Unit_Cost__c,
                                    Product_Record_Type__c
                            FROM GMBLASERP__Serial_Number__c
                            WHERE Nest__c = :serialId
                            AND Product_Record_Type__c IN ('Motor', 'Trailer')])
            {
                System.debug('SOQL return: ' + e);
                Equipment eq = new Equipment( e );
                equipment.add( eq );
            }
            System.debug('getSerialNumbers Equipment: ' + equipment);

            List<Product2> options = new List<Product2>();
            String boatId = b.GMBLASERP__Product__r.Id;
            for( Product2 p : [SELECT Name, Make__c,
                    (SELECT  Pricebook2Id, PriceBook2.Name, UnitPrice, Special_Price__c, Special_Price_Description__c, CreatedDate FROM PricebookEntries WHERE Pricebook2.isStandard = false AND isActive = true AND Pricebook2.isActive = true ORDER BY CreatedDate DESC),
                    (SELECT Id, Feature_ID__r.Description__c, Feature_ID__r.Description_Fr__c,Feature_ID__r.Category__c, Feature_ID__r.Value__c FROM Product_Feature_Maps__r),
                    (SELECT Id, Standard__C, Maximum__c, displayOnWeb__c, isBiggestMotor__c, From_Product__r.Id, From_Product__r.Name, From_Product__r.RecordType.Name, From_Product__r.Family FROM To_Product_Options__r ORDER BY From_Product__r.Name),
                    (SELECT Id, Fee_Product__c FROM Parent_Product_Fee_Maps__r)
                    FROM Product2 WHERE Id = :boatId])
            {
                options.add(p);
            }

            RiggedBoat rb = new RiggedBoat(boatModel, equipment, options);

            boats.add(rb);
        }
        System.debug('getSerialNumbers Boats: ' + boats);
        FSInventory_Service selector = new FSInventory_Service(boats);

        return selector.riggedInventory;
    }

    public class RiggedBoat{
        @AuraEnabled public BoatModel Serial;
        @AuraEnabled public List<Equipment> Equipment;
        @AuraEnabled public List<Product2> Options;

        public RiggedBoat(BoatModel s, List<Equipment> e, List<Product2> o){
            Serial = s;
            Equipment = e;
            Options = o;
        }
    }

    public class BoatModel{
        @AuraEnabled public String serialId;
        @AuraEnabled public String serialNumber;
        @AuraEnabled public Decimal serialModelYear;
        @AuraEnabled public String productId;
        @AuraEnabled public String productMake;
        @AuraEnabled public String productName;

        public BoatModel(GMBLASERP__Serial_Number__c b){
            serialId = b.Id;
            serialNumber = b.Name;
            serialModelYear = b.Model_Year__c;
            productId = b.GMBLASERP__Product__r.Id;
            productMake = b.GMBLASERP__Product__r.Make__c;
            productName = b.GMBLASERP__Product__r.Name;
        }
    }

    public class Equipment{
        @AuraEnabled public Decimal unitCost;
        @AuraEnabled public String serialNumber;
        @AuraEnabled public String productManufacturer;
        @AuraEnabled public String productType;            
        @AuraEnabled public String productName;
        @AuraEnabled public String productId;

        public Equipment(GMBLASERP__Serial_Number__c e){
            System.debug('Equipment eq: ' + e);
            unitCost = e.Current_Unit_Cost__c;
            serialNumber = e.Name;
            productManufacturer = e.GMBLASERP__Product__r.Make__c;
            productType = e.Product_Record_Type__c;
            productName = e.GMBLASERP__Product__r.Name;
            productId = e.GMBLASERP__Product__r.Id;
        }
    }

    private String fieldsToString(String[] fields, String prefix){
        String qString = '';
        for( String f : fields ){
            qString += prefix + f + ', ';
        }
        return qString.removeEnd(', ');
    }

//    public class StandardOption{
//        @AuraEnabled public feeMap;
//        public StandardOption(Product2 p){
//            System.debug('Option op: ' + p);
//
//        }
//    }



}