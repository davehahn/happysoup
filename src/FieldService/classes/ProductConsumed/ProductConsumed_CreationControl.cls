public with sharing class ProductConsumed_CreationControl {
  public static void creationControl(List<ProductConsumed> newProductConsumed) {
    List<ProductConsumed> newProductConsumedStandard = new List<ProductConsumed>();
    Set<Id> WorkOrderIds = new Set<Id>();
    Set<Id> WorkOrderLineItemsIds = new Set<Id>();
    Set<Id> WorkdOrderAndWorkOrderLinesItemsIds = new Set<Id>();
    List<ProductRequired> productRequired = new List<ProductRequired>();
    List<WorkOrderLineItem> workOrderLineItemsRecords = new List<WorkOrderLineItem>();
    Map<String, Id> productRequiredMappedToParentRecordKey = new Map<String, Id>();
    Map<Id, Id> workOrderMappedToWorkOrderLineItem = new Map<Id, Id>();
    Set<Id> productRequiredIds = new Set<Id>();
    String mappingKey;
    String mappingKey2;
    String substringProductId;

    for (ProductConsumed productConsumedRecord : newProductConsumed) {
      if (productConsumedRecord.Type__c == 'Standard') {
        newProductConsumedStandard.add(productConsumedRecord);
      }
    }

    for (ProductConsumed productConsumedRecord : newProductConsumedStandard) {
      if (productConsumedRecord.WorkOrderId != null) {
        WorkOrderIds.add(productConsumedRecord.WorkOrderId);
      }
      if (productConsumedRecord.WorkOrderLineItemId != null) {
        WorkOrderLineItemsIds.add(productConsumedRecord.WorkOrderLineItemId);
      }
    }

    WorkdOrderAndWorkOrderLinesItemsIds.addAll(WorkOrderLineItemsIds);
    WorkdOrderAndWorkOrderLinesItemsIds.addAll(WorkOrderIds);

    productRequired = [
      SELECT Id, Product2Id, ParentRecordId
      FROM ProductRequired
      WHERE ParentRecordId IN :WorkdOrderAndWorkOrderLinesItemsIds
    ];

    if (productRequired.size() > 0) {
      for (productRequired prodReq : productRequired) {
        mappingKey = prodReq.ParentRecordId;
        substringProductId = prodReq.Product2Id;
        substringProductId = substringProductId.substring(0, 15);
        mappingKey += substringProductId;
        productRequiredMappedToParentRecordKey.put(mappingKey, substringProductId);

        System.debug('Product Required Product Id: ' + substringProductId);
      }
    }

    for (ProductConsumed productConsumedRecord : newProductConsumedStandard) {
      if (productConsumedRecord.WorkOrderId != null && productConsumedRecord.WorkOrderLineItemId == null) {
        mappingKey = productConsumedRecord.WorkOrderId;
        mappingKey += productConsumedRecord.ProductId__c;

        System.debug(
          'Product Consumed PricebookEntryId: ' +
          productConsumedRecord.PricebookEntryId +
          ' and Product2Id: ' +
          productConsumedRecord.ProductId__c
        );

        if (!(productRequiredMappedToParentRecordKey.get(mappingKey) != null)) {
          productConsumedRecord.addError(
            'The Product Consumed cannot be created since the Product selected is not part of the Products Required from the Work Order'
          );
        }
      } else if (productConsumedRecord.WorkOrderLineItemId != null) {
        mappingKey = productConsumedRecord.WorkOrderLineItemId;
        mappingKey += productConsumedRecord.ProductId__c;

        mappingKey2 = productConsumedRecord.WorkOrderId;
        mappingKey2 += productConsumedRecord.ProductId__c;

        if (
          !(productRequiredMappedToParentRecordKey.get(mappingKey) != null ||
          productRequiredMappedToParentRecordKey.get(mappingKey2) != null)
        ) {
          System.debug(
            'Mapping 1 ' +
            mappingKey +
            ' result: ' +
            productRequiredMappedToParentRecordKey.get(mappingKey)
          );
          System.debug(
            'Mapping 2 ' +
            mappingKey2 +
            ' result: ' +
            productRequiredMappedToParentRecordKey.get(mappingKey2)
          );
          productConsumedRecord.addError(
            'The Product Consumed cannot be created since the Product selected is not part of the Products Required from the Work Order or the Work Order Line Item'
          );
        }
      }
    }
  }
}
