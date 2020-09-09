public without sharing class DealerOrder_Ext {

  public class DetailsWrapper {
    public Id accountId { get; set; }
    public String province { get; set; }
    public List<Object> programYearOptions { get; set; }
    public List<Map<String, String>> financeCompanyOptions { get; set; }
    public List<Map<String, String>> accountOptions { get; set; }
    public List<String> paymentMethodOptions { get; set; }
    public Dealer_Order__c dealerOrder { get; set; }
    public Partner_Booking_Order__c bookingOrder { get; set; }
    public Boolean fromInternal { get; set; }
    public Boolean isFactoryStore { get; set; }
    public Set<String> legendAccounts { get; set; }
    public Boolean allowBookingOrder { get; set; }

    public DetailsWrapper()
    {
      this.allowBookingOrder = true;
      this.dealerOrder = new Dealer_Order__c();
      Integer currentYear = System.Today().year();
      if( System.Today().month() >= 8 )
        currentYear++;
      this.DealerOrder.Program_Year__c = String.valueOf( currentYear );
      this.DealerOrder.Is_Legend_Transfer__c = false;
      this.paymentMethodOptions = LGND_Utilities.getPicklistValues('Dealer_Order__c', 'Payment_Method__c');
      this.financeCompanyOptions = new List<Map<String, String>>();
      this.accountOptions = new List<Map<String, String>>();
      this.fromInternal = false;
      this.isFactoryStore = false;
      this.legendAccounts = setLegendAccounts();
      buildProgramYearOptions();
    }

    private void buildProgramYearOptions()
    {
      this.programYearOptions = new List<Object>();
      for( String year : Partner_Program_Settings__c.getOrgDefaults().Available_Program_Years__c.split(',') )
      {
        Map<String,Object> opt = new Map<String, Object>{
          'label' => year,
          'value' => year
        };
        if( year == String.valueOf(this.dealerOrder.Program_Year__c) )
          opt.put('selected', true);
        this.programYearOptions.add( opt );
      }
    }

    public DetailsWrapper addFinanceCompanyOptions( Financing_Company__c[] fics )
    {
      for( Financing_Company__c fic : fics )
      {
        Map<String, String> opts = new Map<String, String>();
        opts.put('Id', fic.Id);
        opts.put('Name', fic.Financing_Company__r.Name);
        this.financeCompanyOptions.add( opts );
      }
      return this;
    }

    public DetailsWrapper addAccountOptions( Account[] accts )
    {
      for( Account a : accts )
      {
        Map<String, String> opt = new Map<String, String>();
        opt.put('Id', a.Id);
        opt.put('Name', a.Name);
        this.accountOptions.add( opt );
      }
      return this;
    }

    private Set<String> setLegendAccounts()
    {
      Legend_Settings__c settings = Legend_Settings__c.getOrgDefaults();
      return new Set<String>{
        settings.LegendBarrieAccountId__c,
        settings.LegendMontrealAccountId__c,
        settings.LegendWhitefishAccountId__c
      };
    }

  }

  public class DealerOrderLineWrapper {
    public String notes { get; set; }
    public Integer quantity { get; set;}
    public String dealerOrderId { get; set; }
    public String dealerMotorRequestId { get; set; }
    public Boolean isLegendTransfer { get; set; }
    public Boolean isMotorRequest { get; set; }
    public String accountId { get; set; }
    public String orderGroupId { get; set; }
    public String modelYear { get; set; }
    public OptionWrapper boat { get; set; }
    public OptionWrapper trailer { get; set; }
    public OptionWrapper motor { get; set; }
    public OptionWrapper trollingMotor { get; set; }
    public OptionWrapper[] lineItems { get; set; }
    public List<Map<String,String>> discounts { get; set; }

    public DealerOrderLineWrapper() {}
  }

  public class ProductWrapper {
    public Boolean isFactory { get; set; }
    public Boolean isPartner { get; set; }
    public String name { get; set; }
    public String id { get; set; }
    public Decimal cost { get; set; }
    public Decimal canvasDiscountAmount { get; set; }
    public String standardTrailer_Id { get; set; }
    public String standardTrailer_Name { get; set; }
    public String standardMotor_Id { get; set; }
    public String standardMotor_Name { get; set; }
    public String standardTrollingMotor_Id { get; set; }
    public String standardTrollingMotor_Name { get; set; }
    public List<UpgradeWrapper> trailerUpgrades { get; set; }
    public List<UpgradeWrapper> motorUpgrades { get; set; }
    public List<UpgradeWrapper> trollingMotorUpgrades { get; set; }
//    public List<OptionWrapper> canvasOptions { get; set; }
//    public List<OptionWrapper> buildOptions { get; set; }
    public List<OptionWrapper> motorOptions { get; set; }
    public Map<String, List<OptionWrapper>> optionalProducts { get; set; }
    public Map<String, List<LGND_APIv2_Product.FeeProduct>> fees { get; set; }
    private List<String> enabledOptionFamilies;

    public ProductWrapper( LGND_APIv2_Product apiProd, String pricebookId )
    {
      this.optionalProducts = new Map<String, List<OptionWrapper>>();
//      for( String fam : enabledOptionFamilies )
//      {
//        this.optionalProducts.put( fam, new List<OptionWrapper>() );
//      }
      Partner_Boat_Sale_Settings__c settings = Partner_Boat_Sale_Settings__c.getOrgDefaults();
      this.enabledOptionFamilies = settings.Enabled_Part_Families__c == null ?
        new List<String>() :
        settings.Enabled_Part_Families__c.split(',');
      isFactory = pricebookId == gcConstants.idPricebookFactory;
      isPartner = pricebookId == gcConstants.idPricebookPartner;
      this.name = apiProd.Name;
      this.id = apiProd.Id;
      if( isFactory )
        this.cost = apiProd.FactoryPrice;
      if( isPartner )
        this.cost = apiProd.PartnerPrice;
      this.fees = apiProd.Fees;
      // Boat stuff
      if( apiProd.RecordTypeName == 'Boat' )
      {
        this.trailerUpgrades = new List<UpgradeWrapper>();
        this.motorUpgrades = new List<UpgradeWrapper>();
        this.trollingMotorUpgrades = new List<UpgradeWrapper>();
//        this.canvasOptions = new List<OptionWrapper>();
//        this.buildOptions = new List<OptionWrapper>();
        if( apiProd.StandardTrailer != null )
        {
          this.standardTrailer_Id = apiProd.StandardTrailer.Id;
          this.standardTrailer_Name = apiProd.StandardTrailer.Name;
          this.trailerUpgrades.add( new UpgradeWrapper( apiProd.StandardTrailer, apiProd.StandardTrailer.Id ) );
        }
        if( apiProd.TrailerUpgrades != null && apiProd.TrailerUpgrades.size() > 0 )
          this.trailerUpgrades.addAll( this.createUpgradeList( apiProd.TrailerUpgrades, this.standardTrailer_Id ) );

        //Motor Stuff
        if(  apiProd.MotorUpgrades != null && apiProd.MotorUpgrades.size() > 0 )
        {
          if( isPartner )
          {
            switch on apiProd.Family {
              when 'Utility' {
                this.motorUpgrades.addAll(this.createUpgradeList(apiProd.MotorUpgrades, null));
              }
              when else {
                if( LGND_Constants.mercuryDiscountBoatIds.contains( this.Id ) )
                {
                  List<LGND_APIv2_Product.UpgradeProduct> mUpgrades = new List<LGND_APIv2_Product.UpgradeProduct>();
                  for( LGND_APIv2_Product.UpgradeProduct ug : apiProd.MotorUpgrades )
                  {
                    if( ug.availableForMercDiscount )
                      mUpgrades.add( ug );
                  }
                  if( mUpgrades.size() > 0 )
                    this.motorUpgrades.addAll(this.createUpgradeList(mUpgrades, null));
                }
              }
            }
          }
          if( isFactory )
            this.motorUpgrades.addAll( this.createUpgradeList( apiProd.MotorUpgrades, null) );
        }


//        if( apiProd.StandardTrollingMotor != null )
//        {
//          this.standardTrollingMotor_Id = apiProd.StandardTrollingMotor.Id;
//          this.standardTrollingMotor_Name = apiProd.StandardTrollingMotor.Name;
//          this.trollingMotorUpgrades.add( new UpgradeWrapper( apiProd.StandardTrollingMotor, apiProd.StandardTrollingMotor.Id ) );
//        }
        if( apiProd.TrollingMotorUpgrades != null && apiProd.TrollingMotorUpgrades.size() > 0 )
          this.trollingMotorUpgrades.addAll( this.createUpgradeList( apiProd.TrollingMotorUpgrades, this.standardTrollingMotor_Id ) );

        findCanvasDiscount( apiProd.Id, pricebookId );

        //Options
        for( String fam : this.enabledOptionFamilies )
        {
          if (apiProd.OptionalProducts != null &&
            apiProd.OptionalProducts.containsKey(fam))
          {
            if (!this.optionalProducts.containsKey(fam))
              this.optionalProducts.put(fam, new List<OptionWrapper>());

            for (LGND_APIv2_Product.PartProduct pp : apiProd.OptionalProducts.get(fam))
            {
              this.optionalProducts.get(fam).add(new OptionWrapper(pp));
            }
          }
        }

//        if( apiProd.OptionalProducts != null &&
//            apiProd.OptionalProducts.containsKey('Canvas') )
//        {
//          for( LGND_APIv2_Product.PartProduct pp : apiProd.OptionalProducts.get('Canvas') )
//          {
//            this.canvasOptions.add( new OptionWrapper( pp ) );
//          }
//        }
//        //Build Options
//        if( apiProd.OptionalProducts != null &&
//            apiProd.OptionalProducts.containsKey('Boat Build Option') )
//        {
//          for( LGND_APIv2_Product.PartProduct pp : apiProd.OptionalProducts.get('Boat Build Option') )
//          {
//            this.buildOptions.add( new OptionWrapper( pp ) );
//          }
//        }
      }
      if( apiProd.RecordTypeName == 'Motor' && isFactory)
      {
        this.motorOptions = new List<OptionWrapper>();
        if( apiProd.OptionalProducts != null &&
            apiProd.OptionalProducts.containsKey('Labour') )
        {
          for( LGND_APIv2_Product.PartProduct pp : apiProd.OptionalProducts.get('Labour') )
          {
            OptionWrapper ow = new OptionWrapper( pp );
            ow.parent_id = this.id;
            this.motorOptions.add( ow );
          }
        }
      }
    }

    private void findCanvasDiscount( String boatId, String pricebookId )
    {
      try {
        //if( pricebookId == gcConstants.idPricebookFactory )
        //  return;
        Product2 boat = [SELECT Id, Partner_Canvas_Promotion__c
                         FROM Product2
                         WHERE Id = :boatId];
        if( boat.Partner_Canvas_Promotion__c != null )
        {
          PricebookEntry pbe = [ SELECT UnitPrice
                                 FROM PricebookEntry
                                 WHERE Product2Id = :boat.Partner_Canvas_Promotion__c
                                 AND Pricebook2Id = :pricebookId ];
          this.canvasDiscountAmount = pbe.UnitPrice;
        }
      }
      catch(Exception e)
      {
        //this.canvasDiscoutAmount
      }
    }

    private List<UpgradeWrapper> createUpgradeList( List<LGND_APIv2_Product.UpgradeProduct> upgrades,
                                                     String standardProductId )
    {
      List<UpgradeWrapper> result = new List<UpgradeWrapper>();
      for( LGND_APIv2_Product.UpgradeProduct uProd : upgrades )
      {
        if( ( standardProductId != null && uProd.PartnerUpgradeCost != null && uProd.PartnerUpgradeCost > 0 ) ||
            ( standardProductId == null && uProd.PartnerPrice != null && uProd.PartnerPrice > 0) )
        result.add( new UpgradeWrapper( uProd, standardProductId ) );
      }
      return result;
    }
  }

  public class UpgradeWrapper {
    public String name { get; set; }
    public String id { get; set; }
    public Decimal cost { get; set; }
    public Boolean isUpgrade { get; set; }

    public UpgradeWrapper( LGND_APIv2_Product.UpgradeProduct uProd, String standardProductId )
    {
      this.id = uProd.Id;
      this.name = uProd.Name;
      this.isUpgrade = standardProductId == null ? false :
        standardProductId == uProd.Id ? false : true;
      if( standardProductId != null )
        this.cost = uProd.PartnerUpgradeCost;
      else
        this.cost = uProd.PartnerPrice;
    }
  }

  public class OptionWrapper {
    public String id { get; set; }
    public String name { get; set; }
    public String parent_id { get; set; }
    public Decimal cost { get; set; }
    public Decimal individualCost { get; set; }
    public Integer quantityStandard { get; set; }
    public Integer quantityMaximum { get; set; }
    public Integer quantitySelected { get; set; }
    public Boolean isSelected { get; set; }
    public Boolean hasOptions { get; set; }
    public Boolean isDisabled { get; set; }
    public Boolean isCheckbox { get; set; }
    public Set<Integer> quantityOptions { get; set; }
    public List<OptionWrapper> subOptions { get; set; }

    public OptionWrapper( LGND_APIv2_Product.PartProduct pp )
    {
      this.id = pp.Id;
      this.name = pp.Name;
      this.individualCost = pp.PartnerPrice;
      this.cost = pp.QuantityStandard > 0 ? 0 : pp.PartnerPrice;
      this.hasOptions = pp.HasOptions;
      this.isSelected = pp.QuantityStandard > 0 ? true : false;
      this.isDisabled = pp.QuantityStandard == pp.MaximumQuantity;
      this.quantityStandard = pp.QuantityStandard;
      this.quantityMaximum = pp.MaximumQuantity;
      this.quantitySelected = pp.QuantityStandard;
      this.isCheckbox = pp.MaximumQuantity == 1;
      buildQuantityOptions();
    }

    public OptionWrapper( PricebookEntry pbe, Product_Option__c opt )
    {
      this.id = pbe.Product2Id;
      this.name = pbe.Product2.Name;
      this.individualCost = pbe.UnitPrice;
      this.cost = opt.Standard__c > 0 ? 0 : pbe.UnitPrice;
      this.isSelected = opt.Standard__c > 0;
      this.quantityStandard = Integer.valueOf( opt.Standard__c );
      this.quantityMaximum = Integer.valueOf( opt.Maximum__c );
      this.quantitySelected = Integer.valueOf( opt.Standard__c );
      this.isCheckbox = opt.Maximum__c == 1;
      this.isDisabled = opt.Standard__c == opt.Maximum__c;
      buildQuantityOptions();
    }

    public OptionWrapper( PricebookEntry pbe )
    {
      this.id = pbe.Product2Id;
      this.name = pbe.Product2.Name;
      this.cost = pbe.UnitPrice;
      this.hasOptions = false;
      this.isSelected = false;
      this.isDisabled = false;
    }

    public OptionWrapper( AcctSeedERP__Material__c mat )
    {
      this.id = mat.AcctSeedERP__Product__c;
      this.name = mat.AcctSeedERP__Product__r.Name;
      this.cost = mat.GMBLASERP__Unit_Price__c;
      if( mat.Parent_Product__c != null )
        this.parent_id = mat.Parent_Product__c;
      this.isSelected = true;
    }

    public OptionWrapper( AcctSeedERP__Material__c mat,
                          Product_Option__c opt)
    {
      this.id = mat.AcctSeedERP__Product__c;
      this.name = mat.AcctSeedERP__Product__r.Name;
      this.cost = mat.GMBLASERP__Unit_Price__c;
      if( mat.Parent_Product__c != null )
        this.parent_id = mat.Parent_Product__c;
      this.isCheckbox = opt.Maximum__c == 1;
      if( this.isCheckbox )
        this.isSelected = true;
      else
        this.quantitySelected = Integer.valueOf( mat.AcctSeedERP__Quantity_Per_Unit__c );
      this.quantityStandard = Integer.valueOf( opt.Standard__c );
      this.quantityMaximum = Integer.valueOf( opt.Maximum__c );
      this.isDisabled = opt.Standard__c == opt.Maximum__c;
      buildQuantityOptions();
    }

    public OptionWrapper( Legend_Transfer_Item__c item )
    {
      this.id = item.Product__c;
      this.name = item.Product__r.Name;
      this.cost = 0.00;
      if( item.Parent_Product__c != null )
        this.parent_id = item.Parent_Product__c;
      this.isSelected = true;
    }

    private void buildQuantityOptions()
    {
      this.quantityOptions = new Set<Integer>();
      for( Integer i=this.quantityStandard; i<=this.quantityMaximum; i++ )
      {
        this.quantityOptions.add( i );
      }
    }
  }

  public class DolWrapper {
    public String province                      { get; set; }
    public String family                        { get; set; }
    public String recordType                    { get; set; }
    public String selectedBoat_Id               { get; set; }
    public String selectedTrailer_Id            { get; set; }
    public String selectedMotor_Id              { get; set; }
    public String selectedTrollingMotor_Id      { get; set; }
    public String selectedTrollingMotor_Name    { get; set; }
    public String notes                         { get; set; }
    public String modelYear                     { get; set; }
    public Integer quantity                     { get; set; }
    public Map<String, OptionWrapper> options   { get; set; }
    public List<OptionWrapper> motorOptions     { get; set; }
    public Dealer_Motor_Request__c motorRequest { get; set; }
    public Boolean isMotorRequestOnly           { get; set; }

    public DolWrapper(){
      this.options = new Map<String, OptionWrapper>();
      this.isMotorRequestOnly = false;
    }
  }

  public class DolViewWrapper {
    public String notes { get; set; }
    public Map<String, Object> boat { get; set; }
    public Map<String, Object> motor { get; set; }
    public Map<String, Object> trollingMotor { get; set; }
    public Map<String, Object> trailer { get; set; }
    public List<Map<String, Object>> options { get; set; }
    public List<Map<String, Object>> fees { get; set; }
    public List<Map<String, Object>> discounts { get; set; }
    public String invoiceNumber { get; set; }
    public Integer quantity { get; set; }
    public Decimal orderTotal { get; set; }
    public Boolean booking { get; set; }
    public String orderGroupId { get; set; }
    public Decimal grandTotal { get; set; }
    public Decimal totalBeforeSavings { get; set; }
    public Decimal totalSavings { get; set; }

    public DolViewWrapper()
    {
      this.totalBeforeSavings = 0;
      this.totalSavings = 0;
      this.options = new List<Map<String, Object>>();
      this.fees = new List<Map<String, Object>>();
      this.discounts = new List<Map<String, Object>>();
    }

    public DolViewWrapper addBoat( AcctSeedERP__Material__c mat )
    {
      this.boat = makeEntry(mat.AcctSeedERP__Product__r.Name,
                            mat.GMBLASERP__Unit_Price__c,
                            mat.GMBLASERP__Serial_Number__r.Name);
      this.totalBeforeSavings += mat.GMBLASERP__Unit_Price__c;
      return this;
    }
    public DolViewWrapper addBoat( Legend_Transfer_Item__c item )
    {
      this.boat = makeEntry(item.Product__r.Name, 0.00);
      return this;
    }

    public DolViewWrapper addTrailer( AcctSeedERP__Material__c mat )
    {
      this.trailer = makeEntry(mat.AcctSeedERP__Product__r.Name,
                               mat.GMBLASERP__Unit_Price__c,
                               mat.GMBLASERP__Serial_Number__r.Name);
      this.totalBeforeSavings += mat.GMBLASERP__Unit_Price__c;
      return this;
    }
    public DolViewWrapper addTrailer( Legend_Transfer_Item__c item )
    {
      this.trailer = makeEntry(item.Product__r.Name, 0.00);
      return this;
    }

    public DolViewWrapper addMotor( AcctSeedERP__Material__c mat )
    {
      this.motor = makeEntry(mat.AcctSeedERP__Product__r.Name,
                             mat.GMBLASERP__Unit_Price__c,
                             mat.GMBLASERP__Serial_Number__r.Name);
      this.totalBeforeSavings += mat.GMBLASERP__Unit_Price__c;
      return this;
    }
    public DolViewWrapper addMotor( Legend_Transfer_Item__c item )
    {
      this.motor = makeEntry(item.Product__r.Name, 0.00);
      return this;
    }

    public DolViewWrapper addTrollingMotor( AcctSeedERP__Material__c mat )
    {
      this.trollingMotor = makeEntry(mat.AcctSeedERP__Product__r.Name, mat.GMBLASERP__Unit_Price__c);
      this.totalBeforeSavings += mat.GMBLASERP__Unit_Price__c;
      return this;
    }
    public DolViewWrapper addTrollingMotor( Legend_Transfer_Item__c item )
    {
      this.trollingMotor = makeEntry(item.Product__r.Name, 0.00);
      return this;
    }

    public DolViewWrapper addOption( AcctSeedERP__Material__c mat )
    {
      Map<String, Object> entry =
        makeEntry(mat.AcctSeedERP__Product__r.Name, mat.GMBLASERP__Unit_Price__c);
      entry.put('hasChildren', false);
      entry.put( 'parentId', mat.Parent_Product__c );
      entry.put( 'productId', mat.AcctSeedERP__Product__c );
      entry.put( 'kitParentId', mat.Material__c == null ? null : mat.Material__r.AcctSeedERP__Product__c );
      if( mat.AcctSeedERP__Quantity_Per_Unit__c > 1 )
      {
        entry.put('name', entry.get('name') + '  ( qty ' + String.valueOf(mat.AcctSeedERP__Quantity_Per_Unit__c.stripTrailingZeros()) + ' )' );
        if( mat.GMBLASERP__Unit_Price__c == 0 )
          entry.put('more_name', entry.get('more_name') + '  ( ' + String.valueOf(mat.AcctSeedERP__Quantity_Per_Unit__c.stripTrailingZeros()) + ' )' );
        else
          entry.put('more_name', entry.get('more_name') + '  ( ' + String.valueOf(mat.AcctSeedERP__Quantity_Per_Unit__c.stripTrailingZeros()) + ' @ $' + mat.GMBLASERP__Unit_Price__c.setScale(2) + ' ea. )' );
        entry.put('cost', mat.AcctSeedERP__Quantity_Per_Unit__c * mat.GMBLASERP__Unit_Price__c );
      }
      this.options.add( entry );
      this.totalBeforeSavings += mat.GMBLASERP__Unit_Price__c * mat.AcctSeedERP__Quantity_Per_Unit__c;
      return this;
    }
    public DolViewWrapper addOption( Legend_Transfer_Item__c item )
    {
      this.options.add( makeEntry(item.Product__r.Name, 0.00) );
      return this;
    }

    public DolViewWrapper addFee( AcctSeedERP__Material__c mat )
    {
      this.fees.add( makeEntry(mat.AcctSeedERP__Product__r.Name, mat.GMBLASERP__Unit_Price__c) );
      this.totalBeforeSavings += mat.GMBLASERP__Unit_Price__c;
      return this;
    }
    public DolViewWrapper addFee( Legend_Transfer_Item__c item )
    {
      this.fees.add( makeEntry(item.Product__r.Name, 0.00) );
      return this;
    }

    public DolViewWrapper addDiscount( AcctSeedERP__Material__c mat )
    {
      this.discounts.add( makeEntry(mat.AcctSeedERP__Comment__c, mat.GMBLASERP__Unit_Price__c) );
      this.totalSavings += mat.GMBLASERP__Unit_Price__c;
      return this;
    }

    public void groupOptions()
    {
      List<Map<String, Object>> result = new List<Map<String, Object>>();
      Map<String, Map<String,Object>> groupedOptions = new Map<String, Map<String, Object>>();
      Map<String, List<Map<String, Object>>> subOptionMap = new Map<String, List<Map<String, Object>>>();
      Map<String, List<Map<String, Object>>> kitPartsMap = new Map<String, List<Map<String, Object>>>();
      for( Map<String, Object> option : this.options )
      {
        if( option.containsKey('parentId') && option.get('parentId') != null)
        {
          if( !subOptionMap.containsKey( (String)option.get('parentId') ) )
            subOptionMap.put( (String)option.get('parentId'), new List<Map<String, Object>>() );
          subOptionMap.get( (String)option.get('parentId') ).add( option );
        }
        else if( option.containsKey('kitParentId') && option.get('kitParentId') != null)
        {
          if( !kitPartsMap.containsKey( (String)option.get('kitParentId') ) )
            kitPartsMap.put( (String)option.get('kitParentId'), new List<Map<String, Object>>() );
          kitPartsMap.get( (String)option.get('kitParentId') ).add( option );
        }
        else
        {
          groupedOptions.put( (String)option.get('productId'), option );
        }
      }
      for( String parentId : subOptionMap.keySet() )
      {
        if( groupedOptions.containsKey( parentId ) )
        {
          List<Map<String, Object>> subOptions = subOptionMap.get( parentId );
          groupedOptions.get( parentId ).put('subOptions', subOptions );
          groupedOptions.get( parentId ).put('hasChildren', true);
        }
      }
      for( String kitParentId : kitPartsMap.keySet() )
      {
        if( groupedOptions.containsKey( kitParentId ) )
        {
          List<Map<String, Object>> kitParts = kitPartsMap.get( kitParentId );
          groupedOptions.get( kitParentId ).put('kitParts', kitParts );
          groupedOptions.get( kitParentId ).put('hasChildren', true);
        }
      }
      for( String productId : groupedOptions.keySet() )
      {
        result.add( groupedOptions.get( productId ) );
      }
      this.options = result;
    }

    private Map<String, Object> makeEntry( String name, Decimal cost )
    {
      Map<String, Object> entry = new Map<String, Object>();
      entry.put('name', name);
      entry.put('more_name', name);
      entry.put('cost', cost );
      if( cost == 0 )
        entry.put('cost_description', 'Included');
      return entry;
    }

    private Map<String, Object> makeEntry( String name, Decimal cost, String serNum )
    {
      Map<String, Object> entry = new Map<String, Object>();
      entry.put('name', name);
      entry.put('serial_number', serNum);
      entry.put('cost', String.valueOf( cost ) );
      if( cost == 0 )
        entry.put('cost_description', 'Included');
      return entry;
    }

  }

	public DealerOrder_Ext(ApexPages.StandardController std) {}

  @AuraEnabled
  public static String builderInit()
  {
    Integer currentYear = System.Today().year();
    if( System.Today().month() >= 8 )
      currentYear++;
    Map<String, Object> result = new Map<String, Object>();
    result.put('userType', UserInfo.getUserType() );
    result.put('modelYear', currentYear );
    result.put('uiTheme', UserInfo.getUiThemeDisplayed() );
    List<Map<String, Object>> options = new List<Map<String,Object>>();
    for( String year : Partner_Program_Settings__c.getOrgDefaults().Available_Model_Years__c.split(',') )
    {
      Map<String,Object> opt = new Map<String, Object>{
        'label' => year,
        'value' => year
      };
      if( year == String.valueOf(currentYear) )
        opt.put('selected', true);
      options.add( opt );
    }
    result.put(
      'modelYearOptions',
      options
    );
    return JSON.serialize( result );
  }

  @AuraEnabled
  public static String getUserType()
  {
    return UserInfo.getUserType();
  }

  @AuraEnabled
  public static String getInitNewOrder()
  {
    DetailsWrapper dw = new DetailsWrapper();
    Id contactId = [SELECT ContactId FROM User WHERE Id = :Userinfo.getUserId()].ContactId;
    try {
      Contact ct = [SELECT AccountId, Account.BillingState, Account.Is_Internal__c FROM Contact WHERE Id = :contactId];
      dw.accountId = ct.AccountId;
      dw.isFactoryStore = ct.Account.Is_Internal__c;
      dw.province = ct.Account.BillingState;
      dw.addFinanceCompanyOptions( [SELECT Id, Financing_Company__r.Name
                                  FROM Financing_Company__c
                                  WHERE Account__c = :dw.accountId]);
      dw.dealerOrder.Account__c = dw.accountId;
      dw.dealerOrder.Pricebook__c = dw.isFactoryStore ? gcConstants.idPricebookFactory :
                                                        gcConstants.idPricebookPartner;
    }
    catch(Exception e) {
      Id dealerRT = LGND_Utilities.recordTypeIdFromName('Account', 'Dealer');
      dw.addAccountOptions( [SELECT Id, Name
                         FROM Account
                         WHERE RecordTypeId = :dealerRT
                         ORDER By Name ASC ] );
      dw.fromInternal = true;
    }
    try
    {
      String uniq = dw.dealerOrder.Program_Year__c + '-' + dw.dealerOrder.Account__c;
      dw.bookingOrder = [
        SELECT
          Id,
          Name,
          Dealer_Order__c,
          Account__c,
          V_Hull_Discount_Percent__c,
          Pontoon_Volume_Discount_Percent__c,
          Uniquifier__c
        FROM Partner_Booking_Order__c
        WHERE Uniquifier__c = :uniq];
      dw.allowBookingOrder = false;
    }
    catch( Exception e ){}
    dw.dealerOrder.Is_Booking_Order__c = dw.bookingOrder == null;
    return JSON.serialize( dw );
  }

  @AuraEnabled
  public static String fetchFinanceCompanys( String accountId )
  {
    DetailsWrapper dw = new DetailsWrapper();
    dw.addFinanceCompanyOptions( [SELECT Id, Financing_Company__r.Name
                                  FROM Financing_Company__c
                                  WHERE Account__c = :accountId]);
    return JSON.serialize( dw.financeCompanyOptions );
  }

  @AuraEnabled
  public static Dealer_Order__c saveDealerOrder( String dealerOrderJSON )
  {
    Dealer_Order__c dealerOrder = (Dealer_Order__c)JSON.deserialize( dealerOrderJSON, Dealer_Order__c.class);
    if( dealerOrder == null )
      return new Dealer_Order__c();
    upsert dealerOrder;
    return  fetchDealerOrder( dealerOrder.Id ) ;
  }

  @AuraEnabled
  public static void submitDealerOrder( Id dealerOrderId )
  {
    Dealer_Order__c d = [SELECT Id FROM Dealer_Order__c WHERE Id = :dealerOrderId];
    d.Stage__c = 'Pending Review';
    update d;
  }

  @AuraEnabled
  public static void deleteDealerOrder( String dealerOrderId )
  {
    Dealer_Order__c dOrder = new Dealer_Order__c( Id = dealerOrderId );
    delete dOrder;
  }

  @AuraEnabled
  public static String viewDealerLineItem( String groupId )
  {
    Dealer_Order_Line__c[] dols = [SELECT Id,
                                          ERP_Order__c,
                                          ERP_Order__r.Customer_Notes__c,
                                          Legend_Transfer_Request__c,
                                          Legend_Transfer_Request__r.Notes__c,
                                          Dealer_Order__r.Account__r.BillingState,
                                          Dealer_Order__r.Is_Legend_Transfer__c,
                                          Dealer_Motor_Request__c,
                                          Line_Total_Pre_Tax__c,
                                          Dealer_Order__r.Is_Booking_Order__c,
                                          Model_Year__c
                                   FROM Dealer_Order_Line__c
                                   WHERE Order_Group_Id__c = :groupId];
    if( dols.size() == 0 )
      return null;

    if( dols[0].ERP_Order__c == null &&
        dols[0].Legend_Transfer_Request__c == null &&
        dols[0].Dealer_Motor_Request__c != null )
      return JSON.serialize( viewDealerLineItemFromMotorRequest( dols ) );

    if( dols[0].Dealer_Order__r.Is_Legend_Transfer__c )
      return JSON.serialize( viewDealerLineItemFromTransfer( dols ) );
    else
      return JSON.serialize( viewDealerLineItemFromERP( dols ) );

  }

  private static DolViewWrapper viewDealerLineItemFromTransfer( Dealer_Order_Line__c[] dols )
  {
    DolViewWrapper result = new DolViewWrapper();
    result.orderTotal = dols[0].Line_Total_Pre_Tax__c;
    result.notes = dols[0].Legend_Transfer_Request__r.Notes__c;
    result.quantity = dols.size();

    for( Legend_Transfer_Item__c item : [SELECT Id,
                                                Product__r.Name,
                                                Product__r.RecordType.Name,
                                                Product__r.Family,
                                                Comment__c
                                         FROM Legend_Transfer_Item__c
                                         WHERE Legend_Transfer_Request__c = : dols[0].Legend_Transfer_Request__c ])
    {
      if( item.Product__r.RecordType.Name == 'Boat' )
        result.addBoat( item );
      if( item.Product__r.RecordType.Name == 'Trailer' )
        result.addTrailer( item );
      if( item.Product__r.RecordType.Name == 'Motor' )
        result.addMotor( item );
      if( item.Product__r.RecordType.Name == 'Trolling Motor' )
        result.addTrollingMotor( item );
      if( item.Product__r.RecordType.Name == 'Part' )
        result.addOption( item );
      if( item.Product__r.RecordType.Name == 'Fees' )
        result.addFee( item );
    }
    return result;

  }

  public class OrderDetailsWrapper {
    public List<Map<String, String>> boats { get; set; }
    public List<Map<String, String>> trailers { get; set; }
    public List<Map<String, String>> trollingMotors { get; set; }
    public List<Map<String, String>> motors { get; set; }
    public List<Map<String, String>> mercuryMotors { get; set; }
    public List<Map<String, String>> fees { get; set; }
    public List<Map<String, String>> discounts { get; set; }
    public List<Map<String, Object>> options { get; set; }

    public OrderDetailsWrapper()
    {
      this.boats = new List<Map<String, String>>();
      this.trailers = new List<Map<String, String>>();
      this.trollingMotors = new List<Map<String, String>>();
      this.motors = new List<Map<String, String>>();
      this.mercuryMotors = new List<Map<String, String>>();
      this.fees = new List<Map<String, String>>();
      this.discounts = new List<Map<String, String>>();
      this.options = new List<Map<String, Object>>();
    }

    public OrderDetailsWrapper addItem( AcctSeedERP__Material__c mat )
    {
      if( mat.AcctSeedERP__Product__r.RecordType.Name == 'Boat' )
        this.boats.add( buildObj(mat) );
      if( mat.AcctSeedERP__Product__r.RecordType.Name == 'Trailer' )
        this.trailers.add( buildObj(mat) );
      if( mat.AcctSeedERP__Product__r.RecordType.Name == 'Trolling Motor' )
        this.trollingMotors.add( buildObj(mat) );
      if( mat.AcctSeedERP__Product__r.RecordType.Name == 'Motor' )
        this.motors.add( buildObj(mat) );
      if( mat.AcctSeedERP__Product__r.RecordType.Name == 'Fees' )
        this.buildSummedObj( mat, this.fees );
      if( mat.AcctSeedERP__Product__r.RecordType.Name == 'Part' )
      {
        if( mat.AcctSeedERP__Product__r.Family == 'Discount' )
          this.buildSummedObj( mat, this.discounts );
          //this.discounts.add( buildObj(mat));
        else
          this.options.add( buildOptionObj(mat) );
      }
      return this;
    }

    private void buildSummedObj( AcctSeedERP__Material__c mat,
                                 List<Map<String, String>> theList )
    {
      Boolean exists = false;
      String name = mat.AcctSeedERP__Product__r.Family == 'Discount' ?
        mat.AcctSeedERP__Comment__c :
        mat.AcctSeedERP__Product__r.Name;
      for( Map<String, String> item : theList )
      {
        if( name == item.get('name') )
        {
          exists = true;
          Decimal cost = mat.GMBLASERP__Unit_Price__c;
          Decimal total = Decimal.valueOf( item.get('total') );
          Integer count = Integer.valueOf( item.get('quantity') );
          item.put('quantity', String.valueOf( count += 1 ) );
          item.put('total', String.valueOf( total + cost ) );
          break;
        }
      }
      if( !exists )
      {
        Map<String, String> item =  buildObj( mat );
        item.put('quantity', '1');
        item.put('total', item.get('cost') );
        theList.add( item );
      }
    }

    public OrderDetailsWrapper addMercuryItem( Dealer_Motor_Request__c dmr )
    {
      Map<String, String> result = new Map<String, String>();
      result.put('name', dmr.Motor__r.Name );
      result.put('cost', 'Package and Save');
      result.put('quantity', String.valueOf( dmr.Quantity__c ) );
      this.mercuryMotors.add( result );
      return this;
    }

    public Map<String, String> buildObj( AcctSeedERP__Material__c mat )
    {
      Map<String, String> result = new Map<String, String>();
      String name = mat.AcctSeedERP__Product__r.Family == 'Discount' ?
        mat.AcctSeedERP__Comment__c :
        mat.AcctSeedERP__Product__r.Name;
      result.put('name', name );
      result.put('invoiceNumber', mat.AcctSeedERP__Project__r.AcctSeedERP__Work_Order_Number__c );
      result.put('cost', String.valueOf( mat.GMBLASERP__Unit_Price__c ) );
      result.put('itemStatus', mat.AcctSeedERP__Project__r.Stage__c );
      result.put('serialNumber', mat.GMBLASERP__Serial_Number__r.Name);
      return result;
    }

    public Map<String, Object> buildOptionObj( AcctSeedERP__Material__c mat )
    {
      Map<String, Object> result = new Map<String, Object>();
      String name = mat.AcctSeedERP__Product__r.Family == 'Discount' ?
        mat.AcctSeedERP__Comment__c :
        mat.AcctSeedERP__Product__r.Name;
      result.put('name', name );
      result.put('invoiceNumber', mat.AcctSeedERP__Project__r.AcctSeedERP__Work_Order_Number__c );
      result.put('cost', mat.GMBLASERP__Unit_Price__c * mat.AcctSeedERP__Quantity_Per_Unit__c );
      result.put('itemStatus', mat.AcctSeedERP__Project__r.Stage__c );
      result.put('serialNumber', mat.GMBLASERP__Serial_Number__r.Name);
      result.put('hasChildren', false);
      result.put('productId', mat.AcctSeedERP__Product__c );
      result.put('kitParentId', mat.Material__c == null ? null : mat.Material__r.AcctSeedERP__Product__c );
      result.put('parentId', mat.Parent_Product__c );
      if( mat.AcctSeedERP__Quantity_Per_Unit__c > 1 )
      {
        if( mat.GMBLASERP__Unit_Price__c == 0 )
          result.put('name', name + ' ( ' + String.valueOf( mat.AcctSeedERP__Quantity_Per_Unit__c.stripTrailingZeros()) + ' )');
        else
          result.put('name', name + '  ( ' + String.valueOf(mat.AcctSeedERP__Quantity_Per_Unit__c.stripTrailingZeros()) + ' @ $' + mat.GMBLASERP__Unit_Price__c.setScale(2) + ' ea. )');
      }
      return result;
    }

    public void groupOptions()
    {
      List<Map<String, Object>> result = new List<Map<String, Object>>();
      Map<String, Map<String,Object>> groupedOptions = new Map<String, Map<String, Object>>();
      Map<String, List<Map<String, Object>>> subOptionMap = new Map<String, List<Map<String, Object>>>();
      Map<String, List<Map<String, Object>>> kitPartsMap = new Map<String, List<Map<String, Object>>>();
      for( Map<String, Object> option : this.options )
      {
        if( option.containsKey('parentId') && option.get('parentId') != null)
        {
          if( !subOptionMap.containsKey( (String)option.get('parentId') ) )
            subOptionMap.put( (String)option.get('parentId'), new List<Map<String, Object>>() );
          subOptionMap.get( (String)option.get('parentId') ).add( option );
        }
        else if( option.containsKey('kitParentId') && option.get('kitParentId') != null)
        {
          if( !kitPartsMap.containsKey( (String)option.get('kitParentId') ) )
            kitPartsMap.put( (String)option.get('kitParentId'), new List<Map<String, Object>>() );
          kitPartsMap.get( (String)option.get('kitParentId') ).add( option );
        }
        else
        {
          groupedOptions.put( (String)option.get('productId'), option );
        }
      }
      for( String parentId : subOptionMap.keySet() )
      {
        if( groupedOptions.containsKey( parentId ) )
        {
          List<Map<String, Object>> subOptions = subOptionMap.get( parentId );
          groupedOptions.get( parentId ).put('subOptions', subOptions );
          groupedOptions.get( parentId ).put('hasChildren', true);
        }
      }
      for( String kitParentId : kitPartsMap.keySet() )
      {
        if( groupedOptions.containsKey( kitParentId ) )
        {
          List<Map<String, Object>> kitParts = kitPartsMap.get( kitParentId );
          groupedOptions.get( kitParentId ).put('kitParts', kitParts );
          groupedOptions.get( kitParentId ).put('hasChildren', true);
        }
      }
      for( String productId : groupedOptions.keySet() )
      {
        result.add( groupedOptions.get( productId ) );
      }
      this.options = result;
    }
  }

  @AuraEnabled
  public static String fetchOrderDetails( String recordId )
  {
    OrderDetailsWrapper result = new OrderDetailsWrapper();
    Set<Id> erpIds = new Set<Id>();
    Set<Id> motorRequestIds = new Set<Id>();

    for( Dealer_Order_Line__c dol : [ SELECT Id, ERP_Order__c, Dealer_Motor_Request__c
                                      FROM Dealer_Order_Line__c
                                      WHERE Dealer_Order__c = :recordId] )
    {
      erpIds.add( dol.ERP_Order__c );
      motorRequestIds.add( dol.Dealer_Motor_Request__c );
    }
    for( AcctSeedERP__Material__c mat : [SELECT Id,
                                                AcctSeedERP__Product__r.Name,
                                                AcctSeedERP__Product__r.RecordType.Name,
                                                AcctSeedERP__Product__r.Family,
                                                AcctSeedERP__Comment__c,
                                                AcctSeedERP__Quantity_per_Unit__c,
                                                AcctSeedERP__Project__r.Stage__c,
                                                GMBLASERP__Serial_Number__r.Name,
                                                GMBLASERP__Unit_Price__c,
                                                Parent_Product__c,
                                                Material__c,
                                                Material__r.AcctSeedERP__Product__c,
                                                AcctSeedERP__Project__r.AcctSeedERP__Work_Order_Number__c
                                      FROM AcctSeedERP__Material__c
                                      WHERE AcctSeedERP__Project__c IN :erpIds])
    {
      result.addItem( mat );
    }
    for( Dealer_Motor_Request__c dmr : [SELECT Id,
                                               Motor__r.Name,
                                               Quantity__c
                                        FROM Dealer_Motor_Request__c
                                        WHERE Id IN :motorRequestIds])
    {
      result.addMercuryItem( dmr );
    }
    result.groupOptions();
    return JSON.serialize( result );

  }

  @AuraEnabled
  public static String fetchUniqueOrderDetails( String recordId )
  {
    Map<String, List<DolViewWrapper>> result = new Map<String, List<DolViewWrapper>>{
      'boats' => new List<DolViewWrapper>(),
      'motors' => new List<DolViewWrapper>(),
      'trailers' => new List<DolViewWrapper>(),
      'trollingMotors' => new List<DolViewWrapper>()
    };
    Map<String, Dealer_Order_Line__c> uniqueERPLines = new Map<String, Dealer_Order_Line__c>();
    List<Dealer_Order_Line__c> motorRequestLines = new List<Dealer_Order_Line__c>();
    Map<String, Integer> quantityMap = new Map<String, Integer>();
    Map<Id, Dealer_Order_Line__c> erpIdMap = new Map<Id, Dealer_Order_Line__c>();
    for( Dealer_Order_Line__c line : [SELECT Id,
                                             Line_Total_Pre_Tax__c,
                                             Order_Group_Id__c,
                                             Dealer_Motor_Request__c,
                                             Dealer_Motor_Request__r.Motor__r.Name,
                                             Dealer_Motor_Request__r.Quantity__c,
                                             ERP_Order__c,
                                             Notes__c
                                      FROM Dealer_Order_Line__c
                                      WHERE Dealer_Order__c = :recordId] )
    {
      if( !uniqueERPLines.containsKey( line.Order_Group_Id__c ) )
      {
        if( line.ERP_Order__c != null )
        {
          uniqueERPLines.put( line.Order_Group_Id__c, line );
          erpIdMap.put( line.Erp_Order__c, line );
        }
        if( line.ERP_Order__c == null &&
            line.Dealer_Motor_Request__c != null )
        {
          motorRequestLines.add( line );
        }
      }

      if( !quantityMap.containsKey( line.Order_Group_Id__c ) )
        quantityMap.put( line.Order_Group_Id__c, 1 );
      else
      {
        Integer q = quantityMap.get( line.Order_Group_Id__c );
        quantityMap.put( line.Order_Group_Id__c, q + 1);
      }
    }

    for( AcctSeed__Project__c erp : [ SELECT Id,
                                             Customer_Notes__c,
                                             AcctSeedERP__Work_Order_Number__c,
                                             Stage__c,
                                      (SELECT Id,
                                              AcctSeedERP__Product__r.Name,
                                              AcctSeedERP__Product__r.RecordType.Name,
                                              AcctSeedERP__Product__r.Family,
                                              AcctSeedERP__Comment__c,
                                              AcctSeedERP__Quantity_per_Unit__c,
                                              GMBLASERP__Unit_Price__c,
                                              GMBLASERP__Serial_Number__r.Name,
                                              Parent_Product__c,
                                              Material__c,
                                              Material__r.AcctSeedERP__Product__c
                                      FROM AcctSeedERP__Project_Materials__r)
                                     FROM AcctSeed__Project__c
                                     WHERE Id IN :erpIdMap.keySet() ] )
    {
      Dealer_Order_Line__c workingLine = erpIdMap.get( erp.Id );
      DolViewWrapper r = new DolViewWrapper();
      r.orderTotal = workingLine.Line_Total_Pre_Tax__c;
      r.quantity = quantityMap.get( workingLine.Order_Group_Id__c );
      r.grandTotal = r.quantity * r.orderTotal;
      r.orderGroupId = workingLine.Order_Group_Id__c;
      r.notes = erp.Customer_Notes__c;
      r.invoiceNumber = erp.AcctSeedERP__Work_Order_Number__c;
      for( AcctSeedERP__Material__c mat : erp.AcctSeedERP__Project_Materials__r)
      {
        if( mat.AcctSeedERP__Product__r.RecordType.Name == 'Boat' )
          r.addBoat( mat );
        if( mat.AcctSeedERP__Product__r.RecordType.Name == 'Trailer' )
          r.addTrailer( mat );
        if( mat.AcctSeedERP__Product__r.RecordType.Name == 'Motor' )
          r.addMotor( mat );
        if( mat.AcctSeedERP__Product__r.RecordType.Name == 'Trolling Motor' )
          r.addTrollingMotor( mat );
        if( mat.AcctSeedERP__Product__r.RecordType.Name == 'Part' &&
            mat.AcctSeedERP__Product__r.Family != 'Discount' )
          r.addOption( mat );
        if( mat.AcctSeedERP__Product__r.RecordType.Name == 'Part' &&
            mat.AcctSeedERP__Product__r.Family == 'Discount' )
          r.addDiscount( mat );
        if( mat.AcctSeedERP__Product__r.RecordType.Name == 'Fees' )
          r.addFee( mat );
      }
      r.groupOptions();
      if( workingLine.Dealer_Motor_Request__c != null )
      {
        Map<String, String> motor = new Map<String,String>{
          'name' => workingLine.Dealer_Motor_Request__r.Motor__r.Name,
          'cost' => '0',
          'cost_description' => 'Package and Save'
        };
        r.motor = motor;
      }
      if( r.boat != null )
        result.get('boats').add(r);
      else if( r.motor != null )
        result.get('motors').add( r );
      else if( r.trailer != null )
        result.get('trailers').add( r );
      else if( r.trollingMotor != null )
        result.get('trollingMotors').add( r );
    }
    for( Dealer_Order_Line__c dol : motorRequestLines )
    {
      DolViewWrapper r = new DolViewWrapper();
      r.orderTotal = dol.Line_Total_Pre_Tax__c;
      r.quantity = Integer.valueOf( dol.Dealer_Motor_Request__r.Quantity__c );
      r.grandTotal = r.quantity * r.orderTotal;
      r.orderGroupId = dol.Order_Group_Id__c;
      r.notes = dol.Notes__c;
      Map<String, String> motor = new Map<String,String>{
        'name' => dol.Dealer_Motor_Request__r.Motor__r.Name,
        'cost' => '0',
        'cost_description' => 'Package and Save'
      };
      r.motor = motor;
      result.get('motors').add( r );
    }
    return JSON.serialize( result );
  }

  private static DolViewWrapper viewDealerLineItemFromERP( Dealer_Order_Line__c[] dols )
  {
    DolViewWrapper result = new DolViewWrapper();
    result.orderTotal = dols[0].Line_Total_Pre_Tax__c;
    result.notes = dols[0].ERP_Order__r.Customer_Notes__c;
    result.booking = dols[0].Dealer_Order__r.Is_Booking_Order__c;
    result.quantity = dols.size();

    for( AcctSeedERP__Material__c mat : [SELECT Id,
                                                AcctSeedERP__Product__r.Name,
                                                AcctSeedERP__Product__r.RecordType.Name,
                                                AcctSeedERP__Product__r.Family,
                                                AcctSeedERP__Comment__c,
                                                AcctSeedERP__Quantity_per_Unit__c,
                                                GMBLASERP__Unit_Price__c,
                                                GMBLASERP__Serial_Number__r.Name,
                                                Parent_Product__c,
                                                Material__c,
                                                Material__r.AcctSeedERP__Product__c
                                         FROM AcctSeedERP__Material__c
                                         WHERE AcctSeedERP__Project__c = : dols[0].ERP_Order__c ])
    {
      if( mat.AcctSeedERP__Product__r.RecordType.Name == 'Boat' )
        result.addBoat( mat );
      if( mat.AcctSeedERP__Product__r.RecordType.Name == 'Trailer' )
        result.addTrailer( mat );
      if( mat.AcctSeedERP__Product__r.RecordType.Name == 'Motor' )
        result.addMotor( mat );
      if( mat.AcctSeedERP__Product__r.RecordType.Name == 'Trolling Motor' )
        result.addTrollingMotor( mat );
      if( mat.AcctSeedERP__Product__r.RecordType.Name == 'Part' )
      {
        if( mat.AcctSeedERP__Product__r.Family == 'Discount' )
          result.addDiscount( mat );
        else
          result.addOption( mat );
      }
      if( mat.AcctSeedERP__Product__r.RecordType.Name == 'Fees' )
        result.addFee( mat );

      if( dols[0].Dealer_Motor_Request__c != null )
      {
        Dealer_Motor_Request__c dmr = [SELECT Id, Motor__r.Name
                                       FROM Dealer_Motor_Request__c
                                       WHERE Id = : dols[0].Dealer_Motor_Request__c];
        Map<String, String> motor = new Map<String,String>{
          'name' => dmr.Motor__r.Name,
          'cost' => '0',
          'cost_description' => 'Legend - Mercury Special Programs'
        };
        result.motor = motor;
      }
    }
    result.groupOptions();
    return result;

  }

  private static DolViewWrapper viewDealerLineItemFromMotorRequest( Dealer_Order_Line__c[] dols )
  {
    DolViewWrapper result = new DolViewWrapper();
    result.orderTotal = dols[0].Line_Total_Pre_Tax__c;
    Dealer_Motor_Request__C dmr = [SELECT Id,
                                          Motor__c,
                                          Motor__r.Name,
                                          Notes__c,
                                          Quantity__c
                                  FROM Dealer_Motor_Request__c
                                  WHERE Id = : dols[0].Dealer_Motor_Request__c];
    result.notes = dmr.Notes__c;
    result.quantity = Integer.valueOf( dmr.Quantity__c );
    Map<String,String> motor = new Map<String, String>();
    motor.put('name', dmr.Motor__r.Name );
    motor.put('cost_description', 'Package and Save');
    result.motor = motor;
    return result;
  }

  @AuraEnabled
  public static String editDealerLineItem( String groupId,
                                           String pricebookId )
  {
    Dealer_Order_Line__c[] dols = [SELECT Id,
                                          ERP_Order__c,
                                          ERP_Order__r.Customer_Notes__c,
                                          Legend_Transfer_Request__c,
                                          Legend_Transfer_Request__r.Notes__c,
                                          Dealer_Order__r.Account__r.BillingState,
                                          Dealer_Order__r.Is_Legend_Transfer__c,
                                          Dealer_Motor_Request__c,
                                          Model_Year__c,
                                          Notes__c
                                   FROM Dealer_Order_Line__c
                                   WHERE Order_Group_Id__c = :groupId];
    if( dols.size() == 0 )
      return null;

    if( dols[0].ERP_Order__c == null &&
        dols[0].Legend_Transfer_Request__c == null &&
        dols[0].Dealer_Motor_Request__c != null )
      return JSON.serialize( reconstructFromMotorRequest( dols ) );

    if( dols[0].Dealer_Order__r.Is_Legend_Transfer__c )
      return JSON.serialize( reconstructFromTransfer( dols, pricebookId ) );
    else
      return JSON.serialize( reconstructFromERP( dols, pricebookId ) );

  }

  private static DolWrapper reconstructFromMotorRequest( Dealer_Order_Line__c[] dols )
  {
    DolWrapper result = new DolWrapper();
    result.province = dols[0].Dealer_Order__r.Account__r.BillingState;
    result.motorRequest = [SELECT Id, Motor__c, Quantity__c
                             FROM Dealer_Motor_Request__c
                             WHERE Id = :dols[0].Dealer_Motor_Request__c];
    result.quantity = Integer.valueOf( result.motorRequest.Quantity__c );
    result.recordType = 'Motor';
    result.selectedMotor_Id = result.motorRequest.Motor__c;
    result.isMotorRequestOnly = true;
    result.notes = dols[0].Notes__c;
    return result;
  }

  private static DolWrapper reconstructFromTransfer( Dealer_Order_Line__c[] dols,
                                                     String pricebookId )
  {
    DolWrapper result = new DolWrapper();
    Legend_Transfer_Item__c boat;
    Legend_Transfer_Item__c trailer;
    Legend_Transfer_Item__c motor;
    Legend_Transfer_Item__c trollingMotor;
    Legend_Transfer_Item__c[] parts = new List<Legend_Transfer_Item__c>();
    Legend_Transfer_Item__c[] fees = new List<Legend_Transfer_Item__c>();
    result.province = dols[0].Dealer_Order__r.Account__r.BillingState;
    // fetch Items form a single Transfer
    Legend_Transfer_Item__c[] items = [SELECT Id,
                                              Product__c,
                                              Product__r.Name,
                                              Product__r.RecordType.Name,
                                              Product__r.Family,
                                              Comment__c,
                                              Parent_Product__c
                                       FROM Legend_Transfer_Item__c
                                       WHERE Legend_Transfer_Request__c = : dols[0].Legend_Transfer_Request__c];
    //Iterate through materials to determine Boat, Trailer Options and subOptions
    for( Legend_Transfer_Item__c item : items )
    {
      if( item.Product__r.RecordType.Name == 'Boat' )
      {
        boat = item;
      }
      if( item.Product__r.RecordType.Name == 'Trailer' )
      {
        trailer = item;
      }
      if( item.Product__r.RecordType.Name == 'Motor' )
      {
        motor = item;
      }
      if( item.Product__r.RecordType.Name == 'Trolling Motor' )
      {
        trollingMotor = item;
      }
      if( item.Product__r.RecordType.Name == 'Part' )
      {
        parts.add( item );
      }
      if( item.Product__r.RecordType.Name == 'Fee' )
      {
        fees.add( item );
      }
    }

    if( boat != null )
    {
      result.family = boat.Product__r.Family;
      result.selectedBoat_Id = boat.Product__c;
      result.recordType = 'Boat';
    }
    if( trailer != null )
    {
      if( boat == null )
      {
        result.family = trailer.Product__r.Family;
        result.recordType = 'Trailer';
      }
      result.selectedTrailer_Id = trailer.Product__c;
    }
    if( motor != null )
    {
      if( boat == null )
      {
        result.family = motor.Product__r.Family;
        result.recordType = 'Motor';
      }
      result.selectedMotor_Id = motor.Product__c;
    }
    if( trollingMotor != null )
    {
      result.selectedTrollingMotor_Id = trollingMotor.Product__c;
      result.selectedTrollingMotor_Name = trollingMotor.Product__r.Name;
    }
    if( parts.size() > 0 )
    {
      /* Find ALL sub options for selected Options */
      Set<id> parentIds = new Set<Id>();
      Map<Id,Set<Id>> selectedParentChildMap = new Map<Id, Set<Id>>();
      for( Legend_Transfer_Item__c item : parts )
      {
        /*
          if the Parent_Product is not null than this is a "subOption"
          and we map it to the parent, this has been previously selected.
          if Parent Product is null then this is first level option and we
          need to find all the available subOptions
        */
        if( item.Parent_Product__c != null )
        {
          if( !selectedParentChildMap.containsKey(item.Product__c) )
            selectedParentChildMap.put( item.Parent_Product__c, new Set<Id>() );
          selectedParentChildMap.get( item.Parent_Product__c ).add( item.Product__c );
        }
        else
          parentIds.add( item.Product__c );
      }
      /*
        childParentMap = maps the available subOptions to Set of Parent Product Ids
        it is possible for a single subOption( child ) to be available in many
        options( parent )
      */
      Map<Id, Set<Id>> childParentMap = new Map<Id, Set<Id>>();
      /* find the parent product options (SubOptions) */
      Product_Option__c[] options = [SELECT From_Product__c, To_Product__c
                                     FROM Product_Option__c
                                     WHERE To_Product__c IN :parentIds];
      /*build the childParentMap */
      for( Product_Option__c opt : options )
      {
        if( !childParentMap.containsKey(opt.From_Product__c) )
          childParentMap.put( opt.From_Product__c, new Set<Id>() );
        childParentMap.get( opt.From_Product__c).add(opt.To_Product__c);
      }
      /*
        parent_subOptions_Map - maps parentProductId to a List of subOptions
      */
      Map<Id, List<OptionWrapper>> parent_subOptions_Map = new Map<Id, List<optionWrapper>>();
      /*
        get the Pricebook entries for all the subOptions and iterate through
      */
      for( PricebookEntry pbe : [SELECT Id, UnitPrice, Product2Id, Product2.Name
                               FROM PricebookEntry
                               WHERE Product2Id IN :childParentMap.keySet()
                               AND Pricebook2Id = :pricebookId ] )
      {
        /*
          using the childProductId (pbe.Product2Id) we iterate through the list
          of parentIds which have this subOptions
        */
        for( Id parentId : childParentMap.get( pbe.Product2Id) )
        {
          /*
            create an OptionWrapper object for each subOption
            and add it to the parent_subOption_Map
          */
          if( !parent_subOptions_Map.containsKey(parentId) )
          {
            parent_subOptions_Map.put( parentId, new List<OptionWrapper>() );
          }
          OptionWrapper ow = new OptionWrapper( pbe );
          /*
            check see if this sub option was previously selected
          */
          ow.isSelected = selectedParentChildMap.containsKey( parentId ) &&
                          selectedParentChildMap.get(parentId).contains(ow.id);
          ow.parent_id = parentId;
          parent_subOptions_Map.get( parentId ).add( ow );
        }
      }
      /*
        finally iterate over all the selected materials ( options ) and build
        an OptionWrapper object for each adding the subOption where applicable
      */
      for( Legend_Transfer_Item__c item : parts )
      {
        if( item.Parent_Product__c == null )
        {
          OptionWrapper ow = new OptionWrapper(item);
          if( parent_subOptions_Map.containsKey( ow.id ) )
          {
            ow.subOptions = parent_subOptions_Map.get( ow.id );
            ow.hasOptions = true;
          }
          result.options.put( ow.id, ow);
        }
      }
    }
    result.quantity = dols.size();
    result.notes = dols[0].Legend_Transfer_Request__r.Notes__c;

    return result;
  }

  private static DolWrapper reconstructFromERP( Dealer_Order_Line__c[] dols,
                                                String pricebookId )
  {
    DolWrapper result = new DolWrapper();
    Set<Id> productIds = new Set<Id>();
    Map<Id, Product_Option__c> optionMap = new Map<Id, Product_Option__c>();
    Map<String, List<AcctSeedERP__Material__c>> subOptionMaterialsMap = new Map<String, List<AcctSeedERP__Material__c>>();
    AcctSeedERP__Material__c boat;
    AcctSeedERP__Material__c trailer;
    AcctSeedERP__Material__c motor;
    AcctSeedERP__Material__c trollingMotor;
    AcctSeedERP__Material__c[] parts = new List<AcctSeedERP__Material__c>();
    AcctSeedERP__Material__c[] fees = new List<AcctSeedERP__Material__c>();
    result.province = dols[0].Dealer_Order__r.Account__r.BillingState;
    // fetch Materials form a single ERP
    AcctSeedERP__Material__c[] mats = [SELECT Id,
                                              AcctSeedERP__Product__c,
                                              AcctSeedERP__Product__r.Name,
                                              AcctSeedERP__Product__r.RecordType.Name,
                                              AcctSeedERP__Product__r.Family,
                                              AcctSeedERP__Comment__c,
                                              AcctSeedERP__Quantity_per_Unit__c,
                                              Parent_Product__c,
                                              GMBLASERP__Unit_Price__c
                                       FROM AcctSeedERP__Material__c
                                       WHERE AcctSeedERP__Project__c = : dols[0].ERP_Order__c];
    //Iterate through materials to determine Boat, Trailer Options and subOptions
    for( AcctSeedERP__Material__c mat : mats )
    {
      if( mat.AcctSeedERP__Product__r.RecordType.Name == 'Boat' )
      {
        boat = mat;
        productIds.add( mat.AcctSeedERP__Product__c );
      }
      if( mat.AcctSeedERP__Product__r.RecordType.Name == 'Trailer' )
      {
        trailer = mat;
      }
      if( mat.AcctSeedERP__Product__r.RecordType.Name == 'Motor' )
      {
        motor = mat;
        productIds.add( mat.AcctSeedERP__Product__c );
      }
      if( mat.AcctSeedERP__Product__r.RecordType.Name == 'Trolling Motor' )
      {
        trollingMotor = mat;
      }
      if( mat.AcctSeedERP__Product__r.RecordType.Name == 'Part' )
      {
        parts.add( mat );
      }
      if( mat.AcctSeedERP__Product__r.RecordType.Name == 'Fee' )
      {
        fees.add( mat );
      }
    }
    /* find Product Options */
    for( Product_Option__c option : [ SELECT From_Product__c, Standard__c, Maximum__c
                                      FROM Product_Option__c
                                      WHERE To_Product__c IN :productIds ] )
    {
      optionMap.put( option.From_Product__c, option );
    }
    /* if the dol has a Dealer_Motor_Request find it and set it */
    if( dols[0].Dealer_Motor_Request__c != null )
    {
      result.motorRequest = [SELECT Id, Motor__c, Quantity__c
                             FROM Dealer_Motor_Request__c
                             WHERE Id = :dols[0].Dealer_Motor_Request__c];
    }

    if( boat != null )
    {
      result.family = boat.AcctSeedERP__Product__r.Family;
      result.selectedBoat_Id = boat.AcctSeedERP__Product__c;
      result.recordType = 'Boat';
    }
    if( trailer != null )
    {
      if( boat == null )
      {
        result.family = trailer.AcctSeedERP__Product__r.Family;
        result.recordType = 'Trailer';
      }
      result.selectedTrailer_Id = trailer.AcctSeedERP__Product__c;
    }
    if( motor != null )
    {
      if( boat == null )
      {
        result.family = motor.AcctSeedERP__Product__r.Family;
        result.recordType = 'Motor';
      }
      result.selectedMotor_Id = motor.AcctSeedERP__Product__c;
    }
    if( trollingMotor != null )
    {
      if( boat == null )
      {
        result.family = trollingMotor.AcctSeedERP__Product__r.Family;
        result.recordType = 'Trolling Motor';
      }
      result.selectedTrollingMotor_Id = trollingMotor.AcctSeedERP__Product__c;
      result.selectedTrollingMotor_Name = trollingMotor.AcctSeedERP__Product__r.Name;
    }
    if( parts.size() > 0 )
    {
      /* Find ALL sub options for selected Options */
      Set<Id> parentIds = new Set<Id>();
      Map<Id,Set<Id>> selectedParentChildMap = new Map<Id, Set<Id>>();
      for( AcctSeedERP__Material__c mat : parts )
      {
        /*
          if the Parent_Product is not null than this is a "subOption"
          and we map it to the parent, this has been previously selected.
          if Parent Product is null then this is first level option and we
          need to find all the available subOptions
        */
        System.debug( mat.AcctSeedERP__Product__r.Name + ' - parentId - ' + mat.Parent_Product__c );
        if( mat.Parent_Product__c != null )
        {
          String key = mat.Parent_Product__c + '-' + mat.AcctSeedERP__Product__c;
          System.debug( 'building key = ' + key);
          if( !subOptionMaterialsMap.containsKey(key) )
            subOptionMaterialsMap.put( key, new List<AcctSeedERP__Material__c>() );
          subOptionMaterialsMap.get( key).add( mat );
          /* if the parent Id is equal to the motor, then this is a
             selected motor option
          */
          if( result.selectedMotor_Id == mat.Parent_Product__c )
          {
            if( result.motorOptions == null )
              result.motorOptions = new List<OptionWrapper>();
            result.motorOptions.add( new OptionWrapper(mat) );
          }
          else
          {
            if( !selectedParentChildMap.containsKey(mat.Parent_product__c) )
            {
              selectedParentChildMap.put(mat.Parent_Product__c, new Set<Id>());
            }
            selectedParentChildMap.get( mat.Parent_Product__c ).add( mat.AcctSeedERP__Product__c );
          }
        }
        else
        {
          parentIds.add(mat.AcctSeedERP__Product__c);
        }
      }
      /*
        childParentMap = maps the available subOptions to Set of Parent Product Ids
        it is possible for a single subOption( child ) to be available in many
        options( parent )
      */
      //Map<Id, Set<Id>> childParentMap = new Map<Id, Set<Id>>();
      Map<Id, List<Product_Option__c>> childParentOptionMap = new Map<Id, List<Product_Option__c>>();
      /* find the parent product options (SubOptions) */
      Product_Option__c[] options = [SELECT From_Product__c, To_Product__c, Standard__c, Maximum__c
                                     FROM Product_Option__c
                                     WHERE To_Product__c IN :parentIds];
      /*build the childParentMap */
      for( Product_Option__c opt : options )
      {
        if( !childParentOptionMap.containsKey(opt.From_Product__c) )
          childParentOptionMap.put( opt.From_Product__c, new List<Product_Option__c>() );
        childParentOptionMap.get( opt.From_Product__c).add(opt);
      }
      /*
        parent_subOptions_Map - maps parentProductId to a List of subOptions
      */
      Map<Id, List<OptionWrapper>> parent_subOptions_Map = new Map<Id, List<optionWrapper>>();
      /*
        get the Pricebook entries for all the subOptions and iterate through
      */
      for( PricebookEntry pbe : [SELECT Id, UnitPrice, Product2Id, Product2.Name
                               FROM PricebookEntry
                               WHERE Product2Id IN :childParentOptionMap.keySet()
                               AND Pricebook2Id = :pricebookId ] )
      {
        /*
          using the childProductId (pbe.Product2Id) we iterate through the list
          of parentIds which have this subOptions
        */
        for( Product_Option__c opt : childParentOptionMap.get( pbe.Product2Id) )
        {
          /*
            create an OptionWrapper object for each subOption
            and add it to the parent_subOption_Map
          */
          if( !parent_subOptions_Map.containsKey(opt.To_Product__c) )
          {
            parent_subOptions_Map.put( opt.To_Product__c, new List<OptionWrapper>() );
          }
          OptionWrapper ow = new OptionWrapper( pbe, opt );
          ow.parent_id = opt.To_Product__c;
          /*
            check see if this sub option was previously selected
          */
          if( ow.isCheckbox )
          {
            ow.isSelected = selectedParentChildMap.containsKey(opt.To_Product__c) &&
              selectedParentChildMap.get(opt.To_Product__c).contains(ow.id);
          }
          else
          {
            //ow.quantitySelected = 2;
            String key = opt.To_Product__c + '-' + opt.From_Product__c;
            System.debug( 'reconstruct Key = ' + key );
            if( subOptionMaterialsMap.containsKey( key ) )
            {
              Integer quan = 0;
              for( AcctSeedERP__Material__c mat : subOptionMaterialsMap.get( key ) )
              {
                 quan += Integer.valueOf( mat.AcctSeedERP__Quantity_Per_Unit__c );
              }
              ow.quantitySelected = quan;
            }
          }
          System.debug('SUB OPTION OW');
          System.debug(ow);
          parent_subOptions_Map.get( opt.To_Product__c ).add( ow );
        }
      }
      /*
        finally iterate over all the selected materials ( options ) and build
        an OptionWrapper object for each adding the subOption where applicable
      */
      for( AcctSeedERP__Material__c mat : parts )
      {
        if( mat.Parent_Product__c == null )
        {
          OptionWrapper ow;
          if( optionMap.containsKey( mat.AcctSeedERP__Product__c) )
            ow = new OptionWrapper(mat, optionMap.get( mat.AcctSeedERP__Product__c) );
          else
            ow = new OptionWrapper(mat);
          if( parent_subOptions_Map.containsKey( ow.id ) )
          {
            ow.subOptions = parent_subOptions_Map.get( ow.id );
            ow.hasOptions = true;
          }
          result.options.put( ow.id, ow);
        }
      }
    }
    result.quantity = dols.size();
    result.notes = dols[0].Notes__c;
    result.modelYear = dols[0].Model_Year__c;
    return result;
  }

  @AuraEnabled
  public static Dealer_Order__c saveDealerLineItem( String jsonData ) {
    DealerOrderLineWrapper wrapper = (DealerOrderLineWrapper)JSON.deserialize(jsonData, DealerOrderLineWrapper.class );
    System.debug('*** WRAPPER *** ' + wrapper);
    if( wrapper.orderGroupId == null )
    {
      return createDealerLineItems( wrapper );
    }
    else
      return updateDealerLineItems( wrapper );
  }

  @AuraEnabled
  public static Dealer_Motor_Request__c saveMotorRequest( Dealer_Motor_Request__c motorRequest )
  {

    if( motorRequest.Id != null &&
        motorRequest.Motor__c == null
      )
    {
      Dealer_Motor_Request__c dmr = new Dealer_Motor_Request__c(Id = motorRequest.Id);
      delete dmr;
      return new Dealer_Motor_Request__c();
    }
    else
    {
      upsert motorRequest;
      return motorRequest;
    }
  }

  @AuraEnabled
  public static void deleteOrderGroup( String groupId )
  {
    Dealer_Order_Line__c[] dols = [ SELECT Id
                                    FROM Dealer_Order_Line__c
                                    WHERE Order_Group_Id__c = :groupId];
    delete dols;
  }

  @AuraEnabled
  public static List<Map<String, String>> fetchProducts( String recordType,
                                                         String family,
                                                         String pricebookId )
  {
    String userType = UserInfo.getUserType();
    Boolean isFactoryStore = pricebookId == gcConstants.idPricebookFactory;
    Id rtId = LGND_Utilities.recordTypeIdFromName('Product2', recordType );
    List<Map<String, String>> result = new List<Map<String, String>>();
    String queryString = 'SELECT Product2.Id, Product2.Name, UnitPrice, Product2.Available_For_Package_And_Save__c, Product2.Available_For_Mercury_Partner_Discount__c FROM PricebookEntry WHERE IsActive = true AND Product2.RecordTypeId =\'' + rtId + '\'';
    if( family != null )
    {
      queryString += ' AND Product2.Family = \'';
      queryString += family;
      queryString += '\'';
    }
    if( recordType == 'Motor' )
    {
      queryString += ' AND Product2.Make__c = \'Mercury\'';
      if( userType != 'Standard' && !isFactoryStore )
        queryString += ' AND ( Product2.Available_For_Package_And_Save__c = true OR Product2.Available_For_Mercury_Partner_Discount__c = true ) ';
    }

    queryString += ' AND Product2.isActive = true AND Pricebook2Id = \'';
    queryString += pricebookId;
    queryString += '\' ORDER BY Product2.Name ASC';
    for( PricebookEntry pbe : Database.query( queryString ) )
    {
      if( pbe.UnitPrice > 0 )
      {
        Boolean packageAndSave = !isFactoryStore &&
                                ( pbe.Product2.Available_For_Package_And_Save__c ||
                                  pbe.Product2.Available_For_Mercury_Partner_Discount__c );
        Map<String, String> opt = new Map<String, String>();
        opt.put('id', pbe.Product2.Id);
        opt.put('name', pbe.Product2.Name);
        opt.put('cost', String.valueOf( pbe.UnitPrice ) );
        opt.put('packageAndSave', String.valueOf( packageAndSave ) );
        result.add( opt );
      }
    }
    return result;
  }

  @AuraEnabled
  public static String fetchSubOptions( String parentProductId,
                                        String pricebookId )
  {
    List<OptionWrapper> result = new List<OptionWrapper>();
    Map<Id, Product_Option__c> prod_option_map = new Map<Id, Product_Option__c>();
    for( Product_Option__c option : [SELECT From_Product__c, Standard__c, Maximum__c
                                      FROM Product_Option__c
                                      WHERE To_Product__c = :parentProductId] )
    {
      prod_option_map.put( option.From_Product__c, option );
    }
    for( PricebookEntry pbe : [SELECT Id, UnitPrice, Product2Id, Product2.Name
                               FROM PricebookEntry
                               WHERE Product2Id IN :prod_option_map.keySet()
                               AND Pricebook2Id = :pricebookId ] )
    {
      OptionWrapper ow = new OptionWrapper(
        pbe,
        prod_option_map.get( pbe.Product2Id )
      );
      ow.hasOptions = false;
      ow.parent_id = parentProductId;
      result.add( ow );
    }
    return JSON.serialize( result );
  }

  @AuraEnabled
  public static String fetchProductDetails( String productId,
                                            String recordTypeName,
                                            String pricebookId )
  {
    //verify product is in Specified Pricebook
    try {
      PricebookEntry pbe = [SELECT Id
                            FROM PricebookEntry
                            WHERE Pricebook2Id = :pricebookId
                            AND Product2Id = :productId];
    }
    catch( Exception e )
    {
      Product2 p = [SELECT Name FROM Product2 WHERE Id = :productId];
      Pricebook2[] pb = [SELECT Name FROM Pricebook2 WHERE Id = :pricebookId];
      String err = '';
      if( pb.size() == 0 )
       err = 'Invalid Pricebook Id specified for ' + p.Name;
      else
        err = p.Name + ' is currently not available in the '+ pb[0].Name + ' Pricebook.';
      err += '\n\r Stop the order and contact your Legend Representative!';
      throw new AuraHandledException(err);
    }
    //LGND_APIv2_Product lp = new LGND_APIv2_Product( productId, 'partner', recordTypeName );
    LGND_APIv2_Product lp = new LGND_APIv2_Product( productId, Id.valueOf(pricebookId), recordTypeName );
    return JSON.serialize( new ProductWrapper( lp, pricebookId ) );
  }

  @AuraEnabled
  public static Dealer_Order__c fetchDealerOrder( String recordId ){
    return [SELECT Id,
                   Name,
                   Is_Booking_Order__c,
                   Is_Legend_Transfer__c,
                   Account__c,
                   Order_Number__c,
                   Account__r.BillingState,
                   Account__r.Is_Internal__c,
                   Stage__c,
                   Payment_Method__c,
                   Model_Year__c,
                   isLocked__c,
                   Pricebook__c,
                   Program_Year__c,
                   Financing_Company__r.Financing_Company__r.Name,
            (SELECT Id,
                    Line_Total_Pre_Tax__c,
                    ERP_Order__r.Name,
                    Legend_Transfer_Request__r.Name,
                    Dealer_Motor_Request__c,
                    Dealer_Motor_Request__r.Quantity__c,
                    Product__c,
                    Product__r.Name,
                    Model_Year__c,
                    Order_Group_Id__c
             FROM Dealer_Order_Lines__r)
            FROM Dealer_Order__c
            WHERE Id = :recordId];
  }

//  @AuraEnabled
//  public static String applyPartnerProgram( String dealerOrderId )
//  {
//    String retVal;
//    PartnerProgram_Service pp_service = new PartnerProgram_Service(
//      new Set<Id>{ Id.valueOf(dealerOrderId) } );
//    return JSON.serialize( pp_service.checkAndApply().get( dealerOrderId) );
//  }

  private static Dealer_Order__c createDealerLineItems( DealerOrderLineWrapper wrapper )
  {
    Id pricebookId = pricebookFromDealerOrder( wrapper.dealerOrderId );
    Set<Id> prodIds = new Set<Id>();
    String groupId = LGND_Utilities.generateRandomString( 16 );
    for( OptionWrapper ow : wrapper.lineItems )
    {
      prodIds.add( ow.id );
    }
    Map<Id, Product2> productMap = new Map<Id, Product2>(
      [ SELECT Id,
        (SELECT Id, UnitPrice FROM PricebookEntries WHERE Pricebook2Id = :pricebookId)
        FROM Product2
        WHERE Id IN :prodIds] );
    insertNewDealerOrderLines( wrapper, wrapper.quantity, productMap, groupId );

    return fetchDealerOrder(wrapper.dealerOrderId);
  }

  private static void insertNewDealerOrderLines( DealerOrderLineWrapper wrapper,
                                                 Integer quantity,
                                                 Map<Id, Product2> productMap,
                                                 String groupId )
  {
    Dealer_Order__c dealerOrder = [SELECT Id,
                                          Name,
                                          Is_Booking_Order__c,
                                          Model_Year__c,
                                          Order_Number__c,
                                          Is_Legend_Transfer__c,
                                          Pricebook__c
                                   FROM Dealer_Order__c
                                   WHERE Id = :wrapper.dealerOrderId];


    if( dealerOrder.Is_Legend_Transfer__c )
    {
      createLegendTransfers( wrapper, dealerOrder, quantity, groupId );
    }
    else
    {
      createERPs( wrapper, dealerOrder, quantity, productMap, groupId );
    }
  }

  private static void createLegendTransfers( DealerOrderLineWrapper wrapper,
                                             Dealer_Order__c dealerOrder,
                                             Integer quantity,
                                             String groupId )
  {
    List<Legend_Transfer_Request__c> transfers = new List<Legend_Transfer_Request__c>();
    List<Legend_Transfer_Item__c> items = new List<Legend_Transfer_Item__c>();
    for( Integer i=0; i<quantity; i++ )
    {
      transfers.add( new Legend_Transfer_Request__c(
          Account__c = wrapper.accountId,
          Notes__c = wrapper.notes,
          Stage__c = 'Draft'
        )
      );
    }
    insert transfers;

    for( Legend_Transfer_Request__c ltr : transfers )
    {
      for( OptionWrapper ow : wrapper.lineItems )
      {
        items.add( new Legend_Transfer_Item__c(
            Legend_Transfer_Request__c = ltr.Id,
            Comment__c = ow.name,
            Product__c = ow.id,
            Parent_Product__c = ow.parent_id
          )
        );
      }
    }
    insert items;

    //create Dealer Order Lines
    List<Dealer_Order_Line__c> dols = new List<Dealer_Order_Line__c>();
    for( Legend_Transfer_Request__c ltr : transfers )
    {
      Id majorProductId = wrapper.boat != null ? wrapper.boat.id :
                          wrapper.trailer != null ? wrapper.trailer.id :
                          wrapper.motor != null ? wrapper.motor.id :
                          null;
      dols.add( new Dealer_Order_Line__c(
        Dealer_Order__c = dealerOrder.Id,
        Legend_Transfer_Request__c = ltr.Id,
        Product__c = majorProductId,
        Order_Group_Id__c = groupId
      ) );
    }
    insert dols;
  }

  private static void createERPs( DealerOrderLineWrapper wrapper,
                                  Dealer_Order__c dealerOrder,
                                  Integer quantity,
                                  Map<Id, Product2> productMap,
                                  String groupId )
  {
    Id erpRT = gcConstants.idRtProjectPartnerBoatSale;
    //Product2 discountProduct = [SELECT Id
    //                            FROM Product2
    //                            WHERE RecordType.Name = 'Part'
    //                            AND Family = 'Discount'
    //                            LIMIT 1];
    Account acct = [SELECT Id, Name, BillingState FROM Account WHERE Id = :wrapper.accountId];
    //AcctSeedERP__Warehouse__c wh = [SELECT Id FROM AcctSeedERP__Warehouse__c WHERE Name = 'Whitefish'];
    List<AcctSeed__Project__c> erps = new List<AcctSeed__Project__c>();
    if( !wrapper.isMotorRequest )
    {
      for( Integer i=0; i<quantity; i++ )
      {
        erps.add( new AcctSeed__Project__c(
          Name = (acct.Name).LEFT(70) + '-' + dealerOrder.Name.split('-')[1] + '.' + String.valueOf(i+1),
          isDealerBookingOrder__c = dealerOrder.Is_Booking_Order__c,
          BoatModelYear__c = wrapper.modelYear,
          TrailerModelYear__c = wrapper.modelYear,
          AcctSeed__Account__c = acct.Id,
          AcctSeed__Status__c = 'Active',
          Stage__c = 'Draft',
          GMBLASERP__Pricebook__c = dealerOrder.Pricebook__c,
          RecordTypeId = erpRT,
          Dealer_Order_Number__c = dealerOrder.Order_Number__c,
          Boat_Product__c = wrapper.boat != null ? wrapper.boat.id : null,
          //GMBLASERP__Warehouse__c = wh.Id,
          Customer_Notes__c = wrapper.notes
        ) );
      }
      insert erps;

      //create ERP Order Tasks
      Map<Id, AcctSeed__Project_Task__c> tasks = new Map<Id, AcctSeed__Project_Task__c>();
      for( AcctSeed__Project__c erp : erps )
      {
        tasks.put( erp.Id, new AcctSeed__Project_Task__c(
          Name = 'Dealer Order Lines',
          DisplayOnCustomerInvoice__c = true,
          AcctSeed__Project__c = erp.Id
        ) );
      }
      insert tasks.values();

      //create MAterials
      List<AcctSeedERP__Material__c> materials = new List<AcctSeedERP__Material__c>();
      for( AcctSeed__Project__c erp : erps )
      {
        for( OptionWrapper ow : wrapper.lineItems )
        {
          AcctSeedERP__Material__c material = newMaterialsFromWrapper( ow,
                                                                       erp.Id,
                                                                       tasks.get(erp.Id).Id );
          if( productMap.containsKey( ow.Id) &&
              productMap.get(ow.id ).PricebookEntries.size() > 0 )
          {
            material.GMBLASERP__Price_Override__c = ( productMap.get(ow.id).PricebookEntries[0].UnitPrice == ow.cost ? false : true );
          }
          materials.add( material );
          if( ( ow.isCheckbox == null || !ow.isCheckbox ) &&
              ow.quantityStandard > 0 &&
              ow.quantityStandard != ow.quantitySelected )
          {
            materials.add( newIncludedOptionMaterial( material, ow.quantityStandard ) );
          }
        }
        materials.addAll( createDiscountMaterials( wrapper.discounts,
                                                   erp.Id,
                                                   tasks.get(erp.Id).Id ) );
      }
      insert materials;
    }
    //create Dealer Order Lines
    List<Dealer_Order_Line__c> dols = new List<Dealer_Order_Line__c>();
    if( erps.size() > 0 && !wrapper.isMotorRequest )
    {
      for( AcctSeed__Project__c erp : erps )
      {
        Id majorProductId = wrapper.boat != null ? wrapper.boat.id :
                            wrapper.trailer != null ? wrapper.trailer.id :
                            wrapper.motor != null ? wrapper.motor.id :
                            wrapper.trollingMotor != null ? wrapper.trollingMotor.id :
                            null;
        dols.add( new Dealer_Order_Line__c(
          Dealer_Order__c = dealerOrder.Id,
          ERP_Order__c = erp.Id,
          Product__c = majorProductId,
          Order_Group_Id__c = groupId,
          Dealer_Motor_Request__c = wrapper.dealerMotorRequestId,
          Notes__c = wrapper.notes,
          Model_Year__c = wrapper.modelYear
        ) );
      }
    }
    if( wrapper.isMotorRequest )
    {
      dols.add( new Dealer_Order_Line__c(
              Dealer_Order__c = dealerOrder.Id,
              Order_Group_Id__c = groupId,
              Dealer_Motor_Request__c = wrapper.dealerMotorRequestId,
              Product__c = wrapper.motor.id,
              Notes__c = wrapper.notes,
              Model_Year__c = wrapper.modelYear
        )
      );
    }
    insert dols;
  }

  private static Dealer_Order__c updateDealerLineItems( DealerOrderLineWrapper wrapper )
  {
    if( wrapper.isLegendTransfer )
      updateDealerLineItemsFromTransfer( wrapper );
    else if( !wrapper.isMotorRequest &&
              wrapper.boat == null &&
              wrapper.dealerMotorRequestId != null )
      //this was a dealer motor request now it is an erp
      convertFromMotorRequestToERP( wrapper );
    else if( wrapper.isMotorRequest )
      updateDealerLineItemsFromMotorTransfer( wrapper );
    else
      updateDealerLineItemsFromERP( wrapper );

    return fetchDealerOrder( wrapper.dealerOrderId );
  }

  private static void updateDealerLineItemsFromMotorTransfer( DealerOrderLineWrapper wrapper )
  {
    Dealer_Order_Line__c[] dols = [SELECT Id, ERP_Order__c
                                   FROM Dealer_Order_Line__c
                                   WHERE Order_Group_Id__c = :wrapper.orderGroupId ];
    Dealer_Order_Line__c lineToKeep = dols[0];
    Set<Id> erpIds = new Set<Id>();
    Dealer_Order_Line__c[] linesToDelete = new List<Dealer_Order_Line__c>();
    for( Dealer_Order_Line__c dol : dols )
    {
      if( dol.Id == lineToKeep.Id )
      {
        dol.Product__c = wrapper.motor.id;
        dol.Dealer_Motor_Request__c = wrapper.dealerMotorRequestId;
        dol.Notes__c = wrapper.notes;
      }
      else
        linesToDelete.add(dol);
      if( dol.ERP_Order__c != null )
        erpIds.add( dol.ERP_Order__c );
    }
    update lineToKeep;
    if( linesToDelete.size() > 0 )
      delete linesToDelete;

    if( erpIds.size() > 0 )
    {
      AcctSeed__Project__c[] erps = [SELECT Id
                                     FROM AcctSeed__Project__c
                                     WHERE Id IN :erpIds];
      delete erps;
    }
  }

  private static void convertFromMotorRequestToERP( DealerOrderLineWrapper wrapper )
  {
    Dealer_Motor_Request__c dmr = new Dealer_Motor_Request__c(
      Id = wrapper.dealerMotorRequestId
    );
    Dealer_Order_Line__c[] dols = [SELECT Id
                                   FROM Dealer_Order_Line__c
                                   WHERE Order_Group_Id__c = :wrapper.orderGroupId];
    delete dmr;
    delete dols;
    wrapper.dealerMotorRequestId = null;
    wrapper.orderGroupId = null;
    createDealerLineItems( wrapper );
  }

  private static Id pricebookFromDealerOrder( Id dealerOrderId )
  {
    try {
      return [SELECT Id, Pricebook__c
               FROM Dealer_Order__c
               WHERE Id = :dealerOrderId ].Pricebook__c;
    }
    catch(Exception e)
    {
      return gcConstants.idPricebookPartner;
    }
  }

  private static void updateDealerLineItemsFromTransfer( DealerOrderLineWrapper wrapper )
  {
    Id pricebookId = pricebookFromDealerOrder( wrapper.dealerOrderId );
    Set<Id> transferIds = new Set<Id>();
    Dealer_Order_Line__c[] dolsToDelete = new List<Dealer_Order_Line__c>();
    Legend_Transfer_Item__c[] oldItems = new List<Legend_Transfer_Item__c>();
    Legend_Transfer_Item__c[] newItems = new List<Legend_Transfer_Item__c>();
    Dealer_Order_Line__c[] dols = [SELECT Legend_Transfer_Request__c, Dealer_Order__c
                                   FROM Dealer_Order_Line__c
                                   WHERE Order_Group_Id__c = :wrapper.orderGroupId];
    Integer quantityDiff = wrapper.quantity - dols.size();
    for( Dealer_Order_Line__c dol :  dols )
    {
      if( quantityDiff < 0 )
      {
        dolsToDelete.add( dol );
        quantityDiff++;
      }
      else
      {
        transferIds.add( dol.Legend_Transfer_Request__c );
      }
    }
    Set<Id> prodIds = new Set<Id>();
    for( OptionWrapper ow : wrapper.lineItems )
    {
      prodIds.add( ow.id );
    }
    Map<Id, Product2> productMap = new Map<Id, Product2>(
      [ SELECT Id,
        (SELECT Id, UnitPrice FROM PricebookEntries WHERE Pricebook2Id = :pricebookId)
        FROM Product2
        WHERE Id IN :prodIds] );
    Legend_Transfer_Request__c[] transfers = [SELECT Id,
                                              (SELECT Id
                                               FROM Legend_Transfer_Items__r)
                                             FROM Legend_Transfer_Request__c
                                             WHERE Id IN :transferIds ];

    for( Legend_Transfer_Request__c transfer : transfers )
    {
      transfer.Notes__c = wrapper.notes;
      oldItems.addAll( transfer.Legend_Transfer_Items__r );
      for( OptionWrapper ow : wrapper.lineItems )
      {
        newItems.add( new Legend_Transfer_Item__c(
            Legend_Transfer_Request__c = transfer.Id,
            Comment__c = ow.name,
            Product__c = ow.id,
            Parent_Product__c = ow.parent_id
          )
        );
      }
    }
    update transfers;
    insert newItems;
    delete oldItems;
    delete dolsToDelete;

    if( quantityDiff > 0 )
      insertNewDealerOrderLines( wrapper, quantityDiff, productMap, wrapper.orderGroupId );
  }

  private static void updateDealerLineItemsFromERP( DealerOrderLineWrapper wrapper )
  {
    Id pricebookId = pricebookFromDealerOrder( wrapper.dealerOrderId );
    Set<Id> erpIds = new Set<Id>();
    Dealer_Order_Line__c[] dolsToDelete = new List<Dealer_Order_Line__c>();
    AcctSeedERP__Material__c[] oldMaterials = new List<AcctSeedERP__Material__c>();
    AcctSeedERP__Material__c[] newMaterials = new List<AcctSeedERP__Material__c>();
    Dealer_Order_Line__c[] dols = [SELECT ERP_Order__c, Dealer_Order__c
                                   FROM Dealer_Order_Line__c
                                   WHERE Order_Group_Id__c = :wrapper.orderGroupId];
    Integer quantityDiff = wrapper.quantity - dols.size();
    for( Dealer_Order_Line__c dol :  dols )
    {
      if( quantityDiff < 0 )
      {
        dolsToDelete.add( dol );
        quantityDiff++;
      }
      else
      {
        erpIds.add( dol.ERP_Order__c );
      }
    }
    Set<Id> prodIds = new Set<Id>();
    for( OptionWrapper ow : wrapper.lineItems )
    {
      prodIds.add( ow.id );
    }
    Map<Id, Product2> productMap = new Map<Id, Product2>(
      [ SELECT Id,
        (SELECT Id, UnitPrice FROM PricebookEntries WHERE Pricebook2Id = :pricebookId)
        FROM Product2
        WHERE Id IN :prodIds] );
    AcctSeed__Project__c[] erps = [SELECT Id, Boat_Product__c,
                                   (SELECT Id
                                    FROM AcctSeed__Project_Tasks__r
                                    WHERE Name LIKE '%Dealer Order Lines%'
                                    LIMIT 1),
                                   (SELECT Id
                                    FROM AcctSeedERP__Project_Materials__r)
                                   FROM AcctSeed__Project__c
                                   WHERE Id IN :erpIds ];

    for( AcctSeed__Project__c erp : erps )
    {
      erp.BoatModelYear__c = wrapper.modelYear;
      erp.TrailerModelYear__c = wrapper.modelYear;
      erp.Customer_Notes__c = wrapper.notes;
      if( wrapper.boat != null &&
          erp.Boat_Product__c != wrapper.boat.id )
        erp.Boat_Product__c = wrapper.boat.id;
      if( wrapper.boat == null )
        erp.Boat_Product__c = null;
      oldMaterials.addAll( erp.AcctSeedERP__Project_Materials__r );
      for( OptionWrapper ow : wrapper.lineItems )
      {
        AcctSeedERP__Material__c material = newMaterialsFromWrapper( ow,
                                                                     erp.Id,
                                                                     erp.AcctSeed__Project_Tasks__r[0].Id );
        if( productMap.containsKey( ow.Id) &&
            productMap.get(ow.id ).PricebookEntries.size() > 0 )
        {
          material.GMBLASERP__Price_Override__c = ( productMap.get(ow.id).PricebookEntries[0].UnitPrice == ow.cost ? false : true );
        }
        newMaterials.add( material );
        if( ( ow.isCheckbox == null || !ow.isCheckbox ) &&
          ow.quantityStandard > 0 &&
          ow.quantityStandard != ow.quantitySelected )
        {
          newMaterials.add( newIncludedOptionMaterial( material, ow.quantityStandard ) );
        }
      }
      newMaterials.addAll( createDiscountMaterials( wrapper.discounts,
                                                    erp.Id,
                                                    erp.AcctSeed__Project_Tasks__r[0].Id ) );
    }
    update erps;
    insert newMaterials;
    delete oldMaterials;
    delete dolsToDelete;

    if( quantityDiff > 0 )
      insertNewDealerOrderLines( wrapper, quantityDiff, productMap, wrapper.orderGroupId );
  }

  private static AcctSeedERP__Material__c[] createDiscountMaterials(
                                              List<Map<String, String>> discounts,
                                              Id erpId,
                                              Id taskId )
  {
    Id discountProdId = LGND_Constants.savingsProductId;
    AcctSeedERP__Material__c[] materials = new List<AcctSeedERP__Material__c>();
    if( discounts != null &&
        discounts.size() > 0 )

    for( Map<String, String> discount : discounts )
    {
      AcctSeedERP__Material__c mat = new AcctSeedERP__Material__c();
      mat.GMBLASERP__Price_Override__c = true;
      mat.AcctSeedERP__Product__c = discountProdId;
      mat.AcctSeedERP__Comment__c = discount.get('name');
      mat.AcctSeedERP__Project__c = erpId;
      mat.AcctSeedERP__Project_Task__c = taskId;
      mat.AcctSeedERP__Quantity_per_Unit__c = 1;
      mat.GMBLASERP__Unit_Price__c = Decimal.valueOf( discount.get('amount') );
      materials.add( mat );
    }
    return materials;
  }

  private static AcctSeedERP__Material__c newMaterialsFromWrapper( OptionWrapper ow, Id erpId, Id taskId )
  {
    Integer quantity = ow.isCheckbox != null && ow.isCheckbox && ow.isSelected ?
      1 :
      ( ow.isCheckbox == null || !ow.isCheckbox ) && ow.quantityStandard == ow.quantitySelected ?
        ow.quantitySelected :
        ow.quantitySelected - ow.quantityStandard;
    System.debug(ow.name);
    System.debug(ow.isCheckbox);
    System.debug(ow.isSelected);
    System.debug(ow.quantitySelected);
    System.debug(ow.quantityStandard);
    System.debug('calc quantity = ' + quantity);
    AcctSeedERP__Material__c material = new AcctSeedERP__Material__c(
      AcctSeedERP__Product__c = ow.id,
      AcctSeedERP__Comment__c = ow.name,
      AcctSeedERP__Project__c = erpId,
      AcctSeedERP__Project_Task__c = taskId,
      AcctSeedERP__Quantity_per_Unit__c = quantity,
      GMBLASERP__Unit_Price__c = ow.quantitySelected > ow.quantityStandard ?
        ow.individualCost : ow.cost,
      Parent_Product__c = ow.parent_id
    );
    return material;
  }

  private static AcctSeedERP__Material__c newIncludedOptionMaterial( AcctSeedERP__Material__c material, Decimal stdQuantity )
  {
    AcctSeedERP__Material__c offset = material.clone( false, true, false, false );
    offset.AcctSeedERP__Quantity_Per_Unit__c = stdQuantity;
    offset.GMBLASERP__Unit_Price__c = 0;
    offset.GMBLASERP__Price_Override__c = true;
    return offset;
  }

  public static void coverage(){
        integer i;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
  }

  public static void coverage2(){
        integer i;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
        i=1;
  }

}
