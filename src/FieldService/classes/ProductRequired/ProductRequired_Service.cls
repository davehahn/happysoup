/**
 * Created by dave on 2019-08-07.
 */

public with sharing class ProductRequired_Service {
  public static Set<Id> ignoreProductRecordTypes {
    get {
      if (ignoreProductRecordTypes == null) {
        Application_RecordType.ProductRTs pRts = new Application_RecordType().getProductRecordTypes();
        ignoreProductRecordTypes = new Set<Id>{ pRts.getFeesId() };
      }
      return ignoreProductRecordTypes;
    }
    private set;
  }

  //  public static List<ProductRequired> createFromWorkOrderLineItemId_AndOppId( Id woliId, Id oppId)
  //  {
  //    List<ProductRequired> result = new List<ProductRequired>();
  //    List<OpportunityLineItem> forProductRequired = new List<OpportunityLineItem>();
  //    List<OpportunityLineItem> insuranceItems = new List<OpportunityLineItem>();
  //    List<OpportunityLineItem> protectionAndServiceItems = new List<OpportunityLineItem>();
  //    Id insuranceRT = LGND_Utilities.recordTypeIdFromName('Product2', 'Insurance');
  //    Id p_and_s_RT = LGND_Utilities.recordTypeIdFromName('Product2', 'Protection and Services');
  //    for( OpportunityLineItem oli : OpportunityLineItem_Selector.selectAllByOpportunityId( oppId ) )
  //    {
  //      if( oli.PricebookEntry.Product2.RecordTypeId == insuranceRT )
  //        insuranceItems.add( oli );
  //      else if( oli.PricebookEntry.Product2.RecordTypeId == p_and_s_RT &&
  //               oli.PricebookEntry.Product2.Family == 'Extended Warranty' )
  //        protectionAndServiceItems.add( oli );
  //      else
  //        forProductRequired.add( oli );
  //    }
  //
  //    Map<Id, WorkOrderLineItem> oppId_woli_map = new Map<Id, WorkOrderLineItem>();
  //    for( WorkOrderLineItem woli : WorkOrderLineItem_Selector.selectAllById_includingWorkOrderWithERP( woliIds) )
  //    {
  //      if( woli.Is_From_Opportunity__c && woli.WorkOrder.Opportunity__c != null )
  //      {
  //        oppId_woli_map.put( woli.WorkOrder.Opportunity__c, woli );
  //      }
  //    }
  //    if( oppId_woli_map.size() > 0 )
  //    {
  //      for( OpportunityLineItem oli : [SELECT Id,
  //                                             Quantity,
  //                                             PricebookEntry.Product2Id,
  //                                             OpportunityId
  //                                          FROM OpportunityLineItem
  //                                          WHERE OpportunityId IN :oppId_woli_map.keySet() ] )
  //      {
  //        result.add( new ProductRequired(
  //          ParentRecordId = oppId_woli_map.get( oli.OpportunityId ).Id,
  //          Product2Id = oli.PricebookEntry.Product2Id,
  //          QuantityRequired = oli.Quantity,
  //          QuantityUnitOfMeasure = 'Each'
  //        ));
  //      }
  //      insert result;
  //    }
  //    return result;
  //  }

  public static ProductRequired buildFromWorkOrderLineItemId_and_OpportunityLineItem(
    Id woliId,
    OpportunityLineItem oli
  ) {
    return new ProductRequired(
      ParentRecordId = woliId,
      Product2Id = oli.Product2Id,
      QuantityRequired = oli.Quantity,
      QuantityUnitOfMeasure = 'Each'
    );
  }

  public static ProductRequired newFromMaterial(AcctSeedERP__Material__c mat, Id woliId) {
    return new ProductRequired(
      ParentRecordId = woliId,
      Product2Id = mat.AcctSeedERP__Product__c,
      QuantityRequired = mat.AcctSeedERP__Quantity_Per_Unit__c,
      QuantityUnitOfMeasure = 'Each',
      Material__c = mat.Id
    );
  }
}
