public with sharing class Case_CreatePurchaseOrderController_dh {

  public class Vendor implements Comparable {
    public String name;
    public String id;
    public List<Case_Part__c> caseParts;

    public Vendor(Id supId, String supName ) {
      this.caseParts = new List<Case_Part__c>();
      this.id = supId;
      this.name = supName == null ? 'Un-Set' : supName;
    }

    public Integer compareTo(Object compareTo) {
      Vendor v = (Vendor)compareTo;
      if( this.name == v.name )
        return 0;
      if( this.name > v.name )
        return 1;
      return -1;
    }
  }

  @AuraEnabled(Cacheable=true)
  public static List<Case_Part__c> fetchCaseParts( List<Id> casePartIds )
  {
    return CasePart_Selector.allByIds( casePartIds );
  }

  @AuraEnabled
  public static List<Map<String, Object>> findOpenPOs(
    Id vendorId,
    Id warehouseId,
    List<Id> productIds
  )
  {
    List<Map<String, Object>> result = new List<Map<String, Object>>();
    List<AcctSeedERP__Purchase_Order_Line__c> pols =[
      SELECT
        Id,
        AcctSeedERP__Product__c,
        AcctSeedERP__Quantity__c,
        AcctSeedERP__Quantity_Received__c,
        deliverDate__c,
        AcctSeedERP__Purchase_Order__r.Id,
        AcctSeedERP__Purchase_Order__r.Name,
        AcctSeedERP__Purchase_Order__r.CreatedDate,
        AcctSeedERP__Purchase_Order__r.CreatedBy.Name,
        AcctSeedERP__Purchase_Order__r.AcctSeedERP__Vendor__r.Name,
        AcctSeedERP__Purchase_Order__r.AcctSeedERP__Vendor__c,
        AcctSeedERP__Purchase_Order__r.Estimated_Time_of_Arrival_ETA__c
      FROM AcctSeedERP__Purchase_Order_Line__c
      WHERE AcctSeedERP__Product__c IN :productIds
      AND AcctSeedERP__Purchase_Order__r.Warehouse__c = :warehouseId
      AND AcctSeedERP__Purchase_Order__r.AcctSeedERP__Vendor__c = :vendorId
      AND AcctSeedERP__Purchase_Order__r.AcctSeedERP__Status__c <> 'Closed'
    ];
    for( AcctSeedERP__Purchase_Order_Line__c pol : pols )
    {
      result.add( new Map<String, Object>{
        'createdDate' => pol.AcctSeedERP__Purchase_Order__r.CreatedDate,
        'createdBy' => pol.AcctSeedERP__Purchase_Order__r.CreatedBy.Name,
        'productId' => pol.AcctSeedERP__Product__c,
        'qtyOrdered' => pol.AcctSeedERP__Quantity__c,
        'qtyReceived' => pol.AcctSeedERP__Quantity_Received__c,
        'qtyRemaining' => pol.AcctSeedERP__Quantity__c - pol.AcctSeedERP__Quantity_Received__c,
        'id' => pol.Id,
        'poName' => pol.AcctSeedERP__Purchase_Order__r.Name,
        'eta' => pol.deliverDate__c == null ? pol.AcctSeedERP__Purchase_Order__r.Estimated_Time_of_Arrival_ETA__c : pol.deliverDate__c
      });
    }
    return result;
  }

  @AuraEnabled
  public static Integer checkForParts( String recordId )
  {
    Case_Part__c[] cps = [SELECT Id
                          FROM Case_Part__c
                          WHERE Case__c = :recordId
                          AND Purchase_Order_Line__c = null];
    return cps.size();
  }

  @AuraEnabled
  public static String fetchInitialPoData( String recordId )
  {
    Map<String, String> result = new Map<String, String>();
    Case c = [SELECT Id, ERP_WarehouseId__c FROM Case WHERE Id = :recordId];
    Id whId = c.ERP_WarehouseId__c;
    result.put( 'userWarehouse', String.valueOf(whId) );
    Vendor[] vendors = buildPartsByVendor( recordId );
    if( vendors != null )
      result.put('vendors', JSON.serialize( vendors ) );
    return JSON.serialize( result );
  }

  @AuraEnabled
  public static Case_Part__c linkPurchaseOrderLineToCasePart(
    Id casePartId,
    Id polId
  )
  {
    Case_Part__c cp = new Case_Part__c(
      Id = casePartId,
      Purchase_Order_Line__c = polId
    );
    update cp;
    return cp;
  }

  @AuraEnabled
  public static void createPOlinesAndUdateCase( String[] casePartIds, String poId, Boolean setDefaultVendor )
  {
    createPOlines( casePartIds, poId, setDefaultVendor );
  }

//  private static String findUserWareHouse()
//  {
//    User u = [SELECT Id, Warehouse__c
//              FROM User
//              WHERE Id = :UserInfo.getUserId() ];
//    try {
//      return [SELECT Id
//              FROM AcctSeedERP__Warehouse__c
//              WHERE Name = :u.Warehouse__c ].Id;
//    }
//    catch( Exception e )
//    {
//      return null;
//    }
//  }

  private static Vendor[] buildPartsByVendor( String recordId )
  {
    Case_Part__c[] caseParts = [SELECT Id,
                                   Product__c,
                                   Product__r.Name,
                                   Product__r.ProductCode,
                                   Product__r.AcctSeedERP__Default_Vendor__c,
                                   Product__r.AcctSeedERP__Default_Vendor__r.Name,
                                   Quantity__c
                              FROM Case_Part__c
                              WHERE Case__c = :recordId
                              AND Purchase_Order_Line__c = null ];
    if( caseParts.size() == 0 )
      return null;

    Map<String, Vendor> vendors = new Map<String, Vendor>();
    for( Case_Part__c cp :  caseParts )
    {
      String vendorId = cp.Product__r.AcctSeedERP__Default_Vendor__c == null ?
                        'none' :
                        cp.Product__r.AcctSeedERP__Default_Vendor__c;
      if( !vendors.containsKey(vendorId) )
      {
        vendors.put( vendorId, new Vendor( cp.Product__r.AcctSeedERP__Default_Vendor__c,
                                           cp.Product__r.AcctSeedERP__Default_Vendor__r.Name) );
      }
       vendors.get( vendorId ).caseParts.add( cp );
    }
    Vendor[] result = vendors.values();
    result.sort();
    return result;
  }

  private static void createPOlines( String[] casePartIds,
                                     String poId,
                                     Boolean setDefaultVendor )
  {
    Map<String, AcctSeedERP__Purchase_Order_Line__c> pols = new Map<String, AcctSeedERP__Purchase_Order_Line__c>();
    Set<Id> productIds = new Set<Id>();
    for( Case_Part__c cp : [SELECT Id, Product__c, Quantity__c
                            FROM Case_Part__c
                            WHERE Id IN :casePartIds ] )
    {
      productIds.add( cp.Product__c );
      pols.put( cp.Id, new AcctSeedERP__Purchase_Order_Line__c(
        AcctSeedERP__Product__c = cp.Product__c,
        AcctSeedERP__Quantity__c = cp.Quantity__c,
        AcctSeedERP__Purchase_Order__c = poId
      ));
    }
    insert pols.values();
    Case_Part__c[] caseParts = new List<Case_Part__c>();
    for( String casePartId : pols.keySet() )
    {
      caseParts.add( new Case_Part__c(
        Id = casePartId,
        Purchase_Order_Line__c = pols.get( casePartId ).Id
      ));
    }
    update caseParts;
    if( setDefaultVendor )
    {
      setDefaultVendorOnProducts( productIds, poId );
    }
  }

  private static void setDefaultVendorOnProducts( Set<Id> productIds, String poId )
  {
    AcctSeedERP__Purchase_Order__c po = [SELECT Id,
                                                AcctSeedERP__Vendor__c
                                         FROM AcctSeedERP__Purchase_Order__c
                                         WHERE Id = :poId ];
    Product2[] prods = new List<Product2>();
    for( String pId : productIds )
    {
      prods.add( new Product2(
        Id = pId,
        AcctSeedERP__Default_Vendor__c = po.AcctSeedERP__Vendor__c
      ));
    }
    update prods;
  }
}