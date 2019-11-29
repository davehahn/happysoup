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
    public List<Map<String, String>> pbOptions;
    public List<DataWrapper> saleItems;
    public List<DataWrapper> businessOfficeItems;
    public List<DataWrapper> items;
    private Set<Id> businessOfficeProductRTs = new Set<Id>{
      LGND_Constants.productRtId_Protection,
      LGND_Constants.productRtId_Bundle,
      LGND_Constants.productRtId_Insurance
    };
    public ResultWrapper( String recordId, String pbId )
    {
      this.pbOptions = new List<Map<String,String>>();
      this.items = new List<DataWrapper>();
      this.saleItems = new List<DataWrapper>();
      this.businessOfficeItems = new List<DataWrapper>();
      this.pbId = pbId;
      if( this.pbId == null )
        createPbOptions( recordId );
      buildItems( recordId );
    }

    public void addPbOption( Pricebook2 pb )
    {
      this.pbOptions.add( new Map<String, String>{
        'id' => pb.Id,
        'name' => pb.Name
      });
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

    private void separateByDepartments()
    {
      for( DataWrapper dw : this.items )
      {
        if( this.businessOfficeProductRTs.contains( dw.productRecordTypeId ) )
          this.businessOfficeItems.add( dw );
        else
          this.saleItems.add( dw );
      }
    }

    private void createPbOptions( String recordId )
    {
      String recordPbYear =  findRecordPricebookYear( recordId );
      for( Pricebook2 pb : [SELECT Id, Name FROM Pricebook2 WHERE Name LIKE '%Factory%'] )
      {
        this.addPbOption( pb );
        if( recordPbYear != null && pb.Name.contains( recordPbYear ) )
        {
          this.pbId = pb.Id;
        }
      }
      if( this.pbId == null )
        this.pbId = Legend_Settings__c.getOrgDefaults().Default_Factory_Pricebook__c;
    }

    private String findRecordPricebookYear( String recordId )
    {
      String objType = LGND_Utilities.sObjectNameFromId( Id.valueOf( recordId ) );
      String pbName;
      switch on objType
      {
        when 'Opportunity'
        {
          try
          {
            pbName = [SELECT Pricebook2.Name FROM Opportunity WHERE Id = :recordId LIMIT 1].Pricebook2.Name;
          }
          catch( Exception e ){}
        }
        when 'AcctSeed__Project__c'
        {
          try
          {
            AcctSeed__Project__c erp = [SELECT GMBLASERP__Pricebook__r.Name FROM AcctSeed__Project__c WHERE Id = :recordId LIMIT 1];
            System.debug(erp.GMBLASERP__Pricebook__r.Name );
            pbName = erp.GMBLASERP__Pricebook__r.Name;
          }
          catch( Exception e ){}
        }
      }
      if( pbName != null )
      {
        try
        {
          return pbName.remove(' ').split('-')[0];
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

    private void buildItems( String recordId )
    {
      String objType = LGND_Utilities.sObjectNameFromId( Id.valueOf( recordId ) );
      switch on objType
      {
        when 'Opportunity'
        {
          this.addItems( buildForOpportunity( recordId ) );
        }
        when 'AcctSeed__Project__c'
        {
          this.addItems( buildForERP( recordId ) );
        }
      }
      this.setPricebookValuesOnItems();
      this.sortAndGroupItems();
    }

    private List<DataWrapper> buildForOpportunity( String recordId )
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
                                          WHERE OpportunityId = :recordId
                                          AND Product2.AcctSeed__Revenue_GL_Account__r.AcctSeed__Type__c  = 'Revenue'];
      for( OpportunityLineItem oli : olis )
      {
        result.add( new DataWrapper( oli, riggingRate ) );
      }
      return result;
    }

    private List<DataWrapper> buildForERP( String recordId )
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
                                                        WHERE AcctSeedERP__Project__c = :recordId
                                                        AND AcctSeedERP__Product__r.AcctSeed__Revenue_GL_Account__r.AcctSeed__Type__c  = 'Revenue'];
      for( AcctSeedERP__Material__c mat : materials )
      {
        result.add( new DataWrapper( mat, riggingRate ) );
      }
      return result;
    }
  }

  @AuraEnabled
  public static String fetchData( String recordId )
  {
    if( !LGND_Utilities.CustomPermissions.canViewGrossMargin )
      return 'denied';
    try
    {
      return JSON.serialize(new ResultWrapper(recordId, null));
    }
    catch( Exception e )
    {
      AuraHandledException ae = new AuraHandledException( e.getMessage() );
      ae.setMessage( e.getMessage() );
      throw ae;
    }
  }

  @AuraEnabled
  public static String updateData( String recordId, String pbId )
  {
    try
    {
      ResultWrapper rw = new ResultWrapper( recordId, pbId );
      return JSON.serialize( rw.items );
    }
    catch( Exception e )
    {
      AuraHandledException ae = new AuraHandledException( e.getMessage() );
      ae.setMessage( e.getMessage() );
      throw ae;
    }
  }

}