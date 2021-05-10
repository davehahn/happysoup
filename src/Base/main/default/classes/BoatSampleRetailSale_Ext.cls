public with sharing class BoatSampleRetailSale_Ext {

  public final ApexPages.StandardController stdController;
  public final Id recordId { get; set; }
  public Boat_Sample_Retail_Sale__c record { get; set; }
  public Boat_Sample_Retail_Sale_Example_Product__c[] exampleProducts { get; set; }
  public Map<Id, Product_Option__c> allOptions;
  public Map<Id, Product_Option__c> resultOptionsMap;
  public Boat_Sample_Retail_Sale_Example_Product__c[] exampleProductsToDelete;

	public BoatSampleRetailSale_Ext( ApexPages.StandardController std)
  {
		stdController = std;
    recordId = stdController.getId();
    fetchRecord();
    fetchOptionalProducts();
    resultOptionsMap = allOptions;
    exampleProductsToDelete = new List<Boat_Sample_Retail_Sale_Example_Product__c>();
	}

  public void productSearch()
  {
    resultOptionsMap = new Map<Id, Product_Option__c>();
    String queryString = ApexPages.currentPage().getParameters().get('qString');
    for( Product_Option__c po : allOptions.values() )
    {
      if( po.From_Product__r.Name.containsIgnoreCase(queryString) ||
          ( po.From_Product__r.Family != null &&
            po.From_Product__r.Family.containsIgnoreCase(queryString) )||
          po.From_Product__r.RecordType.Name.containsIgnoreCase(queryString) )
      {
        resultOptionsMap.put(po.Id, po);
      }
    }
  }

  public Product_Option__c[] getResultOptions()
  {
    if( exampleProducts.size() > 0 )
    {
      for( Boat_Sample_Retail_Sale_Example_Product__c xProd : exampleProducts )
      {
        if( resultOptionsMap.containsKey( xProd.Product_Option__c ) )
        {
          resultOptionsMap.remove(xProd.Product_Option__c);
        }
      }
    }
    Product_Option__c[] pos = resultOptionsMap.values();
    pos.sort();
    return pos;
  }

  public void selectProduct()
  {
    String poId = ApexPages.currentPage().getParameters().get('product_option_id');
    if( allOptions.containsKey(poId) )
    {
      Product_Option__c selected = allOptions.get(poId);
      exampleProducts.add(
        new Boat_Sample_Retail_Sale_Example_Product__c(
          Product_Option__c = selected.Id,
          Product_Option__r = selected,
          Sample_Retail_Sale__c = recordId
        )
      );
      allOptions.remove(poId);
      resultOptionsMap.remove(poId);
    }
  }

  public void removeProduct()
  {
    String poId = ApexPages.currentPage().getParameters().get('product_option_id');
    for( Integer i=0; i<exampleProducts.size(); i++ )
    {
      if( poId == exampleProducts[i].Product_Option__r.Id )
      {
        allOptions.put( poId, exampleProducts[i].Product_Option__r);
        resultOptionsMap.put( poId, exampleProducts[i].Product_Option__r);
        if( exampleProducts[i].Id != null )
        {
          exampleProductsToDelete.add( exampleProducts[i] );
        }
        exampleProducts.remove(i);
      }
    }
  }

  public PageReference save()
  {
    upsert record;
    Boat_Sample_Retail_Sale_Example_Product__c[] newXProds = new List<Boat_Sample_Retail_Sale_Example_Product__c>();
    for( Boat_Sample_Retail_Sale_Example_Product__c xProd : exampleProducts )
    {
      if( xProd.Sample_Retail_Sale__c == null )
      {
        xProd.Sample_Retail_Sale__c = record.Id;
      }
      if( xProd.Id == null )
      {
        newXProds.add(xProd);
      }
    }

    if( newXProds.size() > 0 )
    {
      insert newXProds;
    }
    if( exampleProductsToDelete.size() > 0 )
    {
      delete exampleProductsToDelete;
    }
    return new PageReference('/' + record.Boat__c );
  }





  private void fetchOptionalProducts()
  {
    Set<Id> selectedIds = new Set<Id>();
    allOptions = new Map<Id, Product_Option__c>(
                  [SELECT Id,
                         From_Product__c,
                         From_Product__r.Name,
                         From_Product__r.Family,
                         From_Product__r.RecordType.Name
                  FROM Product_Option__c
                  WHERE To_Product__c = :record.Boat__c]);
  }

  public List<String> fieldList() {
    List<String> fieldNames = new List<String>();
    Map<String, Schema.FieldSet> FsMap = Schema.SObjectType.Boat_Sample_Retail_Sale__c.FieldSets.getMap();
    for(String fsn : FsMap.keySet() ){
      for(Schema.FieldSetMember f : FsMap.get(fsn).getFields()){
        fieldNames.add(f.getFieldPath());
      }
    }
    fieldNames.add('Boat__r.Name');
    return fieldNames;
  }

  private void fetchRecord()
  {
    if( recordId != null )
    {
      record = [SELECT Id,
                       Boat__c,
                       Boat__r.Name,
                       Motor_Upgrade__c,
                       BatteryCost__c,
                       BoatShowDiscount__c,
                       MercuryEngineRebate__c,
                       PropCost__c,
                       s_VolumeDiscount__c,
                       m_VolumeDiscount__c,
                       l_VolumeDiscount__c,
                       xl_VolumeDiscount__c,
                       WOW_VolumeDiscount__c,
                (SELECT Id,
                        Sample_Retail_Sale__c,
                        Product_Option__c,
                        Product_Option__r.From_Product__r.Name,
                        Product_Option__r.From_Product__r.Family,
                        Product_Option__r.From_Product__r.RecordType.Name
                  FROM Example_Products__r)
                FROM Boat_Sample_Retail_Sale__c
                WHERE Id = :recordId];
     exampleProducts = record.Example_Products__r;
    }
    else
    {
      if(!test.isRunningTest())
      {
        stdController.addFields( fieldList() );
      }
      record = (Boat_Sample_Retail_Sale__c)stdController.getRecord();
      exampleProducts = new List<Boat_Sample_Retail_Sale_Example_Product__c>();
    }
  }
}