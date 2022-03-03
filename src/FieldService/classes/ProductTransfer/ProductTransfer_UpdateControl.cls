/**
 * Created by aminrubel on 23/10/19.
 */

public with sharing class ProductTransfer_UpdateControl {
//  public static void updateControl(
//    List<ProductTransfer> newProductTransfer,
//    Map<Id, ProductTransfer> oldMapProductTransfer
//  ) {
//    for (ProductTransfer productTransferRecord : newProductTransfer) {
//      if (productTransferRecord.Type__c == 'Standard') {
//        if (productTransferRecord.QuantitySent != oldMapProductTransfer.get(productTransferRecord.Id).QuantitySent)
//          productTransferRecord.addError('Quantity of a Transfer cannot be modified.');
//      }
//      if (productTransferRecord.Is_Destination_Warehouse__c && productTransferRecord.Is_Source_Warehouse__c) {
//        productTransferRecord.addError('Cannot transfer from warehouse to warehouse.');
//      }
//      if (
//        productTransferRecord.Is_Serialized__c &&
//        (productTransferRecord.QuantitySent != 1 &&
//        productTransferRecord.QuantitySent != -1 &&
//        productTransferRecord.QuantitySent != 0)
//      ) {
//        productTransferRecord.addError('For serialized products Quantity Sent must be -1,1 or 0.');
//      }
//      if (
//        productTransferRecord.Is_Serialized__c &&
//        (productTransferRecord.QuantityReceived != 1 &&
//        productTransferRecord.QuantityReceived != -1 &&
//        productTransferRecord.QuantityReceived != 0)
//      ) {
//        productTransferRecord.addError('For serialized products Quantity Received must be -1,1 or 0.');
//      }
//    }
//  }
}
