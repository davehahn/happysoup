/**
 * Created by dave on 2019-11-06.
 */

public with sharing class Profit_Analysis_Controller
{
  public class Profit_Analysis_Exception extends Exception{}

  private static final Decimal riggingRate
  {
    get
    {
      if( riggingRate == null )
      {
        try
        {
          Labour_Rate__mdt rate = [SELECT Hourly_Rate__c FROM Labour_Rate__mdt WHERE DeveloperName = 'Retail'];
          riggingRate = rate.Hourly_Rate__c;
        }
        catch( Exception e )
        {
          throw new Profit_Analysis_Exception( 'No Retail Labour Rate set.  Please have your administrator set a Retail Labour rate in Labour Rates Custom Metadata Type');
        }
      }
      return riggingRate;
    }
    set;
  }

  public class DataWrapper implements Comparable
  {
    public Boolean include;
    public String id;
    public String productId;
    public String productRecordTypeId;
    public String productName;
    public String parentRecordId;
    public Decimal quantity;
    public Boolean isSerialized;
    public Decimal salePrice;
    public Decimal saleTotal;
    public Decimal costPrice;
    public Decimal costTotal;
    public Decimal factoryPb;
    public Decimal factoryPbTotal;
    public Decimal riggingTime;
    public Decimal riggingCost;
    public List<DataWrapper> kitParts;
    public String province;

    public DataWrapper( Product_Fee_Amount__c pfa )
    {
      this.include = true;
      this.quantity = 1;
      this.productName = pfa.Fee_Product__r.Name;
      this.salePrice = 0;
      this.saleTotal = 0;
      this.factoryPb = pfa.Amount__c;
      this.factoryPbTotal = pfa.Amount__c;
      this.riggingTime = 0;
      this.riggingCost = 0;
      this.kitParts = new List<DataWrapper>();
      this.province = pfa.Province__c;
    }

    public DataWrapper( OpportunityLineItem oli, Decimal riggingRate )
    {
      this.include = true;
      this.id = oli.Id;
      this.quantity = oli.Quantity;
      this.productId = oli.Product2Id;
      this.productName = oli.Product2.Name;
      this.productRecordTypeId = oli.Product2.RecordTypeId;
      this.isSerialized = oli.Product2.AcctSeedERP__Serialized__c;
      this.salePrice = oli.UnitPrice;
      this.saleTotal = oli.TotalPrice;
      this.costPrice = oli.Product2.Landed_Unit_Cost__c == null ? 0 : oli.Product2.Landed_Unit_Cost__c;
      this.costTotal = this.costPrice * this.quantity;
      this.factoryPb = 0;
      this.factoryPbTotal = 0;
      this.riggingTime = oli.Product2.Rigging_Time__c == null ? 0 : oli.Product2.Rigging_Time__c;
      this.riggingCost = this.riggingTime * riggingRate;
      this.kitParts = new List<DataWrapper>();
    }

    public DataWrapper( AcctSeedERP__Material__c mat, Decimal riggingRate )
    {
      this.include = true;
      this.id = mat.Id;
      this.parentRecordId = mat.Material__c;
      this.quantity = mat.AcctSeedERP__Quantity_Per_Unit__c;
      this.productId = mat.AcctSeedERP__Product__c;
      this.productName = mat.AcctSeedERP__Product__r.Name;
      this.productRecordTypeId = mat.AcctSeedERP__Product__r.RecordTypeId;
      this.isSerialized = mat.AcctSeedERP__Product__r.AcctSeedERP__Serialized__c;
      this.salePrice = mat.GMBLASERP__Unit_Price__c;
      this.saleTotal = mat.GMBLASERP__Total_Price__c;
      this.costPrice = mat.AcctSeedERP__Product__r.Landed_Unit_Cost__c == null ? 0 : mat.AcctSeedERP__Product__r.Landed_Unit_Cost__c;
      this.costTotal = this.costPrice * this.quantity;
      this.factoryPb = 0;
      this.factoryPbTotal = 0;
      this.riggingTime = mat.AcctSeedERP__Product__r.Rigging_Time__c == null ? 0 : mat.AcctSeedERP__Product__r.Rigging_Time__c;
      this.riggingCost = this.riggingTime * riggingRate;
      this.kitParts = new List<DataWrapper>();
    }

    public Integer compareTo( Object compareTo )
    {
      DataWrapper compareOW = (DataWrapper)compareTo;
      if( productName == compareOW.productName ) return 0;
      if( productName > compareOW.productName ) return 1;
      return -1;
    }
  }

  public class ResultWrapper {
    public String pbId;
    public String currentProvince;
    public List<Map<String, String>> pbOptions;
    public List<String> provinceOptions;
    public List<DataWrapper> saleItems;
    public List<DataWrapper> businessOfficeItems;
    public List<DataWrapper> items;
    private Set<Id> businessOfficeProductRTs = new Set<Id>{
      LGND_Constants.productRtId_Protection,
      LGND_Constants.productRtId_Bundle,
      LGND_Constants.productRtId_Insurance
    };
    private String sObjectId;
    private String sObjectName;
    private String pricebookName;

    public ResultWrapper( String recordId, String pbId, String province )
    {
      this.sObjectId = recordId;
      this.sObjectName = LGND_Utilities.sObjectNameFromId( Id.valueOf( recordId ) );
      this.pbOptions = new List<Map<String,String>>();
      this.items = new List<DataWrapper>();
      this.saleItems = new List<DataWrapper>();
      this.businessOfficeItems = new List<DataWrapper>();
      this.pbId = pbId;
      this.currentProvince = province;
      createOptions();
      findTheRecordAndSetDefaults();
      buildItems();
    }

    public void addItems( List<DataWrapper> items )
    {
      if( items != null )
        this.items.addAll( items );
    }

    public void setPricebookValuesOnItems()
    {
      Set<String> prodIds = new Set<String>();
      for( DataWrapper dw : this.items )
      {
        prodIds.add( dw.productId );
      }
      Map<Id, Decimal> prod_cost_map = findProductCost( prodIds, this.pbId );
      for( DataWrapper dw : this.items)
      {
        if( prod_cost_map.containsKey( dw.productId ) )
        {
          dw.factoryPb = prod_cost_map.get( dw.productId );
          dw.factoryPbTotal = dw.quantity * dw.factoryPb;
        }
      }
    }

    public void sortAndGroupItems()
    {
      List<DataWrapper> serialized = new List<DataWrapper>();
      List<DataWrapper> nonSerialized = new List<DataWrapper>();
      Map<String, List<DataWrapper>> parentId_item_map = new Map<String, List<DataWrapper>>();
      for( DataWrapper dw : this.items )
      {
        if( dw.parentRecordId != null )
        {
          if( !parentId_Item_map.containsKey( dw.parentRecordId ) )
            parentId_Item_map.put( dw.parentRecordId, new List<DataWrapper>() );
          parentId_Item_map.get( dw.parentRecordId ).add( dw );
        }
      }
      for( DataWrapper dw : this.items )
      {
        if (dw.parentRecordId == null)
        {
          if( parentId_item_map.containsKey( dw.id ) )
          {
            dw.kitParts.addAll(parentId_item_map.get(dw.id));
            dw.kitParts.sort();
          }
          if( dw.isSerialized )
            serialized.add( dw );
          else
            nonSerialized.add( dw );
        }
      }
      serialized.sort();
      nonSerialized.sort();
      this.items = new List<DataWrapper>();
      this.items.addAll( serialized );
      this.items.addAll( nonSerialized );
      this.separateByDepartments();
    }

    private void findTheRecordAndSetDefaults()
    {
      switch on this.sObjectName
      {
        when 'Opportunity'
        {
          Opportunity opp = [ SELECT Id, GL_Account_Variable_3__r.Name, Pricebook2.Name FROM Opportunity WHERE Id = :this.sObjectId ];
          this.pricebookName = opp.Pricebook2.Name;
          if( this.currentProvince == null )
          {
            this.currentProvince = opp.GL_Account_Variable_3__r.Name;
          }
        }
        when 'AcctSeed__Project__c'
        {
          AcctSeed__Project__c project = [ SELECT Id, GL_Account_Variable_3__r.Name, GMBLASERP__Pricebook__r.Name FROM AcctSeed__Project__c WHERE Id = :this.sObjectId ];
          this.pricebookName = project.GMBLASERP__Pricebook__r.Name;
          if( this.currentProvince == null )
          {
            this.currentProvince = project.GL_Account_Variable_3__r.Name;
          }
        }
      }
      if( this.currentProvince == null )
      {
        this.currentProvince = 'Ontario';
      }
      if( this.pbId == null )
      {
        setCurrentPb();
      }
    }

    private void setCurrentPB()
    {
      String recordPbYear =  findRecordPricebookYear();
      for(Map<String, String> pbOpt : this.pbOptions )
      {
        if(pbOpt.get('name').contains( recordPbYear) )
        {
          this.pbId = pbOpt.get('id');
          break;
        }
      }
      if( this.pbId == null )
      {
        this.pbId = Legend_Settings__c.getOrgDefaults().Default_Factory_Pricebook__c;
      }
    }

    private void separateByDepartments()
    {
      for( DataWrapper dw : this.items )
      {
        if( this.businessOfficeProductRTs.contains( dw.productRecordTypeId ) )
        {
          this.businessOfficeItems.add(dw);
        }
        else
        {
          this.saleItems.add(dw);
        }
      }
    }

    private void createOptions()
    {
      for( Pricebook2 pb : [SELECT Id, Name FROM Pricebook2 WHERE Name LIKE '%Factory%'] )
      {
        this.pbOptions.add( new Map<String, String>{
          'id' => pb.Id,
          'name' => pb.Name
        });
      }
      this.provinceOptions = LGND_Utilities.getPicklistValues('Product_Fee_Amount__c', 'Province__c' );
    }

    private String findRecordPricebookYear()
    {
      if( this.pricebookName != null )
      {
        try
        {
          return this.pricebookName.remove(' ').split('-')[0];
        }
        catch( Exception e ){}
      }
      return null;
    }

    private Map<Id, Decimal> findProductCost( Set<String> prodIds, String factoryPBId )
    {
      Map<Id, Decimal> result = new Map<Id, Decimal>();
      for( PricebookEntry pbe : [ SELECT Id, UnitPrice, Product2Id
                                  FROM PricebookEntry
                                  WHERE Pricebook2Id = :factoryPBId
                                  AND Product2Id IN :prodIds] )
      {
        result.put( pbe.Product2Id, pbe.UnitPrice );
      }
      return result;
    }

    private void buildItems()
    {
      switch on this.sObjectName
      {
        when 'Opportunity'
        {
          this.addItems( buildForOpportunity() );
        }
        when 'AcctSeed__Project__c'
        {
          this.addItems( buildForERP() );
        }
      }
      this.sortAndGroupItems();
      this.setPricebookValuesOnItems();
      this.buildFreightCharges();
    }

    private void buildFreightCharges()
    {
      List<DataWrapper> freights = new List<DataWrapper>();
      Set<Id> productIds = new Set<Id>();
      Set<Id> feeProdIds = new Set<Id>();
      for( DataWrapper dw : this.items )
      {
        productIds.add( dw.productId );
      }
      for( Product_Fee_Map__c pfm : [ SELECT Id, Fee_Product__c, Fee_Product__r.Name
                                      FROM Product_Fee_Map__c
                                      WHERE Parent_Product__c IN :productIds
                                      AND Fee_Product__r.Family = 'Freight'] )
      {
        feeProdIds.add( pfm.Fee_Product__c );
      }
      for( Product_Fee_Amount__c pfa : [SELECT Id, Amount__c, Fee_Product__r.Name, Province__c
                                        FROM Product_Fee_Amount__c
                                        WHERE Fee_Product__c IN :feeProdIds
                                        AND Province__c = :this.currentProvince
                                        AND Price_Book__c = :this.pbId] )
      {
        freights.add( new DataWrapper( pfa ) );
      }
      this.items.addAll( freights );
      this.saleItems.addAll( freights );
    }

    private List<DataWrapper> buildForOpportunity()
    {
      List<DataWrapper> result = new List<DataWrapper>();
      List<OpportunityLineItem> olis = [ SELECT Id,
                                                Quantity,
                                                UnitPrice,
                                                TotalPrice,
                                                Product2Id,
                                                Product2.Name,
                                                Product2.RecordTypeId,
                                                Product2.Landed_Unit_Cost__c,
                                                Product2.Rigging_Time__c,
                                                Product2.AcctSeedERP__Serialized__c
                                          FROM OpportunityLineItem
                                          WHERE OpportunityId = :this.sObjectId
                                          AND Product2.AcctSeed__Revenue_GL_Account__r.AcctSeed__Type__c  = 'Revenue'];
      for( OpportunityLineItem oli : olis )
      {
        result.add( new DataWrapper( oli, riggingRate ) );
      }
      return result;
    }

    private List<DataWrapper> buildForERP()
    {
      List<DataWrapper> result = new List<DataWrapper>();
      List<AcctSeedERP__Material__c> materials = [ SELECT Id,
                                                          AcctSeedERP__Quantity_Per_Unit__c,
                                                          GMBLASERP__Unit_Price__c,
                                                          GMBLASERP__Total_Price__c,
                                                          AcctSeedERP__Product__c,
                                                          AcctSeedERP__Product__r.RecordTypeId,
                                                          AcctSeedERP__Product__r.AcctSeedERP__Serialized__c,
                                                          AcctSeedERP__Product__r.Rigging_Time__c,
                                                          AcctSeedERP__Product__r.Name,
                                                          AcctSeedERP__Product__r.Landed_Unit_Cost__c,
                                                          AcctSeedERP__Product__r.AcctSeed__Revenue_GL_Account__r.AcctSeed__Type__c,
                                                          Material__c
                                                        FROM AcctSeedERP__Material__c
                                                        WHERE AcctSeedERP__Project__c = :this.sObjectId
                                                        AND AcctSeedERP__Product__r.AcctSeed__Revenue_GL_Account__r.AcctSeed__Type__c  = 'Revenue'];
      for( AcctSeedERP__Material__c mat : materials )
      {
        result.add( new DataWrapper( mat, riggingRate ) );
      }
      return result;
    }
  }

  @AuraEnabled
  public static String fetchData( String recordId, String pbId, String province )
  {
    if( !LGND_Utilities.CustomPermissions.canViewGrossMargin )
      return 'denied';
    try
    {
      return JSON.serialize(new ResultWrapper(recordId, pbId, province) );
    }
    catch( Exception e )
    {
      AuraHandledException ae = new AuraHandledException( e.getMessage() );
      ae.setMessage( e.getMessage() );
      throw ae;
    }
  }

}