/**
 * Created by Tim on 2021-07-12.
 */

public with sharing class FSBoatDetails_Service {

    /**
        ┌─┐┬ ┬┬  ┬    ┌┐ ┌─┐┌─┐┌┬┐  ┌┬┐┌─┐┌┬┐┌─┐┬┬  ┌─┐
        ├┤ │ ││  │    ├┴┐│ │├─┤ │    ││├┤  │ ├─┤││  └─┐
        └  └─┘┴─┘┴─┘  └─┘└─┘┴ ┴ ┴   ─┴┘└─┘ ┴ ┴ ┴┴┴─┘└─┘
        Derived from LGND_APIv2_Product
     */

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
//    @AuraEnabled public Map<String, List<String>> Features { get; set; }
    @AuraEnabled public Map<String, List<PartProduct>> OptionalProducts { get; set; }
    @AuraEnabled public List<UpgradeProduct> MotorUpgrades { get; set; }
    @AuraEnabled public List<UpgradeProduct> TrailerUpgrades { get; set; }
    @AuraEnabled public UpgradeProduct MaximumMotor { get; set; }
//    @AuraEnabled public PremiumPackage PremiumPackage { get; set; }
//    @AuraEnabled public Map<String, List<FeeProduct>> Fees { get; set; }
//    @AuraEnabled public Map<String, String> DefaultImages { get; set; }
//    @AuraEnabled public Map<String, String> BoatSpecs { get; set; }
    @AuraEnabled public String PricebookName { get; set; }

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

    public FSBoatDetails_Service(Id pid){
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


    private FSBoatDetails_Service processPriceBooks(Product2 prod)
    {
        try
        {
            if( prod.PricebookEntries != null && !prod.PricebookEntries.isEmpty() )
            {
                //this.Prices = new Map<String, Decimal>();
                for( PricebookEntry pbe : prod.PricebookEntries )
                {
                    if( pricebookMap.containsKey(pbe.Pricebook2Id) ) {
                        if (pricebookMap.get(pbe.Pricebook2Id) == 'retail' ||
                            pricebookMap.get(pbe.Pricebook2Id) == 'dev-retail')
                        {
                            RetailPrice = pbe.UnitPrice;
                            ParentRetailPrice = pbe.UnitPrice;
                            RetailSpecialPrice = pbe.Special_Price__c;
                            RetailSpecialPriceDescription = pbe.Special_Price_Description__c;
                        }
                    }
                }
            }
        }
        catch(Exception e){}
        return this;
    }

    private FSBoatDetails_Service processOptions(Product2 parentProduct){
        try
        {
            if( parentProduct.To_Product_Options__r != null || !parentProduct.To_Product_Options__r.isEmpty() )
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
//        @AuraEnabled public Decimal PartnerPrice { get; set; }
//        @AuraEnabled public Decimal FactoryPrice { get; set; }
        @AuraEnabled public Decimal RetailSpecialPrice { get; set; }
        @AuraEnabled public String RetailSpecialPriceDescription { get; set; }
//        @AuraEnabled public Decimal PartnerSpecialPrice { get; set; }
//        @AuraEnabled public String PartnerSpecialPriceDescription { get; set; }
        @AuraEnabled public Decimal RetailUpgradeCost { get; set; }
//        @AuraEnabled public Decimal PartnerUpgradeCost { get; set; }
//        @AuraEnabled public Decimal FactoryUpgradeCost { get; set; }
        @AuraEnabled public Decimal WeeklyUpgradeCost { get; set; }
        /* other motor related detail fields */
        @AuraEnabled public Map<String, List<PartProduct>> OptionalProducts { get; set; }
        @AuraEnabled public Boolean availableForMercDiscount { get; set; }

//        public UpgradeProduct(Product2 m, Boolean excludedStandard)
//        {
//            this.Name = m.Name;
//            this.Family = m.RecordType.Name;
//            this.Id = m.Id;
//            this.DefaultImage = m.Default_Gallery_Image__c;
//            this.processOptions(m);
//            this.processPrices(m, excludedStandard);
//            this.WeeklyUpgradeCost = calcWeeklyCost();
//            this.availableForMercDiscount = m.Available_For_Mercury_Partner_Discount__c;
//        }

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
                this.OptionalProducts = FSBoatDetails_Service.buildOptionalProducts( prods );
            }
            return this;
        }

    }

    /* -------------------- PartProduct Class ------------------------ */
    public Class PartProduct {

        @AuraEnabled public String Id { get; set; }
        @AuraEnabled public String Name { get; set; }
        @AuraEnabled public Boolean HasOptions { get; set; }
        @AuraEnabled public Decimal RetailPrice { get; set; }
//        @AuraEnabled public Decimal PartnerPrice { get; set; }
//        @AuraEnabled public Decimal FactoryPrice { get; set; }
//        @AuraEnabled public Decimal FactorySpecialPrice { get; set; }
//        @AuraEnabled public String FactorySpecialPriceDescription { get; set; }
        @AuraEnabled public Decimal RetailSpecialPrice { get; set; }
        @AuraEnabled public String RetailSpecialPriceDescription { get; set; }
//        @AuraEnabled public Decimal PartnerSpecialPrice { get; set; }
//        @AuraEnabled public String PartnerSpecialPriceDescription { get; set; }
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

    private String fieldsToString(String[] fields, String prefix){
        String qString = '';
        for( String f : fields ){
            qString += prefix + f + ', ';
        }
        return qString.removeEnd(', ');
    }

}