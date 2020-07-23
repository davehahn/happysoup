/**
 * Created by dave on 2020-01-28.
 */

public with sharing class CommissionLineItem2_Service
{
  public static Decimal grossMarginRate = 0.10;
  public static Decimal insuranceRate = 0.30;
  public static Decimal warrantyRate = 0.30;
  public static Decimal protectionAndServiceRate = 0.30;
  public static Decimal partsRate = 0.05;
  public static Decimal packageBundleRate = 0.05;
  public static Decimal maintenancePackageRate = 0.05;

  public class RateCostCalculator
  {
    public List<CommissionLineItem2__c> lineItems;
    private Set<Id> prodIds;
    private Set<Id> comRecIds;
    private Set<Id> factoryPbIds;
    private Set<String> provinces;
    private Map<Id, CommissionRecord2__c> commissionRecord_map;
    private Map<Id, Product2> protectionAndServicesProducts;
    private Map<Id, Product2> warrantyProducts;
    private Map<Id, Product2> insuranceProducts;
    private Map<Id, Product2> maintenancePackages;
    private Map<Id, Product2> packageBundles;
    private Map<Id, Product2> feeProducts;
    private Map<String, Decimal> feeCostAmount;
    private Map<String, Decimal> product_cost_map;

    public RateCostCalculator( List<CommissionLineItem2__c> lineItems )
    {
      this.lineItems = lineItems;
      init();
    }

    public void calculate( CommissionLineItem2__c cli )
    {
      Decimal cost = 0;
      Decimal rate = partsRate;
      Boolean paymentBasedOnProfit = false;
      CommissionRecord2__c comRec = this.commissionRecord_map.get( cli.CommissionRecord2__c);

      if( cli.Product__c != null )
      {
        String factoryPB_Product_Key = String.valueOf(comRec.Factory_Pricebook__c);
        factoryPB_Product_Key += ':';
        factoryPB_Product_Key += String.valueOf(cli.Product__c);
        if( this.product_cost_map.containsKey(factoryPB_Product_Key) )
        {
          cost = this.product_cost_map.get(factoryPB_Product_Key);
        }
        if( this.warrantyProducts.containsKey( cli.Product__c ) )
        {
          rate = warrantyRate;
          paymentBasedOnProfit = true;
        }
        else if( this.maintenancePackages.containsKey( cli.Product__c ) )
        {
          rate = maintenancePackageRate;
          paymentBasedOnProfit = true;
        }
        else if( this.protectionAndServicesProducts.containsKey( cli.Product__c ) )
        {
          rate = protectionAndServiceRate;
          paymentBasedOnProfit = true;
        }
        else if( this.packageBundles.containsKey( cli.Product__c ) )
        {
          rate = packageBundleRate;
        }
        else if( this.insuranceProducts.containsKey( cli.Product__c ) )
        {
          Product2 insuranceP = this.insuranceProducts.get( cli.Product__c );
          Decimal profitPercent = ( insuranceP.Insurance_Profit_Percent_Override__c != null &&
                                    insuranceP.Insurance_Profit_Percent_Override__c > 0 ) ?
                                  insuranceP.Insurance_Profit_Percent_Override__c :
                                  insuranceP.InsurancePlan__r.Profit_Percent__c;
          cost = cli.Sale_Price__c * ( ( 100 - profitPercent ) / 100 );
          rate = insuranceRate;
          paymentBasedOnProfit = true;
        }
        else
        {
          if( comRec.Calculation_Method__c == 'Gross Margin' )
          {
            rate = grossMarginRate;
            paymentBasedOnProfit = true;
          }
          factoryPB_Product_Key += ':' + comRec.TaxProvince__c;
          if( this.feeCostAmount.containsKey( factoryPB_Product_Key ) )
          {
            cost = this.feeCostAmount.get( factoryPB_Product_Key );
          }
        }
      }
      cli.Cost__c = cost;
      cli.Commission_Rate__c = rate;
      cli.Payment_Based_on_Profit__c = paymentBasedOnProfit;
    }

    private void init()
    {
      sortCommissionRecordAndProductIds();
      handleCommissionRecords();
      fetchAndSortProducts();
      handleFeeAmounts();
      setupFactoryCosts();
    }

    private void sortCommissionRecordAndProductIds()
    {
      this.prodIds = new Set<Id>();
      this.comRecIds = new Set<Id>();
      for( CommissionLineItem2__c cli : this.lineItems )
      {
        this.comRecIds.add( cli.CommissionRecord2__c );
        if( cli.Product__c != null )
        {
          this.prodIds.add( cli.Product__c );
        }
      }
    }

    private void handleCommissionRecords()
    {
      this.factoryPbIds = new Set<Id>();
      this.provinces = new Set<String>();
      this.commissionRecord_map = new Map<Id,CommissionRecord2__c>();
      for( CommissionRecord2__c cr : CommissionRecord2_Selector.allById( this.comRecIds ) )
      {
        this.factoryPbIds.add( cr.Factory_Pricebook__c );
        this.commissionRecord_map.put( cr.Id, cr );
        this.provinces.add( cr.TaxProvince__c );
      }
    }

    private void fetchAndSortProducts()
    {
      this.protectionAndServicesProducts = new Map<Id, Product2>();
      this.warrantyProducts = new Map<Id, Product2>();
      this.insuranceProducts = new Map<Id, Product2>();
      this.maintenancePackages = new Map<Id, Product2>();
      this.packageBundles = new Map<Id, Product2>();
      this.feeProducts = new Map<Id, Product2>();
      for( Product2 p : [ SELECT Id,
                                  Insurance_Profit_Percent_Override__c,
                                  InsurancePlan__c,
                                  InsurancePlan__r.Profit_Percent__c,
                                  RecordTypeId,
                                  Family
                                FROM Product2
                                WHERE Id IN :this.prodIds ] )
      {
        if( p.InsurancePlan__c != null)
        {
          this.insuranceProducts.put(p.Id, p);
        }
        else if( p.Family != null && p.Family.contains('Warranty') )
        {
          this.warrantyProducts.put( p.Id, p );
        }
        else if( p.RecordTypeId == LGND_Constants.productRtId_Bundle )
        {
          this.packageBundles.put( p.Id, p );
        }
        else if( p.Family != null && p.Family.contains('Maintenance Package') )
        {
          this.maintenancePackages.put( p.Id, p );
        }
        else if( p.RecordTypeId == LGND_Constants.productRtId_Protection )
        {
          this.protectionAndServicesProducts.put(p.Id, p);
        }
        else if( p.RecordTypeId == LGND_Constants.productRtId_Fees )
        {
          this.feeProducts.put( p.Id, p );
        }
      }
    }

    private void handleFeeAmounts()
    {
      this.feeCostAmount = new Map<String, Decimal>();
      for( Product_Fee_Amount__c pfa : [ SELECT Id,
        Fee_Product__c,
        Price_Book__c,
        Province__c,
        Amount__c
      FROM Product_Fee_Amount__c
      WHERE Fee_Product__c IN :this.feeProducts.keySet()
      AND Province__c IN :this.provinces
      AND Price_Book__c IN :this.factoryPbIds] )
      {
        String key = String.valueOf( pfa.Price_Book__c ) + ':' + String.valueOf( pfa.Fee_Product__c ) + ':' + pfa.Province__c;
        this.feeCostAmount.put( key, pfa.Amount__c );
      }
    }

    private void setupFactoryCosts()
    {
      this.product_cost_map = new Map<String, Decimal>();
      for( PricebookEntry pbe : [SELECT Pricebook2Id,
        Product2Id,
        UnitPrice
      FROM PricebookEntry
      WHERE Pricebook2Id IN :this.factoryPbIds
      AND Product2Id IN :this.prodIds ] )
      {
        String key = String.valueOf( pbe.Pricebook2Id ) + ':' + String.valueOf( pbe.Product2Id );
        this.product_cost_map.put( key, pbe.UnitPrice );
      }
    }
  }

  public Set<Id> allMaterialIds;
  public Map<Id, Set<AcctSeedERP__Material__c>> taskId_materials_map;
  public List<CommissionLineItem2__c> lineItems;
  private Map<Id, Id> taskId_ComRecId_map;

  public CommissionLineItem2_Service()
  {
    this.allMaterialIds = new Set<Id>();
    this.taskId_materials_map = new Map<Id, Set<AcctSeedERP__Material__c>>();
    this.lineItems = new List<CommissionLineItem2__c>();
    this.taskId_ComRecId_map = new Map<Id, Id>();
  }

  public void addMaterials(Set<Id> materialIds)
  {
    this.allMaterialIds.addAll( materialIds );
    //addMaterials( Material_Selector.selectAllByIds( materialIds ) );
  }

  public void addMaterials( List<AcctSeedERP__Material__c> materials )
  {
    this.allMaterialIds.addAll(
      LGND_Utilities.getIdSetFromList(
        (List<SObject>)materials
      )
    );
  }

  public void saveRecords()
  {
    processMaterials();
    Map<Id, Id> mat2cli_map = checkForCurrentCommissionLineItems();
    for( Id taskId : this.taskId_materials_map.keySet() )
    {
      for( AcctSeedERP__Material__c mat : this.taskId_materials_map.get( taskId ) )
      {
        if( this.taskId_ComRecId_map.containsKey( taskId) )
        {
          CommissionLineItem2__c cli = new CommissionLineItem2__c(
            CommissionRecord2__c = this.taskId_ComRecId_map.get(taskId),
            Product__c = mat.AcctSeedERP__Product__c,
            Quantity__c = mat.AcctSeedERP__Quantity_Per_Unit__c,
            Sale_Price__c = mat.GMBLASERP__Unit_Price__c,
            Material__c = mat.Id,
            Comment__c = mat.AcctSeedERP__Comment__c
          );
          if (mat2cli_map.containsKey(mat.Id))
          {
            cli.Id = mat2cli_map.get(mat.Id);
          }
          this.lineItems.add(cli);
        }
      }
    }

    upsert this.lineItems;
  }

  public void deleteRecords()
  {
    delete [ SELECT Id FROM CommissionLineItem2__c WHERE Material__c IN :this.allMaterialIds ];
  }

  public void recalculate( Set<Id> commissionRecordIds )
  {
    List<CommissionLineItem2__c> lineItems = [ SELECT Id FROM CommissionLineItem2__c WHERE CommissionRecord2__c IN :commissionRecordIds ];
    update lineItems;
  }

  private void processMaterials()
  {
    Set<Id> nonRevenueRtIds = new Set<Id>{
      LGND_Constants.productRtId_Protection,
      LGND_Constants.productRtId_Bundle
    };
    Set<Id> taskIds_toFindComRecord = new Set<Id>();
    for( AcctSeedERP__Material__c mat :  Material_Selector.selectAllByIds( this.allMaterialIds ) )
    {
      if( mat.Material__c == null && // added to ignore any kit parts
          ( mat.AcctSeedERP__Product__r.AcctSeed__Revenue_GL_Account__r.AcctSeed__Type__c == 'Revenue' ||
            ( nonRevenueRtIds.contains( mat.AcctSeedERP__Product__r.RecordTypeId ) &&
              mat.AcctSeedERP__Product__r.Family == 'Maintenance Package')
          )
        )
      {
        if( mat.AcctSeedERP__Project_Task__r.Commission_Override_Project_Task__c != null )
        {
          if (!this.taskId_materials_map.containsKey(mat.AcctSeedERP__Project_Task__r.Commission_Override_Project_Task__c))
          {
            taskIds_toFindComRecord.add(mat.AcctSeedERP__Project_Task__r.Commission_Override_Project_Task__c);
            this.taskId_materials_map.put(mat.AcctSeedERP__Project_Task__r.Commission_Override_Project_Task__c, new Set<AcctSeedERP__Material__c>());
          }
          this.taskId_materials_map.get(mat.AcctSeedERP__Project_Task__r.Commission_Override_Project_Task__c).add(mat);
        }
        else
        {
          if (!this.taskId_materials_map.containsKey(mat.AcctSeedERP__Project_Task__c))
          {
            taskIds_toFindComRecord.add(mat.AcctSeedERP__Project_Task__c);
            this.taskId_materials_map.put(mat.AcctSeedERP__Project_Task__c, new Set<AcctSeedERP__Material__c>());
          }
          this.taskId_materials_map.get(mat.AcctSeedERP__Project_Task__c).add(mat);
        }
      }
    }
    if( taskIds_toFindComRecord.size() > 0 )
    {
      for( CommissionRecord2__c cr : [ SELECT Id,
                                              Project_Task__c
                                            FROM CommissionRecord2__c
                                            WHERE Project_Task__c IN :taskIds_toFindComRecord ] )
      {
        this.taskId_ComRecId_map.put( cr.Project_Task__c, cr.Id );
      }
    }
  }

  private Map<Id,Id> checkForCurrentCommissionLineItems()
  {
    Map<Id, Id> result = new Map<Id, Id>();
    for( CommissionLineItem2__c cli : [ SELECT Id, Material__c
                                        FROM CommissionLineItem2__c
                                        WHERE Material__c IN :this.allMaterialIds ] )
    {
      result.put( cli.Material__c, cli.Id );
    }
    return result;
  }

  //STATICS

  public static void syncMaterials( List<AcctSeedERP__Material__c> triggerNew,
                                    Map<Id, AcctSeedERP__Material__c> triggerOldMap )
  {
    Set<Id> changedMatIds = new Set<Id>();
    for( AcctSeedERP__Material__c mat : triggerNew )
    {
      AcctSeedERP__Material__c oldMat = triggerOldMap.get( mat.Id );
      if( mat.AcctSeedERP__Quantity_Per_Unit__c != oldMat.AcctSeedERP__Quantity_Per_Unit__c ||
          mat.GMBLASERP__Unit_Price__c != oldMat.GMBLASERP__Unit_Price__c ||
          mat.AcctSeedERP__Comment__c != oldMat.AcctSeedERP__Comment__c )
      {
        changedMatIds.add( mat.Id );
      }
    }
    if( changedMatIds.size() > 0 )
    {
      doMaterialSync( changedMatIds );
    }
  }

  public static void createDefaultLineItems( List<CommissionRecord2__c> commissionRecords )
  {
    List<CommissionLineItem2__c> defaults = new List<CommissionLineItem2__c>();
    for( CommissionRecord2__c record : commissionRecords )
    {
      if( record.Department_GLV2__c == LGND_Constants.GLV2Id_BusinessOffice )
      {
        defaults.add( new CommissionLineItem2__c(
          Description__c = 'Admin Fee',
          Quantity__c = 1,
          Sale_Price__c = 199,
          Cost__c = 0,
          Labour_Cost__c = 0,
          CommissionRecord2__c = record.Id,
          Commission_Rate__c = 0.20
        ));
        defaults.add( new CommissionLineItem2__c(
          Description__c = 'Bank Reserve',
          Quantity__c = 1,
          Sale_Price__c = 0,
          Cost__c = 0,
          Labour_Cost__c = 0,
          CommissionRecord2__c = record.Id,
          Commission_Rate__c = 0.20
        ));
      }
    }
    if( defaults.size() > 0 )
    {
      insert defaults;
    }
  }

  public static void makeChatterPostsAboutChanges( Map<Id, List<String>> changeMap )
  {
    List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();
    for( Id comRecId : changeMap.keySet() )
    {
      ConnectApi.BatchInput bi = new ConnectApi.BatchInput(
        buildChangesChatterPost( comRecId, changeMap.get( comRecId) )
      );
      batchInputs.add( bi );
    }
    if( batchInputs.size() > 0 && !Test.isRunningTest() )
    {
      ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), batchInputs);
    }
  }

  public static void syncToMaterials( List<AcctSeedERP__Material__c> changedMaterials )
  {
    doMaterialSync( LGND_Utilities.getIdSetFromList( changedMaterials ) );
  }

  private static ConnectApi.FeedItemInput buildChangesChatterPost( Id recordId, List<String> changes )
  {
    ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
    ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
    ConnectApi.MarkupBeginSegmentInput markupBeginSegment;
    ConnectApi.MarkupEndSegmentInput markupEndSegment;
    ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
    messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();


    /* HEADER */
    markupBeginSegment = new ConnectApi.MarkupBeginSegmentInput();
    markupBeginSegment.markupType = ConnectApi.MarkupType.Bold;
    messageBodyInput.messageSegments.add(markupBeginSegment);

    textSegment = new ConnectApi.TextSegmentInput();
    textSegment.text = 'The following changes where made:\n\n';
    messageBodyInput.messageSegments.add( textSegment );

    markupEndSegment = new ConnectApi.MarkupEndSegmentInput();
    markupEndSegment.markupType = ConnectApi.MarkupType.Bold;
    messageBodyInput.messageSegments.add(markupEndSegment);

    /* BLANK LINE */
    markupBeginSegment = new ConnectApi.MarkupBeginSegmentInput();
    markupBeginSegment.markupType = ConnectApi.MarkupType.Paragraph;
    messageBodyInput.messageSegments.add(markupBeginSegment);

    textSegment = new ConnectApi.TextSegmentInput();
    textSegment.text = '&nbsp;';
    messageBodyInput.messageSegments.add( textSegment );

    markupEndSegment = new ConnectApi.MarkupEndSegmentInput();
    markupEndSegment.markupType = ConnectApi.MarkupType.Paragraph;
    messageBodyInput.messageSegments.add(markupEndSegment);

    /* ACTUAL NOTES */

    /* begin unOrderedList */
    markupBeginSegment = new ConnectApi.MarkupBeginSegmentInput();
    markupBeginSegment.markupType = ConnectApi.MarkupType.UnorderedList;
    messageBodyInput.messageSegments.add(markupBeginSegment);

    /* create listItem for each change */
    for( String change: changes )
    {
      markupBeginSegment = new ConnectApi.MarkupBeginSegmentInput();
      markupBeginSegment.markupType = ConnectApi.MarkupType.ListItem;
      messageBodyInput.messageSegments.add(markupBeginSegment);
      textSegment = new ConnectApi.TextSegmentInput();
      textSegment.text = change;
      messageBodyInput.messageSegments.add( textSegment );
      markupEndSegment = new ConnectApi.MarkupEndSegmentInput();
      markupEndSegment.markupType = ConnectApi.MarkupType.ListItem;
      messageBodyInput.messageSegments.add(markupEndSegment);
    }

    markupEndSegment = new ConnectApi.MarkupEndSegmentInput();
    markupEndSegment.markupType = ConnectApi.MarkupType.UnorderedList;
    messageBodyInput.messageSegments.add(markupEndSegment);

    feedItemInput.body = messageBodyInput;
    feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
    feedItemInput.subjectId = recordId;
    return feedItemInput;
  }


  private static void doMaterialSync( Set<Id> matIds )
  {
    Map<Id, AcctSeedERP__Material__c> materialMap = Material_Selector.mapAllByIds( matIds );
    List<CommissionLineItem2__c> commLineItems =
      CommissionLineItem2_Selector.allByMaterialIds(
        matIds
      );
    if( commLineItems.size() > 0 )
    {
      for( CommissionLineItem2__c cli : commLineItems )
      {
        AcctSeedERP__Material__c mat = materialMap.get(cli.Material__c);
        cli.Quantity__c = mat.AcctSeedERP__Quantity_Per_Unit__c;
        cli.Sale_Price__c = mat.GMBLASERP__Unit_Price__c;
        cli.Comment__c = mat.AcctSeedERP__Comment__c;
      }
      update commLineItems;
    }
  }

}