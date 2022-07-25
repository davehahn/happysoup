/**
 * Created by aminrubel on 4/11/19.
 */

public with sharing class ProductTransfer_DeleteControl {
  //  public static void deleteControl(Map<Id, ProductTransfer> oldMapProductTransfer) {
  //    for (ProductTransfer productTransferRecord : oldMapProductTransfer.values()) {
  //      // Find the Material and remove from MFG
  //      // The issue here is that there can be multiple MFG. Which one should we remove needs to identify
  //      // But we do not have a relationship with ProductTransfer to MFGMovement
  //      // For now we will remove the MFG order with the Material
  //      Set<Id> setIdP = new Set<Id>();
  //      Map<Id, Id> mapPTIWOI = new Map<Id, Id>();
  //      Map<Id, Id> mapPartPTIWOI = new Map<Id, Id>();
  //      Map<Id, Map<Id, ProductTransfer>> mapProdWOITransfer = new Map<Id, Map<Id, ProductTransfer>>();
  //      for (ProductTransfer pit : oldMapProductTransfer.values()) {
  //        if (pit.Is_Serialized__c) {
  //          setIdP.add(pit.Product2Id);
  //          mapPTIWOI.put(pit.Id, pit.Work_Order_Line_Item__c);
  //        } else if (pit.Inventory_Product__c) {
  //          setIdP.add(pit.Product2Id);
  //          if (!mapProdWOITransfer.containsKey(pit.Product2Id))
  //            mapProdWOITransfer.put(pit.Product2Id, new Map<Id, ProductTransfer>());
  //          mapProdWOITransfer.get(pit.Product2Id).put(pit.Work_Order_Line_Item__c, pit);
  //          mapPartPTIWOI.put(pit.Id, pit.Work_Order_Line_Item__c);
  //        }
  //      }
  //      if (!mapPTIWOI.isEmpty()) {
  //        /// Retrieve all the Product Required
  //        Map<Id, Map<Id, ProductRequired>> mapPR = new Map<Id, Map<Id, ProductRequired>>();
  //        Map<Id, Id> mapMatSerial = new Map<Id, Id>();
  //        for (ProductRequired pr : [
  //          SELECT Id, Product2Id, Material__c, ParentRecordId
  //          FROM ProductRequired
  //          WHERE ParentRecordId IN :mapPTIWOI.values() AND Product2Id IN :setIdP
  //        ]) {
  //          if (!mapPR.containsKey(pr.Product2Id))
  //            mapPR.put(pr.Product2Id, new Map<Id, ProductRequired>());
  //          if (!mapPR.get(pr.Product2Id).containsKey(pr.ParentRecordId))
  //            mapPR.get(pr.Product2Id).put(pr.ParentRecordId, pr);
  //          mapMatSerial.put(pr.Material__c, null);
  //        }
  //        /// Load all serial numbers based on Material
  //        Set<Id> setIdMaterials = new Set<Id>();
  //        Map<Id, Set<String>> mapProjectMatl = new Map<Id, Set<String>>();
  //        Map<Id, String> mapProjectWarehouse = new Map<Id, String>();
  //        //undoWipSelected(idProject,setIdMaterials,pIdWarehouse);
  //        if (!mapMatSerial.isEmpty()) {
  //          for (AcctSeedERP__Material__c matl : [
  //            SELECT
  //              Id,
  //              AcctSeedERP__Project__c,
  //              AcctSeedERP__Project__r.GMBLASERP__Warehouse__c,
  //              GMBLASERP__Serial_Number__c
  //            FROM AcctSeedERP__Material__c
  //            WHERE Id IN :mapMatSerial.keySet()
  //          ]) {
  //            if (!mapProjectMatl.containsKey(matl.AcctSeedERP__Project__c))
  //              mapProjectMatl.put(matl.AcctSeedERP__Project__c, new Set<String>());
  //            mapProjectMatl.get(matl.AcctSeedERP__Project__c).add(matl.Id);
  //            mapProjectWarehouse.put(matl.AcctSeedERP__Project__c, matl.AcctSeedERP__Project__r.GMBLASERP__Warehouse__c);
  //          }
  //        }
  //        /// Calling for removal of WIP in runtime.
  //        Boolean oldVal = GCR_InventoryMovement.disableFSL;
  //        GCR_InventoryMovement.disableFSL = true;
  //        for (Id idProject : mapProjectMatl.keySet()) {
  //          gcProject_AccountingActions.undoWipSelected(
  //            idProject,
  //            mapProjectMatl.get(idProject),
  //            mapProjectWarehouse.get(idProject)
  //          );
  //        }
  //        GCR_InventoryMovement.disableFSL = oldVal;
  //      }
  //      if (!mapPartPTIWOI.isEmpty()) {
  //        /// Retrieve all the Product Required
  //        Map<Id, Map<Id, ProductRequired>> mapPR = new Map<Id, Map<Id, ProductRequired>>();
  //        Map<Id, Id> mapMatSerial = new Map<Id, Id>();
  //        Map<Id, List<Map<String, String>>> mapProjectMaterial = new Map<Id, List<Map<String, String>>>();
  //        Map<Id, String> mapProjectWarehouse = new Map<Id, String>();
  //        for (ProductRequired pr : [
  //          SELECT
  //            Id,
  //            Product2Id,
  //            Material__c,
  //            Material__r.AcctSeedERP__Project__c,
  //            Material__r.AcctSeedERP__Project__r.GMBLASERP__Warehouse__c,
  //            ParentRecordId
  //          FROM ProductRequired
  //          WHERE ParentRecordId IN :mapPartPTIWOI.values() AND Product2Id IN :setIdP
  //        ]) {
  //          mapProjectWarehouse.put(
  //            pr.Material__r.AcctSeedERP__Project__c,
  //            pr.Material__r.AcctSeedERP__Project__r.GMBLASERP__Warehouse__c
  //          );
  //          ProductTransfer pt = mapProdWOITransfer.get(pr.Product2Id).get(pr.ParentRecordId);
  //          if (!mapProjectMaterial.containsKey(pr.Material__r.AcctSeedERP__Project__c))
  //            mapProjectMaterial.put(pr.Material__r.AcctSeedERP__Project__c, new List<Map<String, String>>());
  //
  //          Map<String, String> mapMaterial = new Map<String, String>();
  //          mapMaterial.put('idMaterial', pr.Material__c);
  //          Decimal qtyRec = 0;
  //          if (pt.QuantityReceived != null)
  //            qtyRec = pt.QuantityReceived;
  //          mapMaterial.put('qtyToMove', String.valueOf(qtyRec * -1));
  //          mapProjectMaterial.get(pr.Material__r.AcctSeedERP__Project__c).add(mapMaterial);
  //        }
  //        /// Load all serial numbers based on Material
  //        Boolean oldVal = GCR_InventoryMovement.disableFSL;
  //        GCR_InventoryMovement.disableFSL = true;
  //        System.debug(loggingLevel.error, 'mapProjectMaterial:' + mapProjectMaterial);
  //        for (Id idProject : mapProjectMaterial.keySet()) {
  //          System.debug(loggingLevel.error, 'idProject:' + idProject);
  //          System.debug(loggingLevel.error, 'idProjectWH:' + mapProjectWarehouse.get(idProject));
  //          //(Id idProject, String pIdWarehouse, List<Map<String,String>> listMaterials, String movementDate)
  //          list<String> lstMsg = gcProject_AccountingActions.createWipRASelected(
  //            idProject,
  //            mapProjectWarehouse.get(idProject),
  //            mapProjectMaterial.get(idProject),
  //            Date.today().format()
  //          );
  //          if (lstMsg.size() > 0) {
  //            String msg = '';
  //            for (String mg : lstMsg)
  //              msg += mg + ' ';
  //
  //            throw new gcException(msg);
  //          }
  //        }
  //        GCR_InventoryMovement.disableFSL = oldVal;
  //      }
  //      System.debug(loggingLevel.error, 'mapPartPTIWOI:' + mapPartPTIWOI);
  //      //throw new gcException('testing exceptions');
  //    }
  //  }
}
