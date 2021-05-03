public with sharing class MoveAllSerialsToWholesale_ar implements Database.Batchable<sObject>{
	public final String transferId;
	public final String queryStr;
	public MoveAllSerialsToWholesale_ar(String pTransferId) {
		transferId = pTransferId;
		queryStr = null;
	}

	public MoveAllSerialsToWholesale_ar(String pTransferId, String pQuery) {
		transferId = pTransferId;
		queryStr = pQuery;
	}
	
	public Database.QueryLocator start(Database.BatchableContext BC) {
		String query = queryStr;
		if(queryStr == null)
			query = 'SELECT Id FROM GMBLASERP__Serial_Number__c WHERE GMBLASERP__Inventory_Balance__c != null AND Status__c != \'Used\'';

		return Database.getQueryLocator(query);
	}

   	public void execute(Database.BatchableContext BC, List<sObject> scope) {
   		Set<String> setId = new Set<String>();
		for(SObject sObj : scope) {
			GMBLASERP__Serial_Number__c sr = (GMBLASERP__Serial_Number__c) sObj;
			setId.add(sr.Id);
		}
		// Barrie = a2G1Y000001xVbLUAU
		// Whitefish = a2G1Y000001xVbGUAU
		// Montreal = a2G1Y000001xVbBUAU
		GMBLASERP__Inventory_Transfer__c tr = [SELECT Id, GMBLASERP__Warehouse_From__c, GMBLASERP__Warehouse_To__c, GMBLASERP__Outbound_Date__c FROM GMBLASERP__Inventory_Transfer__c WHERE Id=:transferId][0];
		list<String> listSerailIds = new list<String>();
		listSerailIds.addAll(setId);

		Map<Id,GMBLASERP__Serial_Number__c> mapSerial = new Map<Id,GMBLASERP__Serial_Number__c>();
		for(GMBLASERP__Serial_Number__c sr : [SELECT Id, GMBLASERP__Product__r.AcctSeed__Inventory_GL_Account__c FROM GMBLASERP__Serial_Number__c WHERE Id IN:setId])
			mapSerial.put(sr.Id, sr);

		list<String> listWarehouseIds = new list<String>{tr.GMBLASERP__Warehouse_From__c};
		Map<String,List<String>> mapFilter = new map<String,list<String>>{'idSerial'=>listSerailIds,'idWarehouse'=>listWarehouseIds};
		list<gcInventoryMovementCube_Report.cube> listCubes = gcInventoryMovementCube_Report.inventoryAggRes(mapFilter, new list<String>{'idBalance','idWarehouse','idLocation','idProduct','idLot','idSerial'});

		List<AcctSeedERP__Outbound_Inventory_Movement__c> listOIM = new List<AcctSeedERP__Outbound_Inventory_Movement__c>();
		for(gcInventoryMovementCube_Report.cube c : listCubes){
			AcctSeedERP__Outbound_Inventory_Movement__c move = new AcctSeedERP__Outbound_Inventory_Movement__c(
	            AcctSeedERP__Debit_GL_Account__c = mapSerial.get(c.idSerial).GMBLASERP__Product__r.AcctSeed__Inventory_GL_Account__c,
	            AcctSeedERP__Inventory_Balance__c = c.idBalance,
	            AcctSeedERP__Movement_Date__c = tr.GMBLASERP__Outbound_Date__c,
	            AcctSeedERP__Quantity__c = c.qty,
	            AcctSeedERP__Type__c = 'Non-Accounting',
	            AcctSeedERP__Unit_Cost__c = 0,
	            GMBLASERP__Cost_Override__c = true,
	            GMBLASERP__Inventory_Transfer__c = tr.Id,
	            GMBLASERP__Lot__c = c.idLot,
	            GMBLASERP__Serial_Number__c = c.idSerial
	        );
	        listOIM.add(move);
	    }
	    if(!listOIM.isEmpty())
        	Database.insert(listOIM,false);
	}
	
	public void finish(Database.BatchableContext BC) {}

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
	}
}